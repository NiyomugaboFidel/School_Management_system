import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sqlite_crud_app/SQLite/database_helper.dart';
import 'package:sqlite_crud_app/models/student.dart';
import 'package:sqlite_crud_app/models/attendance.dart';
import 'package:sqlite_crud_app/constants/app_colors.dart';
import 'package:sqlite_crud_app/Views/home/screens/class_list.dart';
import 'package:sqlite_crud_app/Views/home/screens/student_list.dart';
import 'package:sqlite_crud_app/Views/home/screens/attendance_record_list.dart';
import 'package:sqlite_crud_app/models/class.dart';
import 'package:sqlite_crud_app/models/level.dart';
import '../../../Components/attendance_result_popup.dart';
import '../../../services/attendance_service.dart';

class AttendanceScreen extends StatefulWidget {
  @override
  _AttendanceScreenState createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  List<Level> levels = [];
  List<SchoolClass> classes = [];
  SchoolClass? selectedClass;
  List<Student> students = [];
  List<AttendanceLog> todayAttendance = [];
  List<AttendanceLog> allTodayAttendance = [];
  bool isLoading = false;
  String searchQuery = '';

  List<Student> _globalStudents = [];
  bool _studentsLoaded = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadLevelsAndClasses();
    _ensureGlobalStudentsLoaded();
  }

  Future<void> _loadLevelsAndClasses() async {
    setState(() => isLoading = true);
    try {
      levels = await DatabaseHelper().getAllLevels();
      classes = await DatabaseHelper().getAllClasses();
      allTodayAttendance = await DatabaseHelper().getTodayAttendance();
    } catch (e) {
      debugPrint('Error loading levels/classes: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _loadStudentsAndAttendance() async {
    if (selectedClass == null) return;
    setState(() => isLoading = true);
    try {
      students = await DatabaseHelper().getStudentsByClass(
        selectedClass!.classId,
      );
      todayAttendance =
          allTodayAttendance
              .where((log) => students.any((s) => s.studentId == log.studentId))
              .toList();
    } catch (e) {
      debugPrint('Error loading students/attendance: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _ensureGlobalStudentsLoaded() async {
    if (!_studentsLoaded) {
      _globalStudents = await DatabaseHelper().getAllStudents();
      _studentsLoaded = true;
    }
  }

  void _onClassSearchChanged(String value) {
    setState(() => searchQuery = value);
  }

  void _backToClassList() {
    setState(() {
      selectedClass = null;
      students = [];
      todayAttendance = [];
    });
  }

  Map<int, int> get _studentCounts {
    final map = <int, int>{};
    for (final c in classes) {
      map[c.classId] = c.studentCount;
    }
    return map;
  }

  Map<int, int> get _attendanceCounts {
    final Map<int, int> map = {for (final c in classes) c.classId: 0};
    // Build global studentId -> classId map
    final Map<int, int> studentIdToClassId = {
      for (final s in _globalStudents) s.studentId: s.classId,
    };
    for (final log in allTodayAttendance) {
      final classId = studentIdToClassId[log.studentId];
      if (classId != null) {
        map[classId] = (map[classId] ?? 0) + 1;
      }
    }
    return map;
  }

  void showAttendancePopup(
    BuildContext context, {
    required String studentName,
    required String studentId,
    required String gender,
    required String imageUrl,
    required String status,
    required bool success,
  }) {
    final overlay = Overlay.of(context);
    final entry = OverlayEntry(
      builder:
          (_) => AttendanceResultPopup(
            studentName: studentName,
            studentId: studentId,
            gender: gender,
            imageUrl: imageUrl,
            status: status,
            success: success,
          ),
    );
    overlay.insert(entry);
    // Auto-dismiss is handled by the popup itself
  }

  Future<void> _markAttendance(Student student, String status) async {
    try {
      final result = await AttendanceService.instance.markAttendance(
        student.studentId,
        status,
        'CurrentUser',
      );

      // Handle AttendanceResult object
      bool success = result.isSuccess;

      // Always show popup after local mark
      AttendanceResultPopup.show(
          context,
          studentName: student.fullName,
          studentId: student.studentId.toString(),
          gender: 'N/A',
          imageUrl: student.profileImage ?? '',
          status: status,
        success: success,
        );

      // Reload attendance data from local DB
        await _loadStudentsAndAttendance();
      setState(() {});

      if (success) {
        HapticFeedback.lightImpact();
      } else {
        // Show error snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to mark attendance for ${student.fullName}'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // Show failure popup for exceptions
      AttendanceResultPopup.show(
        context,
        studentName: student.fullName,
        studentId: student.studentId.toString(),
        gender: 'N/A',
        imageUrl: student.profileImage ?? '',
        status: status,
        success: false,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error marking attendance: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: AppColors.scaffoldWithBoxBackground,
          child: TabBar(
            controller: _tabController,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textLight,
            indicatorColor: AppColors.primary,
            indicatorWeight: 3,
            tabs: const [
              Tab(text: 'Mark Attendance'),
              Tab(text: 'Today\'s Records'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              // Mark Attendance Tab
              isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : selectedClass == null
                  ? ClassList(
                    classes: classes,
                    onClassSelected: (c) async {
                      setState(() => selectedClass = c);
                      await _loadStudentsAndAttendance();
                    },
                    selectedClassId: selectedClass?.classId,
                    searchQuery: searchQuery,
                    onSearchChanged: _onClassSearchChanged,
                    studentCounts: _studentCounts,
                    attendanceCounts: _attendanceCounts,
                  )
                  : Column(
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back),
                            onPressed: _backToClassList,
                          ),
                          Text(
                            selectedClass?.fullName ?? '',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Expanded(
                        child: StudentList(
                          students: students,
                          attendanceStatus: {
                            for (var log in todayAttendance)
                              log.studentId: log.status.value,
                          },
                          onMarkAttendance: (student, status) async {
                            await _markAttendance(student, status);
                          },
                        ),
                      ),
                    ],
                  ),
              // Today's Records Tab
              isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : selectedClass == null
                  ? ClassList(
                    classes: classes,
                    onClassSelected: (c) async {
                      setState(() => selectedClass = c);
                      await _loadStudentsAndAttendance();
                    },
                    selectedClassId: selectedClass?.classId,
                    searchQuery: searchQuery,
                    onSearchChanged: _onClassSearchChanged,
                    studentCounts: _studentCounts,
                    attendanceCounts: _attendanceCounts,
                  )
                  : Column(
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back),
                            onPressed: _backToClassList,
                          ),
                          Text(
                            selectedClass?.fullName ?? '',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Expanded(
                        child: AttendanceRecordList(
                          records: todayAttendance,
                          studentMap: {for (var s in students) s.studentId: s},
                        ),
                      ),
                    ],
                  ),
            ],
          ),
        ),
      ],
    );
  }
}
