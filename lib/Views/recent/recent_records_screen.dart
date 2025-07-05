import 'package:flutter/material.dart';
import 'package:sqlite_crud_app/SQLite/database_helper.dart';
import 'package:sqlite_crud_app/models/attendance.dart';
import 'package:sqlite_crud_app/models/payment.dart';
import 'package:sqlite_crud_app/models/discipline.dart';
import 'package:sqlite_crud_app/constants/app_colors.dart';

class RecentRecordsScreen extends StatefulWidget {
  const RecentRecordsScreen({Key? key}) : super(key: key);

  @override
  State<RecentRecordsScreen> createState() => _RecentRecordsScreenState();
}

class _RecentRecordsScreenState extends State<RecentRecordsScreen> {
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: const Text(
            'Recent Records',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: AppColors.primary,
          elevation: 0.5,
          iconTheme: const IconThemeData(color: Colors.white),
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: AppColors.gray,
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            tabs: [
              Tab(text: 'Attendance'),
              Tab(text: 'Payments'),
              Tab(text: 'Discipline'),
            ],
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: TextField(
                controller: _searchController,
                onChanged:
                    (value) => setState(() => _searchQuery = value.trim()),
                decoration: InputDecoration(
                  hintText: 'Search by name, ID, or status/type...',
                  prefixIcon: const Icon(
                    Icons.search,
                    color: AppColors.primary,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 0,
                    horizontal: 16,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 2,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: TabBarView(
                children: [
                  _RecentAttendanceTab(searchQuery: _searchQuery),
                  _RecentPaymentsTab(searchQuery: _searchQuery),
                  _RecentDisciplineTab(searchQuery: _searchQuery),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Modern status chip for attendance
Widget _attendanceStatusChip(AttendanceStatus status) {
  Color color;
  String label = status.value;
  switch (status) {
    case AttendanceStatus.present:
      color = AppColors.success;
      break;
    case AttendanceStatus.late:
      color = AppColors.warning;
      break;
    case AttendanceStatus.absent:
      color = AppColors.error;
      break;
    case AttendanceStatus.excused:
      color = AppColors.info;
      break;
  }
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: color.withOpacity(0.12),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      label,
      style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12),
    ),
  );
}

class _RecentAttendanceTab extends StatelessWidget {
  final String searchQuery;
  const _RecentAttendanceTab({this.searchQuery = ''});
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
        final filtered =
            logs.where((log) {
              final name = log.fullName?.toLowerCase() ?? '';
              final reg = log.regNumber?.toLowerCase() ?? '';
              final status = log.status.value.toLowerCase();
              final q = searchQuery.toLowerCase();
              return q.isEmpty ||
                  name.contains(q) ||
                  reg.contains(q) ||
                  log.studentId.toString().contains(q) ||
                  status.contains(q);
            }).toList();
        if (filtered.isEmpty) {
          return const Center(child: Text('No records match your search.'));
        }
        return ListView.separated(
          itemCount: filtered.length,
          separatorBuilder: (_, __) => const Divider(height: 0),
          itemBuilder: (context, i) {
            final log = filtered[i];
            final initials =
                (log.fullName != null && log.fullName!.trim().isNotEmpty)
                    ? log.fullName!
                        .trim()
                        .split(' ')
                        .map((e) => e.isNotEmpty ? e[0].toUpperCase() : '')
                        .join()
                    : (log.regNumber != null && log.regNumber!.isNotEmpty
                        ? log.regNumber![0].toUpperCase()
                        : '?');
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.primary.withOpacity(0.12),
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      log.fullName != null && log.fullName!.trim().isNotEmpty
                          ? log.fullName!
                          : (log.regNumber != null && log.regNumber!.isNotEmpty
                              ? log.regNumber!
                              : 'No Name'),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  _attendanceStatusChip(log.status),
                ],
              ),
              subtitle: Text(
                'ID: ${log.studentId}  |  ${log.className ?? ''}\n${log.status.value} at '
                '${log.markedAt.hour.toString().padLeft(2, '0')}:${log.markedAt.minute.toString().padLeft(2, '0')}',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textLight,
                ),
              ),
              trailing: null,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 8,
                horizontal: 18,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: AppColors.primary.withOpacity(0.06)),
              ),
              tileColor: Colors.white,
              minVerticalPadding: 10,
            );
          },
        );
      },
    );
  }
}

