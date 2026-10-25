import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mizan/features/statistics/domain/stats_range.dart';
import 'package:mizan/features/statistics/presentation/statistics_providers.dart';

/// Chooses the range of days the statistics cover, and says how many of them
/// have food logged.
class RangeBar extends ConsumerWidget {
  const RangeBar({super.key});

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

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final preset in StatsPreset.values)
                ChoiceChip(
                  label: Text(_presetLabel(preset)),
                  // Compact so all four fit on one line on a phone.
                  showCheckmark: false,
                  visualDensity: VisualDensity.compact,
                  selected: range.preset == preset,
                  onSelected: (_) => preset == StatsPreset.custom
                      ? _pickCustom(context, ref)
                      : ref
                            .read(statsRangeProvider.notifier)
                            .selectPreset(preset),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            logged == null
                ? span
                : '$span · $logged of $count '
                      '${count == 1 ? 'day' : 'days'} logged',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

String _presetLabel(StatsPreset preset) => switch (preset) {
  StatsPreset.today => 'Today',
  StatsPreset.lastWeek => '7 days',
  StatsPreset.lastMonth => '30 days',
  StatsPreset.custom => 'Custom',
};
