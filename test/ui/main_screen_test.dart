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

Future<void> pumpApp(WidgetTester tester, HabitStore store) async {
  await store.load();
  await tester.pumpWidget(HabitApp(store: store));
}

/// 画面外(キャッシュ領域)にあるウィジェットを確実に表示してからタップする。
Future<void> revealAndTap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  group('フッターメニュー', () {
    testWidgets('TOP/登録/履歴の3ボタンが並ぶ', (tester) async {
      await pumpApp(tester, buildStore());

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.text('TOP'), findsOneWidget);
      expect(find.text('登録'), findsOneWidget);
      expect(find.text('履歴'), findsOneWidget);
    });

    testWidgets('タブでタイトルが切り替わる', (tester) async {
      await pumpApp(tester, buildStore());

      await tester.tap(find.text('登録'));
      await tester.pumpAndSettle();
      expect(find.text('habitを選ぶ'), findsOneWidget);

      await tester.tap(find.text('履歴'));
      await tester.pumpAndSettle();
      expect(find.text('habit履歴'), findsOneWidget);
    });
  });

  group('TOPタブ', () {
    testWidgets('habitがない場合は空状態が表示される', (tester) async {
      await pumpApp(tester, buildStore());

      expect(find.text('habitがまだありません'), findsOneWidget);
    });

    testWidgets('habit一覧と次のhabitバナーが表示される', (tester) async {
      await pumpApp(tester, buildStore(habits: [sampleHabit()]));

      expect(find.text('次のhabit'), findsOneWidget);
      expect(find.text('久しぶりの友人への連絡'), findsNWidgets(2));
      expect(find.textContaining('日次・次回'), findsOneWidget);
    });

    testWidgets('実施ボタンで履歴に記録される', (tester) async {
      final store = buildStore(habits: [sampleHabit()]);
      await pumpApp(tester, store);

      await tester.tap(find.text('実施'));
      await tester.pumpAndSettle();

      expect(store.logs.length, 1);
    });
  });

  group('登録タブ', () {
    testWidgets('カスタムhabitが一番上、その下にプリセットが並ぶ', (tester) async {
      await pumpApp(tester, buildStore());

      await tester.tap(find.text('登録'));
      await tester.pumpAndSettle();

      expect(find.text('カスタムhabit'), findsOneWidget);
      expect(find.text('人を幸せにするhabit'), findsOneWidget);
      expect(find.text('久しぶりの友人への連絡'), findsOneWidget);
      // カスタムhabitはリストの一番上
      final customY = tester.getTopLeft(find.text('カスタムhabit')).dy;
      final presetY = tester.getTopLeft(find.text('久しぶりの友人への連絡')).dy;
      expect(customY, lessThan(presetY));
    });

    testWidgets('プリセットを選ぶと入力済みの登録画面が開き、登録できる', (tester) async {
      final store = buildStore();
      await pumpApp(tester, store);

      await tester.tap(find.text('登録'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('5分ストレッチ'));
      await tester.pumpAndSettle();

      expect(find.text('habitを登録'), findsOneWidget);
      expect(find.text('5分ストレッチ'), findsOneWidget);

      await revealAndTap(tester, find.text('登録する'));

      expect(store.habits.length, 1);
      expect(store.habits.first.title, '5分ストレッチ');

      // TOPタブに戻ると一覧に表示される
      await tester.tap(find.text('TOP'));
      await tester.pumpAndSettle();
      expect(find.text('5分ストレッチ'), findsWidgets);
    });

    testWidgets('カスタムhabitは空のフォームで、タイトル未入力では登録できない', (tester) async {
      final store = buildStore();
      await pumpApp(tester, store);

      await tester.tap(find.text('登録'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('カスタムhabit'));
      await tester.pumpAndSettle();

      expect(find.text('カスタムhabit'), findsOneWidget); // AppBarタイトル

      await revealAndTap(tester, find.text('登録する'));

      expect(find.text('タイトルを入力してください'), findsOneWidget);
      expect(store.habits, isEmpty);
    });
  });

  group('遷移先の設定', () {
    Future<void> openCustomRegister(WidgetTester tester) async {
      await tester.tap(find.text('登録'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('カスタムhabit'));
      await tester.pumpAndSettle();
    }

    testWidgets('「アプリ」を選ぶと一覧から選択でき、選んだアプリ名が表示される', (tester) async {
      await pumpApp(tester, buildStore());
      await openCustomRegister(tester);

      await revealAndTap(tester, find.text('アプリ'));

      await tester.tap(find.text('アプリを選ぶ'));
      await tester.pumpAndSettle();

      // FamousAppCatalog(テスト環境のフォールバック)の一覧が出る
      expect(find.text('LINE'), findsOneWidget);
      await tester.tap(find.text('LINE'));
      await tester.pumpAndSettle();

      expect(find.text('LINE'), findsOneWidget);
      expect(find.text('アプリを選ぶ'), findsNothing);
    });

    testWidgets('「Webサイト」は不正なURLだと登録できない', (tester) async {
      final store = buildStore();
      await pumpApp(tester, store);
      await openCustomRegister(tester);

      await tester.enterText(
          find.widgetWithText(TextFormField, 'タイトル'), 'ニュースを読む');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'アラートメッセージ'), '今日の一番の見出しは？');

      await revealAndTap(tester, find.text('Webサイト'));

      await tester.enterText(
          find.widgetWithText(TextFormField, 'WebサイトのURL'), 'ただの文字列');
      await revealAndTap(tester, find.text('登録する'));

      expect(find.text('http(s)://で始まるURLを入力してください'), findsOneWidget);
      expect(store.habits, isEmpty);
    });

    testWidgets('「Webサイト」で正しいURLなら登録され、URLが保存される', (tester) async {
      final store = buildStore();
      await pumpApp(tester, store);
      await openCustomRegister(tester);

      await tester.enterText(
          find.widgetWithText(TextFormField, 'タイトル'), 'ニュースを読む');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'アラートメッセージ'), '今日の一番の見出しは？');

      await revealAndTap(tester, find.text('Webサイト'));

      await tester.enterText(find.widgetWithText(TextFormField, 'WebサイトのURL'),
          'https://news.example.com');
      await revealAndTap(tester, find.text('登録する'));

      expect(store.habits.length, 1);
      expect(store.habits.first.deepLinkUrl, 'https://news.example.com');
    });

    testWidgets('プリセットの遷移先はアプリとして初期表示される', (tester) async {
      await pumpApp(tester, buildStore());

      await tester.tap(find.text('登録'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('久しぶりの友人への連絡'));
      await tester.pumpAndSettle();

      // line:// → LINE ラベルで表示される
      await tester.scrollUntilVisible(find.text('LINE'), 200,
          scrollable: find.byType(Scrollable).last);
      expect(find.text('LINE'), findsOneWidget);
    });
  });

  group('履歴タブ', () {
    testWidgets('消化したhabitが並ぶ', (tester) async {
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
      await pumpApp(tester, store);

      await tester.tap(find.text('履歴'));
      await tester.pumpAndSettle();

      expect(find.text('実施'), findsOneWidget);
      expect(find.text('逃げ切り'), findsOneWidget);
      expect(find.text('久しぶりの友人への連絡'), findsNWidgets(2));
    });
  });
}
