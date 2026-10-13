import 'package:flutter/material.dart';
import 'package:mizan/core/theme/app_colors.dart';

/// A labelled horizontal bar showing progress toward a limit.
class MeterRow extends StatelessWidget {
  const MeterRow({
    required this.label,
    required this.value,
    required this.fraction,
    required this.color,
    super.key,
  });

  final String label;

  /// The figures behind the bar, such as `45 / 120 g`.
  final String value;

  /// How full the bar is, from 0 to 1; larger values show as full. Null
  /// leaves the bar empty because there is no limit to measure against.
  final double? fraction;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.bodySmall;
    final fill = (fraction ?? 0).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: style?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              Text(value, style: style),
            ],
          ),
          const SizedBox(height: 3),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: SizedBox(
              height: 6,
              child: ColoredBox(
                color: AppColors.chartTrack,
                child: FractionallySizedBox(
                  alignment: AlignmentDirectional.centerStart,
                  widthFactor: fill,
                  child: ColoredBox(color: color),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
