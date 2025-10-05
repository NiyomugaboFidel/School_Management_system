/// Sync Queue Item Model
/// Represents a pending operation that needs to be synced to Firebase
/// when the device comes back online
class SyncQueueItem {
  final String id;
  final String tableName;
  final String operation; // 'insert', 'update', 'delete'
  final String payload; // JSON string of the data
  final int timestamp;
  final int retryCount;
  final String? errorMessage;
  final String userId; // Track which user made the change
  final String? recordId; // ID of the record being synced

  SyncQueueItem({
    required this.id,
    required this.tableName,
    required this.operation,
    required this.payload,
    required this.timestamp,
    this.retryCount = 0,
    this.errorMessage,
    required this.userId,
    this.recordId,
  });

  /// Create from database map
  factory SyncQueueItem.fromMap(Map<String, dynamic> map) {
    return SyncQueueItem(
      id: map['id'] as String,
      tableName: map['table_name'] as String,
      operation: map['operation'] as String,
      payload: map['payload'] as String,
      timestamp: map['timestamp'] as int,
      retryCount: map['retry_count'] as int? ?? 0,
      errorMessage: map['error_message'] as String?,
      userId: map['user_id'] as String,
      recordId: map['record_id'] as String?,
    );
  }

  /// Convert to database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'table_name': tableName,
      'operation': operation,
      'payload': payload,
      'timestamp': timestamp,
      'retry_count': retryCount,
      'error_message': errorMessage,
      'user_id': userId,
      'record_id': recordId,
    };
  }

  /// Create a copy with updated fields
  SyncQueueItem copyWith({
    String? id,
    String? tableName,
    String? operation,
    String? payload,
    int? timestamp,
    int? retryCount,
    String? errorMessage,
    String? userId,
    String? recordId,
  }) {
    return SyncQueueItem(
      id: id ?? this.id,
      tableName: tableName ?? this.tableName,
      operation: operation ?? this.operation,
      payload: payload ?? this.payload,
      timestamp: timestamp ?? this.timestamp,
      retryCount: retryCount ?? this.retryCount,
      errorMessage: errorMessage ?? this.errorMessage,
      userId: userId ?? this.userId,
      recordId: recordId ?? this.recordId,
    );
  }

  @override
  String toString() {
    return 'SyncQueueItem(id: $id, table: $tableName, op: $operation, retry: $retryCount)';
  }
}
