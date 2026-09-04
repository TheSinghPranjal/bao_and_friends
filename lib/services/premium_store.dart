import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Gated home activities with their own daily free-tap pools.
enum ActivitySection {
  learn,
  play,
  feed,
  chores;

  String get label => switch (this) {
        ActivitySection.learn => 'Learn',
        ActivitySection.play => 'Play',
        ActivitySection.feed => 'Feed',
        ActivitySection.chores => 'Chores',
      };

  String get route => '/$name';

  static ActivitySection? fromRoute(String route) {
    final path = route.split('?').first;
    return switch (path) {
      '/learn' => ActivitySection.learn,
      '/play' => ActivitySection.play,
      '/feed' => ActivitySection.feed,
      '/chores' => ActivitySection.chores,
      _ => null,
    };
  }
}

/// Per-section daily free taps + premium unlock.
///
/// Each section starts each calendar day with [maxTapsPerSection] remaining.
/// Opening that section consumes 1. Premium unlocks unlimited access.
class PremiumStore {
  PremiumStore._();

  static const maxTapsPerSection = 10;

  static const _unlockedKey = 'bao_premium_unlocked';
  static const _remainingPrefix = 'bao_section_remaining_';

  static final ValueNotifier<bool> unlockedListenable = ValueNotifier(false);

  static Future<SharedPreferences> get _prefs =>
      SharedPreferences.getInstance();

  static String _dayKey([DateTime? now]) {
    final t = now ?? DateTime.now();
    return '${t.year.toString().padLeft(4, '0')}'
        '${t.month.toString().padLeft(2, '0')}'
        '${t.day.toString().padLeft(2, '0')}';
  }

  static String _remainingKey(ActivitySection section, [DateTime? now]) =>
      '$_remainingPrefix${section.name}_${_dayKey(now)}';

  static bool isGatedRoute(String route) =>
      ActivitySection.fromRoute(route) != null;

  static Future<bool> isPremiumUnlocked() async {
    final prefs = await _prefs;
    final v = prefs.getBool(_unlockedKey) ?? false;
    if (unlockedListenable.value != v) {
      unlockedListenable.value = v;
    }
    return v;
  }

  /// Testing toggle / mock purchase. Off by default.
  static Future<void> setPremiumUnlocked(bool unlocked) async {
    final prefs = await _prefs;
    await prefs.setBool(_unlockedKey, unlocked);
    unlockedListenable.value = unlocked;
  }

  /// Remaining free taps for [section] today (defaults to [maxTapsPerSection]).
  static Future<int> remainingTaps(
    ActivitySection section, [
    DateTime? now,
  ]) async {
    if (await isPremiumUnlocked()) return maxTapsPerSection;
    final prefs = await _prefs;
    return prefs.getInt(_remainingKey(section, now)) ?? maxTapsPerSection;
  }

  static Future<void> _setRemaining(
    ActivitySection section,
    int value, [
    DateTime? now,
  ]) async {
    final prefs = await _prefs;
    await prefs.setInt(
      _remainingKey(section, now),
      value.clamp(0, maxTapsPerSection),
    );
  }

  static Future<Map<ActivitySection, int>> remainingBySection([
    DateTime? now,
  ]) async {
    final map = <ActivitySection, int>{};
    for (final s in ActivitySection.values) {
      map[s] = await remainingTaps(s, now);
    }
    return map;
  }

  /// Call before opening a gated activity. Consumes one tap when allowed.
  static Future<bool> tryConsumeActivityTap(
    ActivitySection section, [
    DateTime? now,
  ]) async {
    if (await isPremiumUnlocked()) return true;
    final t = now ?? DateTime.now();
    final left = await remainingTaps(section, t);
    if (left <= 0) return false;
    await _setRemaining(section, left - 1, t);
    return true;
  }
}
