import 'package:flutter/material.dart';

import 'app.dart';
import 'data/habit_log_repository.dart';
import 'data/habit_repository.dart';
import 'services/app_catalog.dart';
import 'services/local_notification_scheduler.dart';
import 'services/notification_scheduler.dart';
import 'state/habit_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  late final HabitStore store;
  final scheduler = LocalNotificationScheduler(
    onAction: (habitId, action) {
      switch (action) {
        case HabitAction.start:
          store.startHabit(habitId);
        case HabitAction.snooze:
          store.snoozeHabit(habitId);
      }
    },
  );
  store = HabitStore(
    habitRepository: SharedPrefsHabitRepository(),
    logRepository: SharedPrefsHabitLogRepository(),
    scheduler: scheduler,
  );

  await scheduler.initialize();
  await store.load();

  runApp(HabitApp(store: store, appCatalog: const DeviceAppCatalog()));
}
