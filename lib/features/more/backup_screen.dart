import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../data/backup.dart';
import '../../ui/forms.dart';
import '../../ui/widgets.dart';

const lastBackupSetting = 'last_backup_at';

class BackupScreen extends ConsumerStatefulWidget {
  const BackupScreen({super.key});

  @override
  ConsumerState<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends ConsumerState<BackupScreen> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() task) async {
    setState(() => _busy = true);
    try {
      await task();
    } on BackupException catch (e) {
      if (mounted) showSnack(context, e.message);
    } catch (e) {
      if (mounted) showSnack(context, 'Something went wrong: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<(String, Uint8List)> _export() async {
    final now = DateTime.now();
    final bytes = await Backup.export(ref.read(databaseProvider), now: now);
    return (Backup.fileName(now), bytes);
  }

  Future<void> _markBackedUp() =>
      ref.read(repositoryProvider).setSetting(lastBackupSetting, DateTime.now().toIso8601String());

  Future<void> _saveToPhone() => _run(() async {
    final (name, bytes) = await _export();
    final uri = await FilePicker.saveFile(fileName: name, bytes: bytes);
    if (uri == null) return;
    await _markBackedUp();
    if (mounted) showSnack(context, 'Backup saved: $name');
  });

  Future<void> _share() => _run(() async {
    final (name, bytes) = await _export();
    final result = await SharePlus.instance.share(
      ShareParams(
        files: [XFile.fromData(bytes, name: name, mimeType: 'application/octet-stream')],
        fileNameOverrides: [name],
        subject: 'My Fin Tracker backup',
      ),
    );
    if (result.status == ShareResultStatus.success) await _markBackedUp();
  });

  Future<void> _restore() => _run(() async {
    final files = await FilePicker.pickFiles(dialogTitle: 'Choose a backup (.mft)');
    if (files.isEmpty) return;
    final contents = Backup.read(await files.single.readAsBytes());
    if (!mounted) return;
    final m = contents.manifest;
    final ok = await confirm(
      context,
      title: 'Replace all data with this backup?',
      body:
          'Backup from ${DateFormat.yMMMd().add_jm().format(m.createdAt)}\n'
          '${contents.count('entries')} entries · ${contents.count('accounts')} accounts · '
          '${contents.count('loans')} loans\n\n'
          'Everything now in the app will be replaced. Back up first if you are unsure.',
      action: 'Restore',
      destructive: true,
    );
    if (!ok) return;
    await Backup.restore(ref.read(databaseProvider), contents);
    if (mounted) showSnack(context, 'Backup restored');
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Backup & restore')),
      body: LedgerBuilder(
        builder: (context, ledger) {
          final status = StatusColors.of(context);
          final last = DateTime.tryParse(ledger.settings[lastBackupSetting] ?? '');
          final days = last == null ? null : DateTime.now().difference(last).inDays;

          return PageList(
            children: [
              SectionCard(
                children: [
                  Row(
                    children: [
                      const Expanded(child: Label('Last backup')),
                      if (days == null)
                        const StatusChip('Never', tone: ChipTone.bad)
                      else
                        StatusChip(
                          days == 0 ? 'Today' : '$days days ago',
                          tone: days <= 7 ? ChipTone.good : ChipTone.warn,
                        ),
                    ],
                  ),
                  Text(
                    last == null
                        ? 'Your data is only on this phone. Make a backup and keep it somewhere else.'
                        : DateFormat.yMMMEd().add_jm().format(last),
                  ),
                ],
              ),
              SectionCard(
                children: [
                  const Label('Make a backup'),
                  Text(
                    'One .mft file with all your data. Save it to the phone, or share it to '
                    'Drive, Telegram, email or a computer. Keep a copy off the phone.',
                    style: TextStyle(color: status.muted),
                  ),
                  FilledButton.icon(
                    onPressed: _busy ? null : _saveToPhone,
                    icon: const Icon(Icons.save_alt),
                    label: const Text('Save backup to phone'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _busy ? null : _share,
                    icon: const Icon(Icons.share_outlined),
                    label: const Text('Share backup'),
                  ),
                ],
              ),
              SectionCard(
                children: [
                  const Label('Restore or move to a new phone'),
                  Text(
                    'Install the app on the new phone, then pick the .mft file here. '
                    'The file is checked before anything is replaced.',
                    style: TextStyle(color: status.muted),
                  ),
                  OutlinedButton.icon(
                    onPressed: _busy ? null : _restore,
                    icon: const Icon(Icons.restore),
                    label: const Text('Restore from file'),
                  ),
                ],
              ),
              if (_busy) const LinearProgressIndicator(),
            ],
          );
        },
      ),
    );
  }
}
