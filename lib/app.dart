import 'package:flutter/material.dart';
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
  static final ThemeData light = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF111C4A),
      primary: const Color(0xFF111C4A),
      error: const Color(0xFF931716),
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: const Color(0xFFF4F6FB),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: Color(0xFF121826),
      centerTitle: false,
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFF111C4A),
        foregroundColor: Colors.white,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: const Color(0xFF111C4A)),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF111C4A),
        side: const BorderSide(color: Color(0xFF111C4A)),
      ),
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 34,
        fontWeight: FontWeight.w800,
        color: Color(0xFF121826),
        height: 1.05,
      ),
      headlineMedium: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: Color(0xFF121826),
      ),
      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: Color(0xFF121826),
      ),
      bodyLarge: TextStyle(fontSize: 16, height: 1.5, color: Color(0xFF4B5565)),
    ),
  );
}
