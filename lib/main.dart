import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'app.dart';
import 'services/database_service.dart';
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

  // Ensure last_active_date is initialized on first run
  if (!prefs.containsKey('last_active_date')) {
    await prefs.setString('last_active_date', '');
  }

  final notificationsEnabled = prefs.getBool('notifications_enabled') ?? false;
  if (notificationsEnabled) {
    final alreadyScheduled = await NotificationService().isReminderScheduled();
    if (!alreadyScheduled) {
      final todayStr = DateTime.now().toIso8601String().split('T')[0];
      final lastActiveDate = prefs.getString('last_active_date') ?? '';
      final forceTomorrow = lastActiveDate == todayStr;
      await NotificationService().scheduleDailyStreakReminder(
        forceTomorrow: forceTomorrow,
      );
    }
  }

  final currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser != null) {
    try {
      debugPrint(
        '[StreakSync] startup reconciliation for uid=${currentUser.uid}',
      );
      await DatabaseService().syncLocalStreakCacheToFirestore(currentUser.uid);
    } catch (_) {
      // Ignore reconciliation failures; quiz flow will retry on next sync
    }
  }

  runApp(const MyApp());
}
