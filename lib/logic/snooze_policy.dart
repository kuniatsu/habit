import '../models/frequency.dart';
import '../models/habit.dart';
import 'schedule_calculator.dart';

/// 先送りの結果。
class SnoozeResult {
  /// trueなら逃げ切り(次の実施時間まで先送りが続いた)。
  final bool escaped;

  /// 次にアラートを鳴らす時刻。逃げ切りの場合は次回の定時実施時刻。
  final DateTime fireAt;

  const SnoozeResult({required this.escaped, required this.fireAt});
}

/// 先送りポリシー。先送りには厳しく、実施しないとすぐ次のアラートが鳴る。
class SnoozePolicy {
  final ScheduleCalculator _calculator;

  const SnoozePolicy({ScheduleCalculator calculator = const ScheduleCalculator()})
      : _calculator = calculator;

  /// 頻度ごとの再アラート間隔。
  /// 時次なら5分後、日次なら1時間後、週次なら次の日、月次なら次の週。
  Duration snoozeInterval(Frequency frequency) {
    switch (frequency) {
      case Frequency.hourly:
        return const Duration(minutes: 5);
      case Frequency.daily:
        return const Duration(hours: 1);
      case Frequency.weekly:
        return const Duration(days: 1);
      case Frequency.monthly:
        return const Duration(days: 7);
    }
  }

  /// [now] に先送りしたときの結果を返す。
  /// 再アラートが次の定時実施時刻を超える場合は逃げ切りとなり、
  /// 次の定時にまた追われる。
  SnoozeResult resolveSnooze(Habit habit, DateTime now) {
    final retryAt = now.add(snoozeInterval(habit.frequency));
    final nextRegular = _calculator.nextOccurrence(habit, now);

    if (retryAt.isBefore(nextRegular)) {
      return SnoozeResult(escaped: false, fireAt: retryAt);
    }
    return SnoozeResult(escaped: true, fireAt: nextRegular);
  }
}
