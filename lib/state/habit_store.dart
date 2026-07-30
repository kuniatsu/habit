import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../data/habit_log_repository.dart';
import '../data/habit_repository.dart';
import '../logic/schedule_calculator.dart';
import '../logic/snooze_policy.dart';
import '../models/frequency.dart';
import '../models/habit.dart';
import '../models/habit_log.dart';
import '../services/deep_link_service.dart';
import '../services/notification_scheduler.dart';

/// TOPに表示する「次のhabit」。
class UpcomingHabit {
  final Habit habit;
  final DateTime fireAt;

  const UpcomingHabit({required this.habit, required this.fireAt});
}

/// アプリ全体の状態と操作をまとめたストア。
class HabitStore extends ChangeNotifier {
  final HabitRepository _habitRepository;
  final HabitLogRepository _logRepository;
  final NotificationScheduler _scheduler;
  final DeepLinkService _deepLinkService;
  final ScheduleCalculator _calculator;
  final SnoozePolicy _snoozePolicy;
  final DateTime Function() _now;
  final String Function() _newId;

  List<Habit> _habits = [];
  List<HabitLog> _logs = [];

  HabitStore({
    required HabitRepository habitRepository,
    required HabitLogRepository logRepository,
    required NotificationScheduler scheduler,
    DeepLinkService deepLinkService = const DeepLinkService(),
    ScheduleCalculator calculator = const ScheduleCalculator(),
    SnoozePolicy snoozePolicy = const SnoozePolicy(),
    DateTime Function()? now,
    String Function()? newId,
  })  : _habitRepository = habitRepository,
        _logRepository = logRepository,
        _scheduler = scheduler,
        _deepLinkService = deepLinkService,
        _calculator = calculator,
        _snoozePolicy = snoozePolicy,
        _now = now ?? DateTime.now,
        _newId = newId ?? const Uuid().v4;

  List<Habit> get habits => List.unmodifiable(_habits);
  List<HabitLog> get logs => List.unmodifiable(_logs);

  /// 次に来るhabit。登録がなければnull。
  UpcomingHabit? get nextHabit {
    if (_habits.isEmpty) {
      return null;
    }
    final now = _now();
    final upcoming = _habits
        .map((h) =>
            UpcomingHabit(habit: h, fireAt: _calculator.nextOccurrence(h, now)))
        .toList()
      ..sort((a, b) => a.fireAt.compareTo(b.fireAt));
    return upcoming.first;
  }

  DateTime nextOccurrenceOf(Habit habit) {
    return _calculator.nextOccurrence(habit, _now());
  }

  Future<void> load() async {
    _habits = await _habitRepository.findAll();
    _logs = await _logRepository.findAll();
    notifyListeners();
  }

  Future<void> addHabit({
    required String title,
    required String message,
    required Frequency frequency,
    required int minute,
    required int hour,
    required int weekday,
    required int dayOfMonth,
    String? deepLinkUrl,
  }) async {
    final habit = Habit(
      id: _newId(),
      title: title,
      message: message,
      frequency: frequency,
      minute: minute,
      hour: hour,
      weekday: weekday,
      dayOfMonth: dayOfMonth,
      deepLinkUrl: (deepLinkUrl == null || deepLinkUrl.trim().isEmpty)
          ? null
          : deepLinkUrl.trim(),
      createdAt: _now(),
    );
    await _habitRepository.save(habit);
    await _scheduler.scheduleHabitAlert(
        habit, _calculator.nextOccurrence(habit, _now()));
    await load();
  }

  Future<void> deleteHabit(String habitId) async {
    await _habitRepository.delete(habitId);
    await _scheduler.cancelHabitAlert(habitId);
    await load();
  }

  /// 実施開始。履歴に記録し、次の定時アラートを予約し、
  /// ディープリンクがあれば遷移する。
  Future<void> startHabit(String habitId) async {
    final habit = _findHabit(habitId);
    if (habit == null) {
      return;
    }
    final now = _now();
    await _logRepository.add(HabitLog(
      id: _newId(),
      habitId: habit.id,
      habitTitle: habit.title,
      recordedAt: now,
      result: HabitResult.done,
    ));
    await _scheduler.scheduleHabitAlert(
        habit, _calculator.nextOccurrence(habit, now));
    final url = habit.deepLinkUrl;
    if (url != null) {
      await _deepLinkService.open(url);
    }
    await load();
  }

  /// 先送り。再アラートを予約するが、次の実施時間を超える場合は
  /// 逃げ切りとして記録し、次の定時にまた追われる。
  Future<void> snoozeHabit(String habitId) async {
    final habit = _findHabit(habitId);
    if (habit == null) {
      return;
    }
    final result = _snoozePolicy.resolveSnooze(habit, _now());
    if (result.escaped) {
      await _logRepository.add(HabitLog(
        id: _newId(),
        habitId: habit.id,
        habitTitle: habit.title,
        recordedAt: _now(),
        result: HabitResult.escaped,
      ));
    }
    await _scheduler.scheduleHabitAlert(habit, result.fireAt);
    await load();
  }

  Habit? _findHabit(String habitId) {
    for (final habit in _habits) {
      if (habit.id == habitId) {
        return habit;
      }
    }
    return null;
  }
}
