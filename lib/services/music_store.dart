import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Global music preference (Settings). Off/on for when BGM is wired up.
class MusicStore {
  MusicStore._();

  static const _key = 'bao_music_enabled';

  /// Default on so music plays when assets are added.
  static final ValueNotifier<bool> enabledListenable = ValueNotifier(true);

  static Future<SharedPreferences> get _prefs =>
      SharedPreferences.getInstance();

  static Future<bool> isEnabled() async {
    final prefs = await _prefs;
    final v = prefs.getBool(_key) ?? true;
    if (enabledListenable.value != v) {
      enabledListenable.value = v;
    }
    return v;
  }

  static Future<void> setEnabled(bool enabled) async {
    final prefs = await _prefs;
    await prefs.setBool(_key, enabled);
    enabledListenable.value = enabled;
  }
}
