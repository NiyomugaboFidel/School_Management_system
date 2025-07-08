import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../SQLite/database_helper.dart';
import '../models/user.dart';
import '../models/student.dart';
import '../models/attendance.dart';
import '../models/payment.dart';
import '../models/discipline.dart';
import 'sync_result.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter/foundation.dart';
import 'notification_service.dart';
import 'connectivity_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class SyncService {
  static SyncService? _instance;
  static FirebaseFirestore? _firestore;
  static Database? _localDb;
  static bool _isInitialized = false;

  // Private constructor for singleton
  SyncService._();

  // Singleton instance
  static SyncService get instance {
    _instance ??= SyncService._();
    return _instance!;
  }

  // Static school identifier - no authentication required
  static const String _schoolId = 'school_001';
  static const String _schoolName = 'Default School';

  // Collection names
  static const String _usersCollection = 'users';
  static const String _studentsCollection = 'students';
  static const String _attendanceCollection = 'attendance_logs';
  static const String _paymentsCollection = 'payments';
  static const String _disciplineCollection = 'discipline';
  static const String _syncLogCollection = 'sync_logs';
  static const String _schoolDataCollection = 'school_data';

  /// Initialize sync service (offline-first)
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      // Initialize local database only
      _localDb = await DatabaseHelper().database;
      _isInitialized = true;
      print('✅ SyncService initialized successfully (offline-first)');
      return true;
    } catch (e) {
      print('❌ SyncService initialization failed: $e');
      return false;
    }
  }

  /// Get Firebase instance (lazy initialization only when online)
  Future<FirebaseFirestore?> _getFirestore() async {
    if (_firestore != null) return _firestore;

    try {
      // Check if we're online
      final connectivityStatus =
          await ConnectivityService().getConnectivityStatus();
      if (connectivityStatus == ConnectivityResult.none) {
        print('🌐 No internet connection - Firebase not available');
        return null;
      }

      // Initialize Firebase only when online
      _firestore = FirebaseFirestore.instance;
      print('✅ Firebase initialized for sync');
      return _firestore;
    } catch (e) {
      print('❌ Firebase initialization failed: $e');
      return null;
    }
  }

  /// Check if sync is available
  Future<bool> isSyncAvailable() async {
    try {
      final connectivityStatus =
          await ConnectivityService().getConnectivityStatus();
      if (connectivityStatus == ConnectivityResult.none) {
        return false;
      }

      final firestore = await _getFirestore();
      return firestore != null;
    } catch (e) {
      print('Error checking sync availability: $e');
      return false;
    }
  }

  /// Get school identifier
  String getSchoolId() {
    return _schoolId;
  }

  /// Fetch and sync data from Firebase to local database
  Future<SyncResult> fetchAndSyncData() async {
    try {
      final firestore = await _getFirestore();
      if (firestore == null) {
        return SyncResult.failure(
          error: 'No internet connection',
          message: 'Cannot sync without internet connection',
        );
      }

      print('🔄 Starting data fetch from Firebase...');

      // Fetch all data from Firebase
      await _fetchUsers(firestore);
      await _fetchStudents(firestore);
      await _fetchAttendance(firestore);
      await _fetchPayments(firestore);
      await _fetchDiscipline(firestore);

      // Log sync
      await _logSync(firestore, true, 'Data fetch completed');

      return SyncResult.success(
        message: 'Data fetched successfully',
        recordCount: 0,
      );
    } catch (e) {
      print('❌ Fetch error: $e');
      return SyncResult.failure(error: e.toString(), message: 'Fetch failed');
    }
  }

  /// Sync all local data to Firebase
  Future<SyncResult> syncAllData() async {
    try {
      final firestore = await _getFirestore();
      if (firestore == null) {
        return SyncResult.failure(
          error: 'No internet connection',
          message: 'Cannot sync without internet connection',
        );
      }

      print('🔄 Starting full sync to Firebase...');

      final batch = firestore.batch();

      // Sync users
      await _syncUsers(batch);

      // Sync students
      await _syncStudents(batch);

      // Sync attendance
      await _syncAttendance(batch);

      // Sync payments
      await _syncPayments(batch);

      // Sync discipline records
      await _syncDiscipline(batch);

      // Commit all changes
      await batch.commit();

      // Log sync
      await _logSync(firestore, true, 'Full sync completed');

      // Update last sync time
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_sync_time', DateTime.now().toIso8601String());

      return SyncResult.success(
        message: 'Full sync completed successfully',
        recordCount: 0,
      );
    } catch (e) {
      print('❌ Sync error: $e');
      return SyncResult.failure(error: e.toString(), message: 'Sync failed');
    }
  }

  /// Real-time sync when attendance is marked
  Future<void> syncAttendanceRealtime(AttendanceLog attendance) async {
    try {
      final firestore = await _getFirestore();
      if (firestore == null) {
        print('🌐 No internet - attendance saved locally only');
        return;
      }

      // Create unique document ID
      final docId =
          'attendance_${attendance.id}_${DateTime.now().millisecondsSinceEpoch}';

      final attendanceData = {
        'local_id': attendance.id,
        'student_id': attendance.studentId,
        'date': attendance.date.toIso8601String(),
        'status': attendance.status.value, // Use the string value
        'marked_by': attendance.markedBy,
        'marked_at': attendance.markedAt.toIso8601String(),
        'profile_image': attendance.profileImage,
        'notes': attendance.notes,
        'created_at': attendance.createdAt?.toIso8601String(),
        'synced_at': DateTime.now().toIso8601String(),
        'school_id': _schoolId,
        'device_id': await _getDeviceId(),
        'user_id': await _getCurrentUserId(),
      };

      await firestore
          .collection(_schoolDataCollection)
          .doc(_schoolId)
          .collection(_attendanceCollection)
          .doc(docId)
          .set(attendanceData, SetOptions(merge: true));

      // Mark as synced in local database
      await DatabaseHelper().updateAttendanceSyncStatus(attendance.id, true);

      print('✅ Attendance synced in real-time: ${attendance.id}');
    } catch (e) {
      print('❌ Real-time sync failed: $e');
      // Don't throw error - attendance is still saved locally
    }
  }

  /// Fetch users from Firebase
  Future<void> _fetchUsers(FirebaseFirestore firestore) async {
    try {
      final querySnapshot =
          await firestore
              .collection(_schoolDataCollection)
              .doc(_schoolId)
              .collection(_usersCollection)
              .get();

      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        // Update local user data if needed
        // This would require implementing update methods in DatabaseHelper
      }
    } catch (e) {
      print('Error fetching users: $e');
    }
  }

  /// Fetch students from Firebase
  Future<void> _fetchStudents(FirebaseFirestore firestore) async {
    try {
      final querySnapshot =
          await firestore
              .collection(_schoolDataCollection)
              .doc(_schoolId)
              .collection(_studentsCollection)
              .get();

      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        // Update local student data if needed
      }
    } catch (e) {
      print('Error fetching students: $e');
    }
  }

  /// Fetch attendance from Firebase
  Future<void> _fetchAttendance(FirebaseFirestore firestore) async {
    try {
      final querySnapshot =
          await firestore
              .collection(_schoolDataCollection)
              .doc(_schoolId)
              .collection(_attendanceCollection)
              .get();

      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        // Update local attendance data if needed
      }
    } catch (e) {
      print('Error fetching attendance: $e');
    }
  }

  /// Fetch payments from Firebase
  Future<void> _fetchPayments(FirebaseFirestore firestore) async {
    try {
      final querySnapshot =
          await firestore
              .collection(_schoolDataCollection)
              .doc(_schoolId)
              .collection(_paymentsCollection)
              .get();

      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        // Update local payment data if needed
      }
    } catch (e) {
      print('Error fetching payments: $e');
    }
  }

  /// Fetch discipline records from Firebase
  Future<void> _fetchDiscipline(FirebaseFirestore firestore) async {
    try {
      final querySnapshot =
          await firestore
              .collection(_schoolDataCollection)
              .doc(_schoolId)
              .collection(_disciplineCollection)
              .get();

      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        // Update local discipline data if needed
      }
    } catch (e) {
      print('Error fetching discipline: $e');
    }
  }

  /// Sync users to Firebase
  Future<void> _syncUsers(WriteBatch batch) async {
    final firestore = await _getFirestore();
    if (firestore == null) return;

    final users = await DatabaseHelper().getAllActiveUsers();

    for (final user in users) {
      final userDoc = firestore
          .collection(_schoolDataCollection)
          .doc(_schoolId)
          .collection(_usersCollection)
          .doc('user_${user.id}');

      final userData = {
        'local_id': user.id,
        'username': user.username,
        'full_name': user.fullName,
        'email': user.email,
        'role': user.role.value,
        'is_active': user.isActive,
        'created_at': user.createdAt,
        'updated_at': DateTime.now().toIso8601String(),
        'synced_at': DateTime.now().toIso8601String(),
        'school_id': _schoolId,
        'device_id': await _getDeviceId(),
      };

      batch.set(userDoc, userData, SetOptions(merge: true));
    }
  }

  /// Sync students to Firebase
  Future<void> _syncStudents(WriteBatch batch) async {
    final firestore = await _getFirestore();
    if (firestore == null) return;

    final students = await DatabaseHelper().getAllStudents();

    for (final student in students) {
      final studentDoc = firestore
          .collection(_schoolDataCollection)
          .doc(_schoolId)
          .collection(_studentsCollection)
          .doc('student_${student.studentId}');

      final studentData = {
        'local_id': student.studentId,
        'reg_number': student.regNumber,
        'full_name': student.fullName,
        'class_id': student.classId,
        'barcode': student.barcode,
        'nfc_tag_id': student.nfcTagId,
        'profile_image': student.profileImage,
        'is_active': student.isActive,
        'created_at': student.createdAt,
        'updated_at': DateTime.now().toIso8601String(),
        'synced_at': DateTime.now().toIso8601String(),
        'school_id': _schoolId,
        'device_id': await _getDeviceId(),
      };

      batch.set(studentDoc, studentData, SetOptions(merge: true));
    }

    // Mark as synced in local database
    for (final student in students) {
      await DatabaseHelper().updateStudentSyncStatus(student.studentId, true);
    }
  }

  /// Sync attendance to Firebase
  Future<void> _syncAttendance(WriteBatch batch) async {
    final firestore = await _getFirestore();
    if (firestore == null) return;

    final unsyncedAttendance = await DatabaseHelper().getUnsyncedAttendance();

    for (final attendance in unsyncedAttendance) {
      final attendanceDoc = firestore
          .collection(_schoolDataCollection)
          .doc(_schoolId)
          .collection(_attendanceCollection)
          .doc('attendance_${attendance.id}');

      final attendanceData = {
        'local_id': attendance.id,
        'student_id': attendance.studentId,
        'date': attendance.date.toIso8601String(),
        'status': attendance.status.value, // Use the string value
        'marked_by': attendance.markedBy,
        'marked_at': attendance.markedAt.toIso8601String(),
        'profile_image': attendance.profileImage,
        'notes': attendance.notes,
        'created_at': attendance.createdAt?.toIso8601String(),
        'synced_at': DateTime.now().toIso8601String(),
        'school_id': _schoolId,
        'device_id': await _getDeviceId(),
        'user_id': await _getCurrentUserId(),
      };

      batch.set(attendanceDoc, attendanceData, SetOptions(merge: true));
    }

    // Mark as synced in local database
    for (final attendance in unsyncedAttendance) {
      await DatabaseHelper().updateAttendanceSyncStatus(attendance.id, true);
    }
  }

  /// Sync payments to Firebase
  Future<void> _syncPayments(WriteBatch batch) async {
    final firestore = await _getFirestore();
    if (firestore == null) return;

    final unsyncedPayments = await DatabaseHelper().getUnsyncedPayments();

    for (final payment in unsyncedPayments) {
      final paymentDoc = firestore
          .collection(_schoolDataCollection)
          .doc(_schoolId)
          .collection(_paymentsCollection)
          .doc('payment_${payment.paymentId}');

      final paymentData = {
        'local_id': payment.paymentId,
        'student_id': payment.studentId,
        'amount': payment.amount,
        'date_paid': payment.paymentDate.toIso8601String(),
        'payment_type': payment.paymentType,
        'reference': payment.reference,
        'received_by': payment.receivedBy,
        'notes': payment.notes,
        'created_at': payment.createdAt?.toIso8601String(),
        'synced_at': DateTime.now().toIso8601String(),
        'school_id': _schoolId,
        'device_id': await _getDeviceId(),
        'user_id': await _getCurrentUserId(),
      };

      batch.set(paymentDoc, paymentData, SetOptions(merge: true));
    }

    // Mark as synced in local database
    for (final payment in unsyncedPayments) {
      await DatabaseHelper().updatePaymentSyncStatus(payment.paymentId, true);
    }
  }

  /// Sync discipline records to Firebase
  Future<void> _syncDiscipline(WriteBatch batch) async {
    final firestore = await _getFirestore();
    if (firestore == null) return;

    final unsyncedDiscipline = await DatabaseHelper().getUnsyncedDiscipline();

    for (final discipline in unsyncedDiscipline) {
      final disciplineDoc = firestore
          .collection(_schoolDataCollection)
          .doc(_schoolId)
          .collection(_disciplineCollection)
          .doc('discipline_${discipline.id}');

      final disciplineData = {
        'local_id': discipline.id,
        'student_id': discipline.studentId,
        'date': discipline.date.toIso8601String(),
        'type': discipline.type,
        'description': discipline.description,
        'action_taken': discipline.actionTaken,
        'recorded_by': discipline.recordedBy,
        'resolved': discipline.resolved,
        'created_at': discipline.createdAt?.toIso8601String(),
        'synced_at': DateTime.now().toIso8601String(),
        'school_id': _schoolId,
        'device_id': await _getDeviceId(),
        'user_id': await _getCurrentUserId(),
      };

      batch.set(disciplineDoc, disciplineData, SetOptions(merge: true));
    }

    // Mark as synced in local database
    for (final discipline in unsyncedDiscipline) {
      await DatabaseHelper().updateDisciplineSyncStatus(discipline.id, true);
    }
  }

  /// Log sync operation
  Future<void> _logSync(
    FirebaseFirestore firestore,
    bool success,
    String message,
  ) async {
    try {
      await firestore
          .collection(_schoolDataCollection)
          .doc(_schoolId)
          .collection(_syncLogCollection)
          .add({
            'school_id': _schoolId,
            'success': success,
            'message': message,
            'timestamp': DateTime.now().toIso8601String(),
            'device_id': await _getDeviceId(),
            'user_id': await _getCurrentUserId(),
          });
    } catch (e) {
      print('Error logging sync: $e');
    }
  }

  /// Get sync status
  Future<Map<String, dynamic>> getSyncStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastSync = prefs.getString('last_sync_time');

      final unsyncedAttendance = await DatabaseHelper().getUnsyncedAttendance();
      final unsyncedPayments = await DatabaseHelper().getUnsyncedPayments();
      final unsyncedDiscipline = await DatabaseHelper().getUnsyncedDiscipline();

      return {
        'last_sync': lastSync,
        'unsynced_attendance': unsyncedAttendance.length,
        'unsynced_payments': unsyncedPayments.length,
        'unsynced_discipline': unsyncedDiscipline.length,
        'is_sync_available': await isSyncAvailable(),
        'school_id': _schoolId,
        'school_name': _schoolName,
      };
    } catch (e) {
      print('Error getting sync status: $e');
      return {};
    }
  }

  /// Initialize school data in Firebase
  Future<bool> initializeSchoolData() async {
    try {
      final firestore = await _getFirestore();
      if (firestore == null) return false;

      final schoolDoc = firestore
          .collection(_schoolDataCollection)
          .doc(_schoolId);

      await schoolDoc.set({
        'school_id': _schoolId,
        'school_name': _schoolName,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
        'is_active': true,
        'device_id': await _getDeviceId(),
      });

      return true;
    } catch (e) {
      print('Error initializing school data: $e');
      return false;
    }
  }

  /// Get device ID for multi-user support
  Future<String> _getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    String? deviceId = prefs.getString('device_id');

    if (deviceId == null) {
      deviceId =
          'device_${DateTime.now().millisecondsSinceEpoch}_${(1000 + (DateTime.now().millisecondsSinceEpoch % 9000))}';
      await prefs.setString('device_id', deviceId);
    }

    return deviceId;
  }

  /// Get current user ID
  Future<String?> _getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('current_user_id');
  }

  /// Clean up resources
  void dispose() {
    _firestore = null;
    _localDb = null;
    _isInitialized = false;
  }

  /// Public method to ensure Firebase is initialized if online
  Future<FirebaseFirestore?> ensureFirebaseInitialized() async {
    return await _getFirestore();
  }
}
