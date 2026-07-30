import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/habit.dart';

/// habitの永続化を担うリポジトリ。
abstract class HabitRepository {
  Future<List<Habit>> findAll();
  Future<void> save(Habit habit);
  Future<void> delete(String id);
}

/// SharedPreferencesにJSONで保存する実装。
class SharedPrefsHabitRepository implements HabitRepository {
  static const _key = 'habits';

  @override
  Future<List<Habit>> findAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null) {
        return [];
      }
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => Habit.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (error) {
      // 壊れたデータで起動不能になるより空扱いにする
      return [];
    }
  }

  @override
  Future<void> save(Habit habit) async {
    final habits = await findAll();
    final updated = [
      ...habits.where((h) => h.id != habit.id),
      habit,
    ];
    await _writeAll(updated);
  }

  @override
  Future<void> delete(String id) async {
    final habits = await findAll();
    await _writeAll(habits.where((h) => h.id != id).toList());
  }

  Future<void> _writeAll(List<Habit> habits) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(habits.map((h) => h.toJson()).toList()),
    );
  }
}
