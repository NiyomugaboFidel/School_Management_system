import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sqlite_crud_app/SQLite/database_helper_full.dart';
import 'package:sqlite_crud_app/models/student.dart';
import 'package:sqlite_crud_app/models/attendance.dart';
import 'package:sqlite_crud_app/constants/app_colors.dart';

class AttendanceScreen extends StatefulWidget {
  @override
  _AttendanceScreenState createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  List<Student> students = [];
  List<AttendanceLog> todayAttendance = [];
  bool isLoading = false;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    try {
      students = await DatabaseHelper().getAllStudents();
      todayAttendance = await DatabaseHelper().getTodayAttendance();
    } catch (e) {
      debugPrint('Error loading attendance data: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _markAttendance(Student student, String status) async {
    try {
      final success = await DatabaseHelper().markAttendance(
        student.studentId,
        status,
        'CurrentUser', // Replace with actual user
      );
      if (success) {
        todayAttendance = await DatabaseHelper().getTodayAttendance();
        setState(() {});
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

  Widget _buildStudentsList() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    final filteredStudents =
        students.where((student) {
          return (student.fullName.toLowerCase().contains(
                searchQuery.toLowerCase(),
              ) ||
              student.regNumber.toLowerCase().contains(
                searchQuery.toLowerCase(),
              ) ||
              (student.className?.toLowerCase().contains(
                    searchQuery.toLowerCase(),
                  ) ??
                  false));
        }).toList();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            onChanged: (value) => setState(() => searchQuery = value),
            decoration: InputDecoration(
              hintText: 'Search students by name, ID, or class...',
              prefixIcon: const Icon(Icons.search, color: AppColors.textLight),
              suffixIcon:
                  searchQuery.isNotEmpty
                      ? IconButton(
                        icon: const Icon(
                          Icons.clear,
                          color: AppColors.textLight,
                        ),
                        onPressed: () => setState(() => searchQuery = ''),
                      )
                      : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: AppColors.cardBackground,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
        ),
        if (filteredStudents.isEmpty)
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.search_off,
                    size: 64,
                    color: AppColors.textLight.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No students found',
                    style: TextStyle(
                      fontSize: 18,
                      color: AppColors.textLight,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Try adjusting your search criteria',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textLight.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: filteredStudents.length,
              itemBuilder: (context, index) {
                final student = filteredStudents[index];
                return _buildStudentCard(student);
              },
            ),
          ),
      ],
    );
  }

  Widget _buildStudentCard(Student student) {
    final hasAttendance = todayAttendance.any(
      (log) => log.studentId == student.studentId,
    );
    final attendanceStatus =
        hasAttendance
            ? todayAttendance
                .firstWhere((log) => log.studentId == student.studentId)
                .status
            : null;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border:
            hasAttendance
                ? Border.all(
                  color:
                      attendanceStatus == AttendanceStatus.present
                          ? AppColors.success
                          : attendanceStatus == AttendanceStatus.late
                          ? AppColors.warning
                          : AppColors.error,
                  width: 2,
                )
                : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  child: Text(
                    student.fullName.split(' ').map((e) => e[0]).join(''),
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student.fullName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${student.regNumber} • ${student.className ?? ''}',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textLight,
                        ),
                      ),
                    ],
                  ),
                ),
                if (hasAttendance)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color:
                          attendanceStatus == AttendanceStatus.present
                              ? AppColors.success
                              : attendanceStatus == AttendanceStatus.late
                              ? AppColors.warning
                              : AppColors.error,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      attendanceStatus?.value ?? '',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            if (!hasAttendance) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildAttendanceButton(
                      'Present',
                      Icons.check_circle,
                      AppColors.success,
                      () => _markAttendance(student, 'Present'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildAttendanceButton(
                      'Late',
                      Icons.access_time,
                      AppColors.warning,
                      () => _markAttendance(student, 'Late'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildAttendanceButton(
                      'Absent',
                      Icons.cancel,
                      AppColors.error,
                      () => _markAttendance(student, 'Absent'),
                    ),
                  ),
                ],
              ),
            ] else ...[
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    todayAttendance.removeWhere(
                      (log) => log.studentId == student.studentId,
                    );
                  });
                },
                icon: const Icon(Icons.edit, size: 16),
                label: const Text('Change Attendance'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceButton(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Material(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Column(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAttendanceHistory() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (todayAttendance.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment_outlined,
              size: 64,
              color: AppColors.textLight.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No attendance records today',
              style: TextStyle(
                fontSize: 18,
                color: AppColors.textLight,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start marking attendance to see records here',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textLight.withOpacity(0.7),
              ),
            ),
          ],
        ),
      );
    }
    final presentStudents =
        todayAttendance.where((log) => log.status == 'Present').toList();
    final lateStudents =
        todayAttendance.where((log) => log.status == 'Late').toList();
    final absentStudents =
        todayAttendance.where((log) => log.status == 'Absent').toList();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Present',
                  presentStudents.length.toString(),
                  Icons.check_circle,
                  AppColors.success,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildSummaryCard(
                  'Late',
                  lateStudents.length.toString(),
                  Icons.access_time,
                  AppColors.warning,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildSummaryCard(
                  'Absent',
                  absentStudents.length.toString(),
                  Icons.cancel,
                  AppColors.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Today\'s Attendance Timeline',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 12),
          ...todayAttendance
              .map((log) => _buildAttendanceLogItem(log))
              .toList(),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    String count,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            count,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          Text(
            title,
            style: TextStyle(fontSize: 12, color: AppColors.textLight),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceLogItem(AttendanceLog log) {
    final color =
        log.status == AttendanceStatus.present
            ? AppColors.success
            : log.status == AttendanceStatus.late
            ? AppColors.warning
            : AppColors.error;
    final timeString =
        '${log.markedAt.hour.toString().padLeft(2, '0')}:${log.markedAt.minute.toString().padLeft(2, '0')}';
    // Find the student for this log
    final student = students.firstWhere(
      (s) => s.studentId == log.studentId,
      orElse:
          () => Student(
            studentId: log.studentId,
            regNumber: '',
            fullName: 'Unknown',
            classId: 0,
            className: '',
            levelName: '',
            isActive: true,
          ),
    );
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 22,
            backgroundColor: color.withOpacity(0.15),
            child: Text(
              student.fullName.isNotEmpty
                  ? student.fullName.split(' ').map((e) => e[0]).join('')
                  : '?',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Student info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student.fullName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      'ID: ${student.studentId}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textLight,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (student.className != null &&
                        student.className!.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Text(
                        student.className!,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textLight,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Marked: $timeString',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textLight.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          // Status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.13),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              log.status.value,
              style: TextStyle(
                fontSize: 13,
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
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
            children: [_buildStudentsList(), _buildAttendanceHistory()],
          ),
        ),
      ],
    );
  }
}
