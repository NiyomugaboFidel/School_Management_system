import 'package:flutter/material.dart';
import 'package:sqlite_crud_app/SQLite/database_helper_full.dart';
import 'package:sqlite_crud_app/models/attendance.dart';
import 'package:sqlite_crud_app/models/payment.dart';
import 'package:sqlite_crud_app/models/discipline.dart';
import 'package:sqlite_crud_app/constants/app_colors.dart';

class RecentRecordsScreen extends StatelessWidget {
  const RecentRecordsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Recent Records'),
          backgroundColor: AppColors.primary,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Attendance'),
              Tab(text: 'Payments'),
              Tab(text: 'Discipline'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _RecentAttendanceTab(),
            _RecentPaymentsTab(),
            _RecentDisciplineTab(),
          ],
        ),
      ),
    );
  }
}

class _RecentAttendanceTab extends StatelessWidget {
  const _RecentAttendanceTab();
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<AttendanceLog>>(
      future: DatabaseHelper().getTodayAttendance(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No attendance records for today.'));
        }
        final logs = snapshot.data!;
        return ListView.separated(
          itemCount: logs.length,
          separatorBuilder: (_, __) => const Divider(),
          itemBuilder: (context, i) {
            final log = logs[i];
            return ListTile(
              leading: const Icon(Icons.access_time, color: AppColors.primary),
              title: Text(log.studentId.toString()),
              subtitle: Text(
                '${log.status.value} at '
                '${log.markedAt.hour.toString().padLeft(2, '0')}:${log.markedAt.minute.toString().padLeft(2, '0')}',
              ),
            );
          },
        );
      },
    );
  }
}

class _RecentPaymentsTab extends StatelessWidget {
  const _RecentPaymentsTab();
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Payment>>(
      future: DatabaseHelper().getRecentPayments(limit: 50),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No recent payments.'));
        }
        final payments = snapshot.data!;
        return ListView.separated(
          itemCount: payments.length,
          separatorBuilder: (_, __) => const Divider(),
          itemBuilder: (context, i) {
            final p = payments[i];
            // You may want to fetch the student by ID if you have a student list or cache
            // For now, just show initials from studentId and a placeholder name
            String initials =
                p.studentId.toString().isNotEmpty
                    ? p.studentId.toString().substring(0, 1).toUpperCase()
                    : '?';
            // If you have a student name, replace 'Unknown' with the actual name
            String studentName = 'Unknown';
            // Optionally, fetch student name from a cache or DB if available
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.success.withOpacity(0.15),
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: AppColors.success,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(
                'Frw ${p.amount.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    studentName,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'ID: ${p.studentId} | Type: ${p.paymentType}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textLight,
                    ),
                  ),
                ],
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${p.paymentDate.day.toString().padLeft(2, '0')}/${p.paymentDate.month.toString().padLeft(2, '0')}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${p.paymentDate.hour.toString().padLeft(2, '0')}:${p.paymentDate.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textLight,
                    ),
                  ),
                ],
              ),
              contentPadding: const EdgeInsets.symmetric(
                vertical: 6,
                horizontal: 16,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: AppColors.success.withOpacity(0.08)),
              ),
              tileColor: Colors.white,
              minVerticalPadding: 12,
            );
          },
        );
      },
    );
  }
}

class _RecentDisciplineTab extends StatelessWidget {
  const _RecentDisciplineTab();
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<DisciplineRecord>>(
      future: DatabaseHelper().getRecentDisciplineCases(limit: 50),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No recent discipline cases.'));
        }
        final records = snapshot.data!;
        return ListView.separated(
          itemCount: records.length,
          separatorBuilder: (_, __) => const Divider(),
          itemBuilder: (context, i) {
            final d = records[i];
            return ListTile(
              leading: const Icon(Icons.rule, color: AppColors.error),
              title: Text(d.type),
              subtitle: Text('Student: ${d.studentId} | By: ${d.recordedBy}'),
              trailing: Text('${d.date.day}/${d.date.month}'),
            );
          },
        );
      },
    );
  }
}
