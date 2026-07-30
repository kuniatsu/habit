import 'package:flutter/material.dart';

import '../../models/habit.dart';
import '../format.dart';

/// habit一覧の1行。
class HabitListTile extends StatelessWidget {
  final Habit habit;
  final DateTime nextFireAt;
  final VoidCallback onStart;
  final VoidCallback onDelete;

  const HabitListTile({
    super.key,
    required this.habit,
    required this.nextFireAt,
    required this.onStart,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(habit.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Theme.of(context).colorScheme.errorContainer,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Icon(Icons.delete),
      ),
      confirmDismiss: (_) => _confirmDelete(context),
      onDismissed: (_) => onDelete(),
      child: ListTile(
        title: Text(habit.title),
        subtitle: Text('${habit.frequency.label}・次回 ${formatDateTime(nextFireAt)}'),
        trailing: FilledButton.tonal(
          onPressed: onStart,
          child: const Text('実施'),
        ),
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    final answer = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('「${habit.title}」を削除しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('削除'),
          ),
        ],
      ),
    );
    return answer ?? false;
  }
}
