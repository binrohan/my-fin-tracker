import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_fin_tracker/core/money.dart';
import 'package:my_fin_tracker/data/backup.dart';
import 'package:my_fin_tracker/data/database.dart';
import 'package:my_fin_tracker/data/ledger_repository.dart';
import 'package:my_fin_tracker/data/receipts.dart';
import 'package:my_fin_tracker/data/sample_data.dart';
import 'package:my_fin_tracker/ledger/ledger.dart';

AppDatabase memoryDb() =>
    AppDatabase(DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true));

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late Directory temp;
  late AppDatabase db;
  late LedgerRepository repo;
  late ReceiptStore store;
  final photo = Uint8List.fromList(List.generate(2048, (i) => i % 251));

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('receipts_test');
    db = memoryDb();
    repo = LedgerRepository(db);
    store = ReceiptStore(Directory('${temp.path}/phone/receipts'));
    await loadSampleData(db);
  });
  tearDown(() async {
    await db.close();
    await temp.delete(recursive: true);
  });

  Future<(Ledger, int)> expenseWithReceipt() async {
    final ledger = await Ledger.load(db);
    final bank = ledger.accounts.values.firstWhere((a) => a.name == 'Bank').id;
    final ration = ledger.categories.values.firstWhere((c) => c.name == 'Ration').id;
    final id = await repo.expense(
      DateTime(2026, 10, 9),
      taka(1250),
      categoryId: ration,
      from: (account: bank, fund: ledger.spendingFund.id),
    );
    final source = File('${temp.path}/IMG_0001.JPG')..writeAsBytesSync(photo);
    final name = await store.add(source, now: DateTime(2026, 10, 9, 13));
    await repo.setReceipt(id, name);
    return (await Ledger.load(db), id);
  }

  test('a photo is copied into the folder and attached', () async {
    final (ledger, id) = await expenseWithReceipt();
    final entry = ledger.entries.firstWhere((e) => e.id == id);
    expect(entry.receipt, matches(RegExp(r'^receipt-\d+\.jpg$')));
    expect(store.file(entry.receipt!).readAsBytesSync(), photo);
  });

  test('editing an entry keeps its receipt', () async {
    final (ledger, id) = await expenseWithReceipt();
    final name = ledger.entries.firstWhere((e) => e.id == id).receipt;
    final newId = await repo.replaceEntry(
      id,
      () => repo.expense(
        DateTime(2026, 10, 9),
        taka(1300),
        categoryId: ledger.entries.firstWhere((e) => e.id == id).categoryId!,
        from: (account: ledger.postingsOf(id).first.accountId, fund: ledger.spendingFund.id),
      ),
    );
    final after = await Ledger.load(db);
    expect(after.entries.firstWhere((e) => e.id == newId).receipt, name);
  });

  test('backups carry the photos', () async {
    final (_, id) = await expenseWithReceipt();
    // A photo no entry refers to is left out.
    await store.add(File('${temp.path}/IMG_0001.JPG'), now: DateTime(2026, 1, 1));

    final contents = Backup.read(await Backup.export(db, receipts: store));
    expect(contents.receipts.length, 1);

    final other = memoryDb();
    final otherStore = ReceiptStore(Directory('${temp.path}/new-phone/receipts'));
    await Backup.restore(other, contents, receipts: otherStore);
    final restored = (await Ledger.load(other)).entries.firstWhere((e) => e.id == id);
    expect(otherStore.file(restored.receipt!).readAsBytesSync(), photo);
    await other.close();
  });

  test('a backup without photos still restores', () async {
    await expenseWithReceipt();
    final contents = Backup.read(await Backup.export(db));
    expect(contents.receipts, isEmpty);
    final other = memoryDb();
    await Backup.restore(other, contents, receipts: store);
    expect(store.folder.listSync(), isEmpty, reason: 'restore replaces all photos');
    await other.close();
  });

  test('names that could leave the folder are refused', () {
    expect(ReceiptStore.isValidName('receipt-123.jpg'), isTrue);
    expect(ReceiptStore.isValidName('../data.jpg'), isFalse);
    expect(ReceiptStore.isValidName('a/b.jpg'), isFalse);
    expect(ReceiptStore.isValidName('receipt'), isFalse);
  });

  test('a version 4 database upgrades with its data intact', () async {
    final schemaV4 = File('test/fixtures/schema_v4.sql').readAsStringSync();
    final old = AppDatabase(
      DatabaseConnection(
        NativeDatabase.memory(
          setup: (raw) {
            raw.execute(schemaV4);
            raw.execute("INSERT INTO accounts (name, type) VALUES ('City Bank', 'bank')");
            raw.execute("INSERT INTO funds (name, kind) VALUES ('Spending', 'spending')");
            raw.execute("INSERT INTO categories (name, kind) VALUES ('Ration', 'expense')");
            raw.execute(
              "INSERT INTO entries (date, type, amount, category_id, note) "
              "VALUES (1791331200, 'expense', 125000, 1, 'Shwapno')",
            );
            raw.execute(
              'INSERT INTO postings (entry_id, account_id, fund_id, amount) VALUES (1, 1, 1, -125000)',
            );
            raw.execute('PRAGMA user_version = 4');
          },
        ),
        closeStreamsSynchronously: true,
      ),
    );
    final l = await Ledger.load(old);
    expect(l.entries.single.note, 'Shwapno');
    expect(l.entries.single.receipt, isNull);
    expect(l.liquidTotal(), -taka(1250));
    await LedgerRepository(old).setReceipt(l.entries.single.id, 'receipt-1.jpg');
    expect((await Ledger.load(old)).entries.single.receipt, 'receipt-1.jpg');
    final version = await old.customSelect('PRAGMA user_version').getSingle();
    expect(version.data.values.single, old.schemaVersion);
    await old.close();
  });
}
