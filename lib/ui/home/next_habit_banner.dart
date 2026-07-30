import 'package:flutter/material.dart';

import '../../state/habit_store.dart';
import '../format.dart';

/// TOPの上部に出す「次のhabit」バナー。
class NextHabitBanner extends StatelessWidget {
  final UpcomingHabit upcoming;

  const NextHabitBanner({super.key, required this.upcoming});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.primaryContainer,
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('次のhabit', style: theme.textTheme.labelMedium),
            const SizedBox(height: 4),
            Text(upcoming.habit.title, style: theme.textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(formatDateTime(upcoming.fireAt),
                style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
