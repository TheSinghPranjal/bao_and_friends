import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/activity_schedule.dart';
import '../models/feed_foods.dart';

/// Per-food Feed schedules + daily due badge counts (Play-style).
///
/// Due count = scheduled slots that have passed today − feeds completed today.
/// One bubble always; badge shows how many due taps remain.
class FeedDueStore {
  FeedDueStore._();

  static const _timesPrefix = 'feed_food_times_';
  static const _donePrefix = 'feed_food_done_';

  /// Stars for clearing one due slot.
  static const starsDue = 100;

  /// Stars for a voluntary feed when nothing is due.
  static const starsBonus = 20;

  static Future<SharedPreferences> get _prefs =>
      SharedPreferences.getInstance();

  static String _dayKey(DateTime t) =>
      '${t.year.toString().padLeft(4, '0')}'
      '${t.month.toString().padLeft(2, '0')}'
      '${t.day.toString().padLeft(2, '0')}';

  /// Staggered 4× slots between 6am–10pm, unique per food.
  static List<MinuteOfDay> defaultTimesFor(String foodId) {
    return switch (foodId) {
      'milk' => const [6 * 60, 11 * 60, 16 * 60, 21 * 60],
      'apple' => const [6 * 60 + 15, 11 * 60 + 15, 16 * 60 + 15, 21 * 60 + 15],
      'banana' => const [6 * 60 + 30, 11 * 60 + 30, 16 * 60 + 30, 21 * 60 + 30],
      'rice' => const [6 * 60 + 45, 11 * 60 + 45, 16 * 60 + 45, 21 * 60 + 45],
      'veggies' => const [7 * 60, 12 * 60, 17 * 60, 22 * 60],
      'sandwich' => const [7 * 60 + 15, 12 * 60 + 15, 17 * 60 + 15, 21 * 60 + 50],
      _ => const [6 * 60, 11 * 60, 16 * 60, 21 * 60],
    };
  }

  static Future<List<MinuteOfDay>> timesFor(String foodId) async {
    final prefs = await _prefs;
    final raw = prefs.getString('$_timesPrefix$foodId');
    if (raw == null || raw.isEmpty) return defaultTimesFor(foodId);
    try {
      final list = (jsonDecode(raw) as List<dynamic>)
          .map((e) => (e as num).toInt())
          .toList()
        ..sort();
      if (list.isEmpty) return defaultTimesFor(foodId);
      return list;
    } catch (_) {
      return defaultTimesFor(foodId);
    }
  }

  static Future<void> setTimes(String foodId, List<MinuteOfDay> times) async {
    final prefs = await _prefs;
    final cleaned = times.map((m) => m.clamp(0, 24 * 60 - 1)).toSet().toList()
      ..sort();
    await prefs.setString('$_timesPrefix$foodId', jsonEncode(cleaned));
  }

  static Future<void> resetTimes(String foodId) async {
    final prefs = await _prefs;
    await prefs.remove('$_timesPrefix$foodId');
  }

  static Future<int> completionsToday(String foodId, [DateTime? now]) async {
    final t = now ?? DateTime.now();
    final prefs = await _prefs;
    return prefs.getInt('$_donePrefix${foodId}_${_dayKey(t)}') ?? 0;
  }

  static Future<void> _setCompletionsToday(
    String foodId,
    int count, [
    DateTime? now,
  ]) async {
    final t = now ?? DateTime.now();
    final prefs = await _prefs;
    await prefs.setInt(
      '$_donePrefix${foodId}_${_dayKey(t)}',
      count.clamp(0, 99),
    );
  }

  static Future<int> passedSlotsToday(String foodId, [DateTime? now]) async {
    final t = now ?? DateTime.now();
    final minutes = t.hour * 60 + t.minute;
    final slots = await timesFor(foodId);
    return slots.where((s) => s <= minutes).length;
  }

  static Future<int> dueCount(String foodId, [DateTime? now]) async {
    final t = now ?? DateTime.now();
    final passed = await passedSlotsToday(foodId, t);
    final done = await completionsToday(foodId, t);
    return (passed - done).clamp(0, 99);
  }

  static Future<bool> isDue(String foodId, [DateTime? now]) async =>
      (await dueCount(foodId, now)) > 0;

  static Future<int> totalFeedDue([DateTime? now]) async {
    var sum = 0;
    for (final food in FeedFoods.all) {
      sum += await dueCount(food.id, now);
    }
    return sum;
  }

  static Future<FeedTapResult> completeOneFeed(
    String foodId, [
    DateTime? now,
  ]) async {
    final t = now ?? DateTime.now();
    final due = await dueCount(foodId, t);
    final done = await completionsToday(foodId, t);
    await _setCompletionsToday(foodId, done + 1, t);
    final wasDue = due > 0;
    return FeedTapResult(
      wasDue: wasDue,
      stars: wasDue ? starsDue : starsBonus,
      remainingDue: wasDue ? due - 1 : 0,
    );
  }
}

class FeedTapResult {
  const FeedTapResult({
    required this.wasDue,
    required this.stars,
    required this.remainingDue,
  });

  final bool wasDue;
  final int stars;
  final int remainingDue;
}
