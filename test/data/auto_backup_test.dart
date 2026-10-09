import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_fin_tracker/data/auto_backup.dart';
import 'package:my_fin_tracker/data/backup.dart';
import 'package:my_fin_tracker/data/database.dart';
import 'package:my_fin_tracker/data/ledger_repository.dart';
import 'package:my_fin_tracker/data/sample_data.dart';
import 'package:my_fin_tracker/ledger/ledger.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late AppDatabase db;
  late Directory folder;

  setUp(() async {
    db = AppDatabase(DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true));
    folder = await Directory.systemTemp.createTemp('myfin-auto');
  });
  tearDown(() async {
    await db.close();
    await folder.delete(recursive: true);
  });

  test('nothing to back up in an empty app', () async {
    final auto = AutoBackup(db);
    expect(
      await auto.runIfDue(await Ledger.load(db), folder: Directory('${folder.path}/b')),
      isNull,
    );
  });

  test('weekly, keeping the newest 8, and restorable', () async {
    await loadSampleData(db);
    final auto = AutoBackup(db);
    final dir = Directory('${folder.path}/backups');

    var now = DateTime(2026, 10, 1, 9);
    final first = await auto.runIfDue(await Ledger.load(db), folder: dir, now: now);
    expect(first, isNotNull);
    expect(first!.path, endsWith('myfin-auto-2026-10-01-0900.mft'));

    // Not due again within the week.
    expect(
      await auto.runIfDue(
        await Ledger.load(db),
        folder: dir,
        now: now.add(const Duration(days: 6)),
      ),
      isNull,
    );

    for (var i = 1; i <= 9; i++) {
      now = now.add(const Duration(days: 7));
      expect(await auto.runIfDue(await Ledger.load(db), folder: dir, now: now), isNotNull);
    }
    final files = await AutoBackup.list(dir);
    expect(files.length, 8);
    expect(files.first.path, endsWith('myfin-auto-2026-12-03-0900.mft'));

    final restored = AppDatabase(
      DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true),
    );
    await Backup.restore(restored, Backup.read(await files.first.readAsBytes()));
    expect((await Ledger.load(restored)).netWorth(), (await Ledger.load(db)).netWorth());
    await restored.close();
  });

  test('can be turned off', () async {
    await loadSampleData(db);
    await LedgerRepository(db).setSetting(autoBackupOffSetting, 'true');
    expect(await AutoBackup(db).runIfDue(await Ledger.load(db), folder: folder), isNull);
  });
}
