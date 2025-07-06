import 'package:flutter/material.dart';

/// App Colors - Clean, Professional Design with Dark Mode Support
/// Uses only 2-3 main colors for consistency and elegance
class AppColors {
  // Primary Colors (Blue Theme)
  static const Color primary = Color(0xFF2196F3); // Main blue
  static const Color primaryLight = Color(0xFF64B5F6); // Light blue
  static const Color primaryDark = Color(0xFF1976D2); // Dark blue

  // Secondary Colors (Gray Scale)
  static const Color secondary = Color(0xFF424242); // Dark gray
  static const Color secondaryLight = Color(0xFF757575); // Medium gray
  static const Color secondaryLighter = Color(0xFFBDBDBD); // Light gray

  // Status Colors
  static const Color success = Color(0xFF4CAF50); // Green
  static const Color warning = Color(0xFFFF9800); // Orange
  static const Color error = Color(0xFFF44336); // Red
  static const Color info = Color(0xFF2196F3); // Blue

  // Background Colors
  static const Color background = Color(0xFFFAFAFA); // Light background
  static const Color surface = Color(0xFFFFFFFF); // Surface color
  static const Color cardBackground = Color(0xFFFFFFFF); // Card background

  // Dark Mode Colors
  static const Color backgroundDark = Color(0xFF121212); // Dark background
  static const Color surfaceDark = Color(0xFF1E1E1E); // Dark surface
  static const Color cardBackgroundDark = Color(0xFF2D2D2D); // Dark card

  // Text Colors
  static const Color textPrimary = Color(0xFF212121); // Primary text
  static const Color textSecondary = Color(0xFF757575); // Secondary text
  static const Color textLight = Color(0xFFBDBDBD); // Light text
  static const Color textDisabled = Color(0xFF9E9E9E); // Disabled text

  // Dark Mode Text Colors
  static const Color textPrimaryDark = Color(0xFFFFFFFF); // Dark primary text
  static const Color textSecondaryDark = Color(
    0xFFB3B3B3,
  ); // Dark secondary text
  static const Color textLightDark = Color(0xFF757575); // Dark light text

  // Border Colors
  static const Color border = Color(0xFFE0E0E0); // Light border
  static const Color borderDark = Color(0xFF424242); // Dark border

  // Input Colors
  static const Color inputBackground = Color(0xFFF5F5F5); // Input background
  static const Color inputBackgroundDark = Color(
    0xFF2D2D2D,
  ); // Dark input background
  static const Color inputBorder = Color(0xFFE0E0E0); // Input border
  static const Color inputBorderDark = Color(0xFF424242); // Dark input border

  // Attendance Status Colors
  static const Color present = Color(0xFF4CAF50); // Present - Green
  static const Color absent = Color(0xFFF44336); // Absent - Red
  static const Color late = Color(0xFFFF9800); // Late - Orange
  static const Color excused = Color(0xFF9C27B0); // Excused - Purple

  // Utility Colors
  static const Color divider = Color(0xFFE0E0E0); // Divider
  static const Color dividerDark = Color(0xFF424242); // Dark divider
  static const Color shadow = Color(0x1A000000); // Shadow color
  static const Color overlay = Color(0x80000000); // Overlay color

  // White and Black
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color transparent = Colors.transparent;

  // Legacy color names for backward compatibility
  static const Color primary500 = primary;
  static const Color scaffoldBackground = background;
  static const Color cardColor = cardBackground;
  static const Color neutral300 = secondaryLighter;
  static const Color textDark = textPrimary;
  static const Color textInputBackground = inputBackground;

  // Dark mode legacy names
  static const Color scaffoldBackgroundDark = backgroundDark;
  static const Color cardColorDark = cardBackgroundDark;
  static const Color darkDivider = dividerDark;
  static const Color darkSurface = surfaceDark;
  static const Color textDarkDark = textPrimaryDark;

