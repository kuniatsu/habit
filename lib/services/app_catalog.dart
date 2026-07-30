import 'dart:io';

import 'package:installed_apps/installed_apps.dart';

import 'link_target.dart';

/// 遷移先アプリの候補一覧を提供する。
abstract class AppCatalog {
  Future<List<LinkTarget>> listTargets();
}

/// 有名アプリの固定リスト。アプリ一覧が取得できない環境のフォールバック。
class FamousAppCatalog implements AppCatalog {
  const FamousAppCatalog();

  @override
  Future<List<LinkTarget>> listTargets() async => famousAppTargets;
}

/// 端末のインストール済みアプリ一覧(Androidのみ)。
/// 取得できない場合は有名アプリリストにフォールバックする。
class DeviceAppCatalog implements AppCatalog {
  const DeviceAppCatalog();

  @override
  Future<List<LinkTarget>> listTargets() async {
    if (!Platform.isAndroid) {
      return famousAppTargets;
    }
    try {
      final apps = await InstalledApps.getInstalledApps(
        excludeSystemApps: false,
        excludeNonLaunchableApps: true,
      );
      if (apps.isEmpty) {
        return famousAppTargets;
      }
      final targets = apps
          .where((app) => app.name.trim().isNotEmpty)
          .map((app) =>
              LinkTarget(label: app.name, url: appLaunchUrl(app.packageName)))
          .toList()
        ..sort((a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()));
      return targets;
    } catch (error) {
      return famousAppTargets;
    }
  }
}
