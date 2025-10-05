import 'package:flutter/material.dart';
import 'sync_indicator.dart';

/// Enhanced App Scaffold with Sync Indicator
/// Provides consistent layout across the app with sync status
/// Automatically adapts to light/dark mode
class AppScaffold extends StatelessWidget {
  final String? title;
  final Widget body;
  final Widget? floatingActionButton;
  final List<Widget>? actions;
  final Widget? drawer;
  final Widget? bottomNavigationBar;
  final bool showSyncIndicator;
  final bool showSyncBanner;
  final PreferredSizeWidget? appBar;

  const AppScaffold({
    Key? key,
    this.title,
    required this.body,
    this.floatingActionButton,
    this.actions,
    this.drawer,
    this.bottomNavigationBar,
    this.showSyncIndicator = true,
    this.showSyncBanner = true,
    this.appBar,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          appBar ??
          (title != null
              ? AppBar(
                title: Text(title!),
                actions: [
                  if (showSyncIndicator)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Center(
                        child: SyncIndicator(
                          showText: false,
                          showDetails: true,
                        ),
                      ),
                    ),
                  ...?actions,
                ],
              )
              : null),
      drawer: drawer,
      body: Column(
        children: [
          // Sync status banner
          if (showSyncBanner) const SyncStatusBanner(),
          // Main content
          Expanded(child: body),
        ],
      ),
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}

/// Refresh Indicator Wrapper
/// Provides pull-to-refresh functionality with sync integration
class AppRefreshIndicator extends StatelessWidget {
  final Widget child;
  final Future<void> Function()? onRefresh;

  const AppRefreshIndicator({Key? key, required this.child, this.onRefresh})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(onRefresh: onRefresh ?? () async {}, child: child);
  }
}

/// Empty State Widget
/// Shows when there's no data to display
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  const EmptyState({
    Key? key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 80,
              color: isDark ? Colors.grey[600] : Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[const SizedBox(height: 24), action!],
          ],
        ),
      ),
    );
  }
}

/// Error State Widget
/// Shows when an error occurs
class ErrorState extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onRetry;

  const ErrorState({
    Key? key,
    this.title = 'Oops! Something went wrong',
    required this.message,
    this.onRetry,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Loading State Widget
/// Shows when data is being loaded
class LoadingState extends StatelessWidget {
  final String? message;

  const LoadingState({Key? key, this.message}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(message!, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ],
      ),
    );
  }
}
