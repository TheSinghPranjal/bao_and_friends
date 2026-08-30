import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/activity_schedule.dart';
import '../../models/play_games.dart';
import '../../services/play_due_store.dart';
import '../../services/schedule_store.dart';
import '../../theme/tt_colors.dart';
import '../../theme/tt_typography.dart';
import '../../widgets/back_button_circle.dart';
import '../../widgets/bounce_button.dart';

/// Parent settings — edit reset times for Drink, Play games, Feed, Sleep, Chores.
class ActivityTimersSettingsScreen extends StatefulWidget {
  const ActivityTimersSettingsScreen({super.key});

  @override
  State<ActivityTimersSettingsScreen> createState() =>
      _ActivityTimersSettingsScreenState();
}

class _ActivityTimersSettingsScreenState
    extends State<ActivityTimersSettingsScreen> {
  final Map<ActivityId, List<MinuteOfDay>> _times = {};
  final Map<String, List<MinuteOfDay>> _playTimes = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final map = <ActivityId, List<MinuteOfDay>>{};
    for (final id in DefaultSchedules.editable) {
      if (id == ActivityId.play) continue; // per-game below
      map[id] = await ScheduleStore.timesFor(id);
    }
    final play = <String, List<MinuteOfDay>>{};
    for (final game in PlayGames.all) {
      play[game.id] = await PlayDueStore.timesFor(game.id);
    }
    if (!mounted) return;
    setState(() {
      _times
        ..clear()
        ..addAll(map);
      _playTimes
        ..clear()
        ..addAll(play);
      _loading = false;
    });
  }

  Future<void> _pickAdd(ActivityId id) async {
    if (id == ActivityId.wake) return;
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 8, minute: 0),
      helpText: 'Add time for ${id.label}',
    );
    if (picked == null || !mounted) return;
    final next = [...?_times[id], minuteOfDay(picked)]..sort();
    await ScheduleStore.setTimes(id, next);
    setState(() => _times[id] = next);
  }

  Future<void> _editAt(ActivityId id, int index) async {
    final current = _times[id]![index];
    final labels = id == ActivityId.wake
        ? const ['Night sleep start', 'Morning wake', 'Noon nap']
        : null;
    final picked = await showTimePicker(
      context: context,
      initialTime: timeFromMinutes(current),
      helpText: labels != null
          ? labels[index.clamp(0, labels.length - 1)]
          : 'Edit time for ${id.label}',
    );
    if (picked == null || !mounted) return;
    final next = [..._times[id]!];
    next[index] = minuteOfDay(picked);
    if (id != ActivityId.wake) next.sort();
    await ScheduleStore.setTimes(id, next);
    setState(() => _times[id] = next);
  }

  Future<void> _removeAt(ActivityId id, int index) async {
    if (id == ActivityId.wake) return;
    final next = [..._times[id]!]..removeAt(index);
    if (next.isEmpty) {
      await ScheduleStore.resetTimes(id);
      final restored = await ScheduleStore.timesFor(id);
      setState(() => _times[id] = restored);
      return;
    }
    await ScheduleStore.setTimes(id, next);
    setState(() => _times[id] = next);
  }

  Future<void> _reset(ActivityId id) async {
    await ScheduleStore.resetTimes(id);
    final restored = await ScheduleStore.timesFor(id);
    setState(() => _times[id] = restored);
  }

  Future<void> _pickAddPlay(String gameId, String label) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 7, minute: 0),
      helpText: 'Add time for $label',
    );
    if (picked == null || !mounted) return;
    final next = [...?_playTimes[gameId], minuteOfDay(picked)]..sort();
    await PlayDueStore.setTimes(gameId, next);
    setState(() => _playTimes[gameId] = next);
  }

  Future<void> _editPlay(String gameId, String label, int index) async {
    final current = _playTimes[gameId]![index];
    final picked = await showTimePicker(
      context: context,
      initialTime: timeFromMinutes(current),
      helpText: 'Edit time for $label',
    );
    if (picked == null || !mounted) return;
    final next = [..._playTimes[gameId]!];
    next[index] = minuteOfDay(picked);
    next.sort();
    await PlayDueStore.setTimes(gameId, next);
    setState(() => _playTimes[gameId] = next);
  }

  Future<void> _removePlay(String gameId, int index) async {
    final next = [..._playTimes[gameId]!]..removeAt(index);
    if (next.isEmpty) {
      await PlayDueStore.resetTimes(gameId);
      final restored = await PlayDueStore.timesFor(gameId);
      setState(() => _playTimes[gameId] = restored);
      return;
    }
    await PlayDueStore.setTimes(gameId, next);
    setState(() => _playTimes[gameId] = next);
  }

  Future<void> _resetPlay(String gameId) async {
    await PlayDueStore.resetTimes(gameId);
    final restored = await PlayDueStore.timesFor(gameId);
    setState(() => _playTimes[gameId] = restored);
  }

  @override
  Widget build(BuildContext context) {
    final habitIds = DefaultSchedules.editable
        .where((id) => id != ActivityId.play)
        .toList();

    return Scaffold(
      backgroundColor: TTColors.cream,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  TtBackButton(onPressed: () => context.pop()),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Activity Timers',
                      style: TTTypography.headline(),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Set when Bao gets thirsty, hungry, wants to play, sleeps, and does chores. Play games use due badges (missed slots today).',
                style: TTTypography.subtitle(),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Text('Habits', style: TTTypography.title()),
                        const SizedBox(height: 8),
                        for (final id in habitIds) ...[
                          _ActivityTimesCard(
                            title: id.label,
                            subtitle: id.groupLabel,
                            icon: id.icon,
                            accent: id.accent,
                            times: _times[id] ?? const [],
                            wakeMode: id == ActivityId.wake,
                            onAdd: () => unawaited(_pickAdd(id)),
                            onEdit: (i) => unawaited(_editAt(id, i)),
                            onRemove: (i) => unawaited(_removeAt(id, i)),
                            onReset: () => unawaited(_reset(id)),
                          ),
                          const SizedBox(height: 12),
                        ],
                        const SizedBox(height: 8),
                        Text('Play games', style: TTTypography.title()),
                        const SizedBox(height: 4),
                        Text(
                          'Default: 7am · 9am · 5pm · 7pm. Badge = missed slots today.',
                          style: TTTypography.caption(),
                        ),
                        const SizedBox(height: 8),
                        for (final game in PlayGames.all) ...[
                          _ActivityTimesCard(
                            title: game.label,
                            subtitle: 'Play',
                            icon: game.icon,
                            accent: game.accent,
                            times: _playTimes[game.id] ?? const [],
                            onAdd: () => unawaited(
                              _pickAddPlay(game.id, game.label),
                            ),
                            onEdit: (i) => unawaited(
                              _editPlay(game.id, game.label, i),
                            ),
                            onRemove: (i) =>
                                unawaited(_removePlay(game.id, i)),
                            onReset: () => unawaited(_resetPlay(game.id)),
                          ),
                          const SizedBox(height: 12),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityTimesCard extends StatelessWidget {
  const _ActivityTimesCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.times,
    required this.onAdd,
    required this.onEdit,
    required this.onRemove,
    required this.onReset,
    this.wakeMode = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final List<MinuteOfDay> times;
  final VoidCallback onAdd;
  final ValueChanged<int> onEdit;
  final ValueChanged<int> onRemove;
  final VoidCallback onReset;
  final bool wakeMode;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TTColors.creamWhite,
        borderRadius: BorderRadius.circular(TTSpacing.radiusMd),
        boxShadow: TTShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent.withValues(alpha: 0.25),
                ),
                child: Icon(icon, color: TTColors.darkBrown, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TTTypography.body()),
                    Text(subtitle, style: TTTypography.caption()),
                  ],
                ),
              ),
              TextButton(
                onPressed: onReset,
                child: Text(
                  'Reset',
                  style: TTTypography.caption(color: TTColors.skyDeep),
                ),
              ),
            ],
          ),
          if (wakeMode) ...[
            const SizedBox(height: 6),
            Text(
              'Night sleep start · Morning wake · Noon nap',
              style: TTTypography.caption(),
            ),
          ],
          const SizedBox(height: 10),
          if (wakeMode)
            Column(
              children: [
                for (var i = 0; i < times.length; i++)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      const [
                        'Night sleep start',
                        'Morning wake',
                        'Noon nap',
                      ][i.clamp(0, 2)],
                      style: TTTypography.caption(color: TTColors.darkBrown),
                    ),
                    trailing: BounceButton(
                      onPressed: () => onEdit(i),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          formatMinutes(times[i]),
                          style: TTTypography.body(),
                        ),
                      ),
                    ),
                  ),
              ],
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var i = 0; i < times.length; i++)
                  InputChip(
                    label: Text(formatMinutes(times[i])),
                    onPressed: () => onEdit(i),
                    onDeleted: () => onRemove(i),
                    deleteIconColor: TTColors.softBrown,
                    backgroundColor: accent.withValues(alpha: 0.18),
                    labelStyle:
                        TTTypography.caption(color: TTColors.darkBrown),
                  ),
                ActionChip(
                  avatar: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Add'),
                  onPressed: onAdd,
                ),
              ],
            ),
        ],
      ),
    );
  }
}
