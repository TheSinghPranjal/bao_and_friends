import 'package:flutter/material.dart';

/// Identifiers for scheduled Bao habits (home rings + settings).
enum ActivityId {
  drink,
  play,
  feed,
  wake,
  makeBed,
  brushTeeth,
  washFace,
  learn,
}

extension ActivityIdX on ActivityId {
  String get prefsKey => name;

  String get label => switch (this) {
        ActivityId.drink => 'Drink Water',
        ActivityId.play => 'Play',
        ActivityId.feed => 'Feed',
        ActivityId.wake => 'Sleep / Wake',
        ActivityId.makeBed => 'Make Bed',
        ActivityId.brushTeeth => 'Brush Teeth',
        ActivityId.washFace => 'Wash Face',
        ActivityId.learn => 'Learn',
      };

  String get groupLabel => switch (this) {
        ActivityId.drink => 'Drink',
        ActivityId.play => 'Play',
        ActivityId.feed => 'Feed',
        ActivityId.wake => 'Wake Up',
        ActivityId.makeBed ||
        ActivityId.brushTeeth ||
        ActivityId.washFace =>
          'Chores',
        ActivityId.learn => 'Learn',
      };

  /// Home bottom-sheet route this activity maps to (null = no ring).
  String? get homeRoute => switch (this) {
        ActivityId.drink => '/drink',
        ActivityId.play => '/play',
        ActivityId.feed => '/feed',
        ActivityId.wake => '/wake-up',
        ActivityId.makeBed ||
        ActivityId.brushTeeth ||
        ActivityId.washFace =>
          '/chores',
        ActivityId.learn => '/learn',
      };

  IconData get icon => switch (this) {
        ActivityId.drink => Icons.water_drop_rounded,
        ActivityId.play => Icons.sports_esports_rounded,
        ActivityId.feed => Icons.restaurant_rounded,
        ActivityId.wake => Icons.wb_twilight_rounded,
        ActivityId.makeBed => Icons.bed_rounded,
        ActivityId.brushTeeth => Icons.brush_rounded,
        ActivityId.washFace => Icons.soap_rounded,
        ActivityId.learn => Icons.menu_book_rounded,
      };

  Color get accent => switch (this) {
        ActivityId.drink => const Color(0xFF4DB8E8),
        ActivityId.play => const Color(0xFFF5C542),
        ActivityId.feed => const Color(0xFFF5A88A),
        ActivityId.wake => const Color(0xFFB39DDB),
        ActivityId.makeBed => const Color(0xFF7CB342),
        ActivityId.brushTeeth => const Color(0xFF00ACC1),
        ActivityId.washFace => const Color(0xFF1E88E5),
        ActivityId.learn => const Color(0xFF7EC8E8),
      };
}

/// Minutes from midnight (0–1439).
typedef MinuteOfDay = int;

MinuteOfDay minuteOfDay(TimeOfDay t) => t.hour * 60 + t.minute;

TimeOfDay timeFromMinutes(MinuteOfDay m) {
  final clamped = m.clamp(0, 24 * 60 - 1);
  return TimeOfDay(hour: clamped ~/ 60, minute: clamped % 60);
}

String formatMinutes(MinuteOfDay m) {
  final t = timeFromMinutes(m);
  final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
  final mm = t.minute.toString().padLeft(2, '0');
  final period = t.period == DayPeriod.am ? 'AM' : 'PM';
  return '$h:$mm $period';
}

/// Default reset / cue times for each activity.
abstract final class DefaultSchedules {
  /// Drink: 6am, 10am, 2pm, 6pm, 10pm
  static const drink = <MinuteOfDay>[6 * 60, 10 * 60, 14 * 60, 18 * 60, 22 * 60];

  /// Play: 8am, 10am, 4pm, 6pm, 8pm
  static const play = <MinuteOfDay>[8 * 60, 10 * 60, 16 * 60, 18 * 60, 20 * 60];

  /// Feed: 8am, 10am, 2pm, 4pm, 8pm
  static const feed = <MinuteOfDay>[8 * 60, 10 * 60, 14 * 60, 16 * 60, 20 * 60];

  /// Make bed: 6am, 2pm (before nap), 10pm (before night sleep)
  static const makeBed = <MinuteOfDay>[6 * 60, 14 * 60, 22 * 60];

  /// Brush teeth: 7am, 9pm
  static const brushTeeth = <MinuteOfDay>[7 * 60, 21 * 60];

  /// Wash face: 7am, 9pm
  static const washFace = <MinuteOfDay>[7 * 60, 21 * 60];

  /// Night sleep start / end and noon nap start (wake uses these).
  static const nightSleepStart = 22 * 60; // 10pm
  static const nightSleepEnd = 6 * 60; // 6am
  static const noonNapStart = 14 * 60 + 30; // 2:30pm
  static const noonNapMinutes = 30; // nap until 3:00pm

  /// How long Bao stays awake after a wake-up during noon nap.
  static const awakeAfterWakeMinutes = 60;

  /// How long Bao stays awake after a wake-up during night (10pm–6am).
  static const awakeAfterNightWakeMinutes = 30;

  static List<MinuteOfDay> defaultsFor(ActivityId id) => switch (id) {
        ActivityId.drink => List.of(drink),
        ActivityId.play => List.of(play),
        ActivityId.feed => List.of(feed),
        ActivityId.makeBed => List.of(makeBed),
        ActivityId.brushTeeth => List.of(brushTeeth),
        ActivityId.washFace => List.of(washFace),
        ActivityId.wake => [
            nightSleepStart,
            nightSleepEnd,
            noonNapStart,
          ],
        ActivityId.learn => const [],
      };

  /// Activities parents can edit in Settings.
  static const editable = <ActivityId>[
    ActivityId.drink,
    ActivityId.play,
    ActivityId.feed,
    ActivityId.wake,
    ActivityId.makeBed,
    ActivityId.brushTeeth,
    ActivityId.washFace,
  ];
}

/// Snapshot of one activity's timer for UI rings.
class ActivityTimerStatus {
  const ActivityTimerStatus({
    required this.id,
    required this.progress,
    required this.isDue,
    required this.nextAt,
    required this.windowStart,
  });

  final ActivityId id;

  /// 1 = just satisfied / plenty of time; 0 = due / overdue.
  final double progress;
  final bool isDue;
  final DateTime? nextAt;
  final DateTime? windowStart;

  static ActivityTimerStatus idle(ActivityId id) => ActivityTimerStatus(
        id: id,
        progress: 1,
        isDue: false,
        nextAt: null,
        windowStart: null,
      );
}
