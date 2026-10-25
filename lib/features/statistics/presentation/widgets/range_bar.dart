import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mizan/features/statistics/domain/stats_range.dart';
import 'package:mizan/features/statistics/presentation/statistics_providers.dart';

/// Shows the range the statistics cover and how many of its days have food
/// logged; tapping it opens the list of ranges to choose from.
class RangeBar extends ConsumerWidget {
  const RangeBar({super.key});

  Future<void> _choose(BuildContext context, WidgetRef ref) async {
    final current = ref.read(statsRangeProvider).preset;
    final preset = await showModalBottomSheet<StatsPreset>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final p in StatsPreset.values)
              ListTile(
                title: Text(_presetLabel(p)),
                selected: p == current,
                trailing: p == current ? const Icon(Icons.check) : null,
                // Choosing custom again reopens the calendar.
                onTap: () => Navigator.of(context).pop(p),
              ),
          ],
        ),
      ),
    );
    if (preset == null || !context.mounted) return;
    if (preset == StatsPreset.custom) {
      await _pickCustom(context, ref);
    } else {
      ref.read(statsRangeProvider.notifier).selectPreset(preset);
    }
  }

  Future<void> _pickCustom(BuildContext context, WidgetRef ref) async {
    final range = ref.read(statsRangeProvider);
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDateRange: DateTimeRange(start: range.start, end: range.end),
    );
    if (picked != null) {
      ref
          .read(statsRangeProvider.notifier)
          .selectCustom(picked.start, picked.end);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final range = ref.watch(statsRangeProvider);
    final logged = ref.watch(rangeStatsProvider)?.loggedDays.length;
    final dates = DateFormat.MMMd();
    final span = range.isSingleDay
        ? DateFormat.yMMMEd().format(range.start)
        : '${dates.format(range.start)} – ${dates.format(range.end)}';
    final count = range.days.length;

    return Material(
      color: Colors.transparent,
      child: ListTile(
        onTap: () => _choose(context, ref),
        leading: const Icon(Icons.date_range),
        title: Text(_presetLabel(range.preset)),
        subtitle: Text(
          logged == null
              ? span
              : '$span · $logged of $count '
                    '${count == 1 ? 'day' : 'days'} logged',
        ),
        subtitleTextStyle: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
        trailing: const Icon(Icons.expand_more),
      ),
    );
  }
}

String _presetLabel(StatsPreset preset) => switch (preset) {
  StatsPreset.today => 'Today',
  StatsPreset.lastWeek => 'Last 7 days',
  StatsPreset.lastMonth => 'Last 30 days',
  StatsPreset.custom => 'Custom range',
};
