import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class XappBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onMenuTap;
  final Color backgroundColor;
  final bool hasNavBar;
  final Function(int)? onNavTap;
  final int currentNavIndex;
  final List<String> navItems;
  final bool hasBackButton;

  final bool isSearch;
  final bool isMenu;
  final String? title;
  final bool isTitleCentered;
  final Widget? customTitleWidget;

  const XappBar({
    Key? key,
    this.onMenuTap,
    this.backgroundColor = AppColors.primary,
    this.hasNavBar = false,
    this.onNavTap,
    this.currentNavIndex = 0,
    this.navItems = const ['HOME'],
    this.isSearch = false,
    this.isMenu = false,
    this.title,
    this.isTitleCentered = false,
    this.customTitleWidget,
    this.hasBackButton=false
  }) : super(key: key);

  @override
  Size get preferredSize =>
      Size.fromHeight(hasNavBar ? kToolbarHeight + 40 : kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppBar(
          backgroundColor: backgroundColor,
          elevation: 0,
          leading: hasBackButton
              ? IconButton(
                  icon: const Icon(Icons.arrow_back, color: AppColors.white),
                  onPressed: () => Navigator.pop(context),
                )
              : TextButton(
                  onPressed: onMenuTap ?? () => Scaffold.of(context).openDrawer(),
                  child: const Icon(Icons.menu, color: AppColors.white),
                ),

          title: customTitleWidget ?? (title != null ? Text(
            title!,
            style: const TextStyle(color: AppColors.white, fontSize: 20 , fontWeight: FontWeight.bold),
          ) : _buildLogo()),
          centerTitle: isTitleCentered,
          actions: _buildActions(context),
        ),
        if (hasNavBar) _buildNavBar(),
      ],
    );
  }

  Widget _buildLogo() {
    return Container(
      padding: const EdgeInsets.only(left: 0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TweenAnimationBuilder(
            tween: Tween<double>(begin: 0.8, end: 1.0),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeInOut,
            builder: (context, double value, child) {
              return Transform.scale(scale: value, child: child);
            },
            child: const Text(
              'WM',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: AppColors.white,
              ),
            ),
          ),
          TweenAnimationBuilder(
            tween: Tween<Offset>(begin: const Offset(10, 0), end: Offset.zero),
            duration: const Duration(milliseconds: 1000),
            curve: Curves.elasticOut,
            builder: (context, Offset offset, child) {
              return Transform.translate(offset: offset, child: child);
            },
            child: const Text(
              'HS',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: AppColors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildActions(BuildContext context) {
    final List<Widget> actions = [];

    if (isSearch) {
      actions.add(
        IconButton(
          icon: const Icon(Icons.search, color: AppColors.white),
          onPressed: () => Navigator.pushNamed(context, '/search')
        ),
      );
    }

    // if (isMenu) {
    //   actions.add(
    //     IconButton(
    //       icon: const Icon(Icons.menu, color: AppColors.white),
    //       onPressed: onMenuTap ?? () => Scaffold.of(context).openDrawer(),
    //     ),
    //   );
    // }

    actions.add(const SizedBox(width: 10));
    return actions;
  }

  Widget _buildNavBar() {
    return Container(
      height: 40,
      width: double.infinity,
      color: backgroundColor,
      child: ScrollConfiguration(
        
        behavior: _CustomScrollBehavior(),
        child: ListView.builder(
          
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          itemCount: navItems.length,
          itemBuilder: (context, index) {
            final bool isSelected = index == currentNavIndex;
            return InkWell(
              
              onTap: () => onNavTap?.call(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  border: isSelected
                      ? const Border(
                          bottom: BorderSide(color: AppColors.white, width: 2),
                        )
                      : null,
                ),
                child: Text(
                  navItems[index],
                  style: TextStyle(
                    fontSize: 14,
                    color: isSelected
                        ? AppColors.white
                        : AppColors.white.withOpacity(0.7),
                    fontWeight:
                        isSelected ? FontWeight.w500 : FontWeight.normal,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _CustomScrollBehavior extends ScrollBehavior {
  @override
  Widget buildOverscrollIndicator(
      BuildContext context, Widget child, ScrollableDetails details) {
    return child;
  }

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const BouncingScrollPhysics();
  }
}
