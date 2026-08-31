import 'dart:io' show Platform;

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Result of a Remote Config force-update check.
class ForceUpdateDecision {
  const ForceUpdateDecision({
    required this.required,
    required this.currentVersion,
    required this.minimumVersion,
    required this.latestVersion,
    required this.storeUrl,
  });

  final bool required;
  final String currentVersion;
  final String minimumVersion;
  final String latestVersion;
  final String storeUrl;

  static const none = ForceUpdateDecision(
    required: false,
    currentVersion: '',
    minimumVersion: '',
    latestVersion: '',
    storeUrl: '',
  );
}

/// Reads Firebase Remote Config keys from the console:
/// - [force_update] (bool)
/// - [minimum_android_version] (string)
/// - [latest_android_version] (string)
abstract final class ForceUpdateService {
  static const keyForceUpdate = 'force_update';
  static const keyMinimumAndroid = 'minimum_android_version';
  static const keyLatestAndroid = 'latest_android_version';

  static const androidStoreUrl =
      'https://play.google.com/store/apps/details?id=com.lazy_bear_club.bao_and_friends';

  /// Fetches Remote Config and decides whether the user must update.
  ///
  /// Force when:
  /// - installed version < [minimum_android_version], or
  /// - [force_update] is true AND installed version < [latest_android_version]
  static Future<ForceUpdateDecision> check() async {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
      return ForceUpdateDecision.none;
    }

    final info = await PackageInfo.fromPlatform();
    final current = info.version;

    final remote = FirebaseRemoteConfig.instance;
    await remote.setConfigSettings(
      RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: kDebugMode
            ? Duration.zero
            : const Duration(hours: 1),
      ),
    );
    await remote.setDefaults(const {
      keyForceUpdate: false,
      keyMinimumAndroid: '1.0.0',
      keyLatestAndroid: '1.0.0',
    });

    try {
      await remote.fetchAndActivate();
    } catch (_) {
      // Offline / fetch failed — don't block the app.
      return ForceUpdateDecision(
        required: false,
        currentVersion: current,
        minimumVersion: remote.getString(keyMinimumAndroid),
        latestVersion: remote.getString(keyLatestAndroid),
        storeUrl: androidStoreUrl,
      );
    }

    final forceFlag = remote.getBool(keyForceUpdate);
    final minimum = remote.getString(keyMinimumAndroid).trim();
    final latest = remote.getString(keyLatestAndroid).trim();

    final belowMinimum =
        minimum.isNotEmpty && _compareVersions(current, minimum) < 0;
    final belowLatest =
        latest.isNotEmpty && _compareVersions(current, latest) < 0;
    final required = belowMinimum || (forceFlag && belowLatest);

    return ForceUpdateDecision(
      required: required,
      currentVersion: current,
      minimumVersion: minimum.isEmpty ? '1.0.0' : minimum,
      latestVersion: latest.isEmpty ? minimum : latest,
      storeUrl: androidStoreUrl,
    );
  }

  /// Returns negative if [a] < [b], 0 if equal, positive if [a] > [b].
  static int _compareVersions(String a, String b) {
    final pa = _parse(a);
    final pb = _parse(b);
    final len = pa.length > pb.length ? pa.length : pb.length;
    for (var i = 0; i < len; i++) {
      final x = i < pa.length ? pa[i] : 0;
      final y = i < pb.length ? pb[i] : 0;
      if (x != y) return x.compareTo(y);
    }
    return 0;
  }

  static List<int> _parse(String version) {
    return version
        .split(RegExp(r'[^0-9]+'))
        .where((p) => p.isNotEmpty)
        .map(int.parse)
        .toList();
  }
}
