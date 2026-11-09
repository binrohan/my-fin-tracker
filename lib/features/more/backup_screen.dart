import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../app/google_drive.dart';
import '../../data/auto_backup.dart';
import '../../data/drive_backup.dart';
import '../../data/backup.dart';
import '../../ledger/ledger.dart';
import '../../ledger/reminders.dart';
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
    final bytes = await Backup.export(
      ref.read(databaseProvider),
      now: now,
      receipts: await ref.read(receiptStoreProvider.future),
    );
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
    await _restoreContents(Backup.read(await files.single.readAsBytes()));
  });

  /// Asks, then replaces everything with [contents].
  Future<void> _restoreContents(BackupContents contents) async {
    if (!mounted) return;
    final m = contents.manifest;
    final ok = await confirm(
      context,
      title: 'Replace all data with this backup?',
      body:
          'Backup from ${DateFormat.yMMMd().add_jm().format(m.createdAt)}\n'
          '${contents.count('entries')} entries · ${contents.count('accounts')} accounts · '
          '${contents.count('loans')} loans'
          '${contents.receipts.isEmpty ? '' : ' · ${contents.receipts.length} receipt photos'}\n\n'
          'Everything now in the app will be replaced. Back up first if you are unsure.',
      action: 'Restore',
      destructive: true,
    );
    if (!ok) return;
    await Backup.restore(
      ref.read(databaseProvider),
      contents,
      receipts: await ref.read(receiptStoreProvider.future),
    );
    if (mounted) showSnack(context, 'Backup restored');
  }

  // ------------------------------------------------------- Google Drive

  /// Asks for the Drive backup password; with [twice], to set a new one.
  Future<String?> _askPassword({required bool twice}) => showDialog<String>(
    context: context,
    builder: (context) => _PasswordDialog(twice: twice),
  );

  Future<GoogleDriveStore?> _drive({required bool interactive}) async {
    try {
      final token = await driveAccessToken(interactive: interactive);
      return token == null ? null : GoogleDriveStore(token);
    } catch (e) {
      throw BackupException('Could not connect to Google Drive: $e');
    }
  }

  Future<DriveBackup> _driveBackup(DriveStore drive) async => DriveBackup(
    ref.read(databaseProvider),
    drive,
    receipts: await ref.read(receiptStoreProvider.future),
  );

  Future<void> _connectDrive() async {
    final password = await _askPassword(twice: true);
    if (password == null) return;
    await _run(() async {
      final drive = await _drive(interactive: true);
      if (drive == null) return;
      final key = await BackupCipher.deriveKey(password);
      await DriveKeyStore.write(key);
      await ref.read(repositoryProvider).setSetting(driveBackupOnSetting, 'true');
      await (await _driveBackup(drive)).upload(key);
      if (mounted) showSnack(context, 'Google Drive connected and backed up');
    });
  }

  Future<void> _driveNow() => _run(() async {
    var key = await DriveKeyStore.read();
    if (key == null) {
      if (!mounted) return;
      final password = await _askPassword(twice: true);
      if (password == null) return;
      key = await BackupCipher.deriveKey(password);
      await DriveKeyStore.write(key);
    }
    final drive = await _drive(interactive: true);
    if (drive == null) return;
    await (await _driveBackup(drive)).upload(key);
    if (mounted) showSnack(context, 'Backed up to Google Drive');
  });

  Future<void> _restoreFromDrive() => _run(() async {
    final drive = await _drive(interactive: true);
    if (drive == null) return;
    final backup = await _driveBackup(drive);
    final files = await backup.backups();
    if (!mounted) return;
    if (files.isEmpty) {
      showSnack(context, 'No backups in Google Drive yet');
      return;
    }
    final file = await showDialog<DriveFile>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Backups in Google Drive'),
        children: [
          for (final f in files)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, f),
              child: Text(
                '${DateFormat.yMMMd().add_jm().format(f.at)} · '
                '${(f.size / 1024 / 1024).toStringAsFixed(1)} MB',
              ),
            ),
        ],
      ),
    );
    if (file == null || !mounted) return;
    final password = await _askPassword(twice: false);
    if (password == null) return;
    await _restoreContents(await backup.open(file, password));
  });

  Future<void> _driveOff() async {
    final ok = await confirm(
      context,
      title: 'Stop backing up to Google Drive?',
      body: 'Backups already in Drive stay there and can still be restored with your password.',
      action: 'Stop',
    );
    if (!ok) return;
    await ref.read(repositoryProvider).setSetting(driveBackupOnSetting, 'false');
    await DriveKeyStore.clear();
    await disconnectDrive();
  }

  Widget _driveCard(Ledger ledger, StatusColors status) {
    final on = ledger.settings[driveBackupOnSetting] == 'true';
    final last = DateTime.tryParse(ledger.settings[driveBackupLastSetting] ?? '');
    final error = ledger.settings[driveBackupErrorSetting] ?? '';
    return SectionCard(
      children: [
        Row(
          children: [
            const Expanded(child: Label('Google Drive')),
            if (on)
              StatusChip(
                error.isNotEmpty ? 'Needs you' : 'On',
                tone: error.isNotEmpty ? ChipTone.warn : ChipTone.good,
              ),
          ],
        ),
        Text(
          on
              ? last == null
                    ? 'Every week, locked with your password.'
                    : 'Last: ${DateFormat.yMMMd().add_jm().format(last)} · every week · keeps the newest 8'
              : 'An encrypted copy every week in a hidden folder of your Google Drive. '
                    'Only this app can see it, and only your password opens it.',
          style: TextStyle(color: status.muted, fontSize: 13),
        ),
        if (on && error.isNotEmpty) Text(error, style: TextStyle(color: status.warn)),
        if (!on)
          FilledButton.icon(
            onPressed: _busy ? null : _connectDrive,
            icon: const Icon(Icons.add_to_drive),
            label: const Text('Connect Google Drive'),
          )
        else
          FilledButton.icon(
            onPressed: _busy ? null : _driveNow,
            icon: const Icon(Icons.cloud_upload_outlined),
            label: Text(error.isNotEmpty ? 'Connect again and back up' : 'Back up to Drive now'),
          ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: _busy ? null : _restoreFromDrive,
              icon: const Icon(Icons.cloud_download_outlined),
              label: const Text('Restore from Drive'),
            ),
            if (on) TextButton(onPressed: _busy ? null : _driveOff, child: const Text('Turn off')),
          ],
        ),
      ],
    );
  }

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
              _AutoBackupCard(ledger: ledger),
              _driveCard(ledger, status),
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

