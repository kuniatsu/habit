import 'package:flutter/material.dart';

import 'habit_presets.dart';
import 'register_screen.dart';

/// 登録タブ。事前に用意したhabitを選ぶ。
/// 一番上のカスタムhabitを選ぶとオリジナルのhabitが作れる。
class PresetSelectTab extends StatelessWidget {
  const PresetSelectTab({super.key});

  void _openRegister(BuildContext context, {HabitPreset? preset}) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => RegisterScreen(preset: preset)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      children: [
        ListTile(
          leading: Icon(Icons.edit_outlined, color: theme.colorScheme.primary),
          title: const Text('カスタムhabit'),
          subtitle: const Text('オリジナルのhabitを作る'),
          onTap: () => _openRegister(context),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Text('人を幸せにするhabit', style: theme.textTheme.titleSmall),
        ),
        for (final preset in habitPresets)
          ListTile(
            leading: const Icon(Icons.favorite_outline),
            title: Text(preset.title),
            subtitle: Text(preset.message),
            trailing: Text(preset.frequency.label),
            onTap: () => _openRegister(context, preset: preset),
          ),
      ],
    );
  }
}
