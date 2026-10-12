import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_fin_tracker/core/money.dart';
import 'package:my_fin_tracker/data/backup.dart';
import 'package:my_fin_tracker/data/database.dart';
import 'package:my_fin_tracker/data/ledger_repository.dart';
import 'package:my_fin_tracker/data/sample_data.dart';
import 'package:my_fin_tracker/ledger/enums.dart';
import 'package:my_fin_tracker/ledger/ledger.dart';

AppDatabase memoryDb() =>
    AppDatabase(DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true));

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late AppDatabase db;
  late LedgerRepository repo;
  late Ledger ledger;
  final today = DateTime(2026, 10, 8);

  Future<void> reload() async => ledger = await Ledger.load(db);
  Account account(String name) => ledger.accounts.values.firstWhere((a) => a.name == name);
  int fund(String name) => ledger.funds.values.firstWhere((f) => f.name == name).id;
  int category(String name) => ledger.categories.values.firstWhere((c) => c.name == name).id;
  Tracker tracker(String name) => ledger.trackers.values.firstWhere((t) => t.name == name);

  setUp(() async {
    db = memoryDb();
    repo = LedgerRepository(db);
    await loadSampleData(db);
    await reload();
  });

  tearDown(() => db.close());

  group('investments', () {
    test('DPS value, growth and instalments', () {
      final dps = ledger.investmentStatus(account('DPS · Bank'));
      expect(dps.value, taka(99850));
      expect(dps.invested, taka(99620));
      expect(dps.growth, taka(230));
      expect(dps.instalmentsPaid, 19); // 17 before the app + Sep + Oct
      expect(dps.details!.totalInstalments, 60);
      expect(dps.details!.kind, InvestmentKind.dps);
    });

    test('listed by maturity, and maturing soon', () {
      expect(
        [for (final i in ledger.investments()) i.account.name],
        ['Savings certificate', 'DPS · Bank'],
      );
      expect(ledger.maturingSoon(today), isEmpty);
      final soon = ledger.maturingSoon(DateTime(2029, 3, 1));
      expect(soon.single.account.name, 'Savings certificate');
      expect(soon.single.daysToMaturity(DateTime(2029, 3, 1)), 14);
    });

    test('updating the value records growth, not new money', () async {
      final dps = account('DPS · Bank');
      await repo.updateInvestmentValue(
        accountId: dps.id,
        investmentFund: fund('Investments'),
        currentValue: taka(99850),
        newValue: taka(100500),
        date: today,
      );
      await reload();
      final s = ledger.investmentStatus(dps);
      expect(s.value, taka(100500));
      expect(s.growth, taka(880));
      expect(ledger.liquidTotal(), taka(132920), reason: 'spendable money unchanged');
    });

    test('adding an investment with its current value', () async {
      await repo.addInvestment(
        name: 'FDR · City Bank',
        kind: InvestmentKind.fdr,
        startDate: DateTime(2026, 1, 10),
        maturityDate: DateTime(2027, 1, 10),
        rateBp: 900,
        currentValue: taka(100000),
        asOf: today,
        investmentFund: fund('Investments'),
      );
      await reload();
      final fdr = ledger.investmentStatus(account('FDR · City Bank'));
      expect(fdr.value, taka(100000));
      expect(fdr.instalmentsPaid, 0);
      expect(ledger.investmentTotal(), taka(399850));
      expect(ledger.investments().first.account.name, 'FDR · City Bank');
    });
  });

  group('trackers', () {
    test('countdowns first, then projects', () {
      expect(
        [for (final t in ledger.activeTrackers()) t.tracker.name],
        ['Sylhet Trip', 'Home Office Setup'],
      );
    });

    test('Sylhet Trip countdown', () {
      final trip = ledger.trackerStatus(tracker('Sylhet Trip'));
      expect(trip.spent, taka(4000));
      expect(trip.left, taka(21000));
      expect(trip.daysLeft(DateTime(2026, 10, 7)), 72);
      expect(trip.progress, closeTo(.16, .001));
    });

    test('Home Office Setup project', () {
      final office = ledger.trackerStatus(tracker('Home Office Setup'));
      expect(office.spent, taka(38750));
      expect(office.left, isNull);
      expect(office.entries.single.note, 'Desk lamp');
      expect(office.byCategory, {category('Mine'): taka(1250)});
    });

    test('tagging and untagging an entry', () async {
      final veg = ledger.entries.firstWhere((e) => e.note.startsWith('Vegetables'));
      await repo.setEntryTracker(veg.id, tracker('Sylhet Trip').id);
      await reload();
      expect(ledger.trackerStatus(tracker('Sylhet Trip')).spent, taka(4350));
      await repo.setEntryTracker(veg.id, null);
      await reload();
      expect(ledger.trackerStatus(tracker('Sylhet Trip')).spent, taka(4000));
    });
  });

  group('buying register', () {
    test('purchases of the year, newest first', () {
      expect([for (final p in ledger.purchasesIn(2026)) p.item], ['Ceiling fan', 'Refrigerator']);
      expect(ledger.purchasesIn(2025), isEmpty);
      final fan = ledger.entries.firstWhere((e) => e.note == 'Ceiling fan');
      expect(ledger.purchaseFor(fan.id)!.warrantyUntil, DateTime(2028, 9, 12));
    });

    test('deleting the expense deletes its purchase record', () async {
      final fan = ledger.entries.firstWhere((e) => e.note == 'Ceiling fan');
      await repo.deleteEntry(fan.id);
      await reload();
      expect([for (final p in ledger.purchasesIn(2026)) p.item], ['Refrigerator']);
    });

    test('buying a goal adds it to the register', () async {
      final bike = fund('Motorbike');
      await repo.buyGoal(
        goalId: bike,
        spendingFund: fund('Spending'),
        payFromAccount: account('Bank').id,
        goalMoney: [
          for (final a in ledger.accountsOfType((t) => t.isLiquid))
            (account: a.id, amount: ledger.cell(a.id, bike)),
        ],
        date: today,
        price: taka(14000),
        categoryId: category('Random'),
        note: 'Bicycle',
      );
      await reload();
      expect(ledger.purchasesIn(2026).first.item, 'Bicycle');
      expect(ledger.purchasesIn(2026).first.amount, taka(14000));
    });
  });

  group('backup', () {
    test('includes investments, purchases and trackers', () async {
      final contents = Backup.read(await Backup.export(db));
      expect(contents.count('investment_details'), 2);
      expect(contents.count('purchases'), 2);
      expect(contents.count('trackers'), 2);
      final other = memoryDb();
      await Backup.restore(other, contents);
      final after = await Ledger.load(other);
      await other.close();
      expect(
        after
            .investmentStatus(after.accounts.values.firstWhere((a) => a.name == 'DPS · Bank'))
            .instalmentsPaid,
        19,
      );
      expect(after.trackers.length, 2);
      expect(after.purchases.length, 2);
      expect(
        after
            .trackerStatus(after.trackers.values.firstWhere((t) => t.name == 'Home Office Setup'))
            .spent,
        taka(38750),
      );
    });

    test('a backup made before Phase 4 still restores', () async {
      final archive = ZipDecoder().decodeBytes(await Backup.export(db));
      final data =
          jsonDecode(utf8.decode(archive.findFile('data.json')!.content)) as Map<String, dynamic>;
      final manifest = jsonDecode(
        utf8.decode(archive.findFile('manifest.json')!.content),
      ) as Map<String, dynamic>;
      for (final t in ['investment_details', 'purchases', 'trackers']) {
        data.remove(t);
        (manifest['counts'] as Map).remove(t);
      }
      (manifest['counts'] as Map).remove('purchases');
      final dataBytes = utf8.encode(jsonEncode(data));
      manifest['sha256'] = sha256.convert(dataBytes).toString();
      manifest['schema_version'] = 1;
      final old = Archive()
        ..addFile(ArchiveFile.string('manifest.json', jsonEncode(manifest)))
        ..addFile(ArchiveFile.bytes('data.json', dataBytes));

      final other = memoryDb();
      await Backup.restore(other, Backup.read(ZipEncoder().encodeBytes(old)));
      final after = await Ledger.load(other);
      await other.close();
      expect(after.netWorth(), taka(428770));
      expect(after.trackers, isEmpty);
      expect(after.purchases, isEmpty);
    });
  });

  test('a version 1 database upgrades with its data intact', () async {
    final schemaV1 = File('test/fixtures/schema_v1.sql').readAsStringSync();
    final old = AppDatabase(
      DatabaseConnection(
        NativeDatabase.memory(
          setup: (raw) {
            raw.execute(schemaV1);
            raw.execute("INSERT INTO accounts (name, type) VALUES ('Bank', 'bank')");
            raw.execute("INSERT INTO funds (name, kind) VALUES ('Spending', 'spending')");
            raw.execute(
              "INSERT INTO entries (date, type, amount, note) VALUES (1790000000, 'opening', 500000, 'Start')",
            );
            raw.execute(
              'INSERT INTO postings (entry_id, account_id, fund_id, amount) VALUES (1, 1, 1, 500000)',
            );
            raw.execute('PRAGMA user_version = 1');
          },
        ),
        closeStreamsSynchronously: true,
      ),
    );
    final upgraded = await Ledger.load(old);
    expect(upgraded.netWorth(), taka(5000));
    expect(
      upgraded.accounts.values.single.name,
      'Bank',
      reason: 'no default data added on upgrade',
    );
    final version = await old.customSelect('PRAGMA user_version').getSingle();
    expect(version.data.values.single, old.schemaVersion, reason: 'upgraded to the latest schema');
    // The new tables exist and work.
    await LedgerRepository(old)
        .addTracker(name: 'Test', kind: TrackerKind.project, startDate: DateTime(2026, 10, 1));
    expect((await Ledger.load(old)).trackers.length, 1);
    await old.close();
  });
}
