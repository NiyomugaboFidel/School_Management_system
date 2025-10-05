import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/sync_status.dart';
import '../services/enhanced_sync_service.dart';

/// Sync Indicator Widget
/// Shows the current sync status with icon and optional text
/// Adapts to light/dark mode automatically
class SyncIndicator extends StatelessWidget {
  final bool showText;
  final bool showDetails;
  final double iconSize;

  const SyncIndicator({
    Key? key,
    this.showText = false,
    this.showDetails = false,
    this.iconSize = 20,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<EnhancedSyncService>(
      builder: (context, syncService, child) {
        final status = syncService.syncStatus;
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return GestureDetector(
          onTap: showDetails ? () => _showSyncDetails(context, status) : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: status.color.withOpacity(isDark ? 0.2 : 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Animated icon
                status.isSyncing
                    ? SizedBox(
                      width: iconSize,
                      height: iconSize,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(status.color),
                      ),
                    )
                    : Icon(status.icon, size: iconSize, color: status.color),

                // Optional text
                if (showText) ...[
                  const SizedBox(width: 6),
                  Text(
                    status.message,
                    style: TextStyle(
                      fontSize: 12,
                      color: status.color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSyncDetails(BuildContext context, SyncStatus status) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                Icon(status.icon, color: status.color),
                const SizedBox(width: 8),
                const Text('Sync Status'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('Status', status.message),
                if (status.hasPendingChanges)
                  _buildDetailRow('Pending', '${status.pendingCount} items'),
                if (status.hasErrors)
                  _buildDetailRow('Failed', '${status.failedCount} items'),
                if (status.lastSyncTime != null)
                  _buildDetailRow(
                    'Last Sync',
                    _formatTime(status.lastSyncTime!),
                  ),
                _buildDetailRow(
                  'Connection',
                  status.isOnline ? 'Online' : 'Offline',
                ),
              ],
            ),
            actions: [
              if (status.hasPendingChanges && status.isOnline)
                TextButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    Provider.of<EnhancedSyncService>(
                      context,
                      listen: false,
                    ).syncNow();
                  },
                  icon: const Icon(Icons.sync),
                  label: const Text('Sync Now'),
                ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

/// Sync Status Banner
/// Shows a banner at the top of the screen when offline or syncing
class SyncStatusBanner extends StatelessWidget {
  const SyncStatusBanner({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<EnhancedSyncService>(
      builder: (context, syncService, child) {
        final status = syncService.syncStatus;

        // Only show banner for offline or error states
        if (status.state != SyncState.offline &&
            status.state != SyncState.error &&
            status.state != SyncState.pending) {
          return const SizedBox.shrink();
        }

        return Material(
          color: status.color.withOpacity(0.9),
          elevation: 4,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(status.icon, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    status.message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (status.hasPendingChanges && status.isOnline)
                  TextButton(
                    onPressed: () => syncService.syncNow(),
                    style: TextButton.styleFrom(foregroundColor: Colors.white),
                    child: const Text('SYNC NOW'),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
