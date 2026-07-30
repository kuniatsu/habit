import 'package:flutter_test/flutter_test.dart';
import 'package:habit/logic/snooze_policy.dart';
import 'package:habit/models/frequency.dart';
import 'package:habit/models/habit.dart';

Habit buildHabit(Frequency frequency) {
  return Habit(
    id: 'test-id',
    title: 'テスト',
    message: 'テストメッセージ',
    frequency: frequency,
    minute: 0,
    hour: 9,
    weekday: DateTime.monday,
    dayOfMonth: 1,
    createdAt: DateTime(2026, 1, 1),
  );
}

void main() {
  const policy = SnoozePolicy();

  group('先送り間隔', () {
    test('時次は5分後', () {
      expect(policy.snoozeInterval(Frequency.hourly),
          const Duration(minutes: 5));
    });

    test('日次は1時間後', () {
      expect(
          policy.snoozeInterval(Frequency.daily), const Duration(hours: 1));
    });

    test('週次は翌日', () {
      expect(policy.snoozeInterval(Frequency.weekly), const Duration(days: 1));
    });

    test('月次は翌週', () {
      expect(
          policy.snoozeInterval(Frequency.monthly), const Duration(days: 7));
    });
  });

  group('resolveSnooze', () {
    test('次の実施時間より前なら再アラートを予約する', () {
      // 日次 9:00 のhabitを 9:05 に先送り → 10:05 は翌日9:00より前
      final habit = buildHabit(Frequency.daily);
      final now = DateTime(2026, 7, 30, 9, 5);

      final result = policy.resolveSnooze(habit, now);

      expect(result.escaped, isFalse);
      expect(result.fireAt, DateTime(2026, 7, 30, 10, 5));
    });

    test('再アラートが次の実施時間を超えるなら逃げ切りになる', () {
      // 日次 9:00 のhabitを翌日の 8:30 に先送り → 9:30 は次回9:00を超える
      final habit = buildHabit(Frequency.daily);
      final now = DateTime(2026, 7, 31, 8, 30);

      final result = policy.resolveSnooze(habit, now);

      expect(result.escaped, isTrue);
      expect(result.fireAt, DateTime(2026, 7, 31, 9, 0));
    });

    test('時次: 5分後が次の実施時間より前なら再アラート', () {
      // 毎時0分のhabit、10:10に先送り → 10:15 は 11:00 より前
      final habit = buildHabit(Frequency.hourly);
      final now = DateTime(2026, 7, 30, 10, 10);

      final result = policy.resolveSnooze(habit, now);

      expect(result.escaped, isFalse);
      expect(result.fireAt, DateTime(2026, 7, 30, 10, 15));
    });

    test('時次: 5分後が次の実施時間を超えるなら逃げ切り', () {
      // 毎時0分のhabit、10:57に先送り → 11:02 は 11:00 を超える
      final habit = buildHabit(Frequency.hourly);
      final now = DateTime(2026, 7, 30, 10, 57);

      final result = policy.resolveSnooze(habit, now);

      expect(result.escaped, isTrue);
      expect(result.fireAt, DateTime(2026, 7, 30, 11, 0));
    });
  });
}
