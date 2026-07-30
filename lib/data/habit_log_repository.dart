import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/habit_log.dart';

/// habit履歴の永続化を担うリポジトリ。
abstract class HabitLogRepository {
  /// 新しい順で全件返す。
  Future<List<HabitLog>> findAll();
  Future<void> add(HabitLog log);
}

/// SharedPreferencesにJSONで保存する実装。
class SharedPrefsHabitLogRepository implements HabitLogRepository {
  static const _key = 'habit_logs';

  @override
  Future<List<HabitLog>> findAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null) {
        return [];
      }
      final list = jsonDecode(raw) as List<dynamic>;
      final logs = list
          .map((e) => HabitLog.fromJson(e as Map<String, dynamic>))
          .toList();
      return [...logs]..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
    } catch (error) {
      return [];
    }
  }

  @override
  Future<void> add(HabitLog log) async {
    final prefs = await SharedPreferences.getInstance();
    final logs = await findAll();
    await prefs.setString(
      _key,
      jsonEncode([...logs, log].map((l) => l.toJson()).toList()),
    );
  }
}
