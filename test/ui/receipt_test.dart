import 'dart:io';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_fin_tracker/app/providers.dart';
import 'package:my_fin_tracker/app/theme.dart';
import 'package:my_fin_tracker/data/database.dart';
import 'package:my_fin_tracker/data/receipts.dart';
import 'package:my_fin_tracker/data/sample_data.dart';
import 'package:my_fin_tracker/features/entries/entries_screen.dart';
import 'package:my_fin_tracker/ledger/enums.dart';
import 'package:my_fin_tracker/ledger/ledger.dart';

void main() {
  late Ledger sample;

  setUpAll(() async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    final db = AppDatabase(
      DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true),
    );
    await loadSampleData(db);
    final expense = (await Ledger.load(db)).entries.firstWhere((e) => e.type == EntryType.expense);
    // A photo whose file is not on this phone: the sheet says so.
    await (db.update(db.entries)..where((e) => e.id.equals(expense.id))).write(
      const EntriesCompanion(receipt: Value('receipt-1.jpg')),
    );
    sample = await Ledger.load(db);
    await db.close();
  });

  Future<void> open(WidgetTester tester, Entry entry) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 1080 / 384;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ledgerProvider.overrideWith((ref) => Stream.value(sample)),
          todayProvider.overrideWithValue(DateTime(2026, 10, 8)),
          receiptStoreProvider.overrideWith(
            (ref) async => ReceiptStore(Directory('${Directory.systemTemp.path}/no-receipts')),
          ),
        ],
        child: MaterialApp(
          theme: buildTheme(Brightness.light),
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showEntryDetails(context, entry),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('an expense offers a receipt photo', (tester) async {
    final entry = sample.entries.where((e) => e.type == EntryType.expense).last;
    expect(entry.receipt, isNull);
    await open(tester, entry);
    expect(find.text('Add receipt photo'), findsOneWidget);
  });

  testWidgets('an entry with a receipt shows it', (tester) async {
    final entry = sample.entries.firstWhere((e) => e.receipt != null);
    await open(tester, entry);
    expect(find.text('Photo not found'), findsOneWidget);
    expect(find.text('Replace'), findsOneWidget);
    expect(find.text('Remove'), findsOneWidget);
  });
}
