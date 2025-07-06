import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqlite_crud_app/SQLite/database_helper.dart';
import 'package:sqlite_crud_app/models/attendance.dart';
import 'package:sqlite_crud_app/models/payment.dart';
import 'package:sqlite_crud_app/models/discipline.dart';
import 'package:sqlite_crud_app/constants/app_colors.dart';
import 'package:sqlite_crud_app/services/sync_service.dart';

class RecentRecordsScreen extends StatefulWidget {
  const RecentRecordsScreen({Key? key}) : super(key: key);

  @override
  State<RecentRecordsScreen> createState() => _RecentRecordsScreenState();
}

class _RecentRecordsScreenState extends State<RecentRecordsScreen> {
  String _searchQuery = '';
  final _searchController = TextEditingController();
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final SyncService _syncService = SyncService();

  // Calendar state
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  // Attendance data
  List<AttendanceLog> _selectedDateAttendance = [];
  bool _isLoadingAttendance = false;
  bool _isSyncing = false;

  // Sync status tracking
  Map<DateTime, SyncStatus> _syncStatusMap = {};

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _loadAttendanceForDate(_selectedDay!);
    _loadSyncStatus();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSyncStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final syncedDates = prefs.getStringList('synced_dates') ?? [];

      final statusMap = <DateTime, SyncStatus>{};
      for (final dateStr in syncedDates) {
        final date = DateTime.parse(dateStr);
        statusMap[date] = SyncStatus.synced;
      }