  // Additional legacy colors
  static const Color primary600 = primaryDark;
  static const Color secondary500 = secondary;
  static const Color tertiary500 = warning;
  static const Color darkPrimary = primaryLight;
  static const Color darkSecondary = secondaryLight;
  static const Color darkTertiary = warning;
  static const Color darkBackground = backgroundDark;
  static const Color errorDark = error;
  static const Color scaffoldWithBoxBackground = background;

  /// Get background color based on theme
  static Color getBackgroundColor(bool isDarkMode) {
    return isDarkMode ? backgroundDark : background;
  }

  /// Get surface color based on theme
  static Color getSurfaceColor(bool isDarkMode) {
    return isDarkMode ? surfaceDark : surface;
  }

  /// Get card background color based on theme
  static Color getCardBackgroundColor(bool isDarkMode) {
    return isDarkMode ? cardBackgroundDark : cardBackground;
  }

  /// Get primary text color based on theme
  static Color getPrimaryTextColor(bool isDarkMode) {
    return isDarkMode ? textPrimaryDark : textPrimary;
  }

  /// Get secondary text color based on theme
  static Color getSecondaryTextColor(bool isDarkMode) {
    return isDarkMode ? textSecondaryDark : textSecondary;
  }

  /// Get border color based on theme
  static Color getBorderColor(bool isDarkMode) {
    return isDarkMode ? borderDark : border;
  }

  /// Get input background color based on theme
  static Color getInputBackgroundColor(bool isDarkMode) {
    return isDarkMode ? inputBackgroundDark : inputBackground;
  }

  /// Get input border color based on theme
  static Color getInputBorderColor(bool isDarkMode) {
    return isDarkMode ? inputBorderDark : inputBorder;
  }

  /// Get divider color based on theme
  static Color getDividerColor(bool isDarkMode) {
    return isDarkMode ? dividerDark : divider;
  }