/// The weekly automatic backup: on or off, where, and sharing the newest.
class _AutoBackupCard extends ConsumerWidget {
  const _AutoBackupCard({required this.ledger});

  final Ledger ledger;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = StatusColors.of(context);
    final on = ledger.settings[autoBackupOffSetting] != 'true';
    final last = DateTime.tryParse(ledger.settings[autoBackupSetting] ?? '');
    return SectionCard(
      children: [
        const Label('Automatic backup'),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Every week'),
          subtitle: Text(
            last == null
                ? 'Made when you open the app; keeps the newest 8'
                : 'Last: ${DateFormat.yMMMd().add_jm().format(last)} · keeps the newest 8',
          ),
          value: on,
          onChanged: (v) =>
              ref.read(repositoryProvider).setSetting(autoBackupOffSetting, v ? 'false' : 'true'),
        ),
        Text(
          'Saved inside the app\'s own folder on this phone (Android/data). They survive '
          'updates but not uninstalling, so share one off the phone now and then.',
          style: TextStyle(color: status.muted, fontSize: 13),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              icon: const Icon(Icons.backup_outlined),
              label: const Text('Back up now'),
              onPressed: () async {
                final file = await AutoBackup(
                  ref.read(databaseProvider),
                  receipts: await ref.read(receiptStoreProvider.future),
                ).run(folder: await AutoBackup.defaultFolder());
                if (context.mounted) showSnack(context, 'Saved ${file.uri.pathSegments.last}');
              },
            ),
            OutlinedButton.icon(
              icon: const Icon(Icons.share_outlined),
              label: const Text('Share newest'),
              onPressed: () async {
                final files = await AutoBackup.list(await AutoBackup.defaultFolder());
                if (files.isEmpty) {
                  if (context.mounted) showSnack(context, 'No automatic backup yet');
                  return;
                }
                final file = files.first;
                await SharePlus.instance.share(
                  ShareParams(
                    files: [XFile(file.path, mimeType: 'application/octet-stream')],
                    subject: 'My Fin Tracker backup',
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }
}

/// A password for Drive backups: typed twice when it is new.
class _PasswordDialog extends StatefulWidget {
  const _PasswordDialog({required this.twice});

  final bool twice;

  @override
  State<_PasswordDialog> createState() => _PasswordDialogState();
}

class _PasswordDialogState extends State<_PasswordDialog> {
  final _first = TextEditingController();
  final _second = TextEditingController();

  @override
  void dispose() {
    _first.dispose();
    _second.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final status = StatusColors.of(context);
    final short = _first.text.length < 8;
    final differ = widget.twice && _first.text != _second.text;
    return AlertDialog(
      title: Text(widget.twice ? 'Choose a backup password' : 'Backup password'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 12,
        children: [
          if (widget.twice)
            Text(
              'It locks your Drive backups. Write it down: if you forget it, they can\'t be '
              'opened by anyone.',
              style: TextStyle(color: status.warn, fontSize: 13),
            ),
          TextField(
            controller: _first,
            obscureText: true,
            autofocus: true,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'Password',
              helperText: widget.twice ? 'At least 8 characters' : null,
              border: const OutlineInputBorder(),
            ),
          ),
          if (widget.twice)
            TextField(
              controller: _second,
              obscureText: true,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Same password again',
                border: OutlineInputBorder(),
              ),
            ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: (widget.twice && short) || differ || _first.text.isEmpty
              ? null
              : () => Navigator.pop(context, _first.text),
          child: const Text('OK'),
        ),
      ],
    );
  }
}
