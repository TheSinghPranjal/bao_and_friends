import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/activity_schedule.dart';
import '../models/play_games.dart';

/// Per-game Play schedules + daily due badge counts.
///
/// Due count = scheduled slots that have passed today − plays completed today.
/// One icon always; badge shows how many due taps remain.
class PlayDueStore {
  PlayDueStore._();

  static const _timesPrefix = 'play_game_times_';
  static const _donePrefix = 'play_game_done_';

  /// Stars for clearing one due slot.
  static const starsDue = 100;

  /// Stars for a voluntary play when nothing is due.
  static const starsBonus = 20;

  static Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  static String _dayKey(DateTime t) =>
      '${t.year.toString().padLeft(4, '0')}'
      '${t.month.toString().padLeft(2, '0')}'
      '${t.day.toString().padLeft(2, '0')}';

  /// Default cue times — football: 7am, 9am, 5pm, 7pm; others match for now.
  static List<MinuteOfDay> defaultTimesFor(String gameId) {
    // Same pattern for every play game so settings can customize each.
    return const <MinuteOfDay>[
      7 * 60, // 7am
      9 * 60, // 9am
      17 * 60, // 5pm
      19 * 60, // 7pm
    ];
  }

  static Future<List<MinuteOfDay>> timesFor(String gameId) async {
    final prefs = await _prefs;
    final raw = prefs.getString('$_timesPrefix$gameId');
    if (raw == null || raw.isEmpty) return defaultTimesFor(gameId);
    try {
      final list = (jsonDecode(raw) as List<dynamic>)
          .map((e) => (e as num).toInt())
          .toList()
        ..sort();
      if (list.isEmpty) return defaultTimesFor(gameId);
      return list;
    } catch (_) {
      return defaultTimesFor(gameId);
    }
  }

  static Future<void> setTimes(String gameId, List<MinuteOfDay> times) async {
    final prefs = await _prefs;
    final cleaned = times.map((m) => m.clamp(0, 24 * 60 - 1)).toSet().toList()
      ..sort();
    await prefs.setString('$_timesPrefix$gameId', jsonEncode(cleaned));
  }

  static Future<void> resetTimes(String gameId) async {
    final prefs = await _prefs;
    await prefs.remove('$_timesPrefix$gameId');
  }

  static Future<int> completionsToday(String gameId, [DateTime? now]) async {
    final t = now ?? DateTime.now();
    final prefs = await _prefs;
    return prefs.getInt('$_donePrefix${gameId}_${_dayKey(t)}') ?? 0;
  }

  static Future<void> _setCompletionsToday(
    String gameId,
    int count, [
    DateTime? now,
  ]) async {
    final t = now ?? DateTime.now();
    final prefs = await _prefs;
    await prefs.setInt(
      '$_donePrefix${gameId}_${_dayKey(t)}',
      count.clamp(0, 99),
    );
  }

  /// Slots whose clock time has already passed today.
  static Future<int> passedSlotsToday(String gameId, [DateTime? now]) async {
    final t = now ?? DateTime.now();
    final minutes = t.hour * 60 + t.minute;
    final slots = await timesFor(gameId);
    return slots.where((s) => s <= minutes).length;
  }

  /// Missed / still-due plays for [gameId] today (badge number).
  static Future<int> dueCount(String gameId, [DateTime? now]) async {
    final t = now ?? DateTime.now();
    final passed = await passedSlotsToday(gameId, t);
    final done = await completionsToday(gameId, t);
    return (passed - done).clamp(0, 99);
  }

  static Future<bool> isDue(String gameId, [DateTime? now]) async =>
      (await dueCount(gameId, now)) > 0;

  static Future<bool> anyPlayDue([DateTime? now]) async {
    for (final game in PlayGames.all) {
      if (await isDue(game.id, now)) return true;
    }
    return false;
  }

  static Future<int> totalPlayDue([DateTime? now]) async {
    var sum = 0;
    for (final game in PlayGames.all) {
      sum += await dueCount(game.id, now);
    }
    return sum;
  }

  /// Result of one bubble tap.
  static Future<PlayTapResult> completeOnePlay(
    String gameId, [
    DateTime? now,
  ]) async {
    final t = now ?? DateTime.now();
    final due = await dueCount(gameId, t);
    final done = await completionsToday(gameId, t);
    await _setCompletionsToday(gameId, done + 1, t);
    final wasDue = due > 0;
    return PlayTapResult(
      wasDue: wasDue,
      stars: wasDue ? starsDue : starsBonus,
      remainingDue: wasDue ? due - 1 : 0,
    );
  }
}

class PlayTapResult {
  const PlayTapResult({
    required this.wasDue,
    required this.stars,
    required this.remainingDue,
  });

  final bool wasDue;
  final int stars;
  final int remainingDue;
}
