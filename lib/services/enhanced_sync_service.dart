import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import '../SQLite/database_helper.dart';
import '../models/sync_queue_item.dart';
import '../models/sync_status.dart';

/// Enhanced Sync Service with Offline Queue and Conflict Resolution
/// Implements offline-first architecture with automatic background sync
class EnhancedSyncService extends ChangeNotifier {
  static EnhancedSyncService? _instance;
  static EnhancedSyncService get instance {
    _instance ??= EnhancedSyncService._();
    return _instance!;
  }

  EnhancedSyncService._();

  // Dependencies
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final Connectivity _connectivity = Connectivity();

  // State
  SyncStatus _syncStatus = SyncStatus.idle();
  bool _isInitialized = false;
  bool _isSyncing = false;
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  Timer? _periodicSyncTimer;

  // Real-time listeners
  final Map<String, StreamSubscription> _realtimeListeners = {};

  // Configuration
  static const String _schoolId = 'school_001';
  static const int _maxRetries = 3;
  static const Duration _periodicSyncInterval = Duration(minutes: 5);

  // Getters
  SyncStatus get syncStatus => _syncStatus;
  bool get isOnline => _syncStatus.isOnline;
  bool get isSyncing => _isSyncing;

  /// Initialize the sync service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      print('🔄 Initializing Enhanced Sync Service...');

      // Initialize database and create sync queue table
      await _initializeSyncQueue();

      // Check initial connectivity
      final connectivityResult = await _connectivity.checkConnectivity();
      final isOnline = connectivityResult != ConnectivityResult.none;
      _updateSyncStatus(SyncStatus.idle().copyWith(isOnline: isOnline));

