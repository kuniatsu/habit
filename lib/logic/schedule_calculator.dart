import '../models/frequency.dart';
import '../models/habit.dart';

/// habitの次回実施時刻を計算する。純粋関数のみ。
class ScheduleCalculator {
  const ScheduleCalculator();

  /// [from] より後の直近の実施時刻を返す。[from] ちょうどは含まない。
  DateTime nextOccurrence(Habit habit, DateTime from) {
    switch (habit.frequency) {
      case Frequency.hourly:
        return _nextHourly(habit, from);
      case Frequency.daily:
        return _nextDaily(habit, from);
      case Frequency.weekly:
        return _nextWeekly(habit, from);
      case Frequency.monthly:
        return _nextMonthly(habit, from);
    }
  }

  DateTime _nextHourly(Habit habit, DateTime from) {
    final candidate =
        DateTime(from.year, from.month, from.day, from.hour, habit.minute);
    if (candidate.isAfter(from)) {
      return candidate;
    }
    return candidate.add(const Duration(hours: 1));
  }

  DateTime _nextDaily(Habit habit, DateTime from) {
    final candidate =
        DateTime(from.year, from.month, from.day, habit.hour, habit.minute);
    if (candidate.isAfter(from)) {
      return candidate;
    }
    return DateTime(
        from.year, from.month, from.day + 1, habit.hour, habit.minute);
  }

  DateTime _nextWeekly(Habit habit, DateTime from) {
    final daysAhead = (habit.weekday - from.weekday + 7) % 7;
    final candidate = DateTime(
        from.year, from.month, from.day + daysAhead, habit.hour, habit.minute);
    if (candidate.isAfter(from)) {
      return candidate;
    }
    return candidate.add(const Duration(days: 7));
  }

  DateTime _nextMonthly(Habit habit, DateTime from) {
    final candidate = _monthlyCandidate(
        from.year, from.month, habit.dayOfMonth, habit.hour, habit.minute);
    if (candidate.isAfter(from)) {
      return candidate;
    }
    return _monthlyCandidate(
        from.year, from.month + 1, habit.dayOfMonth, habit.hour, habit.minute);
  }

  /// 存在しない日(例: 2月31日)は月末に丸める。
  DateTime _monthlyCandidate(
      int year, int month, int day, int hour, int minute) {
    final lastDay = DateTime(year, month + 1, 0).day;
    final clamped = day > lastDay ? lastDay : day;
    return DateTime(year, month, clamped, hour, minute);
  }
}
