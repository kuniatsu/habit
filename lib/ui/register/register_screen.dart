import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/frequency.dart';
import '../../services/app_catalog.dart';
import '../../services/link_target.dart';
import '../../state/habit_store.dart';
import 'habit_presets.dart';

/// 遷移先の種類。
enum LinkType { none, app, web }

/// habitの登録画面。
/// [preset] が渡されたらその内容を初期値にする。nullならカスタムhabit。
class RegisterScreen extends StatefulWidget {
  final HabitPreset? preset;

  const RegisterScreen({super.key, this.preset});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _messageController;
  late final TextEditingController _webUrlController;

  late Frequency _frequency;
  TimeOfDay _time = const TimeOfDay(hour: 9, minute: 0);
  int _minute = 0;
  int _weekday = DateTime.monday;
  int _dayOfMonth = 1;
  LinkType _linkType = LinkType.none;
  LinkTarget? _selectedApp;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final preset = widget.preset;
    _titleController = TextEditingController(text: preset?.title ?? '');
    _messageController = TextEditingController(text: preset?.message ?? '');
    _webUrlController = TextEditingController();
    _frequency = preset?.frequency ?? Frequency.daily;

    final presetUrl = preset?.deepLinkUrl;
    if (presetUrl != null) {
      _linkType = LinkType.app;
      _selectedApp = LinkTarget(label: labelForUrl(presetUrl), url: presetUrl);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    _webUrlController.dispose();
    super.dispose();
  }

  String? get _deepLinkUrl {
    switch (_linkType) {
      case LinkType.none:
        return null;
      case LinkType.app:
        return _selectedApp?.url;
      case LinkType.web:
        return _webUrlController.text.trim();
    }
  }

  Future<void> _pickApp() async {
    final catalog = context.read<AppCatalog>();
    final selected = await showModalBottomSheet<LinkTarget>(
      context: context,
      showDragHandle: true,
      builder: (context) => _AppPickerSheet(targetsFuture: catalog.listTargets()),
    );
    if (selected != null) {
      setState(() => _selectedApp = selected);
    }
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
            deepLinkUrl: _deepLinkUrl,
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
      appBar: AppBar(
        title: Text(widget.preset == null ? 'カスタムhabit' : 'habitを登録'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
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
            Text('実施開始で開く遷移先(任意)',
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            SegmentedButton<LinkType>(
              segments: const [
                ButtonSegment(value: LinkType.none, label: Text('なし')),
                ButtonSegment(value: LinkType.app, label: Text('アプリ')),
                ButtonSegment(value: LinkType.web, label: Text('Webサイト')),
              ],
              selected: {_linkType},
              onSelectionChanged: (selection) =>
                  setState(() => _linkType = selection.first),
            ),
            const SizedBox(height: 12),
            ..._buildLinkFields(),
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

  List<Widget> _buildLinkFields() {
    switch (_linkType) {
      case LinkType.none:
        return [];
      case LinkType.app:
        return [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.apps),
            title: Text(_selectedApp?.label ?? 'アプリを選ぶ'),
            subtitle: _selectedApp == null ? const Text('タップして一覧から選択') : null,
            trailing: const Icon(Icons.chevron_right),
            onTap: _pickApp,
          ),
        ];
      case LinkType.web:
        return [
          TextFormField(
            controller: _webUrlController,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(
              labelText: 'WebサイトのURL',
              hintText: '例: https://example.com',
            ),
            validator: (value) {
              if (_linkType != LinkType.web) {
                return null;
              }
              final text = value?.trim() ?? '';
              if (text.isEmpty) {
                return 'URLを入力してください';
              }
              final uri = Uri.tryParse(text);
              final valid = uri != null &&
                  (uri.scheme == 'http' || uri.scheme == 'https') &&
                  uri.host.isNotEmpty;
              return valid ? null : 'http(s)://で始まるURLを入力してください';
            },
          ),
        ];
    }
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

/// 遷移先アプリを一覧から選ぶボトムシート。
class _AppPickerSheet extends StatelessWidget {
  final Future<List<LinkTarget>> targetsFuture;

  const _AppPickerSheet({required this.targetsFuture});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.6,
      child: FutureBuilder<List<LinkTarget>>(
        future: targetsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final targets = snapshot.data ?? famousAppTargets;
          if (targets.isEmpty) {
            return const Center(child: Text('選べるアプリが見つかりません'));
          }
          return ListView.builder(
            itemCount: targets.length,
            itemBuilder: (context, index) {
              final target = targets[index];
              return ListTile(
                leading: const Icon(Icons.apps),
                title: Text(target.label),
                onTap: () => Navigator.of(context).pop(target),
              );
            },
          );
        },
      ),
    );
  }
}
