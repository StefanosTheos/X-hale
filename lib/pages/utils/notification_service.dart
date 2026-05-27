import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:smoking/constants/affirmations.dart';
import 'package:smoking/extensions/datetime.dart';
import 'package:timezone/data/latest_all.dart';
import 'package:timezone/timezone.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Handling background message: ${message.messageId}');
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  late final FlutterLocalNotificationsPlugin _localNotifications;
  late final FirebaseMessaging _firebaseMessaging;

  NotificationService._internal() {
    _localNotifications = FlutterLocalNotificationsPlugin();
    _firebaseMessaging = FirebaseMessaging.instance;
    // initializeNotifications() is awaited explicitly from main.dart; avoid
    // firing a duplicate fire-and-forget init here.
  }

  Future<void> initializeNotifications() async {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Init timezones using the device's actual zone so daily reminders fire at
    // the user's local time, not Athens time.
    initializeTimeZones();
    try {
      final localTz = await FlutterTimezone.getLocalTimezone();
      setLocalLocation(getLocation(localTz));
    } catch (e) {
      debugPrint('Failed to read device timezone, falling back to UTC: $e');
      setLocalLocation(getLocation('UTC'));
    }

    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Initialize local notifications
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    await _localNotifications.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: _handleNotificationTap,
    );

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(
      _handleNotificationTapBackground,
    );
  }

  void _handleNotificationTap(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
  }

  void _handleNotificationTapBackground(RemoteMessage message) {
    debugPrint('Background notification tapped: ${message.messageId}');
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('Received foreground message: ${message.messageId}');

    await _showLocalNotification(
      title: message.notification?.title ?? 'New Message',
      body: message.notification?.body ?? '',
      payload: message.data.toString(),
    );
  }

  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'default_channel',
      'Default Channel',
      importance: Importance.max,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    await _localNotifications.show(
      // Notification ID must be a positive 32-bit int. `DateTime.now()
      // .millisecond` is 0..999 — two notifications fired in the same second
      // overwrite each other in the tray. Use epoch ms truncated to fit.
      DateTime.now().millisecondsSinceEpoch.remainder(1 << 31),
      title,
      body,
      const NotificationDetails(android: androidDetails, iOS: iosDetails),
      payload: payload,
    );
  }

  Future<String?> getFCMToken() async {
    return await _firebaseMessaging.getToken();
  }

  Future<void> scheduleDailyAffirmation() async {
    final now = TZDateTime.now(local);

    var scheduledTime = TZDateTime(
      local,
      now.year,
      now.month,
      now.day,
      12, // hour
      0, // minutes
    );

    if (scheduledTime.isBefore(now)) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
    }

    final dayOfYear = DateTime.now().toLocal().dayOfYear;
    final index = dayOfYear % dailyAffirmations.length;
    final affirmation = '"${dailyAffirmations[index]}"';

    debugPrint(
      '📅 Scheduling daily affirmation '
      'with id=1001 at $scheduledTime: $affirmation',
    );

    await _localNotifications.zonedSchedule(
      1001,
      'Daily Affirmation',
      affirmation,
      scheduledTime,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_affirmation_channel',
          'Daily Affirmations',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );

    final pending = await _localNotifications.pendingNotificationRequests();
    debugPrint('📌 Pending notifications: $pending');
  }

  /// Schedule the 21:00 diary reminder. Pass [wroteToday] to skip tonight's
  /// ping when the user has already written — the schedule is pushed to
  /// tomorrow so the daily-repeat chain (`matchDateTimeComponents: time`)
  /// stays alive.
  Future<void> scheduleDiaryReminder({required bool wroteToday}) async {
    final now = TZDateTime.now(local);

    var scheduledTime = TZDateTime(local, now.year, now.month, now.day, 21, 0);

    if (scheduledTime.isBefore(now)) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
    }

    // Push to tomorrow when the user already wrote today AND the next
    // pending slot is still today — avoids a redundant 21:00 ping for an
    // already-completed entry, without breaking the daily chain.
    if (wroteToday &&
        scheduledTime.year == now.year &&
        scheduledTime.month == now.month &&
        scheduledTime.day == now.day) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
      debugPrint(
        'Diary entry already exists for today; reminder pushed to '
        '$scheduledTime',
      );
    }

    await _localNotifications.zonedSchedule(
      1002,
      'Diary Reminder',
      'Don’t forget to write your diary entry for today!',
      scheduledTime,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'diary_reminder_channel',
          'Diary Reminders',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );

    debugPrint("📌 Diary reminder scheduled at $scheduledTime");
  }

  /// Cancels today's diary reminder (id 1002). Call this after a diary entry is
  /// saved so the user doesn't get a "don't forget" ping for a thing they just
  /// did.
  Future<void> cancelDiaryReminder() async {
    await _localNotifications.cancel(1002);
    debugPrint("📌 Diary reminder cancelled (id 1002)");
  }
}

