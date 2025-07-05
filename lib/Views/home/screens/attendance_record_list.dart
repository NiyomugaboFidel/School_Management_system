import 'package:flutter/material.dart';
import 'package:sqlite_crud_app/models/attendance.dart';
import 'package:sqlite_crud_app/models/student.dart';
import 'package:sqlite_crud_app/constants/app_colors.dart';

class AttendanceRecordList extends StatelessWidget {
  final List<AttendanceLog> records;
  final Map<int, Student> studentMap;

  const AttendanceRecordList({
    Key? key,
    required this.records,
    required this.studentMap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) {
      return const Center(
        child: Text('No attendance records for this class today.'),
      );
    }
    return ListView.builder(
      itemCount: records.length,
      itemBuilder: (context, i) {
        final log = records[i];
        final student = studentMap[log.studentId];
        final color =
            log.status == AttendanceStatus.present
                ? AppColors.success
                : log.status == AttendanceStatus.late
                ? AppColors.warning
                : AppColors.error;
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: color.withOpacity(0.2),
            child: Text(student?.fullName.substring(0, 1) ?? '?'),
          ),
          title: Text(student?.fullName ?? 'Unknown'),
          subtitle: Text('Status: ${log.status.value}'),
          trailing: Text(
            '${log.markedAt.hour.toString().padLeft(2, '0')}:${log.markedAt.minute.toString().padLeft(2, '0')}',
          ),
        );
      },
    );
  }
}
