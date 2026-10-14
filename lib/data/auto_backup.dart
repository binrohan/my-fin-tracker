import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../ledger/ledger.dart';
import '../ledger/reminders.dart';
import 'backup.dart';
import 'database.dart';
import 'ledger_repository.dart';
import 'receipts.dart';

const autoBackupOffSetting = 'auto_backup_off';

/// Weekly backups the app makes by itself, kept in its own folder on the
/// phone (`Android/data/<app>/files/backups`). They survive app updates but
/// not uninstalling, so share one off the phone now and then.
class AutoBackup {
  AutoBackup(this.db, {this.receipts, this.keep = 8, this.every = const Duration(days: 7)});

  final AppDatabase db;
  final ReceiptStore? receipts;
  final int keep;
  final Duration every;

  static Future<Directory> defaultFolder() async {
    final base = await getExternalStorageDirectory() ?? await getApplicationDocumentsDirectory();
    return Directory('${base.path}/backups');
  }

  /// Backups in [folder], newest first.
  static Future<List<File>> list(Directory folder) async {
    if (!await folder.exists()) return [];
    final files = await folder
        .list()
        .where((f) => f is File && f.path.endsWith('.${Backup.fileExtension}'))
        .cast<File>()
        .toList();
    files.sort((a, b) => b.path.compareTo(a.path));
    return files;
  }

  bool isDue(Ledger ledger, DateTime now) {
    if (ledger.isEmpty || ledger.settings[autoBackupOffSetting] == 'true') return false;
    final last = DateTime.tryParse(ledger.settings[autoBackupSetting] ?? '');
    return last == null || now.difference(last) >= every;
  }

  /// Makes a backup if one is due. Returns the new file, or null.
  Future<File?> runIfDue(Ledger ledger, {required Directory folder, DateTime? now}) async {
    final at = now ?? DateTime.now();
    if (!isDue(ledger, at)) return null;
    return run(folder: folder, now: at);
  }

  /// Makes a backup now and removes all but the newest [keep].
  Future<File> run({required Directory folder, DateTime? now}) async {
    final at = now ?? DateTime.now();
    await folder.create(recursive: true);
    final file = File(
      '${folder.path}/${Backup.fileName(at).replaceFirst('myfin-', 'myfin-auto-')}',
    );
    await file.writeAsBytes(await Backup.export(db, now: at, receipts: receipts), flush: true);
    await LedgerRepository(db).setSetting(autoBackupSetting, at.toIso8601String());
    final all = await list(folder);
    for (final old in all.skip(keep)) {
      await old.delete();
    }
    return file;
  }
}
