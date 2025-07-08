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

class SyncService {
  final FirebaseFirestore firestore;
  final Database localDb;

  SyncService({required this.firestore, required this.localDb});

  final DatabaseHelper _dbHelper = DatabaseHelper();

  // Static school identifier - no authentication required
  static const String _schoolId = 'school_001';
  static const String _schoolName = 'Default School';

  // Collection names
  static const String _usersCollection = 'users';
  static const String _studentsCollection = 'students';
  static const String _attendanceCollection = 'attendance';
  static const String _paymentsCollection = 'payments';
  static const String _disciplineCollection = 'discipline';
  static const String _syncLogCollection = 'sync_logs';
  static const String _schoolDataCollection = 'school_data';

  /// Check if sync is available (always true for static school)
  Future<bool> isSyncAvailable() async {
    return true; // No authentication required
  }

  /// Get school identifier
  String getSchoolId() {
    return _schoolId;
  }

  /// Sync all data to Firebase
  Future<SyncResult> syncAllData() async {
    try {
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
      await _logSync(true, 'Full sync completed');

      // Update last sync time
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_sync_time', DateTime.now().toIso8601String());

      return SyncResult.success(
        message: 'Full sync completed successfully',
        recordCount: 0, // TODO: Calculate actual record count
      );
    } catch (e) {
      print('Sync error: $e');
      await _logSync(false, e.toString());
      return SyncResult.failure(error: e.toString(), message: 'Sync failed');
    }
  }

  /// Sync users to Firebase
  Future<void> _syncUsers(WriteBatch batch) async {
    final users = await _dbHelper.getAllActiveUsers();

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
      };

