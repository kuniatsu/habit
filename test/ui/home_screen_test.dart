import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit/app.dart';
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

class NoopScheduler implements NotificationScheduler {
  @override
  Future<void> initialize() async {}

  @override
  Future<void> scheduleHabitAlert(Habit habit, DateTime fireAt) async {}

  @override
  Future<void> cancelHabitAlert(String habitId) async {}
}

HabitStore buildStore({
  List<Habit> habits = const [],
  List<HabitLog> logs = const [],
}) {
  final habitRepo = InMemoryHabitRepository()..habits = List.of(habits);
  final logRepo = InMemoryLogRepository()..logs = List.of(logs);
  var idCounter = 0;
  return HabitStore(
    habitRepository: habitRepo,
    logRepository: logRepo,
    scheduler: NoopScheduler(),
    now: () => DateTime(2026, 7, 30, 8, 0),
    newId: () => 'id-${idCounter++}',
  );
}

Habit sampleHabit() {
  return Habit(
    id: 'h-1',
    title: '久しぶりの友人への連絡',
    message: 'その友人は誰ですか、何を送ったら面白い？',
    frequency: Frequency.daily,
    minute: 0,
    hour: 9,
    weekday: DateTime.monday,
    dayOfMonth: 1,
    createdAt: DateTime(2026, 7, 1),
  );
}

void main() {
  testWidgets('habitがない場合は空状態が表示される', (tester) async {
    final store = buildStore();
    await store.load();

    await tester.pumpWidget(HabitApp(store: store));

    expect(find.text('habitがまだありません'), findsOneWidget);
  });

  testWidgets('habit一覧と次のhabitバナーが表示される', (tester) async {
    final store = buildStore(habits: [sampleHabit()]);
    await store.load();

    await tester.pumpWidget(HabitApp(store: store));

    expect(find.text('次のhabit'), findsOneWidget);
    expect(find.text('久しぶりの友人への連絡'), findsNWidgets(2));
    expect(find.textContaining('日次・次回'), findsOneWidget);
  });

  testWidgets('実施ボタンで履歴に記録される', (tester) async {
    final store = buildStore(habits: [sampleHabit()]);
    await store.load();

    await tester.pumpWidget(HabitApp(store: store));
    await tester.tap(find.text('実施'));
    await tester.pumpAndSettle();

    expect(store.logs.length, 1);
  });

  testWidgets('+ボタンで登録画面に遷移し、登録するとTOPに反映される', (tester) async {
    final store = buildStore();
    await store.load();

    await tester.pumpWidget(HabitApp(store: store));
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    expect(find.text('habitを登録'), findsOneWidget);

    // プリセットから選んで登録
    await tester.tap(find.text('5分ストレッチ'));
    await tester.pump();
    await tester.scrollUntilVisible(find.text('登録する'), 200,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('登録する'));
    await tester.pumpAndSettle();

    expect(find.text('5分ストレッチ'), findsNWidgets(2));
    expect(store.habits.length, 1);
    expect(store.habits.first.message, '伸ばしたら一番気持ちいい場所はどこ？');
  });

  testWidgets('タイトル未入力では登録できずエラーが出る', (tester) async {
    final store = buildStore();
    await store.load();

    await tester.pumpWidget(HabitApp(store: store));
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('登録する'), 200,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('登録する'));
    await tester.pumpAndSettle();

    expect(find.text('タイトルを入力してください'), findsOneWidget);
    expect(store.habits, isEmpty);
  });

  testWidgets('履歴画面に消化したhabitが並ぶ', (tester) async {
    final store = buildStore(logs: [
      HabitLog(
        id: 'log-1',
        habitId: 'h-1',
        habitTitle: '久しぶりの友人への連絡',
        recordedAt: DateTime(2026, 7, 29, 9, 1),
        result: HabitResult.done,
      ),
      HabitLog(
        id: 'log-2',
        habitId: 'h-1',
        habitTitle: '久しぶりの友人への連絡',
        recordedAt: DateTime(2026, 7, 30, 9, 0),
        result: HabitResult.escaped,
      ),
    ]);
    await store.load();

    await tester.pumpWidget(HabitApp(store: store));
    await tester.tap(find.byIcon(Icons.history));
    await tester.pumpAndSettle();

    expect(find.text('habit履歴'), findsOneWidget);
    expect(find.text('実施'), findsOneWidget);
    expect(find.text('逃げ切り'), findsOneWidget);
  });
}
