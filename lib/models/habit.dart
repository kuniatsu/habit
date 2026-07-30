import 'frequency.dart';

/// 習慣化したいタスク。
///
/// スケジュール指定は頻度により使うフィールドが異なる:
/// - 時次: [minute]
/// - 日次: [hour] + [minute]
/// - 週次: [weekday] + [hour] + [minute]
/// - 月次: [dayOfMonth] + [hour] + [minute]
class Habit {
  final String id;
  final String title;

  /// アラート本文。読んだら行動を想像してしまうメッセージにする。
  final String message;
  final Frequency frequency;
  final int minute;
  final int hour;

  /// DateTime.monday(1)〜DateTime.sunday(7)
  final int weekday;
  final int dayOfMonth;

  /// 実施開始時に遷移するディープリンク(例: line://)。
  final String? deepLinkUrl;
  final DateTime createdAt;

  const Habit({
    required this.id,
    required this.title,
    required this.message,
    required this.frequency,
    required this.minute,
    required this.hour,
    required this.weekday,
    required this.dayOfMonth,
    this.deepLinkUrl,
    required this.createdAt,
  });

  Habit copyWith({
    String? id,
    String? title,
    String? message,
    Frequency? frequency,
    int? minute,
    int? hour,
    int? weekday,
    int? dayOfMonth,
    String? deepLinkUrl,
    DateTime? createdAt,
  }) {
    return Habit(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      frequency: frequency ?? this.frequency,
      minute: minute ?? this.minute,
      hour: hour ?? this.hour,
      weekday: weekday ?? this.weekday,
      dayOfMonth: dayOfMonth ?? this.dayOfMonth,
      deepLinkUrl: deepLinkUrl ?? this.deepLinkUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'frequency': frequency.name,
      'minute': minute,
      'hour': hour,
      'weekday': weekday,
      'dayOfMonth': dayOfMonth,
      'deepLinkUrl': deepLinkUrl,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Habit.fromJson(Map<String, dynamic> json) {
    return Habit(
      id: json['id'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      frequency: Frequency.fromName(json['frequency'] as String),
      minute: json['minute'] as int,
      hour: json['hour'] as int,
      weekday: json['weekday'] as int,
      dayOfMonth: json['dayOfMonth'] as int,
      deepLinkUrl: json['deepLinkUrl'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
