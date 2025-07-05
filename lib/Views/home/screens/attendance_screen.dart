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

  Future<void> _markAttendance(Student student, String status) async {
    try {
      final success = await DatabaseHelper().markAttendance(
        student.studentId,
        status,
        'CurrentUser',
      );
      if (success) {
        // Reload all attendance logs for today
        allTodayAttendance = await DatabaseHelper().getTodayAttendance();
        // Reload students and their attendance for the selected class
        await _loadStudentsAndAttendance();
        HapticFeedback.lightImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Attendance marked: ${student.fullName} - $status'),
            backgroundColor:
                status == 'Present'
                    ? AppColors.success
                    : status == 'Late'
                    ? AppColors.warning
                    : AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
        setState(() {}); // Ensure UI updates
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to mark attendance: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: AppColors.cardBackground,
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
