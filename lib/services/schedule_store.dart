import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/activity_schedule.dart';
import 'play_due_store.dart';

/// Persists custom schedule times + last completion per [ActivityId].
class ScheduleStore {
  ScheduleStore._();

  static const _timesPrefix = 'schedule_times_';
  static const _donePrefix = 'schedule_done_';

  static Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  // ---- Custom times ----

  static Future<List<MinuteOfDay>> timesFor(ActivityId id) async {
    final prefs = await _prefs;
    final raw = prefs.getString('$_timesPrefix${id.prefsKey}');
    if (raw == null || raw.isEmpty) {
      return DefaultSchedules.defaultsFor(id);
    }
    try {
      final list = (jsonDecode(raw) as List<dynamic>)
          .map((e) => (e as num).toInt())
          .toList();
      if (list.isEmpty) return DefaultSchedules.defaultsFor(id);
      if (id != ActivityId.wake) {
        list.sort();
      }
      return list;
    } catch (_) {
      return DefaultSchedules.defaultsFor(id);
    }
  }

  static Future<void> setTimes(ActivityId id, List<MinuteOfDay> times) async {
    final prefs = await _prefs;
    List<int> cleaned;
    if (id == ActivityId.wake) {
      // Fixed semantics: [nightStart, morningWake, noonNap] — do not sort.
      cleaned = times.map((m) => m.clamp(0, 24 * 60 - 1)).toList();
      while (cleaned.length < 3) {
        cleaned.add(DefaultSchedules.defaultsFor(id)[cleaned.length]);
      }
      if (cleaned.length > 3) cleaned = cleaned.sublist(0, 3);
    } else {
      cleaned = times.map((m) => m.clamp(0, 24 * 60 - 1)).toSet().toList()
        ..sort();
    }
    await prefs.setString(
      '$_timesPrefix${id.prefsKey}',
      jsonEncode(cleaned),
    );
  }

  static Future<void> resetTimes(ActivityId id) async {
    final prefs = await _prefs;
    await prefs.remove('$_timesPrefix${id.prefsKey}');
  }

  // ---- Completions ----

  static Future<DateTime?> lastCompleted(ActivityId id) async {
    final prefs = await _prefs;
    final ms = prefs.getInt('$_donePrefix${id.prefsKey}');
    if (ms == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }

  static Future<void> markCompleted(ActivityId id, [DateTime? at]) async {
    final prefs = await _prefs;
    await prefs.setInt(
      '$_donePrefix${id.prefsKey}',
      (at ?? DateTime.now()).millisecondsSinceEpoch,
    );
  }

  // ---- Window / due math ----

  /// Most recent scheduled slot ≤ [now] **today only**.
  /// Returns null before the first slot of the calendar day (fresh day = nothing due).
  static DateTime? currentWindowStartToday(
    List<MinuteOfDay> slots,
    DateTime now,
  ) {
    if (slots.isEmpty) return null;
    final minutes = now.hour * 60 + now.minute;
    MinuteOfDay? best;
    for (final s in slots) {
      if (s <= minutes) best = s;
    }
    if (best == null) return null;
    return DateTime(now.year, now.month, now.day, best ~/ 60, best % 60);
  }

  static DateTime nextSlotAfter(List<MinuteOfDay> slots, DateTime now) {
    if (slots.isEmpty) {
      return now.add(const Duration(hours: 4));
    }
    final minutes = now.hour * 60 + now.minute;
    for (final s in slots) {
      if (s > minutes) {
        return DateTime(now.year, now.month, now.day, s ~/ 60, s % 60);
      }
    }
    final first = slots.first;
    final tomorrow = now.add(const Duration(days: 1));
    return DateTime(
      tomorrow.year,
      tomorrow.month,
      tomorrow.day,
      first ~/ 60,
      first % 60,
    );
  }

  static Future<ActivityTimerStatus> statusFor(
    ActivityId id, {
    DateTime? now,
  }) async {
    if (id == ActivityId.learn) {
      return ActivityTimerStatus.idle(id);
    }
    if (id == ActivityId.wake) {
      return _wakeStatus(now: now);
    }

    final t = now ?? DateTime.now();
    final slots = await timesFor(id);
    final next = nextSlotAfter(slots, t);
    final window = currentWindowStartToday(slots, t);

    // Brand-new calendar day (before first cue) → no due, no highlight.
    if (window == null) {
      return ActivityTimerStatus(
        id: id,
        progress: 1,
        isDue: false,
        nextAt: next,
        windowStart: null,
      );
    }

    final done = await lastCompleted(id);
    // Only completions at/after today's window count; yesterday does not carry over.
    final sameDayDone = done != null &&
        done.year == t.year &&
        done.month == t.month &&
        done.day == t.day &&
        !done.isBefore(window);
    final isDue = !sameDayDone;

    final span = next.difference(window).inSeconds.clamp(1, 48 * 3600);
    final remaining = next.difference(t).inSeconds.clamp(0, span);
    final progress = isDue ? 0.0 : (remaining / span).clamp(0.0, 1.0);

    return ActivityTimerStatus(
      id: id,
      progress: progress,
      isDue: isDue,
      nextAt: next,
      windowStart: window,
    );
  }

  /// Aggregate chores hub: most urgent (lowest progress / any due).
  static Future<ActivityTimerStatus> choresHubStatus({DateTime? now}) async {
    final ids = [
      ActivityId.makeBed,
      ActivityId.brushTeeth,
      ActivityId.washFace,
    ];
    ActivityTimerStatus? worst;
    for (final id in ids) {
      final s = await statusFor(id, now: now);
      if (worst == null ||
          (s.isDue && !worst.isDue) ||
          (s.isDue == worst.isDue && s.progress < worst.progress)) {
        worst = s;
      }
    }
    return ActivityTimerStatus(
      id: ActivityId.makeBed,
      progress: worst?.progress ?? 1,
      isDue: worst?.isDue ?? false,
      nextAt: worst?.nextAt,
      windowStart: worst?.windowStart,
    );
  }

  static Future<ActivityTimerStatus> _wakeStatus({DateTime? now}) async {
    // Wake ring mirrors sleep urgency — filled while sleeping (needs wake),
    // depleting while awake toward auto-sleep. Implemented via SleepStore.
    // Placeholder here; CharacterHome uses SleepStore for wake ring.
    return ActivityTimerStatus.idle(ActivityId.wake);
  }

  static Future<Map<String, ActivityTimerStatus>> homeStatuses({
    DateTime? now,
  }) async {
    final t = now ?? DateTime.now();
    final drink = await statusFor(ActivityId.drink, now: t);
    final feed = await statusFor(ActivityId.feed, now: t);
    final chores = await choresHubStatus(now: t);

    final playDue = await PlayDueStore.anyPlayDue(t);
    final play = ActivityTimerStatus(
      id: ActivityId.play,
      progress: playDue ? 0 : 1,
      isDue: playDue,
      nextAt: null,
      windowStart: t,
    );

    return {
      '/drink': drink,
      '/play': play,
      '/feed': feed,
      '/chores': chores,
      '/learn': ActivityTimerStatus.idle(ActivityId.learn),
    };
  }
}
