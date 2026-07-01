import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'app.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize notification service with tap handler
  await NotificationService().init(
    onTap: (payload) {
      // When user taps the daily streak notification, they'll land on the home
      // screen where they can start a quiz. The payload is 'open_quiz'.
    },
  );

  final prefs = await SharedPreferences.getInstance();

  final notificationsEnabled = prefs.getBool('notifications_enabled') ?? false;
  if (notificationsEnabled) {
    final alreadyScheduled = await NotificationService().isReminderScheduled();
    if (!alreadyScheduled) {
      await NotificationService().scheduleDailyStreakReminder();
    }
  }

  runApp(const MyApp());
}
