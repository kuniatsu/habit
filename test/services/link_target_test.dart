import 'package:flutter_test/flutter_test.dart';
import 'package:habit/services/app_catalog.dart';
import 'package:habit/services/link_target.dart';

void main() {
  group('アプリ起動URL', () {
    test('パッケージ名からapp://形式のURLを作れる', () {
      expect(appLaunchUrl('jp.naver.line.android'),
          'app://jp.naver.line.android');
    });

    test('app://形式はアプリ起動URLと判定される', () {
      expect(isAppLaunchUrl('app://jp.naver.line.android'), isTrue);
      expect(isAppLaunchUrl('line://'), isFalse);
      expect(isAppLaunchUrl('https://example.com'), isFalse);
    });

    test('app://形式からパッケージ名を取り出せる', () {
      expect(packageNameFromUrl('app://jp.naver.line.android'),
          'jp.naver.line.android');
    });
  });

  group('labelForUrl', () {
    test('有名アプリのURLはアプリ名になる', () {
      expect(labelForUrl('line://'), 'LINE');
      expect(labelForUrl('tel://'), '電話');
    });

    test('未知のURLはそのまま返す', () {
      expect(labelForUrl('myapp://'), 'myapp://');
    });
  });

  group('FamousAppCatalog', () {
    test('有名アプリの一覧を返す', () async {
      final targets = await const FamousAppCatalog().listTargets();

      expect(targets, isNotEmpty);
      expect(targets.map((t) => t.label), contains('LINE'));
    });
  });
}
