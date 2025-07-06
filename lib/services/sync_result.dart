/// Result of sync operation
class SyncResult {
  final bool isSuccess;
  final String message;
  final int? recordCount;
  final String? error;

  const SyncResult._({
    required this.isSuccess,
    required this.message,
    this.recordCount,
    this.error,
  });

  /// Success result
  factory SyncResult.success({required String message, int? recordCount}) {
    return SyncResult._(
      isSuccess: true,
      message: message,
      recordCount: recordCount,
    );
  }

  /// Failure result
  factory SyncResult.failure({required String error, String? message}) {
    return SyncResult._(
      isSuccess: false,
      message: message ?? 'Sync failed',
      error: error,
    );
  }

  @override
  String toString() {
    return 'SyncResult(isSuccess: $isSuccess, message: $message, recordCount: $recordCount, error: $error)';
  }
}
