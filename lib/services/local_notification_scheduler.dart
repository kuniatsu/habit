import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../models/habit.dart';
import 'notification_scheduler.dart';

/// flutter_local_notificationsによる実装。
class LocalNotificationScheduler implements NotificationScheduler {
  static const startActionId = 'start';
  static const snoozeActionId = 'snooze';
  static const _categoryId = 'habit_alert';

  final FlutterLocalNotificationsPlugin _plugin;
  final void Function(String habitId, HabitAction action)? onAction;

  LocalNotificationScheduler({
    FlutterLocalNotificationsPlugin? plugin,
    this.onAction,
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  @override
  Future<void> initialize() async {
    tz_data.initializeTimeZones();
    try {
      final localTimeZone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(localTimeZone.identifier));
    } catch (error) {
      tz.setLocalLocation(tz.getLocation('Asia/Tokyo'));
    }

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    final iosSettings = DarwinInitializationSettings(
      notificationCategories: [
        DarwinNotificationCategory(
          _categoryId,
          actions: [
            DarwinNotificationAction.plain(
              startActionId,
              '実施',
              options: {DarwinNotificationActionOption.foreground},
            ),
            DarwinNotificationAction.plain(snoozeActionId, '先送り'),
          ],
        ),
      ],
    );

    await _plugin.initialize(
      settings: InitializationSettings(android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: _handleResponse,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  void _handleResponse(NotificationResponse response) {
    final habitId = response.payload;
    if (habitId == null || habitId.isEmpty) {
      return;
    }
    final action = response.actionId == snoozeActionId
        ? HabitAction.snooze
        : HabitAction.start;
    onAction?.call(habitId, action);
  }

  @override
  Future<void> scheduleHabitAlert(Habit habit, DateTime fireAt) async {
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        'habit_alerts',
        'habitアラート',
        channelDescription: 'habitの実施時刻を知らせるアラート',
        importance: Importance.max,
        priority: Priority.high,
        actions: const [
          AndroidNotificationAction(startActionId, '実施',
              showsUserInterface: true),
          AndroidNotificationAction(snoozeActionId, '先送り'),
        ],
      ),
      iOS: const DarwinNotificationDetails(
        categoryIdentifier: _categoryId,
        interruptionLevel: InterruptionLevel.timeSensitive,
      ),
    );

    await _plugin.zonedSchedule(
      id: notificationId(habit.id),
      title: habit.title,
      body: habit.message,
      scheduledDate: tz.TZDateTime.from(fireAt, tz.local),
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: habit.id,
    );
  }

  @override
  Future<void> cancelHabitAlert(String habitId) async {
    await _plugin.cancel(id: notificationId(habitId));
  }

  /// habit IDから安定した通知IDを導出する(32bit範囲)。
  static int notificationId(String habitId) {
    var hash = 0;
    for (final code in habitId.codeUnits) {
      hash = (hash * 31 + code) & 0x7fffffff;
    }
    return hash;
  }
}
