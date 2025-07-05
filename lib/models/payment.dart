/// Payment model class
class Payment {
  final int paymentId;
  final int studentId;
  final double amount;
  final String paymentType;
  final String? reference;
  final DateTime paymentDate;
  final String receivedBy;
  final String? notes;
  final bool synced;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? fullName;
  final String? regNumber;
  final String? className;

  const Payment({
    required this.paymentId,
    required this.studentId,
    required this.amount,
    required this.paymentType,
    this.reference,
    required this.paymentDate,
    required this.receivedBy,
    this.notes,
    this.synced = false,
    this.createdAt,
    this.updatedAt,
    this.fullName,
    this.regNumber,
    this.className,
  });

  factory Payment.fromMap(Map<String, dynamic> map) {
    return Payment(
      paymentId: map['payment_id']?.toInt() ?? 0,
      studentId: map['student_id']?.toInt() ?? 0,
      amount:
          (map['amount'] is int)
              ? (map['amount'] as int).toDouble()
              : (map['amount']?.toDouble() ?? 0.0),
      paymentType: map['payment_type']?.toString() ?? '',
      reference: map['reference']?.toString(),
      paymentDate: DateTime.parse(map['payment_date'].toString()),
      receivedBy: map['received_by']?.toString() ?? '',
      notes: map['notes']?.toString(),
      synced: (map['synced']?.toInt() ?? 0) == 1,
      createdAt:
          map['created_at'] != null
              ? DateTime.tryParse(map['created_at'].toString())
              : null,
      updatedAt:
          map['updated_at'] != null
              ? DateTime.tryParse(map['updated_at'].toString())
              : null,
      fullName: map['full_name']?.toString(),
      regNumber: map['reg_number']?.toString(),
      className: map['class_name']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'payment_id': paymentId,
      'student_id': studentId,
      'amount': amount,
      'payment_type': paymentType,
      'reference': reference,
      'payment_date': paymentDate.toIso8601String(),
      'received_by': receivedBy,
      'notes': notes,
      'synced': synced ? 1 : 0,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  Payment copyWith({
    int? paymentId,
    int? studentId,
    double? amount,
    String? paymentType,
    String? reference,
    DateTime? paymentDate,
    String? receivedBy,
    String? notes,
    bool? synced,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Payment(
      paymentId: paymentId ?? this.paymentId,
      studentId: studentId ?? this.studentId,
      amount: amount ?? this.amount,
      paymentType: paymentType ?? this.paymentType,
      reference: reference ?? this.reference,
      paymentDate: paymentDate ?? this.paymentDate,
      receivedBy: receivedBy ?? this.receivedBy,
      notes: notes ?? this.notes,
      synced: synced ?? this.synced,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() =>
      'Payment(id: $paymentId, student: $studentId, amount: $amount, type: $paymentType)';
}
