import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sqlite_crud_app/Views/auth/screens/auth.dart';
import 'package:sqlite_crud_app/Views/auth/screens/login.dart';
import 'package:sqlite_crud_app/Views/profile/screens/profile.dart';
import 'package:sqlite_crud_app/Views/auth/screens/signup.dart';
import 'package:sqlite_crud_app/constants/app_colors.dart';
import 'package:sqlite_crud_app/navigation_menu.dart';
import 'package:sqlite_crud_app/utils/user_session.dart';
import 'package:sqlite_crud_app/permission_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();


  if (!kIsWeb) {
    await requestAllPermissions();
  }

  // System UI overlay settings.
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserSession()),
        ChangeNotifierProvider(create: (_) => NavigationController()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const AuthScreen(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/profile': (context) => ProfileScreen(),
        '/home': (context) => const NavigationMenu(),
      },
      title: 'XTAP',
      theme: ThemeData(
        primarySwatch: MaterialColor(0xFF0D7E0D, {
          50: Color(0xFFE8F5E8),
          100: Color(0xFFC5E6C5),
          200: Color(0xFF9ED59E),
          300: Color(0xFF77C477),
          400: Color(0xFF5AB75A),
          500: Color(0xFF0D7E0D),
          600: Color(0xFF0B720B),
          700: Color(0xFF096509),
          800: Color(0xFF075807),
          900: Color(0xFF054205),
        }),
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: AppColors.scaffoldBackground,
        cardColor: AppColors.cardBackground,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
    );
  }
}
