const _weekdayLabels = ['月', '火', '水', '木', '金', '土', '日'];

/// DateTime.weekday(1〜7)を日本語の曜日にする。
String weekdayLabel(int weekday) => _weekdayLabels[weekday - 1];

String _two(int n) => n.toString().padLeft(2, '0');

/// 次回実施時刻の表示用フォーマット。
/// 例: 「7/30(木) 09:00」
String formatDateTime(DateTime dt) {
  return '${dt.month}/${dt.day}(${weekdayLabel(dt.weekday)}) '
      '${_two(dt.hour)}:${_two(dt.minute)}';
}

/// 履歴表示用フォーマット。例: 「2026/7/30(木) 09:00」
String formatDateTimeWithYear(DateTime dt) {
  return '${dt.year}/${dt.month}/${dt.day}(${weekdayLabel(dt.weekday)}) '
      '${_two(dt.hour)}:${_two(dt.minute)}';
}
