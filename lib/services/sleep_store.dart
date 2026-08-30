import 'package:shared_preferences/shared_preferences.dart';

import '../models/activity_schedule.dart';
import '../models/rewards.dart';
import 'schedule_store.dart';

/// Persists wake time and computes sleep from schedule windows + 1h awake rule.
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

  /// True when [now] falls in night sleep (wrapping overnight) or noon nap hour.
  static Future<bool> inScheduledSleepWindow({DateTime? now}) async {
    final t = now ?? DateTime.now();
    final minutes = t.hour * 60 + t.minute;
    final (nightStart, nightEnd, noonNap) = await sleepSlots();

    final inNight = nightStart > nightEnd
        ? (minutes >= nightStart || minutes < nightEnd)
        : (minutes >= nightStart && minutes < nightEnd);

    final napEnd = noonNap + DefaultSchedules.noonNapMinutes;
    final inNap = minutes >= noonNap && minutes < napEnd;

    return inNight || inNap;
  }

  /// During night window (10pm–6am), Bao may voluntarily sleep again after wake.
  static Future<bool> canReturnToSleep({DateTime? now}) async {
    return inScheduledSleepWindow(now: now);
  }

  /// Sleep only inside scheduled windows.
  /// - Outside 10pm–6am and noon nap → always awake (even on first launch).
  /// - Inside a window → sleeping unless woken within the last hour.
  static Future<bool> isSleeping({DateTime? now}) async {
    final t = now ?? DateTime.now();
    final inWindow = await inScheduledSleepWindow(now: t);
    if (!inWindow) return false;

    final woke = await lastWokeAt();
    if (woke == null) return true;

    final limit = Duration(minutes: DefaultSchedules.awakeAfterWakeMinutes);
    // Keep WakeUpRules in sync when both are 1h.
    final awakeLimit = WakeUpRules.sleepInterval > limit
        ? WakeUpRules.sleepInterval
        : limit;
    if (t.difference(woke) < awakeLimit) return false;
    return true;
  }

  static Future<Duration> timeUntilSleep({DateTime? now}) async {
    final woke = await lastWokeAt();
    if (woke == null) return Duration.zero;
    final t = now ?? DateTime.now();
    final limit = Duration(minutes: DefaultSchedules.awakeAfterWakeMinutes);
    final elapsed = t.difference(woke);
    if (elapsed >= limit) return Duration.zero;
    return limit - elapsed;
  }

  /// During a sleep window, put Bao back to sleep after a wake.
  static Future<void> goBackToSleep() async {
    final prefs = await SharedPreferences.getInstance();
    final past = DateTime.now().subtract(
      Duration(minutes: DefaultSchedules.awakeAfterWakeMinutes + 1),
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
    final total = Duration(minutes: DefaultSchedules.awakeAfterWakeMinutes);
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
