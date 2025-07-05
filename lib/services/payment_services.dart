import 'package:sqlite_crud_app/SQLite/database_helper.dart';

import '../models/payment.dart';

/// Service class for managing student payments
class PaymentService {
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  /// Record a new payment for a student
  Future<bool> recordPayment({
    required int studentId,
    required double amount,
    required String paymentType,
    required String paymentMethod,
    String? receiptNumber,
    String? parentReason,
    String? notes,
  }) async {
    try {
      if (amount <= 0) {
        throw ArgumentError('Payment amount must be greater than 0');
      }

      return await _databaseHelper.recordPayment(
        studentId,
        amount,
        paymentType,
        paymentMethod,
        receiptNumber: receiptNumber,
        parentReason: parentReason,
      );
    } catch (e) {
      print('Error in PaymentService.recordPayment: $e');
      return false;
    }
  }

  /// Get all payments for a specific student
  Future<List<Payment>> getPaymentsByStudentId(int studentId) async {
    try {
      return await _databaseHelper.getStudentPayments(studentId);
    } catch (e) {
      print('Error in PaymentService.getPaymentsByStudentId: $e');
      return [];
    }
  }

  /// Get recent payments across all students
  Future<List<Payment>> getRecentPayments({int limit = 50}) async {
    try {
      return await _databaseHelper.getRecentPayments(limit: limit);
    } catch (e) {
      print('Error in PaymentService.getRecentPayments: $e');
      return [];
    }
  }

  /// Get total amount paid by a student
  Future<double> getStudentTotalPayments(int studentId) async {
    try {
      return await _databaseHelper.getStudentTotalPayments(studentId);
    } catch (e) {
      print('Error in PaymentService.getStudentTotalPayments: $e');
      return 0.0;
    }
  }

  /// Get payments by date range
  Future<List<Payment>> getPaymentsByDateRange({
    required DateTime startDate,
    required DateTime endDate,
    int? studentId,
  }) async {
    try {
      final db = await _databaseHelper.database;
      String query = '''
        SELECT p.*, s.full_name, s.reg_number, c.name as class_name
        FROM payments p
        JOIN students s ON p.student_id = s.student_id
        JOIN classes c ON s.class_id = c.class_id
        WHERE p.date_paid BETWEEN ? AND ?
      ''';

      List<dynamic> whereArgs = [
        startDate.toIso8601String().split('T')[0],
        endDate.toIso8601String().split('T')[0],
      ];

      if (studentId != null) {
        query += ' AND p.student_id = ?';
        whereArgs.add(studentId);
      }

      query += ' ORDER BY p.date_paid DESC';

      final result = await db.rawQuery(query, whereArgs);
      return result.map((map) => Payment.fromMap(map)).toList();
    } catch (e) {
      print('Error in PaymentService.getPaymentsByDateRange: $e');
      return [];
    }
  }

  /// Get payments by payment type
  Future<List<Payment>> getPaymentsByType(
    String paymentType, {
    int? studentId,
  }) async {
    try {
      final db = await _databaseHelper.database;
      String query = '''
        SELECT p.*, s.full_name, s.reg_number, c.name as class_name
        FROM payments p
        JOIN students s ON p.student_id = s.student_id
        JOIN classes c ON s.class_id = c.class_id
        WHERE p.payment_type = ?
      ''';

      List<dynamic> whereArgs = [paymentType];

      if (studentId != null) {
        query += ' AND p.student_id = ?';
        whereArgs.add(studentId);
      }

      query += ' ORDER BY p.date_paid DESC';

      final result = await db.rawQuery(query, whereArgs);
      return result.map((map) => Payment.fromMap(map)).toList();
    } catch (e) {
      print('Error in PaymentService.getPaymentsByType: $e');
      return [];
    }
  }

