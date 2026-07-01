import 'dart:math';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io' show Platform;

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

    // Request notification permission on Android 13+
    if (Platform.isAndroid) {
      await Permission.notification.request();
    }

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
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        onNotificationTap?.call(response.payload);
      },
    );
  }

  /// Checks whether a daily streak reminder (notification ID 0) is already
  /// pending in the system. This avoids unnecessary cancel/reschedule cycles.
  Future<bool> isReminderScheduled() async {
    final pending = await _notificationsPlugin.pendingNotificationRequests();
    return pending.any((req) => req.id == 0);
  }

  /// Schedules the daily streak reminder notification.
  ///
  /// If [forceTomorrow] is true, the notification is always scheduled for
  /// the next day. Otherwise, it is scheduled for today at a random time
  /// between 6 AM and 10 PM. If that time has already passed today, it
  /// automatically falls through to tomorrow.
  ///
  /// The notification uses [matchDateTimeComponents: DateTimeComponents.time]
  /// so it repeats daily at the same time once scheduled, unless
  /// [cancelStreakReminder] or [rescheduleForTomorrow] is called later.
  Future<void> scheduleDailyStreakReminder({bool forceTomorrow = false}) async {
    final random = Random();
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

  /// Cancels the existing reminder and schedules a new one for **tomorrow**
  /// at a random time. Call this after the user completes a quiz today so
  /// they don't get a duplicate reminder for the same day.
  Future<void> rescheduleForTomorrow() async {
    await _notificationsPlugin.cancel(id: 0);
    // Schedule for tomorrow — forceTomorrow is implied by cancel + schedule
    await scheduleDailyStreakReminder(forceTomorrow: true);
  }

  Future<void> cancelStreakReminder() async {
    await _notificationsPlugin.cancel(id: 0);
  }

  /// Immediately shows the streak reminder as a system notification.
  /// This is intended for debugging purposes to verify that local
  /// notifications are working correctly on the device.
  Future<void> showImmediateStreakNotification() async {
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

    await _notificationsPlugin.show(
      id: 0,
      title: 'Keep your streak alive! 🔥',
      body:
          "Don't forget to take a quick quiz today to keep your streak burning.",
      notificationDetails: platformDetails,
      payload: 'open_quiz',
    );
  }
}