      batch.set(userDoc, userData, SetOptions(merge: true));
    }
  }

  /// Sync students to Firebase
  Future<void> _syncStudents(WriteBatch batch) async {
    final students = await _dbHelper.getAllStudents();

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
      };

      batch.set(studentDoc, studentData, SetOptions(merge: true));
    }

    // Mark as synced in local database
    for (final student in students) {
      await _dbHelper.updateStudentSyncStatus(student.studentId, true);
    }
  }

  /// Sync attendance to Firebase
  Future<void> _syncAttendance(WriteBatch batch) async {
    final unsyncedAttendance = await _dbHelper.getUnsyncedAttendance();

    for (final attendance in unsyncedAttendance) {
      final attendanceDoc = firestore
          .collection(_schoolDataCollection)
          .doc(_schoolId)
          .collection(_attendanceCollection)
          .doc('attendance_${attendance.id}');

      final attendanceData = {
        'local_id': attendance.id,
        'student_id': attendance.studentId,
        'date': attendance.date,
        'status': attendance.status,
        'marked_by': attendance.markedBy,
        'marked_at': attendance.markedAt,
        'profile_image': attendance.profileImage,
        'notes': attendance.notes,
        'created_at': attendance.createdAt,
        'synced_at': DateTime.now().toIso8601String(),
        'school_id': _schoolId,
      };

      batch.set(attendanceDoc, attendanceData, SetOptions(merge: true));
    }

    // Mark as synced in local database
    for (final attendance in unsyncedAttendance) {
      await _dbHelper.updateAttendanceSyncStatus(attendance.id, true);
    }
  }

  /// Sync payments to Firebase
  Future<void> _syncPayments(WriteBatch batch) async {
    final unsyncedPayments = await _dbHelper.getUnsyncedPayments();

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
      };

      batch.set(paymentDoc, paymentData, SetOptions(merge: true));
    }

    // Mark as synced in local database
    for (final payment in unsyncedPayments) {
      await _dbHelper.updatePaymentSyncStatus(payment.paymentId, true);
    }
  }

  /// Sync discipline records to Firebase
  Future<void> _syncDiscipline(WriteBatch batch) async {
    final unsyncedDiscipline = await _dbHelper.getUnsyncedDiscipline();

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
      };

      batch.set(disciplineDoc, disciplineData, SetOptions(merge: true));
    }

    // Mark as synced in local database
    for (final discipline in unsyncedDiscipline) {
      await _dbHelper.updateDisciplineSyncStatus(discipline.id, true);
    }
  }

  /// Pull data from Firebase
  Future<bool> pullFromFirebase() async {
    try {
      // Pull users
      await _pullUsers();

      // Pull students
      await _pullStudents();

      // Pull attendance
      await _pullAttendance();

      // Pull payments
      await _pullPayments();

      // Pull discipline records
      await _pullDiscipline();

      // Log sync
      await _logSync(true, 'Pull from Firebase completed');

      return true;
    } catch (e) {
      print('Pull error: $e');
      await _logSync(false, e.toString());
      return false;
    }
  }

  /// Pull users from Firebase
  Future<void> _pullUsers() async {
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
  }

  /// Pull students from Firebase
  Future<void> _pullStudents() async {
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
  }

  /// Pull attendance from Firebase
  Future<void> _pullAttendance() async {
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
  }

  /// Pull payments from Firebase
  Future<void> _pullPayments() async {
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
  }

  /// Pull discipline records from Firebase
  Future<void> _pullDiscipline() async {
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
  }

  /// Log sync operation
  Future<void> _logSync(bool success, String message) async {
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

      final unsyncedAttendance = await _dbHelper.getUnsyncedAttendance();
      final unsyncedPayments = await _dbHelper.getUnsyncedPayments();
      final unsyncedDiscipline = await _dbHelper.getUnsyncedDiscipline();

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
      final schoolDoc = firestore
          .collection(_schoolDataCollection)
          .doc(_schoolId);

      await schoolDoc.set({
        'school_id': _schoolId,
        'school_name': _schoolName,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
        'is_active': true,
      });

      return true;
    } catch (e) {
      print('Error initializing school data: $e');
      return false;
    }
  }

  // Sync students table
  Future<void> syncStudents() async {
    // 1. Pull from Firebase and update local
    firestore.collection('students').snapshots().listen((snapshot) async {
      for (var doc in snapshot.docChanges) {
        final data = doc.doc.data();
        if (data == null) continue;
        final local = await localDb.query(
          'students',
          where: 'id = ?',
          whereArgs: [data['id']],
        );
        if (local.isEmpty || shouldOverwrite(local.first, data)) {
          await localDb.insert(
            'students',
            data,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
          await NotificationService.showNotification(
            'Student Synced',
            'Student ${data['name']} updated from cloud',
          );
          await logAudit('students', 'sync_pull', data);
        }
      }
    });

    // 2. Push local changes to Firebase (example: all students)
    final localStudents = await localDb.query('students');
    for (var student in localStudents) {
      final doc =
          await firestore
              .collection('students')
              .doc(student['id'].toString())
              .get();
      if (!doc.exists || shouldOverwrite(doc.data() ?? {}, student)) {
        await firestore
            .collection('students')
            .doc(student['id'].toString())
            .set(student);
        await NotificationService.showNotification(
          'Student Synced',
          'Student ${student['name']} updated to cloud',
        );
        await logAudit('students', 'sync_push', student);
      }
    }
  }

  // Conflict resolution (last-write-wins)
  bool shouldOverwrite(
    Map<String, dynamic> local,
    Map<String, dynamic> remote,
  ) {
    return (remote['updatedAt'] ?? 0) > (local['updatedAt'] ?? 0);
  }

  // Log audit to Firestore
  Future<void> logAudit(
    String table,
    String action,
    Map<String, dynamic> data,
  ) async {
    await firestore.collection('logs').add({
      'table': table,
      'action': action,
      'data': data,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  // Call this after every local CRUD
  Future<void> onLocalChange(String table, Map<String, dynamic> data) async {
    // Push to Firebase and log
  }

  // Call this when Firebase changes
  Future<void> onFirebaseChange(String table, Map<String, dynamic> data) async {
    // Update local DB and log
  }
}
