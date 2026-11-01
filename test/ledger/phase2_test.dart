import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_fin_tracker/core/money.dart';
import 'package:my_fin_tracker/core/period.dart';
import 'package:my_fin_tracker/data/backup.dart';
import 'package:my_fin_tracker/data/database.dart';
import 'package:my_fin_tracker/data/ledger_repository.dart';
import 'package:my_fin_tracker/data/sample_data.dart';
import 'package:my_fin_tracker/ledger/allocation.dart';
import 'package:my_fin_tracker/ledger/enums.dart';
import 'package:my_fin_tracker/ledger/ledger.dart';

AppDatabase memoryDb() =>
    AppDatabase(DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true));

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late AppDatabase db;
  late LedgerRepository repo;
  late Ledger ledger;
  const sep = Period(2026, 9);
  const oct = Period(2026, 10);
  final today = DateTime(2026, 10, 8);

  Future<void> reload() async => ledger = await Ledger.load(db);
  int account(String name) => ledger.accounts.values.firstWhere((a) => a.name == name).id;
  int fund(String name) => ledger.funds.values.firstWhere((f) => f.name == name).id;
  int category(String name) => ledger.categories.values.firstWhere((c) => c.name == name).id;
  CategoryLine line(Period p, String name) =>
      ledger.categoryLines(p, CategoryKind.expense).firstWhere((l) => l.category.name == name);

  setUp(() async {
    db = memoryDb();
    repo = LedgerRepository(db);
    await loadSampleData(db);
    await reload();
  });

  tearDown(() => db.close());

  test('a budget stays in force for later months', () {
    const nov = Period(2026, 11);
    expect(line(nov, 'Ration').budget, taka(14000));
    expect(ledger.summary(nov).budget, taka(54280));
  });

  test('changing a budget affects that month onwards only', () async {
    await repo.setBudget(oct, category('Ration'), taka(15000));
    await reload();
    expect(line(sep, 'Ration').budget, taka(14000));
    expect(line(oct, 'Ration').budget, taka(15000));
    expect(line(const Period(2027, 2), 'Ration').budget, taka(15000));
  });

  test('quick-add chips put the most used categories first', () {
    final names = ledger.frequentCategories(CategoryKind.expense, today).map((c) => c.name);
    expect(names.take(4), ['Ration', 'Random', 'Mine', 'House Rent']);
    expect(names, isNot(contains('Fixed')), reason: 'parents are not selectable');
  });

  test('fixed bills still due, and paying them', () async {
    final due = ledger.unpaidFixedBills(oct);
    expect(
      {for (final b in due) b.category.name: b.remaining},
      {'Electricity': taka(2500), 'Water & Service': taka(1500)},
    );

    await repo.payBills(
      [for (final b in due) (categoryId: b.category.id, amount: b.remaining)],
      today,
      (account: account('Bank'), fund: fund('This month')),
    );
    await reload();
    expect(ledger.unpaidFixedBills(oct), isEmpty);
    expect(ledger.summary(oct).expenses, taka(36700));
    expect(ledger.summary(oct).checks, isTrue);
  });

  test('salary plan sets money aside', () async {
    final plan = AllocationPlan(
      categoryId: category('Salary'),
      items: [
        AllocationItem(fundId: fund('Monthly Savings'), amount: taka(20000)),
        AllocationItem(fundId: fund('New Laptop'), amount: taka(8000)),
        AllocationItem(
          fundId: fund('Investments'),
          accountId: account('DPS · Bank'),
          amount: taka(5000),
        ),
      ],
    );
    final decoded = AllocationPlan.parse(plan.encode());
    expect(decoded.total, taka(33000));
    expect(decoded.items.last.accountId, account('DPS · Bank'));

    const nov = Period(2026, 11);
    final bank = (account: account('Bank'), fund: fund('This month'));
    await repo.income(DateTime(2026, 11, 1), taka(85000), categoryId: category('Salary'), to: bank);
    await repo.applyAllocation(decoded, DateTime(2026, 11, 1), bank);
    await reload();
    final s = ledger.summary(nov);
    expect(s.setAside, taka(33000));
    expect(s.invested, taka(5000));
    expect(s.checks, isTrue);
  });

  test('editing an entry replaces it', () async {
    final veg = ledger.entries.firstWhere((e) => e.note.startsWith('Vegetables'));
    await repo.replaceEntry(
      veg.id,
      () => repo.expense(
        veg.date,
        taka(400),
        categoryId: veg.categoryId!,
        from: (account: account('Cash'), fund: fund('This month')),
        note: veg.note,
      ),
    );
    await reload();
    expect(line(oct, 'Ration').actual, taka(4400));
    expect(ledger.entries.where((e) => e.id == veg.id), isEmpty);
    expect(ledger.cell(account('Cash'), fund('This month')), taka(2750));
  });

  test('matching the bank balance records the difference', () async {
    final bank = account('Bank');
    final id = await repo.matchBalance(
      date: today,
      pot: (account: bank, fund: fund('This month')),
      appBalance: ledger.accountBalance(bank),
      realBalance: taka(123500),
    );
    expect(id, isNotNull);
    await reload();
    expect(ledger.accountBalance(bank), taka(123500));
    final s = ledger.summary(oct);
    expect(s.adjustNet, taka(-470));
    expect(s.leftToSpend, taka(23950));
    expect(s.checks, isTrue);

    expect(
      await repo.matchBalance(
        date: today,
        pot: (account: bank, fund: fund('This month')),
        appBalance: taka(5),
        realBalance: taka(5),
      ),
      isNull,
      reason: 'no entry when nothing differs',
    );
  });

  group('closing a month', () {
    test('September waits to be closed, and closing carries forward', () async {
      expect(ledger.monthToClose(today), sep);
      await repo.closeMonth(sep, confirmedBank: taka(74920));
      await reload();
      expect(ledger.isClosed(sep), isTrue);
      expect(ledger.monthToClose(today), isNull);
      expect(ledger.summary(oct).carriedForward, taka(10120));
    });

    test('closing with "move leftover to savings"', () async {
      final spending = fund('This month');
      final leftovers = [
        for (final a in ledger.accountsOfType((t) => t.isLiquid))
          (account: a.id, amount: ledger.cell(a.id, spending, before: sep.end)),
      ];
      await repo.closeMonth(
        sep,
        spendingFund: spending,
        sweepTo: fund('Monthly Savings'),
        leftovers: leftovers,
      );
      await reload();
      expect(ledger.summary(sep).leftToSpend, 0);
      expect(ledger.summary(oct).carriedForward, 0);
      expect(ledger.fundBalance(fund('Monthly Savings'), before: sep.end), taka(57120));
      expect(ledger.cell(account('Cash'), fund('Monthly Savings'), before: sep.end), taka(6700));
      expect(ledger.liquidTotal(before: sep.end), taka(85620), reason: 'money only changed fund');
    });
  });

  test('starting balances are dated the day before you start', () async {
    await db.resetAllData();
    await reload();
    await repo.setStartingBalances(DateTime(2026, 11, 1), [
      ((account: account('Bank'), fund: fund('This month')), taka(40000)),
      ((account: account('Bank'), fund: fund('Monthly Savings')), taka(100000)),
      ((account: account('Cash'), fund: fund('This month')), taka(3000)),
      ((account: account('bKash'), fund: fund('This month')), 0),
    ]);
    await reload();
    expect(ledger.entries.length, 3, reason: 'zero amounts are skipped');
    expect(ledger.entries.every((e) => e.date == DateTime(2026, 10, 31)), isTrue);
    final nov = ledger.summary(const Period(2026, 11));
    expect(nov.carriedForward, taka(43000));
    expect(nov.openingLiquid, taka(143000));
    expect(ledger.monthToClose(DateTime(2026, 11, 15)), isNull);
  });

  group('backup', () {
    test('restores every figure exactly', () async {
      await repo.closeMonth(sep);
      await repo.setSetting('borrow_charge_bp', '700');
      await reload();
      final before = ledger;
      final bytes = await Backup.export(db, now: DateTime(2026, 10, 8, 21));

      final other = memoryDb();
      final contents = Backup.read(bytes);
      expect(contents.manifest.createdAt, DateTime(2026, 10, 8, 21));
      expect(contents.count('entries'), before.entries.length);
      await Backup.restore(other, contents);
      final after = await Ledger.load(other);
      await other.close();

      expect(after.entries.length, before.entries.length);
      expect(after.lines.length, before.lines.length);
      expect(after.netWorth(), taka(428770));
      expect(after.summary(oct).leftToSpend, taka(24420));
      expect(after.summary(sep).expenses, taka(54380));
      expect(
        after.loanStatus(after.loans.firstWhere((l) => l.kind == LoanKind.ownSavings)).remaining,
        taka(2250),
      );
      expect(after.isClosed(sep), isTrue);
      expect(after.settings['borrow_charge_bp'], '700');
      expect(
        after.funds.values.firstWhere((f) => f.name == 'New Laptop').targetDate,
        DateTime(2027, 3, 31),
      );
      expect(
        after.categories.values.firstWhere((c) => c.name == 'Gas').parentId,
        before.categories.values.firstWhere((c) => c.name == 'Gas').parentId,
      );
    });

    test('restore replaces what was there', () async {
      final bytes = await Backup.export(db);
      await db.resetAllData();
      await repo.setSetting('borrow_charge_bp', '900');
      await Backup.restore(db, Backup.read(bytes));
      await reload();
      expect(ledger.netWorth(), taka(428770));
      expect(ledger.settings['borrow_charge_bp'], '500');
    });

    test('rejects files that are not backups', () {
      expect(
        () => Backup.read(Uint8List.fromList(utf8.encode('hello'))),
        throwsA(isA<BackupException>()),
      );
    });

    test('rejects a damaged backup', () async {
      final bytes = await Backup.export(db);
      final archive = ZipDecoder().decodeBytes(bytes);
      final data = utf8
          .decode(archive.findFile('data.json')!.content)
          .replaceFirst('85000', '95000');
      final tampered = Archive()
        ..addFile(archive.findFile('manifest.json')!)
        ..addFile(ArchiveFile.string('data.json', data));
      expect(
        () => Backup.read(ZipEncoder().encodeBytes(tampered)),
        throwsA(isA<BackupException>().having((e) => e.message, 'message', contains('checksum'))),
      );
    });

    test('file name', () {
      expect(Backup.fileName(DateTime(2026, 10, 8, 21, 5)), 'myfin-2026-10-08-2105.mft');
    });
  });
}
