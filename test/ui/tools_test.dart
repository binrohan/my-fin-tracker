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
import 'package:my_fin_tracker/features/tools/tax_rules_screen.dart';
import 'package:my_fin_tracker/features/tools/tax_screen.dart';
import 'package:my_fin_tracker/features/tools/zakat_screen.dart';
import 'package:my_fin_tracker/ledger/ledger.dart';

/// Zakat and income tax at Galaxy S24 size, with the example data.
void main() {
  late AppDatabase db;
  late Ledger sample;

  setUp(() async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    db = AppDatabase(DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true));
    await loadSampleData(db);
    sample = await Ledger.load(db);
  });
  tearDown(() => db.close());

  Future<void> pump(WidgetTester tester, Widget screen, Brightness brightness) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 1080 / 384;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ledgerProvider.overrideWith((ref) => Stream.value(sample)),
          repositoryProvider.overrideWithValue(LedgerRepository(db)),
          todayProvider.overrideWithValue(DateTime(2026, 10, 8)),
        ],
        child: MaterialApp(theme: buildTheme(brightness), home: screen),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder page() => find.byType(Scrollable).first;

  for (final brightness in Brightness.values) {
    testWidgets('zakat (${brightness.name})', (tester) async {
      await pump(tester, const ZakatScreen(), brightness);
      expect(find.text('Bank, cash and wallets'), findsOneWidget);
      // Silver at ৳250 a gram.
      final silverPrice = find.widgetWithText(TextField, 'Price a gram').last;
      await tester.ensureVisible(silverPrice);
      await tester.enterText(silverPrice, '250');
      await tester.pumpAndSettle();
      expect(find.text('Get today\'s price'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('ZAKAT TODAY, 2.5% OF NET'),
        300,
        scrollable: page(),
      );
      expect(find.text('Not set'), findsOneWidget, reason: 'no zakat date yet');
      // Let the delayed save run.
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('income tax (${brightness.name})', (tester) async {
      await pump(tester, const TaxScreen(), brightness);
      expect(find.text('Income year Jul 2026 to Jun 2027'), findsOneWidget);
      expect(find.text('2026-27'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Up to today').last, 300, scrollable: page());
      final segment = find.descendant(
        of: find.byType(SegmentedButton<bool>),
        matching: find.text('Up to today'),
      );
      await tester.ensureVisible(segment);
      await tester.pumpAndSettle();
      await tester.tap(segment);
      await tester.pumpAndSettle();
      expect(find.textContaining('as if the year ended today'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Tax for the year'), 300, scrollable: page());
      expect(find.text('HOW IT IS WORKED OUT'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('2025-26'), -300, scrollable: page());
      await tester.tap(find.text('2025-26'));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('tax rates (${brightness.name})', (tester) async {
      await pump(tester, const TaxRulesScreen(), brightness);
      expect(find.text('The rest'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Add a slab'), 300, scrollable: page());
      await tester.ensureVisible(find.text('Add a slab'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add a slab'));
      await tester.pumpAndSettle();
      expect(find.text('Next'), findsNWidgets(5));
      await tester.scrollUntilVisible(find.text('Save'), 300, scrollable: page());
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      final saved = await tester.runAsync(
        () async => (await Ledger.load(db)).settings['tax_rules'],
      );
      expect(saved, contains('your rates'));
    });
  }
}
