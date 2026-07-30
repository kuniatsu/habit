import '../../models/frequency.dart';

/// 登録画面にあらかじめ並べる「人を幸せにするhabit」。
/// メッセージは読んだら行動を想像してしまう問いかけにする。
class HabitPreset {
  final String title;
  final String message;
  final Frequency frequency;
  final String? deepLinkUrl;

  const HabitPreset({
    required this.title,
    required this.message,
    required this.frequency,
    this.deepLinkUrl,
  });
}

const habitPresets = [
  HabitPreset(
    title: '久しぶりの友人への連絡',
    message: 'その友人は誰ですか、何を送ったら面白い？',
    frequency: Frequency.weekly,
    deepLinkUrl: 'line://',
  ),
  HabitPreset(
    title: '家族に感謝を伝える',
    message: '今日「ありがとう」と言えることを一つ思い出した？',
    frequency: Frequency.daily,
    deepLinkUrl: 'line://',
  ),
  HabitPreset(
    title: '水を一杯飲む',
    message: '飲み干したあとの爽快感、想像してみて',
    frequency: Frequency.hourly,
  ),
  HabitPreset(
    title: '5分ストレッチ',
    message: '伸ばしたら一番気持ちいい場所はどこ？',
    frequency: Frequency.daily,
  ),
  HabitPreset(
    title: '今日の良かったことをメモ',
    message: '思い出してニヤッとした出来事は？',
    frequency: Frequency.daily,
  ),
  HabitPreset(
    title: '部屋の一角を片付ける',
    message: '片付いたあとのスッキリした景色はどんな感じ？',
    frequency: Frequency.weekly,
  ),
  HabitPreset(
    title: '両親に近況報告',
    message: '聞いたら喜びそうな最近の話は何？',
    frequency: Frequency.monthly,
    deepLinkUrl: 'tel://',
  ),
];
