import 'package:flutter_test/flutter_test.dart';
import 'package:habit/logic/schedule_calculator.dart';
import 'package:habit/models/frequency.dart';
import 'package:habit/models/habit.dart';

Habit buildHabit({
  Frequency frequency = Frequency.daily,
  int minute = 0,
  int hour = 9,
  int weekday = DateTime.monday,
  int dayOfMonth = 1,
}) {
  return Habit(
    id: 'test-id',
    title: 'テスト',
    message: 'テストメッセージ',
    frequency: frequency,
    minute: minute,
    hour: hour,
    weekday: weekday,
    dayOfMonth: dayOfMonth,
    createdAt: DateTime(2026, 1, 1),
  );
}

void main() {
  const calculator = ScheduleCalculator();

  group('nextOccurrence: hourly', () {
    test('同じ時間帯で指定分がまだ来ていなければその分を返す', () {
      final habit = buildHabit(frequency: Frequency.hourly, minute: 30);
      final from = DateTime(2026, 7, 30, 10, 10);
      expect(
        calculator.nextOccurrence(habit, from),
        DateTime(2026, 7, 30, 10, 30),
      );
    });

    test('指定分を過ぎていれば次の時間帯を返す', () {
      final habit = buildHabit(frequency: Frequency.hourly, minute: 30);
      final from = DateTime(2026, 7, 30, 10, 45);
      expect(
        calculator.nextOccurrence(habit, from),
        DateTime(2026, 7, 30, 11, 30),
      );
    });

    test('ちょうど指定分のときは次の時間帯を返す', () {
      final habit = buildHabit(frequency: Frequency.hourly, minute: 30);
      final from = DateTime(2026, 7, 30, 10, 30);
      expect(
        calculator.nextOccurrence(habit, from),
        DateTime(2026, 7, 30, 11, 30),
      );
    });
  });

  group('nextOccurrence: daily', () {
    test('当日の指定時刻がまだ来ていなければ当日を返す', () {
      final habit =
          buildHabit(frequency: Frequency.daily, hour: 21, minute: 0);
      final from = DateTime(2026, 7, 30, 9, 0);
      expect(
        calculator.nextOccurrence(habit, from),
        DateTime(2026, 7, 30, 21, 0),
      );
    });

    test('指定時刻を過ぎていれば翌日を返す', () {
      final habit = buildHabit(frequency: Frequency.daily, hour: 9, minute: 0);
      final from = DateTime(2026, 7, 30, 9, 0, 1);
      expect(
        calculator.nextOccurrence(habit, from),
        DateTime(2026, 7, 31, 9, 0),
      );
    });

    test('月末をまたいで翌日を返す', () {
      final habit = buildHabit(frequency: Frequency.daily, hour: 9, minute: 0);
      final from = DateTime(2026, 7, 31, 10, 0);
      expect(
        calculator.nextOccurrence(habit, from),
        DateTime(2026, 8, 1, 9, 0),
      );
    });
  });

  group('nextOccurrence: weekly', () {
    test('同じ週の指定曜日がまだ来ていなければその日を返す', () {
      // 2026-07-30 は木曜
      final habit = buildHabit(
        frequency: Frequency.weekly,
        weekday: DateTime.saturday,
        hour: 10,
        minute: 0,
      );
      final from = DateTime(2026, 7, 30, 12, 0);
      expect(
        calculator.nextOccurrence(habit, from),
        DateTime(2026, 8, 1, 10, 0),
      );
    });

    test('当日でも時刻を過ぎていれば来週を返す', () {
      final habit = buildHabit(
        frequency: Frequency.weekly,
        weekday: DateTime.thursday,
        hour: 10,
        minute: 0,
      );
      final from = DateTime(2026, 7, 30, 12, 0);
      expect(
        calculator.nextOccurrence(habit, from),
        DateTime(2026, 8, 6, 10, 0),
      );
    });

    test('当日で時刻がまだなら当日を返す', () {
      final habit = buildHabit(
        frequency: Frequency.weekly,
        weekday: DateTime.thursday,
        hour: 22,
        minute: 0,
      );
      final from = DateTime(2026, 7, 30, 12, 0);
      expect(
        calculator.nextOccurrence(habit, from),
        DateTime(2026, 7, 30, 22, 0),
      );
    });
  });

  group('nextOccurrence: monthly', () {
    test('当月の指定日がまだ来ていなければ当月を返す', () {
      final habit = buildHabit(
        frequency: Frequency.monthly,
        dayOfMonth: 31,
        hour: 9,
        minute: 0,
      );
      final from = DateTime(2026, 7, 15, 0, 0);
      expect(
        calculator.nextOccurrence(habit, from),
        DateTime(2026, 7, 31, 9, 0),
      );
    });

    test('指定日を過ぎていれば翌月を返す', () {
      final habit = buildHabit(
        frequency: Frequency.monthly,
        dayOfMonth: 10,
        hour: 9,
        minute: 0,
      );
      final from = DateTime(2026, 7, 15, 0, 0);
      expect(
        calculator.nextOccurrence(habit, from),
        DateTime(2026, 8, 10, 9, 0),
      );
    });

    test('存在しない日は月末に丸める(31日→2月28日)', () {
      final habit = buildHabit(
        frequency: Frequency.monthly,
        dayOfMonth: 31,
        hour: 9,
        minute: 0,
      );
      final from = DateTime(2027, 2, 1, 0, 0);
      expect(
        calculator.nextOccurrence(habit, from),
        DateTime(2027, 2, 28, 9, 0),
      );
    });

    test('うるう年の2月は29日に丸める', () {
      final habit = buildHabit(
        frequency: Frequency.monthly,
        dayOfMonth: 31,
        hour: 9,
        minute: 0,
      );
      final from = DateTime(2028, 2, 1, 0, 0);
      expect(
        calculator.nextOccurrence(habit, from),
        DateTime(2028, 2, 29, 9, 0),
      );
    });

    test('年をまたいで翌月を返す', () {
      final habit = buildHabit(
        frequency: Frequency.monthly,
        dayOfMonth: 5,
        hour: 9,
        minute: 0,
      );
      final from = DateTime(2026, 12, 20, 0, 0);
      expect(
        calculator.nextOccurrence(habit, from),
        DateTime(2027, 1, 5, 9, 0),
      );
    });
  });
}
