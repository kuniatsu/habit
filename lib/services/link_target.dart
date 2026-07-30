/// 実施開始時の遷移先(アプリまたはWebサイト)。
class LinkTarget {
  final String label;

  /// 遷移先URL。Androidアプリ起動は `app://<パッケージ名>` 形式、
  /// それ以外はURLスキーム(line:// など)やWebのURL。
  final String url;

  const LinkTarget({required this.label, required this.url});
}

const _appUrlPrefix = 'app://';

/// Androidアプリ起動用URLかどうか。
bool isAppLaunchUrl(String url) => url.startsWith(_appUrlPrefix);

/// `app://<パッケージ名>` からパッケージ名を取り出す。
String packageNameFromUrl(String url) => url.substring(_appUrlPrefix.length);

/// パッケージ名からアプリ起動用URLを作る。
String appLaunchUrl(String packageName) => '$_appUrlPrefix$packageName';

/// アプリ一覧が取得できない環境(iOS等)向けの有名アプリリスト。
const famousAppTargets = [
  LinkTarget(label: 'LINE', url: 'line://'),
  LinkTarget(label: 'X (Twitter)', url: 'twitter://'),
  LinkTarget(label: 'Instagram', url: 'instagram://'),
  LinkTarget(label: 'YouTube', url: 'youtube://'),
  LinkTarget(label: 'Gmail', url: 'googlegmail://'),
  LinkTarget(label: 'マップ', url: 'maps://'),
  LinkTarget(label: '電話', url: 'tel://'),
  LinkTarget(label: 'メッセージ', url: 'sms://'),
  LinkTarget(label: 'メール', url: 'mailto:'),
];

/// URLから表示ラベルを引く。有名アプリに一致すればその名前、なければURLそのもの。
String labelForUrl(String url) {
  for (final target in famousAppTargets) {
    if (target.url == url) {
      return target.label;
    }
  }
  return url;
}
