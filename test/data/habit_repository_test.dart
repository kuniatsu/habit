import 'package:flutter_test/flutter_test.dart';
import 'package:habit/data/habit_log_repository.dart';
import 'package:habit/data/habit_repository.dart';
import 'package:habit/models/frequency.dart';
import 'package:habit/models/habit.dart';
import 'package:habit/models/habit_log.dart';
import 'package:shared_preferences/shared_preferences.dart';

Habit buildHabit(String id) {
  return Habit(
    id: id,
    title: 'habit-$id',
    message: 'メッセージ-$id',
    frequency: Frequency.daily,
    minute: 0,
    hour: 9,
    weekday: DateTime.monday,
    dayOfMonth: 1,
    createdAt: DateTime(2026, 7, 30),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('SharedPrefsHabitRepository', () {
    test('保存して全件取得できる', () async {
      final repo = SharedPrefsHabitRepository();
      await repo.save(buildHabit('a'));
      await repo.save(buildHabit('b'));

      final habits = await repo.findAll();

      expect(habits.length, 2);
      expect(habits.map((h) => h.id), containsAll(['a', 'b']));
    });

    test('同じIDの保存は上書きになる', () async {
      final repo = SharedPrefsHabitRepository();
      await repo.save(buildHabit('a'));
      await repo.save(buildHabit('a').copyWith(title: '更新後'));

      final habits = await repo.findAll();

      expect(habits.length, 1);
      expect(habits.first.title, '更新後');
    });

    test('削除できる', () async {
      final repo = SharedPrefsHabitRepository();
      await repo.save(buildHabit('a'));
      await repo.save(buildHabit('b'));

      await repo.delete('a');

      final habits = await repo.findAll();
      expect(habits.length, 1);
      expect(habits.first.id, 'b');
    });

    test('空の状態では空リストを返す', () async {
      final repo = SharedPrefsHabitRepository();
      expect(await repo.findAll(), isEmpty);
    });
  });

  group('SharedPrefsHabitLogRepository', () {
    test('追加して新しい順で取得できる', () async {
      final repo = SharedPrefsHabitLogRepository();
      await repo.add(HabitLog(
        id: 'log-1',
        habitId: 'a',
        habitTitle: 'habit-a',
        recordedAt: DateTime(2026, 7, 29, 9, 0),
        result: HabitResult.done,
      ));
      await repo.add(HabitLog(
        id: 'log-2',
        habitId: 'a',
        habitTitle: 'habit-a',
        recordedAt: DateTime(2026, 7, 30, 9, 0),
        result: HabitResult.escaped,
      ));

      final logs = await repo.findAll();

      expect(logs.length, 2);
      expect(logs.first.id, 'log-2');
      expect(logs.last.id, 'log-1');
    });
  });
}
