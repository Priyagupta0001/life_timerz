import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) {
  print('🔔 Notification tapped in background: ${response.payload}');
}

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// Initialize notification plugin and request permission
  static Future<void> initialize() async {
    tz_data.initializeTimeZones();

    const AndroidInitializationSettings androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosInit = DarwinInitializationSettings();
    final InitializationSettings initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        print("📩 Notification tapped: ${response.payload}");
      },
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    final status = await Permission.notification.status;
    if (!status.isGranted) {
      await Permission.notification.request();
    }
  }

  /// Show instant notification (skip if task completed)
  static Future<void> showNotification({
    required String title,
    required String body,
    bool isTaskCompleted = false,
  }) async {
    if (isTaskCompleted) return;

    final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'instant_channel',
          'Instant Notification',
          channelDescription: 'Notifications shown immediately',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
        );
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();

    await _notificationsPlugin.show(
      id,
      title,
      body,
      NotificationDetails(android: androidDetails, iOS: iosDetails),
    );

    await _saveNotification(title, body, id);
  }

  /// Schedule notification for specific DateTime
  static Future<int?> scheduleNotification({
    required String title,
    required String body,
    required DateTime scheduledTime,
    bool isTaskCompleted = false,
    required dynamic taskId,
  }) async {
    if (isTaskCompleted) return null;

    final id = taskId.hashCode;

    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'scheduled_channel',
          'Scheduled Notifications',
          channelDescription: 'Task reminder notifications',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );

    await _saveNotification(title, body, id);
    return id;
  }

  /// Schedule 1-hour-before reminder
  static Future<int?> scheduleBeforeTask({
    required String title,
    required String body,
    required DateTime taskTime,
    bool isTaskCompleted = false,
    required dynamic taskId,
  }) async {
    if (isTaskCompleted) return null;

    final notifyTime = taskTime.subtract(const Duration(hours: 1));
    if (notifyTime.isAfter(DateTime.now())) {
      return scheduleNotification(
        title: title,
        body: body,
        scheduledTime: notifyTime,
        taskId: taskId,
      );
    }
    return null;
  }

  /// Schedule daily reminder
  static Future<void> scheduleDailyReminder({
    required String title,
    required String body,
    required int hour,
    required int minute,
    int? notificationId,
  }) async {
    final id = notificationId ?? DateTime.now().millisecondsSinceEpoch ~/ 1000;
    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      _nextInstanceOfTime(hour, minute),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_channel',
          'Daily Reminders',
          channelDescription: 'Daily task reminders',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
    await _saveNotification(title, body, id);
  }

  static tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  /// Cancel notification by ID
  static Future<void> cancelNotificationById(int id) async {
    await _notificationsPlugin.cancel(id);
  }

  /// Cancel all notifications
  static Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }

  /// Save notification locally (skip duplicates within 1 hour)
  static Future<void> _saveNotification(
    String title,
    String body,
    int id,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final key = "notifications_${user.uid}";
    final now = DateTime.now();

    final existing = prefs.getStringList(key) ?? [];
    print("💾 Saving notification: $title - $body - id=$id");

    // Remove old notifications >2 days
    final fresh = existing.where((e) {
      final data = jsonDecode(e);
      final time = DateTime.parse(data['time']);
      return now.difference(time).inDays < 1;
    }).toList();

    // Skip duplicate within 1 hour
    final isDuplicate = fresh.any((e) {
      final data = jsonDecode(e);
      final time = DateTime.parse(data['time']);
      return data['title'] == title &&
          data['body'] == body &&
          now.difference(time).inMinutes < 60;
    });

    if (isDuplicate) return;

    fresh.insert(
      0,
      jsonEncode({
        "id": id,
        "title": title,
        "body": body,
        "time": now.toIso8601String(),
      }),
    );
    await prefs.setStringList(key, fresh);
  }

  /// Fetch saved notifications
  static Future<List<Map<String, dynamic>>> getAllNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    final stored = prefs.getStringList("notifications_${user.uid}") ?? [];
    print("📬 Loaded notifications: ${stored.length}");

    return stored.map((e) => jsonDecode(e) as Map<String, dynamic>).toList();
  }

  /// Clear all saved notifications
  static Future<void> clearNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await prefs.remove("notifications_${user.uid}");
    }
  }

  /// Remove old notifications >2 days
  static Future<void> cleanOldNotifications({int days = 2}) async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList('notifications') ?? [];
    final filtered = stored.where((e) {
      final data = jsonDecode(e);
      final time = DateTime.parse(data['time']);
      return DateTime.now().difference(time).inDays < days;
    }).toList();
    await prefs.setStringList('notifications', filtered);
  }

  static void initializeNotification() {}

  static Future<void> initializeLocalNotification() async {}
}
