import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqlite_crud_app/Views/home/screens/home.dart';
import 'package:sqlite_crud_app/Views/profile/screens/profile.dart';
import 'package:sqlite_crud_app/constants/app_colors.dart';
import 'package:sqlite_crud_app/Views/attendance/screens/attendance_scan_screen.dart';
import 'package:sqlite_crud_app/Views/recent/recent_records_screen.dart';

class NavigationMenu extends StatelessWidget {
  const NavigationMenu({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final navigationController = Provider.of<NavigationController>(context);

    return Scaffold(
      body: navigationController.screens[navigationController.selectedIndex],
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          backgroundColor: AppColors.primary,

          indicatorColor: AppColors.white.withOpacity(0.2),
          labelTextStyle: MaterialStateProperty.resolveWith<TextStyle>((
            Set<MaterialState> states,
          ) {
            if (states.contains(MaterialState.selected)) {
              return const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.white,
              );
            }
            return const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            );
          }),
          iconTheme: MaterialStateProperty.resolveWith<IconThemeData>((
            Set<MaterialState> states,
          ) {
            if (states.contains(MaterialState.selected)) {
              return const IconThemeData(color: AppColors.white, size: 28);
            }
            return const IconThemeData(color: Colors.white54, size: 24);
          }),
        ),
        child: NavigationBar(
          selectedIndex: navigationController.selectedIndex,
          onDestinationSelected: (int index) {
            navigationController.setSelectedIndex(index);
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard),
              label: 'Activities',
            ),
            NavigationDestination(icon: Icon(Icons.history), label: 'Recent'),
            NavigationDestination(icon: Icon(Icons.cloud), label: 'Async'),
            NavigationDestination(icon: Icon(Icons.person_2), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}

class NavigationController extends ChangeNotifier {
  int _selectedIndex = 0;

  int get selectedIndex => _selectedIndex;

  void setSelectedIndex(int index) {
    if (_selectedIndex != index) {
      _selectedIndex = index;
      notifyListeners();
    }
  }

  final List<Widget> screens = [
    HomeScreen(),
    RecentRecordsScreen(),
    AttendanceScanScreen(),
    ProfileScreen(),
  ];
}
