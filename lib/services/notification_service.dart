import 'dart:math';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

/// Callback type for when a notification is tapped.
typedef NotificationTapCallback = void Function(String? payload);

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// Callback invoked when the user taps the daily streak notification.
  NotificationTapCallback? onNotificationTap;

  Future<void> init({NotificationTapCallback? onTap}) async {
    tz.initializeTimeZones();
    final info = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(info.identifier));

    onNotificationTap = onTap;

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    final InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse:
          (NotificationResponse response) async {
        onNotificationTap?.call(response.payload);
      },
    );
  }

  Future<void> scheduleDailyStreakReminder({bool forceTomorrow = false}) async {
    // Cancel any existing reminder before scheduling a new one
    await cancelStreakReminder();

    final random = Random();
    // Schedule randomly between 6 AM (hour 6) and 10 PM (hour 22)
    final hour = 6 + random.nextInt(17); // 6..22 inclusive
    final minute = random.nextInt(60);

    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (forceTomorrow || scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'streak_reminders',
          'Streak Reminders',
          channelDescription: 'Daily reminders to keep your streak alive',
          importance: Importance.high,
          priority: Priority.high,
        );
    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
    );

    await _notificationsPlugin.zonedSchedule(
      id: 0,
      title: 'Keep your streak alive! 🔥',
      body:
          "Don't forget to take a quick quiz today to keep your streak burning.",
      scheduledDate: scheduledDate,
      notificationDetails: platformDetails,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'open_quiz',
    );
  }

  Future<void> cancelStreakReminder() async {
    await _notificationsPlugin.cancel(id: 0);
  }
}
