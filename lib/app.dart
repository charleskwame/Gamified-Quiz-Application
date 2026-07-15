import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'widgets/auth_gate.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Gamified Quiz',
      theme: AppTheme.light,
      home: const AuthGate(),
    );
  }
}

/// Centralized color palette for the application — duolingo-inspired playful colors.
class AppColors {
  // Core palette
  static const Color background = Color(0xFFFBFBFB); // Pure White (off-white)
  static const Color surface = Color(0xFFFFFFFF); // Card surfaces
  static const Color primary = Color(0xFF58CC02); // Feather Green
  static const Color primaryDark = Color(
    0xFF50A700,
  ); // Darker green for 3D button borders
  static const Color secondary = Color(0xFF1CB0F6); // Sky Blue
  static const Color secondaryDark = Color(
    0xFF1590D0,
  ); // Darker blue for 3D button borders
  static const Color accent = Color(0xFFFFC800); // Golden Crown
  static const Color accentDark = Color(
    0xFFD4A800,
  ); // Darker gold for 3D button borders
  static const Color premium = Color(0xFF003F91); // Premium Blue
  static const Color premiumDark = Color(
    0xFF002F6E,
  ); // Darker premium for 3D button borders
  static const Color sale = Color(0xFFFF9600); // Sunset Orange
  static const Color saleDark = Color(
    0xFFD47D00,
  ); // Darker orange for 3D button borders
  static const Color error = Color(0xFFFF4B4B); // Bubblegum Red
  static const Color errorDark = Color(
    0xFFD43D3D,
  ); // Darker red for 3D button borders
  static const Color textPrimary = Color(0xFF4B4B4B); // Ink Gray
  static const Color textSecondary = Color(0xFF777777); // Lighter text
  static const Color textMuted = Color(0xFFAFAFAF); // Muted text (disabled)
  static const Color border = Color(0xFFE5E5E5); // Cloud Gray
  static const Color disabled = Color(
    0xFFE5E5E5,
  ); // Cloud Gray for disabled states
  static const Color disabledText = Color(0xFFAFAFAF); // Disabled text
  static const Color divider = Color(0xFFE5E5E5); // Dividers

  // Progress bar stripe colors
  static const Color progressStripe = Color(
    0x40FFFFFF,
  ); // Semi-transparent white for stripes
}

/// Centralized theme configuration for the app — light, playful, duolingo-inspired.
class AppTheme {
  static final ThemeData light = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      error: AppColors.error,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: AppColors.background,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: AppColors.textPrimary,
      centerTitle: false,
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        disabledBackgroundColor: AppColors.disabled,
        disabledForegroundColor: AppColors.disabledText,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: AppColors.textPrimary),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textPrimary,
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 34,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
        height: 1.05,
      ),
      headlineMedium: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        height: 1.5,
        color: AppColors.textSecondary,
      ),
    ),
  );
}
