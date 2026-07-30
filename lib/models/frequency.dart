/// habitの実施頻度。
enum Frequency {
  hourly,
  daily,
  weekly,
  monthly;

  String get label {
    switch (this) {
      case Frequency.hourly:
        return '時次';
      case Frequency.daily:
        return '日次';
      case Frequency.weekly:
        return '週次';
      case Frequency.monthly:
        return '月次';
    }
  }

  static Frequency fromName(String name) {
    return Frequency.values.firstWhere(
      (f) => f.name == name,
      orElse: () => Frequency.daily,
    );
  }
}