  /// Get payment statistics for a student
  Future<PaymentStatistics> getStudentPaymentStatistics(int studentId) async {
    try {
      final db = await _databaseHelper.database;
      final result = await db.rawQuery(
        '''
        SELECT 
          COUNT(*) as total_payments,
          SUM(amount) as total_amount,
          AVG(amount) as average_amount,
          MIN(amount) as min_amount,
          MAX(amount) as max_amount,
          MIN(date_paid) as first_payment_date,
          MAX(date_paid) as last_payment_date
        FROM payments
        WHERE student_id = ?
      ''',
        [studentId],
      );

      if (result.isNotEmpty) {
        final data = result.first;
        return PaymentStatistics(
          totalPayments: (data['total_payments'] as num?)?.toInt() ?? 0,
          totalAmount: (data['total_amount'] as num?)?.toDouble() ?? 0.0,
          averageAmount: (data['average_amount'] as num?)?.toDouble() ?? 0.0,
          minAmount: (data['min_amount'] as num?)?.toDouble() ?? 0.0,
          maxAmount: (data['max_amount'] as num?)?.toDouble() ?? 0.0,
          firstPaymentDate:
              data['first_payment_date'] != null
                  ? DateTime.tryParse(data['first_payment_date'].toString())
                  : null,
          lastPaymentDate:
              data['last_payment_date'] != null
                  ? DateTime.tryParse(data['last_payment_date'].toString())
                  : null,
        );
      }

      return PaymentStatistics.empty();
    } catch (e) {
      print('Error in PaymentService.getStudentPaymentStatistics: $e');
      return PaymentStatistics.empty();
    }
  }

  /// Check if a student has any pending payments (if needed for business logic)
  Future<bool> hasOutstandingBalance(
    int studentId,
    double expectedTotal,
  ) async {
    try {
      final totalPaid = await getStudentTotalPayments(studentId);
      return totalPaid < expectedTotal;
    } catch (e) {
      print('Error in PaymentService.hasOutstandingBalance: $e');
      return true; // Assume outstanding if error occurs
    }
  }

  /// Get payments by receipt number
  Future<Payment?> getPaymentByReceiptNumber(String receiptNumber) async {
    try {
      final db = await _databaseHelper.database;
      final result = await db.rawQuery(
        '''
        SELECT p.*, s.full_name, s.reg_number, c.name as class_name
        FROM payments p
        JOIN students s ON p.student_id = s.student_id
        JOIN classes c ON s.class_id = c.class_id
        WHERE p.receipt_number = ?
      ''',
        [receiptNumber],
      );

      return result.isNotEmpty ? Payment.fromMap(result.first) : null;
    } catch (e) {
      print('Error in PaymentService.getPaymentByReceiptNumber: $e');
      return null;
    }
  }

  /// Update payment sync status
  Future<bool> updatePaymentSyncStatus(int paymentId, bool synced) async {
    try {
      final db = await _databaseHelper.database;
      final result = await db.update(
        'payments',
        {
          'synced': synced ? 1 : 0,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [paymentId],
      );
      return result > 0;
    } catch (e) {
      print('Error in PaymentService.updatePaymentSyncStatus: $e');
      return false;
    }
  }

  /// Get unsynced payments
  Future<List<Payment>> getUnsyncedPayments() async {
    try {
      final db = await _databaseHelper.database;
      final result = await db.rawQuery('''
        SELECT p.*, s.full_name, s.reg_number, c.name as class_name
        FROM payments p
        JOIN students s ON p.student_id = s.student_id
        JOIN classes c ON s.class_id = c.class_id
        WHERE p.synced = 0
        ORDER BY p.created_at ASC
      ''');

      return result.map((map) => Payment.fromMap(map)).toList();
    } catch (e) {
      print('Error in PaymentService.getUnsyncedPayments: $e');
      return [];
    }
  }
}

/// Payment statistics model
class PaymentStatistics {
  final int totalPayments;
  final double totalAmount;
  final double averageAmount;
  final double minAmount;
  final double maxAmount;
  final DateTime? firstPaymentDate;
  final DateTime? lastPaymentDate;

  const PaymentStatistics({
    required this.totalPayments,
    required this.totalAmount,
    required this.averageAmount,
    required this.minAmount,
    required this.maxAmount,
    this.firstPaymentDate,
    this.lastPaymentDate,
  });

  factory PaymentStatistics.empty() {
    return const PaymentStatistics(
      totalPayments: 0,
      totalAmount: 0.0,
      averageAmount: 0.0,
      minAmount: 0.0,
      maxAmount: 0.0,
      firstPaymentDate: null,
      lastPaymentDate: null,
    );
  }

  @override
  String toString() {
    return 'PaymentStatistics(total: $totalPayments, amount: \$${totalAmount.toStringAsFixed(2)})';
  }
}
