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

/// Centralized theme configuration for the app — monochrome (black, white, grey).
class AppTheme {
  // Grey-scale colors
  static const Color background = Color(0xFF121212);
  static const Color surface = Color(0xFF1A1A1A);
  static const Color card = Color(0xFF242424);
  static const Color cardBorder = Color(0xFF333333);
  static const Color elevated = Color(0xFF2E2E2E);
  static const Color darkText = Color(0xFFFFFFFF);
  static const Color lightText = Color(0xFFB0B0B0);
  static const Color mutedText = Color(0xFF707070);
  static const Color accentGrey = Color(0xFF808080);
  static const Color highlightGrey = Color(0xFF3A3A3A);
  static const Color disabledGrey = Color(0xFF505050);

  static const Color correctGrey = Color(0xFF4A4A4A);
  static const Color errorGrey = Color(0xFF5A3A3A);

  static final ThemeData light = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF333333),
      primary: const Color(0xFF808080),
      error: const Color(0xFF5A3A3A),
      brightness: Brightness.dark,
    ),
    scaffoldBackgroundColor: surface,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: darkText,
      centerTitle: false,
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: accentGrey,
        foregroundColor: Colors.white,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: darkText),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: darkText,
        side: const BorderSide(color: cardBorder),
      ),
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 34,
        fontWeight: FontWeight.w800,
        color: darkText,
        height: 1.05,
      ),
      headlineMedium: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: darkText,
      ),
      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: darkText,
      ),
      bodyLarge: TextStyle(fontSize: 16, height: 1.5, color: lightText),
    ),
  );
}
