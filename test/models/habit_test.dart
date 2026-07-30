import 'package:flutter_test/flutter_test.dart';
import 'package:habit/models/frequency.dart';
import 'package:habit/models/habit.dart';
import 'package:habit/models/habit_log.dart';

void main() {
  final habit = Habit(
    id: 'id-1',
    title: '久しぶりの友人への連絡',
    message: 'その友人は誰ですか、何を送ったら面白い？',
    frequency: Frequency.weekly,
    minute: 30,
    hour: 20,
    weekday: DateTime.friday,
    dayOfMonth: 1,
    deepLinkUrl: 'line://',
    createdAt: DateTime(2026, 7, 30, 12, 0),
  );

  group('Habit', () {
    test('JSONへ変換して復元できる', () {
      final restored = Habit.fromJson(habit.toJson());

      expect(restored.id, habit.id);
      expect(restored.title, habit.title);
      expect(restored.message, habit.message);
      expect(restored.frequency, habit.frequency);
      expect(restored.minute, habit.minute);
      expect(restored.hour, habit.hour);
      expect(restored.weekday, habit.weekday);
      expect(restored.dayOfMonth, habit.dayOfMonth);
      expect(restored.deepLinkUrl, habit.deepLinkUrl);
      expect(restored.createdAt, habit.createdAt);
    });

    test('deepLinkUrlなしでも復元できる', () {
      final noLink = Habit(
        id: 'id-2',
        title: 'ストレッチ',
        message: '伸ばしたら一番気持ちいい場所はどこ？',
        frequency: Frequency.daily,
        minute: 0,
        hour: 7,
        weekday: DateTime.monday,
        dayOfMonth: 1,
        createdAt: DateTime(2026, 7, 30),
      );

      final restored = Habit.fromJson(noLink.toJson());
      expect(restored.deepLinkUrl, isNull);
    });

    test('copyWithは元のオブジェクトを変更しない', () {
      final copied = habit.copyWith(title: '別のタイトル');

      expect(copied.title, '別のタイトル');
      expect(habit.title, '久しぶりの友人への連絡');
      expect(copied.id, habit.id);
    });
  });

  group('HabitLog', () {
    test('JSONへ変換して復元できる', () {
      final log = HabitLog(
        id: 'log-1',
        habitId: 'id-1',
        habitTitle: '久しぶりの友人への連絡',
        recordedAt: DateTime(2026, 7, 30, 20, 31),
        result: HabitResult.done,
      );

      final restored = HabitLog.fromJson(log.toJson());

      expect(restored.id, log.id);
      expect(restored.habitId, log.habitId);
      expect(restored.habitTitle, log.habitTitle);
      expect(restored.recordedAt, log.recordedAt);
      expect(restored.result, HabitResult.done);
    });

    test('逃げ切りも記録できる', () {
      final log = HabitLog(
        id: 'log-2',
        habitId: 'id-1',
        habitTitle: '久しぶりの友人への連絡',
        recordedAt: DateTime(2026, 7, 31, 9, 0),
        result: HabitResult.escaped,
      );

      expect(HabitLog.fromJson(log.toJson()).result, HabitResult.escaped);
    });
  });
}
