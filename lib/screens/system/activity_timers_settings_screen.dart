import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/activity_schedule.dart';
import '../../services/schedule_store.dart';
import '../../theme/tt_colors.dart';
import '../../theme/tt_typography.dart';
import '../../widgets/back_button_circle.dart';
import '../../widgets/bounce_button.dart';

/// Parent settings — edit reset times for Drink, Play, Feed, Sleep, Chores.
class ActivityTimersSettingsScreen extends StatefulWidget {
  const ActivityTimersSettingsScreen({super.key});

  @override
  State<ActivityTimersSettingsScreen> createState() =>
      _ActivityTimersSettingsScreenState();
}

class _ActivityTimersSettingsScreenState
    extends State<ActivityTimersSettingsScreen> {
  final Map<ActivityId, List<MinuteOfDay>> _times = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final map = <ActivityId, List<MinuteOfDay>>{};
    for (final id in DefaultSchedules.editable) {
      map[id] = await ScheduleStore.timesFor(id);
    }
    if (!mounted) return;
    setState(() {
      _times
        ..clear()
        ..addAll(map);
      _loading = false;
    });
  }

  Future<void> _pickAdd(ActivityId id) async {
    if (id == ActivityId.wake) return; // fixed 3 labeled slots
    final initial = const TimeOfDay(hour: 8, minute: 0);
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
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
    if (id == ActivityId.wake) return; // keep 3 sleep slots
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

  String _wakeHint(ActivityId id) {
    if (id != ActivityId.wake) return '';
    return 'Order: night sleep start · morning wake · noon nap start';
  }

  @override
  Widget build(BuildContext context) {
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
                'Set when Bao gets thirsty, hungry, wants to play, sleeps, and does chores. Circular timers on Home follow these times.',
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
                        for (final id in DefaultSchedules.editable) ...[
                          _ActivityTimesCard(
                            id: id,
                            times: _times[id] ?? const [],
                            hint: _wakeHint(id),
                            onAdd: () => unawaited(_pickAdd(id)),
                            onEdit: (i) => unawaited(_editAt(id, i)),
                            onRemove: (i) => unawaited(_removeAt(id, i)),
                            onReset: () => unawaited(_reset(id)),
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
    required this.id,
    required this.times,
    required this.onAdd,
    required this.onEdit,
    required this.onRemove,
    required this.onReset,
    this.hint = '',
  });

  final ActivityId id;
  final List<MinuteOfDay> times;
  final VoidCallback onAdd;
  final ValueChanged<int> onEdit;
  final ValueChanged<int> onRemove;
  final VoidCallback onReset;
  final String hint;

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
                  color: id.accent.withValues(alpha: 0.25),
                ),
                child: Icon(id.icon, color: TTColors.darkBrown, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(id.label, style: TTTypography.body()),
                    Text(id.groupLabel, style: TTTypography.caption()),
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
          if (hint.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(hint, style: TTTypography.caption()),
          ],
          const SizedBox(height: 10),
          if (id == ActivityId.wake)
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
                          color: id.accent.withValues(alpha: 0.18),
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
                    backgroundColor: id.accent.withValues(alpha: 0.18),
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
