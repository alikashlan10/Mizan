import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mizan/features/backup/data/backup_repository.dart';
import 'package:mizan/features/backup/domain/backup_summary.dart';

/// Saves everything the user entered to a file, and restores from one.
class BackupScreen extends ConsumerStatefulWidget {
  const BackupScreen({super.key});

  @override
  ConsumerState<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends ConsumerState<BackupScreen> {
  bool _busy = false;

  Future<void> _export() async {
    await _run(() async {
      final json = await ref.read(backupRepositoryProvider).exportJson();
      final day = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final saved = await FilePicker.saveFile(
        fileName: 'mizan-backup-$day.json',
        bytes: Uint8List.fromList(utf8.encode(json)),
        mimeType: 'application/json',
        dialogTitle: 'Save backup',
      );
      if (saved != null) _show('Backup saved.');
    });
  }

  Future<void> _restore() async {
    final files = await FilePicker.pickFiles(
      dialogTitle: 'Choose a backup',
      type: FileType.custom,
      allowedExtensions: const ['json'],
    );
    if (files.isEmpty || !mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Replace your data?'),
        content: const Text(
          'Your diary, custom foods, meals, profile and settings will be '
          'replaced by the ones in this backup.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Replace'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await _run(() async {
      final json = utf8.decode(await files.single.readAsBytes());
      final summary = await ref.read(backupRepositoryProvider).importJson(json);
      _show(_describe(summary));
    });
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } on BackupFormatException catch (e) {
      _show(e.message);
    } on FormatException {
      _show('This file is not a Mizan backup.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _show(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  String _describe(BackupSummary s) {
    String count(int n, String one, String many) => '$n ${n == 1 ? one : many}';
    final restored =
        'Restored ${count(s.diaryEntries, 'diary entry', 'diary entries')} '
        'and ${count(s.foods, 'custom food or meal', 'custom foods and meals')}.';
    return s.skipped == 0
        ? restored
        : '$restored ${count(s.skipped, 'item uses', 'items use')} a food '
              'this app does not have and was left out.';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Backup'),
        bottom: _busy
            ? const PreferredSize(
                preferredSize: Size.fromHeight(4),
                child: LinearProgressIndicator(),
              )
            : null,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Text(
              'Mizan keeps your data only on this device. Save a backup to '
              'keep it safe or to move it to another device.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.file_upload_outlined),
            title: const Text('Save a backup'),
            subtitle: const Text(
              'Diary, water, exercise, custom foods, meals, profile and '
              'settings, in one file',
            ),
            enabled: !_busy,
            onTap: _export,
          ),
          ListTile(
            leading: const Icon(Icons.file_download_outlined),
            title: const Text('Restore from a backup'),
            subtitle: const Text('Replaces what is on this device'),
            enabled: !_busy,
            onTap: _restore,
          ),
        ],
      ),
    );
  }
}
