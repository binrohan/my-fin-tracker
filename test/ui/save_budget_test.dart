import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_fin_tracker/app/providers.dart';
import 'package:my_fin_tracker/app/theme.dart';
import 'package:my_fin_tracker/data/database.dart';
import 'package:my_fin_tracker/data/ledger_repository.dart';
import 'package:my_fin_tracker/data/sample_data.dart';
import 'package:my_fin_tracker/data/setup_repository.dart';
import 'package:my_fin_tracker/features/spend/spend_screen.dart';
import 'package:my_fin_tracker/ledger/ledger.dart';

void main() {
  late AppDatabase db;
  late Ledger ledger;

  setUp(() async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    db = AppDatabase(DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true));
    await loadSampleData(db);
    var l = await Ledger.load(db);
    final water = l.categories.values.firstWhere((c) => c.name == 'Water & Service').id;
    final savings = l.funds.values.firstWhere((f) => f.name == 'Monthly Savings').id;
    await SetupRepository(db).updateCategory(water, savingsFundId: Value(savings));
    ledger = await Ledger.load(db);
  });
  tearDown(() => db.close());

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 1080 / 384;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ledgerProvider.overrideWith((ref) => Stream.value(ledger)),
          repositoryProvider.overrideWithValue(LedgerRepository(db)),
          todayProvider.overrideWithValue(DateTime(2026, 10, 8)),
        ],
        child: MaterialApp(
          theme: buildTheme(Brightness.light),
          home: const Scaffold(body: SpendScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('Save to pot starts with a linked category and its pot', (tester) async {
    await pump(tester);
    await tester.scrollUntilVisible(find.text('Save to pot'), 300);
    await tester.ensureVisible(find.text('Save to pot'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save to pot'));
    await tester.pumpAndSettle();
    expect(find.text('Save to a pot · October 2026'), findsOneWidget);
    expect(find.text('Water & Service'), findsWidgets);
    expect(find.textContaining('Save ৳'), findsOneWidget);
    expect(find.textContaining('to Monthly Savings'), findsOneWidget);
  });

  testWidgets('tapping a linked category opens it', (tester) async {
    await pump(tester);
    await tester.tap(find.text('Water & Service'));
    await tester.pumpAndSettle();
    expect(find.text('Save to a pot · October 2026'), findsOneWidget);
    expect(find.textContaining('still unspent'), findsOneWidget);
  });
}