      // Listen to connectivity changes
      _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
        _handleConnectivityChange,
      );

      // Start periodic sync if online
      if (isOnline) {
        _startPeriodicSync();
        await _syncPendingOperations();
      }

      _isInitialized = true;
      print('✅ Enhanced Sync Service initialized');
    } catch (e) {
      print('❌ Failed to initialize sync service: $e');
      rethrow;
    }
  }

  /// Initialize sync queue table in local database
  Future<void> _initializeSyncQueue() async {
    final db = await _dbHelper.database;
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sync_queue (
        id TEXT PRIMARY KEY,
        table_name TEXT NOT NULL,
        operation TEXT NOT NULL,
        payload TEXT NOT NULL,
        timestamp INTEGER NOT NULL,
        retry_count INTEGER DEFAULT 0,
        error_message TEXT,
        user_id TEXT NOT NULL,
        record_id TEXT
      )
    ''');
    print('✅ Sync queue table initialized');
  }

  /// Handle connectivity changes
  void _handleConnectivityChange(ConnectivityResult result) async {
    final wasOnline = _syncStatus.isOnline;
    final isNowOnline = result != ConnectivityResult.none;

    print('🌐 Connectivity changed: $result (online: $isNowOnline)');

    if (!wasOnline && isNowOnline) {
      // Just came online - sync pending operations
      print('✅ Connection restored - syncing pending operations');
      await _syncPendingOperations();
      _startPeriodicSync();
      _startRealtimeListeners();
    } else if (wasOnline && !isNowOnline) {
      // Just went offline
      print('⚠️ Connection lost - working offline');
      _stopPeriodicSync();
      _stopRealtimeListeners();
      final pendingCount = await _getPendingOperationsCount();
      _updateSyncStatus(SyncStatus.offline(pendingCount));
    }
  }

  /// Add operation to sync queue (for offline operations)
  Future<void> addToSyncQueue({
    required String tableName,
    required String operation,
    required Map<String, dynamic> data,
    required String userId,
    String? recordId,
  }) async {
    try {
      final db = await _dbHelper.database;
      final queueItem = SyncQueueItem(
        id: '${DateTime.now().millisecondsSinceEpoch}_${tableName}_$operation',
        tableName: tableName,
        operation: operation,
        payload: jsonEncode(data),
        timestamp: DateTime.now().millisecondsSinceEpoch,
        userId: userId,
        recordId: recordId ?? data['id']?.toString(),
      );

      await db.insert('sync_queue', queueItem.toMap());
      print(
        '📝 Added to sync queue: ${queueItem.tableName} - ${queueItem.operation}',
      );

      // Update status
      final pendingCount = await _getPendingOperationsCount();
      if (_syncStatus.isOnline) {
        _updateSyncStatus(SyncStatus.pending(pendingCount));
        // Try to sync immediately if online
        await _syncPendingOperations();
      } else {
        _updateSyncStatus(SyncStatus.offline(pendingCount));
      }
    } catch (e) {
      print('❌ Failed to add to sync queue: $e');
      rethrow;
    }
  }

  /// Sync all pending operations
  Future<void> _syncPendingOperations() async {
    if (_isSyncing) {
      print('⏳ Sync already in progress, skipping...');
      return;
    }

    try {
      _isSyncing = true;
      final db = await _dbHelper.database;

      // Get all pending operations ordered by timestamp
      final results = await db.query('sync_queue', orderBy: 'timestamp ASC');

      if (results.isEmpty) {
        _updateSyncStatus(SyncStatus.synced());
        return;
      }

      print('🔄 Syncing ${results.length} pending operations...');
      _updateSyncStatus(SyncStatus.syncing(results.length));

      int successCount = 0;
      int failedCount = 0;

      for (final row in results) {
        final item = SyncQueueItem.fromMap(row);

        try {
          await _syncSingleOperation(item);
          await db.delete('sync_queue', where: 'id = ?', whereArgs: [item.id]);
          successCount++;
          print('✅ Synced: ${item.tableName} - ${item.operation}');
        } catch (e) {
          print('❌ Failed to sync: ${item.tableName} - ${item.operation}: $e');

          // Update retry count
          final newRetryCount = item.retryCount + 1;
          if (newRetryCount >= _maxRetries) {
            // Max retries reached, mark as failed
            await db.update(
              'sync_queue',
              {'retry_count': newRetryCount, 'error_message': e.toString()},
              where: 'id = ?',
              whereArgs: [item.id],
            );
            failedCount++;
          } else {
            // Retry later
            await db.update(
              'sync_queue',
              {'retry_count': newRetryCount},
              where: 'id = ?',
              whereArgs: [item.id],
            );
          }
        }
      }

      // Update status based on results
      final remainingCount = await _getPendingOperationsCount();
      if (failedCount > 0) {
        _updateSyncStatus(
          SyncStatus.error('Failed to sync $failedCount items', failedCount),
        );
      } else if (remainingCount > 0) {
        _updateSyncStatus(SyncStatus.pending(remainingCount));
      } else {
        _updateSyncStatus(SyncStatus.synced());
      }

      print('✅ Sync completed: $successCount succeeded, $failedCount failed');
    } catch (e) {
      print('❌ Sync failed: $e');
      final pendingCount = await _getPendingOperationsCount();
      _updateSyncStatus(SyncStatus.error(e.toString(), pendingCount));
    } finally {
      _isSyncing = false;
    }
  }

  /// Sync a single operation to Firestore
  Future<void> _syncSingleOperation(SyncQueueItem item) async {
    final data = jsonDecode(item.payload) as Map<String, dynamic>;
    final collectionPath = 'school_data/$_schoolId/${item.tableName}';
    final collection = _firestore.collection(collectionPath);

    switch (item.operation) {
      case 'insert':
      case 'update':
        // Add server timestamp and sync metadata
        data['lastModified'] = FieldValue.serverTimestamp();
        data['lastModifiedBy'] = item.userId;
        data['syncedAt'] = FieldValue.serverTimestamp();

        // Check for conflicts
        if (item.recordId != null) {
          final doc = await collection.doc(item.recordId).get();
          if (doc.exists) {
            // Conflict resolution: compare timestamps
            final serverData = doc.data();
            if (serverData != null && serverData['lastModified'] != null) {
              final serverTimestamp =
                  (serverData['lastModified'] as Timestamp)
                      .millisecondsSinceEpoch;
              if (serverTimestamp > item.timestamp) {
                // Server version is newer, update local instead
                print(
                  '⚠️ Conflict detected: server version is newer, updating local',
                );
                await _updateLocalFromServer(item.tableName, serverData);
                return;
              }
            }
          }
        }

        // No conflict or local version is newer, update server
        await collection
            .doc(item.recordId ?? data['id']?.toString())
            .set(data, SetOptions(merge: true));
        break;

      case 'delete':
        if (item.recordId != null) {
          await collection.doc(item.recordId).delete();
        }
        break;

      default:
        throw Exception('Unknown operation: ${item.operation}');
    }
  }

  /// Update local database from server data (conflict resolution)
  Future<void> _updateLocalFromServer(
    String tableName,
    Map<String, dynamic> serverData,
  ) async {
    final db = await _dbHelper.database;

    // Remove Firestore-specific fields
    final localData = Map<String, dynamic>.from(serverData);
    localData.remove('lastModified');
    localData.remove('lastModifiedBy');
    localData.remove('syncedAt');

    // Convert Timestamp to int if needed
    if (localData['timestamp'] is Timestamp) {
      localData['timestamp'] =
          (localData['timestamp'] as Timestamp).millisecondsSinceEpoch;
    }

    await db.update(
      tableName,
      localData,
      where: 'id = ?',
      whereArgs: [localData['id']],
    );
  }

  /// Get count of pending operations
  Future<int> _getPendingOperationsCount() async {
    try {
      final db = await _dbHelper.database;
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM sync_queue',
      );
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      print('❌ Failed to get pending count: $e');
      return 0;
    }
  }

  /// Start real-time listeners for Firestore collections
  void _startRealtimeListeners() {
    if (!_syncStatus.isOnline) return;

    print('👂 Starting real-time listeners...');

    // Listen to students collection
    _realtimeListeners['students'] = _firestore
        .collection('school_data/$_schoolId/students')
        .snapshots()
        .listen(
          (snapshot) => _handleStudentsSnapshot(snapshot),
          onError: (e) => print('❌ Students listener error: $e'),
        );

    // Listen to attendance collection
    _realtimeListeners['attendance_logs'] = _firestore
        .collection('school_data/$_schoolId/attendance_logs')
        .snapshots()
        .listen(
          (snapshot) => _handleAttendanceSnapshot(snapshot),
          onError: (e) => print('❌ Attendance listener error: $e'),
        );

    // Listen to payments collection
    _realtimeListeners['payments'] = _firestore
        .collection('school_data/$_schoolId/payments')
        .snapshots()
        .listen(
          (snapshot) => _handlePaymentsSnapshot(snapshot),
          onError: (e) => print('❌ Payments listener error: $e'),
        );

    // Listen to discipline collection
    _realtimeListeners['discipline'] = _firestore
        .collection('school_data/$_schoolId/discipline')
        .snapshots()
        .listen(
          (snapshot) => _handleDisciplineSnapshot(snapshot),
          onError: (e) => print('❌ Discipline listener error: $e'),
        );

    print('✅ Real-time listeners started');
  }

  /// Stop all real-time listeners
  void _stopRealtimeListeners() {
    print('🛑 Stopping real-time listeners...');
    for (final listener in _realtimeListeners.values) {
      listener.cancel();
    }
    _realtimeListeners.clear();
  }

  /// Handle students snapshot from Firestore
  Future<void> _handleStudentsSnapshot(QuerySnapshot snapshot) async {
    try {
      final db = await _dbHelper.database;
      for (final change in snapshot.docChanges) {
        final data = change.doc.data() as Map<String, dynamic>?;
        if (data == null) continue;

        // Convert Firestore data to local format
        final localData = _convertFirestoreToLocal(data);

        switch (change.type) {
          case DocumentChangeType.added:
          case DocumentChangeType.modified:
            await db.insert(
              'students',
              localData,
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
            print('🔄 Updated student from Firestore: ${localData['id']}');
            break;
          case DocumentChangeType.removed:
            await db.delete(
              'students',
              where: 'id = ?',
              whereArgs: [localData['id']],
            );
            print('🗑️ Deleted student from local: ${localData['id']}');
            break;
        }
      }
      notifyListeners(); // Notify UI to refresh
    } catch (e) {
      print('❌ Error handling students snapshot: $e');
    }
  }

  /// Handle attendance snapshot from Firestore
  Future<void> _handleAttendanceSnapshot(QuerySnapshot snapshot) async {
    try {
      final db = await _dbHelper.database;
      for (final change in snapshot.docChanges) {
        final data = change.doc.data() as Map<String, dynamic>?;
        if (data == null) continue;

        final localData = _convertFirestoreToLocal(data);

        switch (change.type) {
          case DocumentChangeType.added:
          case DocumentChangeType.modified:
            await db.insert(
              'attendance_logs',
              localData,
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
            print('🔄 Updated attendance from Firestore: ${localData['id']}');
            break;
          case DocumentChangeType.removed:
            await db.delete(
              'attendance_logs',
              where: 'id = ?',
              whereArgs: [localData['id']],
            );
            break;
        }
      }
      notifyListeners();
    } catch (e) {
      print('❌ Error handling attendance snapshot: $e');
    }
  }

  /// Handle payments snapshot from Firestore
  Future<void> _handlePaymentsSnapshot(QuerySnapshot snapshot) async {
    try {
      final db = await _dbHelper.database;
      for (final change in snapshot.docChanges) {
        final data = change.doc.data() as Map<String, dynamic>?;
        if (data == null) continue;

        final localData = _convertFirestoreToLocal(data);

        switch (change.type) {
          case DocumentChangeType.added:
          case DocumentChangeType.modified:
            await db.insert(
              'payments',
              localData,
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
            print('🔄 Updated payment from Firestore: ${localData['id']}');
            break;
          case DocumentChangeType.removed:
            await db.delete(
              'payments',
              where: 'id = ?',
              whereArgs: [localData['id']],
            );
            break;
        }
      }
      notifyListeners();
    } catch (e) {
      print('❌ Error handling payments snapshot: $e');
    }
  }

  /// Handle discipline snapshot from Firestore
  Future<void> _handleDisciplineSnapshot(QuerySnapshot snapshot) async {
    try {
      final db = await _dbHelper.database;
      for (final change in snapshot.docChanges) {
        final data = change.doc.data() as Map<String, dynamic>?;
        if (data == null) continue;

        final localData = _convertFirestoreToLocal(data);

        switch (change.type) {
          case DocumentChangeType.added:
          case DocumentChangeType.modified:
            await db.insert(
              'discipline',
              localData,
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
            print('🔄 Updated discipline from Firestore: ${localData['id']}');
            break;
          case DocumentChangeType.removed:
            await db.delete(
              'discipline',
              where: 'id = ?',
              whereArgs: [localData['id']],
            );
            break;
        }
      }
      notifyListeners();
    } catch (e) {
      print('❌ Error handling discipline snapshot: $e');
    }
  }

  /// Convert Firestore data to local database format
  Map<String, dynamic> _convertFirestoreToLocal(Map<String, dynamic> data) {
    final localData = Map<String, dynamic>.from(data);

    // Convert Timestamp to milliseconds
    for (final key in localData.keys) {
      if (localData[key] is Timestamp) {
        localData[key] = (localData[key] as Timestamp).millisecondsSinceEpoch;
      }
    }

    // Remove Firestore-specific fields
    localData.remove('lastModified');
    localData.remove('lastModifiedBy');
    localData.remove('syncedAt');

    return localData;
  }

  /// Start periodic sync timer
  void _startPeriodicSync() {
    _periodicSyncTimer?.cancel();
    _periodicSyncTimer = Timer.periodic(_periodicSyncInterval, (_) {
      if (_syncStatus.isOnline && !_isSyncing) {
        print('⏰ Periodic sync triggered');
        _syncPendingOperations();
      }
    });
    print(
      '⏰ Periodic sync started (every ${_periodicSyncInterval.inMinutes} minutes)',
    );
  }

  /// Stop periodic sync timer
  void _stopPeriodicSync() {
    _periodicSyncTimer?.cancel();
    _periodicSyncTimer = null;
    print('⏰ Periodic sync stopped');
  }

  /// Manually trigger sync
  Future<void> syncNow() async {
    print('🔄 Manual sync triggered');
    await _syncPendingOperations();
  }

  /// Update sync status and notify listeners
  void _updateSyncStatus(SyncStatus status) {
    _syncStatus = status;
    notifyListeners();
    print('📊 Sync status: ${status.message}');
  }

  /// Dispose resources
  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _periodicSyncTimer?.cancel();
    _stopRealtimeListeners();
    super.dispose();
  }
}
