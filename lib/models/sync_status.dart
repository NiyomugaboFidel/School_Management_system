import 'package:flutter/material.dart';

/// Sync Status Enum
/// Represents the current state of synchronization
enum SyncState {
  idle, // Not syncing, no pending items
  syncing, // Currently syncing data
  synced, // Successfully synced all items
  error, // Error occurred during sync
  offline, // Device is offline with pending changes
  pending, // Has pending changes waiting for network
}

/// Sync Status Model
/// Provides detailed information about the current sync state
class SyncStatus {
  final SyncState state;
  final int pendingCount;
  final int failedCount;
  final String? errorMessage;
  final DateTime? lastSyncTime;
  final bool isOnline;

  const SyncStatus({
    required this.state,
    this.pendingCount = 0,
    this.failedCount = 0,
    this.errorMessage,
    this.lastSyncTime,
    this.isOnline = true,
  });

  /// Create idle status
  factory SyncStatus.idle() {
    return SyncStatus(state: SyncState.idle, lastSyncTime: DateTime.now());
  }

  /// Create syncing status
  factory SyncStatus.syncing(int pendingCount) {
    return SyncStatus(state: SyncState.syncing, pendingCount: pendingCount);
  }

  /// Create synced status
  factory SyncStatus.synced() {
    return SyncStatus(state: SyncState.synced, lastSyncTime: DateTime.now());
  }

  /// Create error status
  factory SyncStatus.error(String message, int failedCount) {
    return SyncStatus(
      state: SyncState.error,
      errorMessage: message,
      failedCount: failedCount,
    );
  }

  /// Create offline status
  factory SyncStatus.offline(int pendingCount) {
    return SyncStatus(
      state: SyncState.offline,
      pendingCount: pendingCount,
      isOnline: false,
    );
  }

  /// Create pending status
  factory SyncStatus.pending(int pendingCount) {
    return SyncStatus(state: SyncState.pending, pendingCount: pendingCount);
  }

  /// Get icon for current state
  IconData get icon {
    switch (state) {
      case SyncState.idle:
        return Icons.cloud_done;
      case SyncState.syncing:
        return Icons.sync;
      case SyncState.synced:
        return Icons.cloud_done;
      case SyncState.error:
        return Icons.error_outline;
      case SyncState.offline:
        return Icons.cloud_off;
      case SyncState.pending:
        return Icons.cloud_upload;
    }
  }

  /// Get color for current state
  Color get color {
    switch (state) {
      case SyncState.idle:
        return Colors.grey;
      case SyncState.syncing:
        return Colors.blue;
      case SyncState.synced:
        return Colors.green;
      case SyncState.error:
        return Colors.red;
      case SyncState.offline:
        return Colors.orange;
      case SyncState.pending:
        return Colors.amber;
    }
  }

  /// Get user-friendly message
  String get message {
    switch (state) {
      case SyncState.idle:
        return 'All synced';
      case SyncState.syncing:
        return 'Syncing $pendingCount item${pendingCount != 1 ? 's' : ''}...';
      case SyncState.synced:
        return 'Synced successfully';
      case SyncState.error:
        return errorMessage ?? 'Sync failed';
      case SyncState.offline:
        return pendingCount > 0
            ? 'Offline - $pendingCount change${pendingCount != 1 ? 's' : ''} pending'
            : 'Offline';
      case SyncState.pending:
        return '$pendingCount change${pendingCount != 1 ? 's' : ''} pending';
    }
  }

  /// Check if sync is in progress
  bool get isSyncing => state == SyncState.syncing;

  /// Check if there are pending changes
  bool get hasPendingChanges => pendingCount > 0;

  /// Check if there are errors
  bool get hasErrors => state == SyncState.error || failedCount > 0;

  /// Copy with updated fields
  SyncStatus copyWith({
    SyncState? state,
    int? pendingCount,
    int? failedCount,
    String? errorMessage,
    DateTime? lastSyncTime,
    bool? isOnline,
  }) {
    return SyncStatus(
      state: state ?? this.state,
      pendingCount: pendingCount ?? this.pendingCount,
      failedCount: failedCount ?? this.failedCount,
      errorMessage: errorMessage ?? this.errorMessage,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      isOnline: isOnline ?? this.isOnline,
    );
  }

  @override
  String toString() {
    return 'SyncStatus(state: $state, pending: $pendingCount, failed: $failedCount, online: $isOnline)';
  }
}

