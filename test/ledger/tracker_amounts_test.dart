import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_fin_tracker/core/money.dart';
import 'package:my_fin_tracker/core/period.dart';
import 'package:my_fin_tracker/data/backup.dart';
import 'package:my_fin_tracker/data/database.dart';
import 'package:my_fin_tracker/data/ledger_repository.dart';
import 'package:my_fin_tracker/data/sample_data.dart';
import 'package:my_fin_tracker/ledger/ledger.dart';

AppDatabase memoryDb() =>
    AppDatabase(DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true));

/// Money for a tracker from outside your accounts: it counts on the
/// tracker and nowhere else.
void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late AppDatabase db;
  late LedgerRepository repo;
  late Ledger ledger;
  const oct = Period(2026, 10);

  Future<void> reload() async => ledger = await Ledger.load(db);
  Tracker trip() => ledger.trackers.values.firstWhere((t) => t.name == 'Sylhet Trip');

  setUp(() async {
    db = memoryDb();
    repo = LedgerRepository(db);
    await loadSampleData(db);
    await reload();
  });
  tearDown(() => db.close());

  test('adds to the tracker only', () async {
    final before = ledger.trackerStatus(trip()).spent;
    final summary = ledger.summary(oct);
    final worth = ledger.netWorth();

    await repo.addTrackerAmount(trip().id, DateTime(2026, 10, 9), taka(3000), note: 'Paid by Abbu');
    await reload();

    final s = ledger.trackerStatus(trip());
    expect(s.spent, before + taka(3000));
    expect(s.outsideTotal, taka(3000));
    expect(s.outside.single.note, 'Paid by Abbu');
    expect(ledger.netWorth(), worth);
    expect(ledger.summary(oct).leftToSpend, summary.leftToSpend);
    expect(ledger.summary(oct).expenses, summary.expenses);
    expect(ledger.isBalanced, isTrue);
  });

  test('edit and delete', () async {
    final id = await repo.addTrackerAmount(trip().id, DateTime(2026, 10, 9), taka(3000));
    await repo.updateTrackerAmount(id, DateTime(2026, 10, 10), taka(3500), note: 'Hotel');
    await reload();
    final a = ledger.trackerStatus(trip()).outside.single;
    expect((a.amount, a.note, a.date), (taka(3500), 'Hotel', DateTime(2026, 10, 10)));
    await repo.deleteTrackerAmount(id);
    await reload();
    expect(ledger.trackerStatus(trip()).outside, isEmpty);
  });

  test('backups keep them', () async {
    await repo.addTrackerAmount(trip().id, DateTime(2026, 10, 9), taka(3000));
    final copy = memoryDb();
    await Backup.restore(copy, Backup.read(await Backup.export(db)));
    final restored = await Ledger.load(copy);
    expect(restored.trackerAmounts.single.amount, taka(3000));
    await copy.close();
  });

  test('a version 6 database upgrades with its data intact', () async {
    final schemaV6 = File('test/fixtures/schema_v6.sql').readAsStringSync();
    final old = AppDatabase(
      DatabaseConnection(
        NativeDatabase.memory(
          setup: (raw) {
            raw.execute(schemaV6);
            raw.execute("INSERT INTO accounts (name, type) VALUES ('City Bank', 'bank')");
            raw.execute("INSERT INTO funds (name, kind) VALUES ('Spending', 'spending')");
            raw.execute(
              "INSERT INTO trackers (name, kind, start_date, opening_spent) "
              "VALUES ('House repair', 'project', 1791331200, 500000)",
            );
            raw.execute('PRAGMA user_version = 6');
          },
        ),
        closeStreamsSynchronously: true,
      ),
    );
    final l = await Ledger.load(old);
    expect(l.trackerStatus(l.trackers.values.single).spent, taka(5000));
    await LedgerRepository(old).addTrackerAmount(1, DateTime(2026, 10, 9), taka(1000));
    final after = await Ledger.load(old);
    expect(after.trackerStatus(after.trackers.values.single).spent, taka(6000));
    final version = await old.customSelect('PRAGMA user_version').getSingle();
    expect(version.data.values.single, old.schemaVersion);
    await old.close();
  });
}
