import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/habit_store.dart';
import 'habit_list_tile.dart';
import 'next_habit_banner.dart';

/// TOPタブ。habit一覧と次のhabitがいつかわかる。
class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<HabitStore>();
    final next = store.nextHabit;

    if (store.habits.isEmpty) {
      return const _EmptyView();
    }

    return ListView(
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
          const Text('「登録」タブから登録しましょう'),
        ],
      ),
    );
  }
}
