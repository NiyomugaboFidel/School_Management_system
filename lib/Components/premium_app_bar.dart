import 'package:flutter/material.dart';
import 'package:sqlite_crud_app/Views/notification/screens/notification_page.dart';
import 'package:sqlite_crud_app/constants/app_colors.dart';

/// Premium app bar with notifications and search
class PremiumAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showNotificationIcon;
  final bool showSearchIcon;
  final int notificationCount;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onSearchTap;
  final bool centerTitle;

  const PremiumAppBar({
    Key? key,
    required this.title,
    this.showNotificationIcon = true,
    this.showSearchIcon = true,
    this.notificationCount = 0,
    this.onNotificationTap,
    this.onSearchTap,
    this.centerTitle = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary500, AppColors.primary600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary500.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: AppBar(
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: centerTitle,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Builder(
          builder:
              (context) => IconButton(
                icon: const Icon(Icons.menu, color: Colors.white),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
        ),
        actions: [
          // Search Icon
          if (showSearchIcon)
            IconButton(
              icon: const Icon(Icons.search, color: Colors.white),
              onPressed:
                  onSearchTap ??
                  () {
                    // TODO: Implement search
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Search coming soon!'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
            ),

          // Notification Icon with Badge
          if (showNotificationIcon)
            Stack(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.notifications_outlined,
                    color: Colors.white,
                  ),
                  onPressed:
                      onNotificationTap ??
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => NotificationPage(),
                          ),
                        );
                      },
                ),
                if (notificationCount > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        notificationCount > 99 ? '99+' : '$notificationCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),

          const SizedBox(width: 8),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
