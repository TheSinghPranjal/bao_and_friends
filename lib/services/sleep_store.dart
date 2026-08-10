import 'package:shared_preferences/shared_preferences.dart';

import '../models/rewards.dart';

/// Persists when Bao last woke up so the 1-hour sleep cycle survives app restarts.
class SleepStore {
  SleepStore._();

  static const _lastWokeKey = 'bao_last_woke_at_ms';

  static Future<DateTime?> lastWokeAt() async {
    final prefs = await SharedPreferences.getInstance();
    final ms = prefs.getInt(_lastWokeKey);
    if (ms == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }

  /// Marks Bao awake now (call after a successful wake-up).
  static Future<void> markWokeUp([DateTime? at]) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      _lastWokeKey,
      (at ?? DateTime.now()).millisecondsSinceEpoch,
    );
  }

  /// Never woken yet → sleeping. After wake, sleeps again every [WakeUpRules.sleepInterval].
  static Future<bool> isSleeping({DateTime? now}) async {
    final woke = await lastWokeAt();
    if (woke == null) return true;
    final t = now ?? DateTime.now();
    return t.difference(woke) >= WakeUpRules.sleepInterval;
  }

  static Future<Duration> timeUntilSleep({DateTime? now}) async {
    final woke = await lastWokeAt();
    if (woke == null) return Duration.zero;
    final t = now ?? DateTime.now();
    final elapsed = t.difference(woke);
    if (elapsed >= WakeUpRules.sleepInterval) return Duration.zero;
    return WakeUpRules.sleepInterval - elapsed;
  }
}
