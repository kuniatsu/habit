/// habitの消化結果。
enum HabitResult {
  /// 実施した
  done,

  /// 次の実施時間まで先送りし続けて逃げ切った
  escaped;

  String get label {
    switch (this) {
      case HabitResult.done:
        return '実施';
      case HabitResult.escaped:
        return '逃げ切り';
    }
  }

  static HabitResult fromName(String name) {
    return HabitResult.values.firstWhere(
      (r) => r.name == name,
      orElse: () => HabitResult.done,
    );
  }
}

/// 消化したhabitの履歴1件。
class HabitLog {
  final String id;
  final String habitId;

  /// habit削除後も履歴表示できるようタイトルを持つ。
  final String habitTitle;
  final DateTime recordedAt;
  final HabitResult result;

  const HabitLog({
    required this.id,
    required this.habitId,
    required this.habitTitle,
    required this.recordedAt,
    required this.result,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'habitId': habitId,
      'habitTitle': habitTitle,
      'recordedAt': recordedAt.toIso8601String(),
      'result': result.name,
    };
  }

  factory HabitLog.fromJson(Map<String, dynamic> json) {
    return HabitLog(
      id: json['id'] as String,
      habitId: json['habitId'] as String,
      habitTitle: json['habitTitle'] as String,
      recordedAt: DateTime.parse(json['recordedAt'] as String),
      result: HabitResult.fromName(json['result'] as String),
    );
  }
}
