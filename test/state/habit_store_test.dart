import 'package:flutter_test/flutter_test.dart';
import 'package:habit/data/habit_log_repository.dart';
import 'package:habit/data/habit_repository.dart';
import 'package:habit/models/frequency.dart';
import 'package:habit/models/habit.dart';
import 'package:habit/models/habit_log.dart';
import 'package:habit/services/notification_scheduler.dart';
import 'package:habit/state/habit_store.dart';

class InMemoryHabitRepository implements HabitRepository {
  List<Habit> habits = [];

  @override
  Future<List<Habit>> findAll() async => List.of(habits);

  @override
  Future<void> save(Habit habit) async {
    habits = [...habits.where((h) => h.id != habit.id), habit];
  }

  @override
  Future<void> delete(String id) async {
    habits = habits.where((h) => h.id != id).toList();
  }
}

class InMemoryLogRepository implements HabitLogRepository {
  List<HabitLog> logs = [];

  @override
  Future<List<HabitLog>> findAll() async =>
      [...logs]..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));

  @override
  Future<void> add(HabitLog log) async {
    logs = [...logs, log];
  }
}

class FakeScheduler implements NotificationScheduler {
  final List<(String habitId, DateTime fireAt)> scheduled = [];
  final List<String> cancelled = [];

  @override
  Future<void> initialize() async {}

  @override
  Future<void> scheduleHabitAlert(Habit habit, DateTime fireAt) async {
    scheduled.add((habit.id, fireAt));
  }

  @override
  Future<void> cancelHabitAlert(String habitId) async {
    cancelled.add(habitId);
  }
}

void main() {
  late InMemoryHabitRepository habitRepo;
  late InMemoryLogRepository logRepo;
  late FakeScheduler scheduler;
  late HabitStore store;
  var idCounter = 0;

  // 2026-07-30(木) 8:00 固定
  final fixedNow = DateTime(2026, 7, 30, 8, 0);

  setUp(() {
    habitRepo = InMemoryHabitRepository();
    logRepo = InMemoryLogRepository();
    scheduler = FakeScheduler();
    idCounter = 0;
    store = HabitStore(
      habitRepository: habitRepo,
      logRepository: logRepo,
      scheduler: scheduler,
      now: () => fixedNow,
      newId: () => 'id-${idCounter++}',
    );
  });

  Future<void> addDailyHabit() async {
    await store.addHabit(
      title: '朝のストレッチ',
      message: '伸ばしたら一番気持ちいい場所はどこ？',
      frequency: Frequency.daily,
      minute: 0,
      hour: 9,
      weekday: DateTime.monday,
      dayOfMonth: 1,
    );
  }

  group('addHabit', () {
    test('保存され、次回実施時刻にアラートが予約される', () async {
      await addDailyHabit();

      expect(store.habits.length, 1);
      expect(scheduler.scheduled.length, 1);
      expect(scheduler.scheduled.first.$2, DateTime(2026, 7, 30, 9, 0));
    });

    test('空のディープリンクはnullとして保存される', () async {
      await store.addHabit(
        title: 't',
        message: 'm',
        frequency: Frequency.daily,
        minute: 0,
        hour: 9,
        weekday: DateTime.monday,
        dayOfMonth: 1,
        deepLinkUrl: '  ',
      );

      expect(store.habits.first.deepLinkUrl, isNull);
    });
  });

  group('deleteHabit', () {
    test('削除され、アラートもキャンセルされる', () async {
      await addDailyHabit();
      final id = store.habits.first.id;

      await store.deleteHabit(id);

      expect(store.habits, isEmpty);
      expect(scheduler.cancelled, [id]);
    });
  });

  group('startHabit', () {
    test('実施が履歴に記録され、次の定時が予約される', () async {
      await addDailyHabit();
      final id = store.habits.first.id;

      await store.startHabit(id);

      expect(store.logs.length, 1);
      expect(store.logs.first.result, HabitResult.done);
      // 登録時 + 実施時の2回予約
      expect(scheduler.scheduled.length, 2);
      expect(scheduler.scheduled.last.$2, DateTime(2026, 7, 30, 9, 0));
    });

    test('存在しないIDは何もしない', () async {
      await store.startHabit('unknown');
      expect(store.logs, isEmpty);
    });
  });

  group('snoozeHabit', () {
    test('次の実施時間より前なら再アラートのみ(履歴なし)', () async {
      // 8:00の先送り → 9:00(日次1時間後)は次回9:00と同時刻なので逃げ切り…
      // ではなく境界確認のため7:00起点で確認する
      final earlyStore = HabitStore(
        habitRepository: habitRepo,
        logRepository: logRepo,
        scheduler: scheduler,
        now: () => DateTime(2026, 7, 30, 7, 0),
        newId: () => 'id-${idCounter++}',
      );
      await earlyStore.addHabit(
        title: '朝のストレッチ',
        message: '伸ばしたら一番気持ちいい場所はどこ？',
        frequency: Frequency.daily,
        minute: 0,
        hour: 9,
        weekday: DateTime.monday,
        dayOfMonth: 1,
      );
      final id = earlyStore.habits.first.id;

      await earlyStore.snoozeHabit(id);

      expect(earlyStore.logs, isEmpty);
      expect(scheduler.scheduled.last.$2, DateTime(2026, 7, 30, 8, 0));
    });

    test('次の実施時間を超えるなら逃げ切りが記録され、次の定時が予約される', () async {
      final lateStore = HabitStore(
        habitRepository: habitRepo,
        logRepository: logRepo,
        scheduler: scheduler,
        now: () => DateTime(2026, 7, 30, 8, 30),
        newId: () => 'id-${idCounter++}',
      );
      await lateStore.addHabit(
        title: '朝のストレッチ',
        message: '伸ばしたら一番気持ちいい場所はどこ？',
        frequency: Frequency.daily,
        minute: 0,
        hour: 9,
        weekday: DateTime.monday,
        dayOfMonth: 1,
      );
      final id = lateStore.habits.first.id;

      await lateStore.snoozeHabit(id);

      expect(lateStore.logs.length, 1);
      expect(lateStore.logs.first.result, HabitResult.escaped);
      expect(scheduler.scheduled.last.$2, DateTime(2026, 7, 30, 9, 0));
    });
  });

  group('nextHabit', () {
    test('登録がなければnull', () {
      expect(store.nextHabit, isNull);
    });

    test('複数のhabitから直近のものを返す', () async {
      await addDailyHabit();
      await store.addHabit(
        title: '毎時の水分補給',
        message: '飲み干したあとの爽快感を想像して',
        frequency: Frequency.hourly,
        minute: 30,
        hour: 0,
        weekday: DateTime.monday,
        dayOfMonth: 1,
      );

      final next = store.nextHabit;

      expect(next, isNotNull);
      expect(next!.habit.title, '毎時の水分補給');
      expect(next.fireAt, DateTime(2026, 7, 30, 8, 30));
    });
  });
}