  /// Get attendance status color
  static Color getAttendanceStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'present':
        return present;
      case 'absent':
        return absent;
      case 'late':
        return late;
      case 'excused':
        return excused;
      default:
        return secondary;
    }
  }

  /// Get status color for different states
  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'success':
      case 'completed':
        return success;
      case 'warning':
      case 'pending':
        return warning;
      case 'error':
      case 'failed':
        return error;
      case 'info':
      case 'processing':
        return info;
      default:
        return secondary;
    }
  }
}

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primarySwatch: MaterialColor(0xFF0D7E0D, {
      50: Color(0xFFE8F2FF),
      100: Color(0xFFC5DDFF),
      200: Color(0xFF9EC7FF),
      300: Color(0xFF77B1FF),
      400: Color(0xFF5AA0FF),
      500: Color(0xFF0D7EFF),
      600: Color(0xFF0B72E6),
      700: Color(0xFF0965CC),
      800: Color(0xFF0758B3),
      900: Color(0xFF054299),
    }),
    primaryColor: AppColors.primary500,
    scaffoldBackgroundColor: AppColors.scaffoldBackground,
    cardColor: AppColors.cardColor,
    dividerColor: AppColors.neutral300,
    shadowColor: Color(0x1A000000),

    // Text Theme
    textTheme: const TextTheme(
      displayLarge: TextStyle(color: AppColors.textDark),
      displayMedium: TextStyle(color: AppColors.textDark),
      displaySmall: TextStyle(color: AppColors.textDark),
      headlineLarge: TextStyle(color: AppColors.textDark),
      headlineMedium: TextStyle(color: AppColors.textDark),
      headlineSmall: TextStyle(color: AppColors.textDark),
      titleLarge: TextStyle(color: AppColors.textDark),
      titleMedium: TextStyle(color: AppColors.textDark),
      titleSmall: TextStyle(color: AppColors.textDark),
      bodyLarge: TextStyle(color: AppColors.textDark),
      bodyMedium: TextStyle(color: AppColors.textDark),
      bodySmall: TextStyle(color: AppColors.textLight),
      labelLarge: TextStyle(color: AppColors.textDark),
      labelMedium: TextStyle(color: AppColors.textDark),
      labelSmall: TextStyle(color: AppColors.textLight),
    ),

    // App Bar Theme
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.primary500,
      foregroundColor: AppColors.white,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: AppColors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),

    // Card Theme
    cardTheme: CardTheme(
      color: AppColors.cardColor,
      elevation: 2,
      shadowColor: Color(0x1A000000),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),

    // Input Decoration Theme
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.neutral300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.neutral300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.primary500, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.error),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),

    // Elevated Button Theme
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary500,
        foregroundColor: AppColors.white,
        elevation: 2,
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),

    // Floating Action Button Theme
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.primary500,
      foregroundColor: AppColors.white,
      elevation: 4,
    ),

    // Bottom Navigation Bar Theme
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.primary500,
      selectedItemColor: AppColors.white,
      unselectedItemColor: AppColors.white,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),

    visualDensity: VisualDensity.adaptivePlatformDensity,
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primarySwatch: MaterialColor(0xFF0D7E0D, {
      50: Color(0xFFE8F2FF),
      100: Color(0xFFC5DDFF),
      200: Color(0xFF9EC7FF),
      300: Color(0xFF77B1FF),
      400: Color(0xFF5AA0FF),
      500: Color(0xFF0D7EFF),
      600: Color(0xFF0B72E6),
      700: Color(0xFF0965CC),
      800: Color(0xFF0758B3),
      900: Color(0xFF054299),
    }),
    primaryColor: AppColors.primary500,
    scaffoldBackgroundColor: AppColors.scaffoldBackgroundDark,
    cardColor: AppColors.cardColorDark,
    dividerColor: AppColors.darkDivider,
    shadowColor: Color(0x40000000),

    // Text Theme
    textTheme: const TextTheme(
      displayLarge: TextStyle(color: AppColors.textDarkDark),
      displayMedium: TextStyle(color: AppColors.textDarkDark),
      displaySmall: TextStyle(color: AppColors.textDarkDark),
      headlineLarge: TextStyle(color: AppColors.textDarkDark),
      headlineMedium: TextStyle(color: AppColors.textDarkDark),
      headlineSmall: TextStyle(color: AppColors.textDarkDark),
      titleLarge: TextStyle(color: AppColors.textDarkDark),
      titleMedium: TextStyle(color: AppColors.textDarkDark),
      titleSmall: TextStyle(color: AppColors.textDarkDark),
      bodyLarge: TextStyle(color: AppColors.textDarkDark),
      bodyMedium: TextStyle(color: AppColors.textDarkDark),
      bodySmall: TextStyle(color: AppColors.textLightDark),
      labelLarge: TextStyle(color: AppColors.textDarkDark),
      labelMedium: TextStyle(color: AppColors.textDarkDark),
      labelSmall: TextStyle(color: AppColors.textLightDark),
    ),

    // App Bar Theme
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.cardColorDark,
      foregroundColor: AppColors.textDarkDark,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: AppColors.textDarkDark,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),

    // Card Theme
    cardTheme: CardTheme(
      color: AppColors.cardColorDark,
      elevation: 2,
      shadowColor: Color(0x40000000),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),

    // Input Decoration Theme
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.darkSurface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.darkDivider),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.darkDivider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.primary500, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.error),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),

    // Elevated Button Theme
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary500,
        foregroundColor: AppColors.white,
        elevation: 2,
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),

    // Floating Action Button Theme
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.primary500,
      foregroundColor: AppColors.white,
      elevation: 4,
    ),

    // Bottom Navigation Bar Theme
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.cardColorDark,
      selectedItemColor: AppColors.primary500,
      unselectedItemColor: AppColors.textLightDark,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),

    visualDensity: VisualDensity.adaptivePlatformDensity,
  );
}
