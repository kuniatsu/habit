import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/habit_store.dart';
import '../history/history_screen.dart';
import '../register/register_screen.dart';
import 'habit_list_tile.dart';
import 'next_habit_banner.dart';

/// TOP画面。habit一覧と次のhabitがいつかわかる。
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<HabitStore>();
    final next = store.nextHabit;

    return Scaffold(
      appBar: AppBar(
        title: const Text('habit'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: '履歴',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const HistoryScreen()),
            ),
          ),
        ],
      ),
      body: store.habits.isEmpty
          ? const _EmptyView()
          : ListView(
              children: [
                if (next != null) NextHabitBanner(upcoming: next),
                for (final habit in store.habits)
                  HabitListTile(
                    habit: habit,
                    nextFireAt: store.nextOccurrenceOf(habit),
                    onStart: () => store.startHabit(habit.id),
                    onDelete: () => store.deleteHabit(habit.id),
                  ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'habitを登録',
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const RegisterScreen()),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.self_improvement,
              size: 64, color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 16),
          const Text('habitがまだありません'),
          const SizedBox(height: 4),
          const Text('右下の+から登録しましょう'),
        ],
      ),
    );
  }
}
