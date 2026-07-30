import '../models/habit.dart';

/// 通知アクションの種類。
enum HabitAction { start, snooze }

/// habitアラートのスケジュール操作の抽象。
/// テストではフェイクに差し替える。
abstract class NotificationScheduler {
  Future<void> initialize();

  /// [fireAt] にhabitのアラートを予約する。既存の予約は置き換える。
  Future<void> scheduleHabitAlert(Habit habit, DateTime fireAt);

  Future<void> cancelHabitAlert(String habitId);
}
