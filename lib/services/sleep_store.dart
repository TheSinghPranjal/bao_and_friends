import 'package:shared_preferences/shared_preferences.dart';

import '../models/activity_schedule.dart';
import 'schedule_store.dart';

/// Persists wake time and computes sleep from schedule windows + awake rule.
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

  /// Customizable sleep cue times: [nightStart, nightEnd, noonNapStart].
  static Future<(int nightStart, int nightEnd, int noonNap)> sleepSlots() async {
    final times = await ScheduleStore.timesFor(ActivityId.wake);
    final nightStart = times.isNotEmpty
        ? times[0]
        : DefaultSchedules.nightSleepStart;
    final nightEnd =
        times.length > 1 ? times[1] : DefaultSchedules.nightSleepEnd;
    final noonNap =
        times.length > 2 ? times[2] : DefaultSchedules.noonNapStart;
    return (nightStart, nightEnd, noonNap);
  }

  /// Night sleep window only (10pm–6am by default), wrapping midnight.
  static Future<bool> inNightSleepWindow({DateTime? now}) async {
    final t = now ?? DateTime.now();
    final minutes = t.hour * 60 + t.minute;
    final (nightStart, nightEnd, _) = await sleepSlots();
    if (nightStart > nightEnd) {
      return minutes >= nightStart || minutes < nightEnd;
    }
    return minutes >= nightStart && minutes < nightEnd;
  }

  /// True when [now] falls in night sleep or noon nap.
  static Future<bool> inScheduledSleepWindow({DateTime? now}) async {
    final t = now ?? DateTime.now();
    final minutes = t.hour * 60 + t.minute;
    final (_, _, noonNap) = await sleepSlots();

    if (await inNightSleepWindow(now: t)) return true;

    final napEnd = noonNap + DefaultSchedules.noonNapMinutes;
    return minutes >= noonNap && minutes < napEnd;
  }

  /// During night window, Bao may voluntarily sleep again after wake.
  static Future<bool> canReturnToSleep({DateTime? now}) async {
    return inNightSleepWindow(now: now);
  }

  /// Awake duration after wake: 30 min at night, otherwise noon-nap default.
  static Future<Duration> awakeDurationAfterWake({DateTime? now}) async {
    if (await inNightSleepWindow(now: now)) {
      return Duration(minutes: DefaultSchedules.awakeAfterNightWakeMinutes);
    }
    return Duration(minutes: DefaultSchedules.awakeAfterWakeMinutes);
  }

  /// Sleep only inside scheduled windows.
  /// - Outside windows → always awake.
  /// - Inside night → sleeping unless woken within last 30 minutes.
  /// - Inside noon nap → sleeping unless woken within last hour.
  static Future<bool> isSleeping({DateTime? now}) async {
    final t = now ?? DateTime.now();
    final inWindow = await inScheduledSleepWindow(now: t);
    if (!inWindow) return false;

    final woke = await lastWokeAt();
    if (woke == null) return true;

    final awakeLimit = await awakeDurationAfterWake(now: t);
    if (t.difference(woke) < awakeLimit) return false;
    return true;
  }

  static Future<Duration> timeUntilSleep({DateTime? now}) async {
    final woke = await lastWokeAt();
    if (woke == null) return Duration.zero;
    final t = now ?? DateTime.now();
    final limit = await awakeDurationAfterWake(now: t);
    final elapsed = t.difference(woke);
    if (elapsed >= limit) return Duration.zero;
    return limit - elapsed;
  }

  /// During a sleep window, put Bao back to sleep after a wake.
  static Future<void> goBackToSleep() async {
    final prefs = await SharedPreferences.getInstance();
    final past = DateTime.now().subtract(
      Duration(minutes: DefaultSchedules.awakeAfterNightWakeMinutes + 1),
    );
    await prefs.setInt(_lastWokeKey, past.millisecondsSinceEpoch);
  }

  /// Progress for wake ring: empty/due while sleeping; depletes while awake.
  static Future<ActivityTimerStatus> wakeTimerStatus({DateTime? now}) async {
    final t = now ?? DateTime.now();
    final sleeping = await isSleeping(now: t);
    if (sleeping) {
      return ActivityTimerStatus(
        id: ActivityId.wake,
        progress: 0,
        isDue: true,
        nextAt: null,
        windowStart: t,
      );
    }
    final inWindow = await inScheduledSleepWindow(now: t);
    if (!inWindow) {
      return ActivityTimerStatus(
        id: ActivityId.wake,
        progress: 1,
        isDue: false,
        nextAt: null,
        windowStart: await lastWokeAt(),
      );
    }
    final remaining = await timeUntilSleep(now: t);
    final total = await awakeDurationAfterWake(now: t);
    final progress =
        (remaining.inSeconds / total.inSeconds.clamp(1, 86400)).clamp(0.0, 1.0);
    return ActivityTimerStatus(
      id: ActivityId.wake,
      progress: progress,
      isDue: false,
      nextAt: t.add(remaining),
      windowStart: await lastWokeAt(),
    );
  }
}
