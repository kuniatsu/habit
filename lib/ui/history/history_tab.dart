import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/habit_log.dart';
import '../../state/habit_store.dart';
import '../format.dart';

/// 履歴タブ。消化したhabitが並ぶ。
class HistoryTab extends StatelessWidget {
  const HistoryTab({super.key});

  @override
  Widget build(BuildContext context) {
    final logs = context.watch<HabitStore>().logs;

    if (logs.isEmpty) {
      return const Center(child: Text('まだ履歴がありません'));
    }

    return ListView.builder(
      itemCount: logs.length,
      itemBuilder: (context, index) {
        final log = logs[index];
        final done = log.result == HabitResult.done;
        return ListTile(
          leading: Icon(
            done ? Icons.check_circle : Icons.directions_run,
            color: done
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.error,
          ),
          title: Text(log.habitTitle),
          subtitle: Text(formatDateTimeWithYear(log.recordedAt)),
          trailing: Text(log.result.label),
        );
      },
    );
  }
}
