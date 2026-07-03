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

/// Centralized theme configuration for the app.
class AppTheme {
  // Game-like accent colors
  static const Color primary = Color(0xFF111C4A);
  static const Color indigoAccent = Color(0xFF6366F1);
  static const Color gold = Color(0xFFFFD700);
  static const Color green = Color(0xFF4ADE80);
  static const Color amber = Color(0xFFF59E0B);
  static const Color red = Color(0xFFEF4444);
  static const Color darkBg = Color(0xFF0F172A);
  static const Color darkCard = Color(0xFF1E2246);
  static const Color darkBorder = Color(0xFF2D3361);
  static const Color darkText = Color(0xFF121826);
  static const Color lightText = Color(0xFF4B5565);

  static final ThemeData light = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      primary: primary,
      error: const Color(0xFF931716),
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: const Color(0xFFF4F6FB),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: darkText,
      centerTitle: false,
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: indigoAccent,
        foregroundColor: Colors.white,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: primary),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primary,
        side: const BorderSide(color: primary),
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
