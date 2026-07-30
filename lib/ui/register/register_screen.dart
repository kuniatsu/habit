import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/frequency.dart';
import '../../state/habit_store.dart';
import 'habit_presets.dart';

/// habitの登録画面。
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  final _deepLinkController = TextEditingController();

  Frequency _frequency = Frequency.daily;
  TimeOfDay _time = const TimeOfDay(hour: 9, minute: 0);
  int _minute = 0;
  int _weekday = DateTime.monday;
  int _dayOfMonth = 1;
  bool _saving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    _deepLinkController.dispose();
    super.dispose();
  }

  void _applyPreset(HabitPreset preset) {
    setState(() {
      _titleController.text = preset.title;
      _messageController.text = preset.message;
      _deepLinkController.text = preset.deepLinkUrl ?? '';
      _frequency = preset.frequency;
    });
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) {
      setState(() => _time = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _saving) {
      return;
    }
    setState(() => _saving = true);
    try {
      await context.read<HabitStore>().addHabit(
            title: _titleController.text.trim(),
            message: _messageController.text.trim(),
            frequency: _frequency,
            minute: _frequency == Frequency.hourly ? _minute : _time.minute,
            hour: _time.hour,
            weekday: _weekday,
            dayOfMonth: _dayOfMonth,
            deepLinkUrl: _deepLinkController.text,
          );
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (error) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('保存に失敗しました。もう一度お試しください')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('habitを登録')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('人を幸せにするhabit',
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final preset in habitPresets)
                  ActionChip(
                    label: Text(preset.title),
                    onPressed: () => _applyPreset(preset),
                  ),
              ],
            ),
            const Divider(height: 32),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'タイトル',
                hintText: '例: 久しぶりの友人への連絡',
              ),
              validator: (value) =>
                  (value == null || value.trim().isEmpty) ? 'タイトルを入力してください' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _messageController,
              decoration: const InputDecoration(
                labelText: 'アラートメッセージ',
                hintText: '例: 送ったら愉快な気持ちになるメッセージは？',
                helperText: '読んだら行動を想像してしまう問いかけに',
              ),
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? 'メッセージを入力してください'
                  : null,
            ),
            const SizedBox(height: 24),
            Text('頻度', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            SegmentedButton<Frequency>(
              segments: [
                for (final f in Frequency.values)
                  ButtonSegment(value: f, label: Text(f.label)),
              ],
              selected: {_frequency},
              onSelectionChanged: (selection) =>
                  setState(() => _frequency = selection.first),
            ),
            const SizedBox(height: 16),
            ..._buildScheduleFields(),
            const SizedBox(height: 24),
            TextFormField(
              controller: _deepLinkController,
              decoration: const InputDecoration(
                labelText: '遷移先アプリ(任意)',
                hintText: '例: line://',
                helperText: '実施開始で開くディープリンクURL',
              ),
              validator: (value) {
                final text = value?.trim() ?? '';
                if (text.isEmpty) {
                  return null;
                }
                return text.contains('://') ? null : 'URL形式(例: line://)で入力してください';
              },
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: const Text('登録する'),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildScheduleFields() {
    switch (_frequency) {
      case Frequency.hourly:
        return [
          _dropdownRow<int>(
            label: '毎時',
            value: _minute,
            items: [
              for (var m = 0; m < 60; m += 5)
                DropdownMenuItem(value: m, child: Text('$m分')),
            ],
            onChanged: (v) => setState(() => _minute = v),
          ),
        ];
      case Frequency.daily:
        return [_timeRow('毎日')];
      case Frequency.weekly:
        return [
          _dropdownRow<int>(
            label: '毎週',
            value: _weekday,
            items: const [
              DropdownMenuItem(value: DateTime.monday, child: Text('月曜')),
              DropdownMenuItem(value: DateTime.tuesday, child: Text('火曜')),
              DropdownMenuItem(value: DateTime.wednesday, child: Text('水曜')),
              DropdownMenuItem(value: DateTime.thursday, child: Text('木曜')),
              DropdownMenuItem(value: DateTime.friday, child: Text('金曜')),
              DropdownMenuItem(value: DateTime.saturday, child: Text('土曜')),
              DropdownMenuItem(value: DateTime.sunday, child: Text('日曜')),
            ],
            onChanged: (v) => setState(() => _weekday = v),
          ),
          const SizedBox(height: 8),
          _timeRow('時刻'),
        ];
      case Frequency.monthly:
        return [
          _dropdownRow<int>(
            label: '毎月',
            value: _dayOfMonth,
            items: [
              for (var d = 1; d <= 31; d++)
                DropdownMenuItem(value: d, child: Text('$d日')),
            ],
            onChanged: (v) => setState(() => _dayOfMonth = v),
          ),
          const SizedBox(height: 8),
          _timeRow('時刻'),
        ];
    }
  }

  Widget _dropdownRow<T>({
    required String label,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required void Function(T) onChanged,
  }) {
    return Row(
      children: [
        SizedBox(width: 64, child: Text(label)),
        const SizedBox(width: 8),
        Expanded(
          child: DropdownButtonFormField<T>(
            initialValue: value,
            items: items,
            onChanged: (v) {
              if (v != null) {
                onChanged(v);
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _timeRow(String label) {
    return Row(
      children: [
        SizedBox(width: 64, child: Text(label)),
        const SizedBox(width: 8),
        OutlinedButton.icon(
          onPressed: _pickTime,
          icon: const Icon(Icons.schedule),
          label: Text(
            '${_time.hour.toString().padLeft(2, '0')}:'
            '${_time.minute.toString().padLeft(2, '0')}',
          ),
        ),
      ],
    );
  }
}
