import 'package:flutter/material.dart';
import 'services/sync_service.dart';
import 'services/attendance_service.dart';
import 'services/connectivity_service.dart';
import 'SQLite/database_helper.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class TestSyncSystem extends StatefulWidget {
  const TestSyncSystem({Key? key}) : super(key: key);

  @override
  State<TestSyncSystem> createState() => _TestSyncSystemState();
}

class _TestSyncSystemState extends State<TestSyncSystem> {
  String _status = 'Initializing...';
  bool _isLoading = false;
  Map<String, dynamic> _syncStatus = {};
  List<String> _logs = [];

  // Update to use single ConnectivityResult
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  ConnectivityResult _connectivityStatus = ConnectivityResult.none;
  bool _isOnline = false;

  @override
  void initState() {
    super.initState();
    _initializeSystem();
    // Listen for connectivity changes using the new API
    _connectivitySubscription = ConnectivityService().onConnectivityChanged
        .listen((result) async {
          setState(() {
            _connectivityStatus = result;
            _isOnline = result != ConnectivityResult.none;
          });
          if (_isOnline) {
            await SyncService.instance.ensureFirebaseInitialized();
          }
          await _checkSyncStatus();
        });
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  Future<void> _initializeSystem() async {
    setState(() {
      _isLoading = true;
      _status = 'Initializing system...';
    });

    try {
      // Initialize connectivity service
      await ConnectivityService().initialize();
      _addLog('✅ Connectivity service initialized');

      // Initialize sync service
      await SyncService.instance.initialize();
      _addLog('✅ Sync service initialized');

      // Initialize database
      await DatabaseHelper().database;
      _addLog('✅ Database initialized');

      // Check sync status
      await _checkSyncStatus();

      setState(() {
        _status = 'System ready';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
        _isLoading = false;
      });
      _addLog('❌ Error: $e');
    }
  }

  Future<void> _checkSyncStatus() async {
    try {
      final status = await SyncService.instance.getSyncStatus();
      setState(() {
        _syncStatus = status;
      });
      _addLog(
        '📊 Sync status: ${status['unsynced_attendance']} unsynced attendance records',
      );
    } catch (e) {
      _addLog('❌ Error checking sync status: $e');
    }
  }

  Future<void> _testSync() async {
    setState(() {
      _isLoading = true;
      _status = 'Testing sync...';
    });

    try {
      // Test data fetch
      _addLog('🔄 Testing data fetch...');
      final fetchResult = await SyncService.instance.fetchAndSyncData();
      if (fetchResult.isSuccess) {
        _addLog('✅ Data fetch successful');
      } else {
        _addLog('⚠️ Data fetch failed: ${fetchResult.message}');
      }

      // Test data sync
      _addLog('🔄 Testing data sync...');
      final syncResult = await SyncService.instance.syncAllData();
      if (syncResult.isSuccess) {
        _addLog('✅ Data sync successful');
      } else {
        _addLog('❌ Data sync failed: ${syncResult.message}');
      }

      // Update sync status
      await _checkSyncStatus();

      setState(() {
        _status = 'Sync test completed';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _status = 'Sync test failed: $e';
        _isLoading = false;
      });
      _addLog('❌ Sync test error: $e');
    }
  }

  Future<void> _testAttendanceMarking() async {
    setState(() {
      _isLoading = true;
      _status = 'Testing attendance marking...';
    });

    try {
      // Get a test student
      final students = await DatabaseHelper().getAllStudents();
      if (students.isEmpty) {
        _addLog('❌ No students found for testing');
        setState(() {
          _status = 'No students available for testing';
          _isLoading = false;
        });
        return;
      }

      final testStudent = students.first;
      _addLog('👤 Testing with student: ${testStudent.fullName}');

      // Mark attendance
      final result = await AttendanceService.instance.markAttendance(
        testStudent.studentId,
        'Present',
        'TestUser',
      );

      if (result.isSuccess) {
        _addLog('✅ Attendance marked successfully');
        _addLog('📊 Status: ${result.status}, Time: ${result.time}');
      } else {
        _addLog('❌ Attendance marking failed: ${result.message}');
      }

      setState(() {
        _status = 'Attendance test completed';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _status = 'Attendance test failed: $e';
        _isLoading = false;
      });
      _addLog('❌ Attendance test error: $e');
    }
  }

  void _addLog(String message) {
    setState(() {
      _logs.add('${DateTime.now().toString().substring(11, 19)}: $message');
      if (_logs.length > 20) {
        _logs.removeAt(0);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sync System Test'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'System Status',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _status,
                      style: TextStyle(
                        color: _isLoading ? Colors.orange : Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (_isLoading) ...[
                      const SizedBox(height: 8),
                      const LinearProgressIndicator(),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Sync Status Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sync Status',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    if (_syncStatus.isNotEmpty) ...[
                      Text(
                        'Unsynced Attendance: ${_syncStatus['unsynced_attendance'] ?? 0}',
                      ),
                      Text(
                        'Unsynced Payments: ${_syncStatus['unsynced_payments'] ?? 0}',
                      ),
                      Text(
                        'Unsynced Discipline: ${_syncStatus['unsynced_discipline'] ?? 0}',
                      ),
                      Text(
                        'Sync Available: ${_syncStatus['is_sync_available'] ?? false}',
                      ),
                    ] else ...[
                      const Text('No sync status available'),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _testSync,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Test Sync'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _testAttendanceMarking,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Test Attendance'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Logs
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'System Logs',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ListView.builder(
                            itemCount: _logs.length,
                            itemBuilder: (context, index) {
                              final log = _logs[index];
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 2,
                                ),
                                child: Text(
                                  log,
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 12,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
