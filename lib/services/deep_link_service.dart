import 'package:url_launcher/url_launcher.dart';

/// 実施開始時にhabitに設定されたアプリへディープリンクで遷移する。
class DeepLinkService {
  const DeepLinkService();

  /// [url] を開く。開けなければfalseを返す(例外は投げない)。
  Future<bool> open(String url) async {
    try {
      final uri = Uri.parse(url);
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (error) {
      return false;
    }
  }
}
