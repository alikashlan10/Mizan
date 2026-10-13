import 'package:flutter/material.dart';

/// A titled block of the diary: a header with a summary and an add button,
/// followed by its entries.
class DiarySection extends StatelessWidget {
  const DiarySection({
    required this.title,
    required this.summary,
    required this.addTooltip,
    required this.onAdd,
    required this.children,
    super.key,
  });

  final String title;
  final String summary;
  final String addTooltip;
  final VoidCallback onAdd;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, right: 4),
          child: Row(
            children: [
              Expanded(child: Text(title, style: theme.textTheme.titleMedium)),
              Text(
                summary,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add),
                tooltip: addTooltip,
                onPressed: onAdd,
              ),
            ],
          ),
        ),
        ...children,
        const Divider(height: 1),
      ],
    );
  }
}

/// One entry in a [DiarySection]; swipe left to delete.
class DiaryEntryTile extends StatelessWidget {
  const DiaryEntryTile({
    required this.entryKey,
    required this.title,
    required this.onDelete,
    this.subtitle,
    this.trailing,
    super.key,
  });

  /// Identifies the entry among its siblings.
  final Object entryKey;
  final String title;
  final String? subtitle;
  final String? trailing;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dismissible(
      key: ValueKey(entryKey),
      direction: DismissDirection.endToStart,
      background: Container(
        color: theme.colorScheme.errorContainer,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: Icon(Icons.delete, color: theme.colorScheme.onErrorContainer),
      ),
      onDismissed: (_) => onDelete(),
      child: ListTile(
        dense: true,
        title: Text(title),
        subtitle: subtitle == null ? null : Text(subtitle!),
        trailing: trailing == null
            ? null
            : Text(trailing!, style: theme.textTheme.bodyMedium),
      ),
    );
  }
}
