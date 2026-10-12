import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_fin_tracker/core/money.dart';
import 'package:my_fin_tracker/core/period.dart';
import 'package:my_fin_tracker/data/backup.dart';
import 'package:my_fin_tracker/data/database.dart';
import 'package:my_fin_tracker/data/ledger_repository.dart';
import 'package:my_fin_tracker/data/sample_data.dart';
import 'package:my_fin_tracker/data/setup_repository.dart';
import 'package:my_fin_tracker/ledger/ledger.dart';

AppDatabase memoryDb() =>
    AppDatabase(DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true));

/// Unused budget of a category saved to its linked pot when a month closes.
void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late AppDatabase db;
  late Ledger ledger;
  const sep = Period(2026, 9);
  const oct = Period(2026, 10);

  Future<void> reload() async => ledger = await Ledger.load(db);
  int category(String name) => ledger.categories.values.firstWhere((c) => c.name == name).id;
  int fund(String name) => ledger.funds.values.firstWhere((f) => f.name == name).id;
  int account(String name) => ledger.accounts.values.firstWhere((a) => a.name == name).id;
  Future<void> link(String cat, String pot) =>
      SetupRepository(db).updateCategory(category(cat), savingsFundId: Value(fund(pot)));

  setUp(() async {
    db = memoryDb();
    await loadSampleData(db);
    await reload();
    await link('Mine', 'New Laptop');
    await link('Random', 'Motorbike');
    await link('Fixed', 'Monthly Savings');
    await link('Electricity', 'Motorbike');
    await reload();
  });
  tearDown(() => db.close());

  test('September: Fixed and Mine move, Random (over budget) does not', () {
    final moves = ledger.unusedBudgetMoves(sep);
    expect(
      [for (final m in moves) (m.category.name, m.fund.name, m.amount)],
      [('Fixed', 'Monthly Savings', taka(320)), ('Mine', 'New Laptop', taka(850))],
    );
    expect(moves.every((m) => m.amount == m.unused), isTrue);
    // The money is in the bank's Spending part; it stays in the bank.
    expect(moves.first.parts, [(account: account('Bank'), amount: taka(320))]);
  });

  test('closing September saves it, and October starts with less to spend', () async {
    await LedgerRepository(db)
        .moveUnusedBudgets(sep, ledger.spendingFund.id, ledger.unusedBudgetMoves(sep));
    await reload();
    expect(ledger.summary(sep).leftToSpend, taka(8950));
    expect(ledger.summary(oct).carriedForward, taka(8950));
    expect(ledger.fundBalance(fund('New Laptop'), before: sep.end), taka(19350));
    expect(ledger.fundBalance(fund('Monthly Savings'), before: sep.end), taka(47320));
    expect(ledger.liquidTotal(before: sep.end), taka(85620), reason: 'only the purpose changed');
    expect(ledger.accountBalance(account('Bank'), before: sep.end), taka(74920));
    final saved = ledger.entries.where((e) => e.note == 'Unused Mine budget, September 2026');
    expect(saved.single.date, DateTime(2026, 9, 30));
    expect(ledger.unusedBudgetMoves(sep), isEmpty, reason: 'nothing left to move a second time');
  });

  test('never moves more than is left in Spending', () async {
    await link('Ration', 'Monthly Savings');
    await LedgerRepository(db).setBudget(oct, category('Ration'), taka(40000));
    await reload();
    final moves = ledger.unusedBudgetMoves(oct);
    final total = moves.fold<Poisha>(0, (t, m) => t + m.amount);
    expect(total, ledger.summary(oct).leftToSpend);
    expect(moves.last.amount, lessThan(moves.last.unused));
  });

  test('a backup keeps the links, and an older backup without them restores', () async {
    final bytes = await Backup.export(db);
    final copy = memoryDb();
    await Backup.restore(copy, Backup.read(bytes));
    final restored = await Ledger.load(copy);
    expect(
      restored.categories.values.firstWhere((c) => c.name == 'Mine').savingsFundId,
      fund('New Laptop'),
    );
    await copy.close();

    final archive = ZipDecoder().decodeBytes(bytes);
    final data =
        jsonDecode(utf8.decode(archive.findFile('data.json')!.content)) as Map<String, dynamic>;
    for (final c in data['categories'] as List) {
      (c as Map).remove('savingsFundId');
    }
    final dataBytes = utf8.encode(jsonEncode(data));
    final manifest =
        jsonDecode(utf8.decode(archive.findFile('manifest.json')!.content)) as Map<String, dynamic>
          ..['sha256'] = sha256.convert(dataBytes).toString();
    final old = Archive()
      ..addFile(ArchiveFile.string('manifest.json', jsonEncode(manifest)))
      ..addFile(ArchiveFile.bytes('data.json', dataBytes));
    final copy2 = memoryDb();
    await Backup.restore(copy2, Backup.read(ZipEncoder().encodeBytes(old)));
    final l2 = await Ledger.load(copy2);
    expect(l2.categories.values.every((c) => c.savingsFundId == null), isTrue);
    expect(l2.netWorth(), ledger.netWorth());
    await copy2.close();
  });

  test('a version 2 database upgrades with its data intact', () async {
    final schemaV2 = File('test/fixtures/schema_v2.sql').readAsStringSync();
    final old = AppDatabase(
      DatabaseConnection(
        NativeDatabase.memory(
          setup: (raw) {
            raw.execute(schemaV2);
            raw.execute("INSERT INTO accounts (name, type) VALUES ('City Bank', 'bank')");
            raw.execute("INSERT INTO funds (name, kind) VALUES ('Spending', 'spending')");
            raw.execute("INSERT INTO funds (name, kind) VALUES ('Laptop', 'goal')");
            raw.execute("INSERT INTO categories (name, kind) VALUES ('Mine', 'expense')");
            raw.execute(
              "INSERT INTO entries (date, type, amount, note) VALUES (1790000000, 'opening', 2000000, 'Start')",
            );
            raw.execute(
              'INSERT INTO postings (entry_id, account_id, fund_id, amount) VALUES (1, 1, 1, 2000000)',
            );
            raw.execute(
              "INSERT INTO trackers (name, kind, start_date) VALUES ('Trip', 'countdown', 1790000000)",
            );
            raw.execute('PRAGMA user_version = 2');
          },
        ),
        closeStreamsSynchronously: true,
      ),
    );
    var l = await Ledger.load(old);
    expect(l.netWorth(), taka(20000));
    expect(l.trackers.length, 1);
    expect(
      (await old.customSelect('PRAGMA user_version').getSingle()).data.values.single,
      old.schemaVersion,
    );
    await SetupRepository(old).updateCategory(1, savingsFundId: const Value(2));
    l = await Ledger.load(old);
    expect(l.categories[1]!.savingsFundId, 2);
    await old.close();
  });
}