      setState(() {
        _syncStatusMap = statusMap;
      });
    } catch (e) {
      print('Error loading sync status: $e');
    }
  }

  Future<void> _loadAttendanceForDate(DateTime date) async {
    setState(() {
      _isLoadingAttendance = true;
    });

    try {
      // First try to load from local database
      List<AttendanceLog> attendance = [];

      if (isSameDay(date, DateTime.now())) {
        // Today's data is always in local database
        attendance = await _dbHelper.getTodayAttendance();
      } else {
        // For past dates, try to load from local first
        attendance = await _dbHelper.getAttendanceForDate(date);

        // If no local data and sync status is not synced, try to fetch from Firebase
        if (attendance.isEmpty && _syncStatusMap[date] != SyncStatus.synced) {
          await _fetchAttendanceFromFirebase(date);
          attendance = await _dbHelper.getAttendanceForDate(date);
        }
      }

      setState(() {
        _selectedDateAttendance = attendance;
        _isLoadingAttendance = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingAttendance = false;
      });
      _showErrorSnackBar('Failed to load attendance: $e');
    }
  }

  Future<void> _fetchAttendanceFromFirebase(DateTime date) async {
    setState(() {
      _isSyncing = true;
    });

    try {
      // This would be implemented in your SyncService
      // await _syncService.fetchAttendanceForDate(date);

      // For now, we'll just mark as synced
      final prefs = await SharedPreferences.getInstance();
      final syncedDates = prefs.getStringList('synced_dates') ?? [];
      final dateStr = DateFormat('yyyy-MM-dd').format(date);

      if (!syncedDates.contains(dateStr)) {
        syncedDates.add(dateStr);
        await prefs.setStringList('synced_dates', syncedDates);

        setState(() {
          _syncStatusMap[date] = SyncStatus.synced;
        });
      }
    } catch (e) {
      _showErrorSnackBar('Failed to fetch from Firebase: $e');
    } finally {
      setState(() {
        _isSyncing = false;
      });
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: const Text(
            'Attendance History',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: AppColors.primary,
          elevation: 0.5,
          iconTheme: const IconThemeData(color: Colors.white),
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: AppColors.textLight,
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            tabs: [Tab(text: 'Calendar'), Tab(text: 'Recent')],
          ),
        ),
        body: TabBarView(children: [_buildCalendarTab(), _buildRecentTab()]),
      ),
    );
  }

  Widget _buildCalendarTab() {
    return Column(
      children: [
        // Calendar
        Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
              _loadAttendanceForDate(selectedDay);
            },
            onFormatChanged: (format) {
              setState(() {
                _calendarFormat = format;
              });
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
            calendarStyle: const CalendarStyle(
              outsideDaysVisible: false,
              weekendTextStyle: TextStyle(color: Colors.red),
              holidayTextStyle: TextStyle(color: Colors.red),
            ),
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, date, events) {
                final syncStatus = _syncStatusMap[date];
                if (syncStatus != null) {
                  return Positioned(
                    right: 1,
                    bottom: 1,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _getSyncStatusColor(syncStatus),
                        shape: BoxShape.circle,
                      ),
                    ),
                  );
                }
                return null;
              },
            ),
          ),
        ),

        // Selected date info
        if (_selectedDay != null)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  DateFormat('EEEE, MMMM d, yyyy').format(_selectedDay!),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                if (_isSyncing)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else if (_syncStatusMap[_selectedDay!] == SyncStatus.synced)
                  Icon(Icons.cloud_done, color: AppColors.success, size: 20)
                else
                  Icon(Icons.cloud_off, color: Colors.grey, size: 20),
              ],
            ),
          ),

        const SizedBox(height: 16),

        // Attendance list for selected date
        Expanded(child: _buildAttendanceList()),
      ],
    );
  }

  Widget _buildRecentTab() {
    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value.trim()),
              decoration: InputDecoration(
                hintText: 'Search by name, ID, or status...',
                hintStyle: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: AppColors.primary,
                  size: 22,
                ),
                suffixIcon:
                    _searchController.text.isNotEmpty
                        ? IconButton(
                          icon: Icon(
                            Icons.clear,
                            color: Colors.grey[400],
                            size: 20,
                          ),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                        : null,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
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
        ),

        // Recent attendance list
        Expanded(
          child: FutureBuilder<List<AttendanceLog>>(
            future: _dbHelper.getTodayAttendance(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(
                  child: Text('No recent attendance records.'),
                );
              }

              final filteredRecords =
                  snapshot.data!.where((record) {
                    if (_searchQuery.isEmpty) return true;
                    return record.fullName?.toLowerCase().contains(
                              _searchQuery.toLowerCase(),
                            ) ==
                            true ||
                        record.regNumber?.toLowerCase().contains(
                              _searchQuery.toLowerCase(),
                            ) ==
                            true ||
                        record.status.value.toLowerCase().contains(
                              _searchQuery.toLowerCase(),
                            ) ==
                            true;
                  }).toList();

              if (filteredRecords.isEmpty) {
                return const Center(
                  child: Text('No records match your search.'),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: filteredRecords.length,
                itemBuilder: (context, index) {
                  final record = filteredRecords[index];
                  return _buildAttendanceCard(record);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAttendanceList() {
    if (_isLoadingAttendance) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_selectedDateAttendance.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No attendance records for this date',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap on a date to view attendance',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _selectedDateAttendance.length,
      itemBuilder: (context, index) {
        final record = _selectedDateAttendance[index];
        return _buildAttendanceCard(record);
      },
    );
  }

  Widget _buildAttendanceCard(AttendanceLog record) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(record.status).withOpacity(0.1),
          child: Icon(
            _getStatusIcon(record.status),
            color: _getStatusColor(record.status),
            size: 20,
          ),
        ),
        title: Text(
          record.fullName ?? 'Unknown Student',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ID: ${record.regNumber ?? 'N/A'}',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
            if (record.className != null)
              Text(
                'Class: ${record.className}',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _buildStatusChip(record.status),
            const SizedBox(height: 4),
            Text(
              DateFormat('HH:mm').format(record.markedAt),
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(AttendanceStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getStatusColor(status).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        status.value,
        style: TextStyle(
          color: _getStatusColor(status),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _getStatusColor(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return AppColors.success;
      case AttendanceStatus.late:
        return AppColors.warning;
      case AttendanceStatus.absent:
        return AppColors.error;
      case AttendanceStatus.excused:
        return AppColors.info;
    }
  }

  IconData _getStatusIcon(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return Icons.check_circle;
      case AttendanceStatus.late:
        return Icons.access_time;
      case AttendanceStatus.absent:
        return Icons.cancel;
      case AttendanceStatus.excused:
        return Icons.info_outline;
    }
  }

  Color _getSyncStatusColor(SyncStatus status) {
    switch (status) {
      case SyncStatus.synced:
        return AppColors.success;
      case SyncStatus.pending:
        return AppColors.warning;
      case SyncStatus.failed:
        return AppColors.error;
    }
  }
}

enum SyncStatus { synced, pending, failed }
