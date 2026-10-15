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
import 'package:my_fin_tracker/ledger/enums.dart';
import 'package:my_fin_tracker/ledger/ledger.dart';
import 'package:my_fin_tracker/ledger/reminders.dart';

AppDatabase memoryDb() =>
    AppDatabase(DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true));

/// The example from UAT: a "Medical Test" slot for one month, funded from
/// Ration and Mine, part spent, the rest given back.
void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late AppDatabase db;
  late LedgerRepository repo;
  late Ledger ledger;
  const nov = Period(2026, 11);
  const dec = Period(2026, 12);
  final day = DateTime(2026, 11, 3);

  Future<void> reload() async => ledger = await Ledger.load(db);
  int category(String name) => ledger.categories.values.firstWhere((c) => c.name == name).id;
  CategoryLine line(Period p, String name, {bool withMoves = true}) {
    CategoryLine? found;
    void walk(CategoryLine l) {
      if (l.category.name == name) found = l;
      l.children.forEach(walk);
    }

    ledger.categoryLines(p, CategoryKind.expense, withMoves: withMoves).forEach(walk);
    return found!;
  }

  setUp(() async {
    db = memoryDb();
    repo = LedgerRepository(db);
    await loadSampleData(db);
    await reload();
  });
  tearDown(() => db.close());

  Future<int> createMedicalTest() async {
    final id = await repo.createSlot(
      nov,
      name: 'Medical Test',
      from: [
        (category: category('Mine'), amount: taka(3000)),
        (category: category('Ration'), amount: taka(6000)),
      ],
      date: day,
    );
    await reload();
    return id;
  }

  test('creating the slot moves budget for this month only', () async {
    await createMedicalTest();
    expect(line(nov, 'Ration').budget, taka(8000));
    expect(line(nov, 'Mine').budget, taka(1000)); // 4,000 − 3,000
    expect(line(nov, 'Medical Test').budget, taka(9000));
    expect(ledger.summary(nov).budget, taka(54280), reason: 'the month total does not change');

    // The Monthly plan and the next month are untouched.
    expect(line(nov, 'Ration', withMoves: false).budget, taka(14000));
    expect(line(dec, 'Ration').budget, taka(14000));
    expect(
      ledger.categoryLines(dec, CategoryKind.expense).any((l) => l.category.name == 'Medical Test'),
      isFalse,
    );
  });

  test('a slot is offered in quick add only in its own month', () async {
    final slot = await createMedicalTest();
    expect(
      ledger.leafCategories(CategoryKind.expense, month: nov).map((c) => c.id),
      contains(slot),
    );
    expect(
      ledger.leafCategories(CategoryKind.expense, month: dec).map((c) => c.id),
      isNot(contains(slot)),
    );
    expect(ledger.frequentCategories(CategoryKind.expense, DateTime(2026, 11, 4)).first.id, slot);
  });

  test('spend 5,000, give back 1,000 to Mine and 3,000 to Ration', () async {
    final slot = await createMedicalTest();
    final bank = ledger.accounts.values.firstWhere((a) => a.name == 'Bank').id;
    await repo.expense(
      DateTime(2026, 11, 6),
      taka(5000),
      categoryId: slot,
      from: (account: bank, fund: ledger.spendingFund.id),
    );
    await reload();
    var status = ledger.slotsIn(nov).single;
    expect((status.budget, status.spent, status.left), (taka(9000), taka(5000), taka(4000)));
    expect(status.sources, {category('Ration'): taka(6000), category('Mine'): taka(3000)});

    await repo.giveBack(
      nov,
      slot: slot,
      to: [
        (category: category('Mine'), amount: taka(1000)),
        (category: category('Ration'), amount: taka(3000)),
      ],
      date: DateTime(2026, 11, 7),
    );
    await reload();
    status = ledger.slotsIn(nov).single;
    expect((status.budget, status.spent, status.left), (taka(5000), taka(5000), 0));
    expect(line(nov, 'Ration').budget, taka(11000));
    expect(line(nov, 'Mine').budget, taka(2000));
    expect(ledger.summary(nov).budget, taka(54280));
    expect(ledger.summary(nov).budgetLeft, taka(54280) - taka(5000));
  });

  test('budget can be moved to cover an overspent category', () async {
    await repo.moveBudget(
      const Period(2026, 9),
      from: category('Ration'),
      to: category('Random'),
      amount: taka(580),
      date: DateTime(2026, 9, 20),
    );
    await reload();
    final random = line(const Period(2026, 9), 'Random');
    expect(random.budget, taka(5580));
    expect(line(const Period(2026, 9), 'Ration').remaining, 0);
    expect(ledger.movableFrom(category('Ration'), const Period(2026, 9)), 0);
  });

  test('a section with its own amount includes moves under it', () async {
    await repo.setBudget(nov, category('Fixed'), taka(32000));
    await repo.moveBudget(
      nov,
      from: category('Gas'),
      to: category('Ration'),
      amount: taka(80),
      date: day,
    );
    await reload();
    expect(line(nov, 'Fixed').budget, taka(31920));
    expect(line(nov, 'Ration').budget, taka(14080));
  });

  test('giving back in proportion, rounding to the largest source', () async {
    await createMedicalTest();
    final shares = ledger.giveBackShares(ledger.slotsIn(nov).single, taka(4000));
    expect(shares, [
      (category: category('Ration'), amount: 266667),
      (category: category('Mine'), amount: 133333),
    ]);
  });

  test('at month end, what is left in a slot goes back to its sources', () async {
    await createMedicalTest();
    await repo.returnSlotLeftovers(nov, ledger);
    await reload();
    expect(ledger.slotsIn(nov).single.left, 0);
    expect(line(nov, 'Ration').budget, taka(14000));
    expect(line(nov, 'Mine').budget, taka(4000));
    expect(ledger.movesIn(nov).last.date, DateTime(2026, 11, 30));
  });

  test('backups keep slots and moves', () async {
    await createMedicalTest();
    final copy = memoryDb();
    await Backup.restore(copy, Backup.read(await Backup.export(db)));
    final l = await Ledger.load(copy);
    expect(l.slotsIn(nov).single.budget, taka(9000));
    expect(l.movesIn(nov).length, 2);
    await copy.close();
  });

  test('a version 3 database upgrades with its data intact', () async {
    final schemaV3 = File('test/fixtures/schema_v3.sql').readAsStringSync();
    final old = AppDatabase(
      DatabaseConnection(
        NativeDatabase.memory(
          setup: (raw) {
            raw.execute(schemaV3);
            raw.execute("INSERT INTO accounts (name, type) VALUES ('City Bank', 'bank')");
            raw.execute("INSERT INTO funds (name, kind) VALUES ('Spending', 'spending')");
            raw.execute("INSERT INTO categories (name, kind) VALUES ('Ration', 'expense')");
            raw.execute(
              'INSERT INTO budgets (year, month, category_id, amount) VALUES (2026, 10, 1, 1400000)',
            );
            raw.execute('PRAGMA user_version = 3');
          },
        ),
        closeStreamsSynchronously: true,
      ),
    );
    final l = await Ledger.load(old);
    expect(
      l.categoryLines(const Period(2026, 10), CategoryKind.expense).single.budget,
      taka(14000),
    );
    expect(
      (await old.customSelect('PRAGMA user_version').getSingle()).data.values.single,
      old.schemaVersion,
    );
    await old.close();
  });

  test('a slot with a date shows on Home from 3 days before until spent', () async {
    final slot = await repo.createSlot(
      nov,
      name: 'Medical Test',
      from: [(category: category('Ration'), amount: taka(6000))],
      date: day,
      spendDay: 12,
    );
    await reload();
    List<String> slotReminders(DateTime d) => [
      for (final r in remindersFor(ledger, d))
        if (r.kind == ReminderKind.slot) '${r.title} | ${r.detail}',
    ];

    expect(slotReminders(DateTime(2026, 11, 8)), isEmpty);
    expect(slotReminders(DateTime(2026, 11, 9)), [
      'Medical Test in 3 days | ৳6,000 set aside · 12 Nov',
    ]);
    expect(slotReminders(DateTime(2026, 11, 12)), [
      'Medical Test today | ৳6,000 set aside · 12 Nov',
    ]);

    final bank = ledger.accounts.values.firstWhere((a) => a.name == 'Bank').id;
    final from = (account: bank, fund: ledger.spendingFund.id);
    await repo.expense(DateTime(2026, 11, 12), taka(2500), categoryId: slot, from: from);
    await reload();
    expect(slotReminders(DateTime(2026, 11, 14)), [
      'Medical Test was planned for 12 Nov | ৳3,500 left of ৳6,000 · 12 Nov',
    ]);

    await repo.expense(DateTime(2026, 11, 14), taka(3500), categoryId: slot, from: from);
    await reload();
    expect(slotReminders(DateTime(2026, 11, 14)), isEmpty, reason: 'all spent');
  });

  test('the date can be set later and changed', () async {
    final slot = await createMedicalTest();
    expect(ledger.categories[slot]!.dueDay, isNull);
    await repo.setSlotDay(slot, 20);
    await reload();
    expect(ledger.categories[slot]!.dueDay, 20);
    expect(
      remindersFor(
        ledger,
        DateTime(2026, 11, 18),
      ).where((r) => r.kind == ReminderKind.slot).single.title,
      'Medical Test in 2 days',
    );
    // A slot lives in its own month only.
    expect(
      remindersFor(ledger, DateTime(2026, 12, 18)).where((r) => r.kind == ReminderKind.slot),
      isEmpty,
    );
  });
}
