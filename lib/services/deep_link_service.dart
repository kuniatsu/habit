import 'package:installed_apps/installed_apps.dart';
import 'package:url_launcher/url_launcher.dart';

import 'link_target.dart';

/// 実施開始時にhabitに設定されたアプリ/Webサイトへディープリンクで遷移する。
class DeepLinkService {
  const DeepLinkService();

  /// [url] を開く。開けなければfalseを返す(例外は投げない)。
  /// `app://<パッケージ名>` はAndroidアプリ起動、それ以外はURLとして開く。
  Future<bool> open(String url) async {
    try {
      if (isAppLaunchUrl(url)) {
        final started = await InstalledApps.startApp(packageNameFromUrl(url));
        return started ?? false;
      }
      final uri = Uri.parse(url);
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (error) {
      return false;
    }
  }
}