class _RecentPaymentsTab extends StatelessWidget {
  final String searchQuery;
  const _RecentPaymentsTab({this.searchQuery = ''});
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
        final filtered =
            payments.where((p) {
              final name = p.fullName?.toLowerCase() ?? '';
              final reg = p.regNumber?.toLowerCase() ?? '';
              final type = p.paymentType.toLowerCase();
              final q = searchQuery.toLowerCase();
              return q.isEmpty ||
                  name.contains(q) ||
                  reg.contains(q) ||
                  p.studentId.toString().contains(q) ||
                  type.contains(q);
            }).toList();
        if (filtered.isEmpty) {
          return const Center(child: Text('No records match your search.'));
        }
        return ListView.separated(
          itemCount: filtered.length,
          separatorBuilder: (_, __) => const Divider(height: 0),
          itemBuilder: (context, i) {
            final p = filtered[i];
            final initials =
                (p.fullName != null && p.fullName!.trim().isNotEmpty)
                    ? p.fullName!
                        .trim()
                        .split(' ')
                        .map((e) => e.isNotEmpty ? e[0].toUpperCase() : '')
                        .join()
                    : (p.regNumber != null && p.regNumber!.isNotEmpty
                        ? p.regNumber![0].toUpperCase()
                        : '?');
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.success.withOpacity(0.13),
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: AppColors.success,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      p.fullName != null && p.fullName!.trim().isNotEmpty
                          ? p.fullName!
                          : (p.regNumber != null && p.regNumber!.isNotEmpty
                              ? p.regNumber!
                              : 'No Name'),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      p.paymentType,
                      style: const TextStyle(
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              subtitle: Text(
                'ID: ${p.studentId}  |  ${p.className ?? ''}\nFrw ${p.amount.toStringAsFixed(2)}  |  ${p.paymentDate.day.toString().padLeft(2, '0')}/${p.paymentDate.month.toString().padLeft(2, '0')} ${p.paymentDate.hour.toString().padLeft(2, '0')}:${p.paymentDate.minute.toString().padLeft(2, '0')}',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textLight,
                ),
              ),
              trailing: null,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 8,
                horizontal: 18,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: AppColors.success.withOpacity(0.06)),
              ),
              tileColor: Colors.white,
              minVerticalPadding: 10,
            );
          },
        );
      },
    );
  }
}

class _RecentDisciplineTab extends StatelessWidget {
  final String searchQuery;
  const _RecentDisciplineTab({this.searchQuery = ''});
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
        final filtered =
            records.where((d) {
              final name = d.fullName?.toLowerCase() ?? '';
              final reg = d.regNumber?.toLowerCase() ?? '';
              final type = d.type.toLowerCase();
              final q = searchQuery.toLowerCase();
              return q.isEmpty ||
                  name.contains(q) ||
                  reg.contains(q) ||
                  d.studentId.toString().contains(q) ||
                  type.contains(q);
            }).toList();
        if (filtered.isEmpty) {
          return const Center(child: Text('No records match your search.'));
        }
        return ListView.separated(
          itemCount: filtered.length,
          separatorBuilder: (_, __) => const Divider(height: 0),
          itemBuilder: (context, i) {
            final d = filtered[i];
            final initials =
                (d.fullName != null && d.fullName!.trim().isNotEmpty)
                    ? d.fullName!
                        .trim()
                        .split(' ')
                        .map((e) => e.isNotEmpty ? e[0].toUpperCase() : '')
                        .join()
                    : (d.regNumber != null && d.regNumber!.isNotEmpty
                        ? d.regNumber![0].toUpperCase()
                        : '?');
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.error.withOpacity(0.13),
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: AppColors.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      d.fullName != null && d.fullName!.trim().isNotEmpty
                          ? d.fullName!
                          : (d.regNumber != null && d.regNumber!.isNotEmpty
                              ? d.regNumber!
                              : 'No Name'),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      d.type,
                      style: const TextStyle(
                        color: AppColors.error,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              subtitle: Text(
                'ID: ${d.studentId}  |  ${d.className ?? ''}\nBy: ${d.recordedBy}  |  ${d.date.day.toString().padLeft(2, '0')}/${d.date.month.toString().padLeft(2, '0')}',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textLight,
                ),
              ),
              trailing: null,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 8,
                horizontal: 18,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: AppColors.error.withOpacity(0.06)),
              ),
              tileColor: Colors.white,
              minVerticalPadding: 10,
            );
          },
        );
      },
    );
  }
}
