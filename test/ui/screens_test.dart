import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_fin_tracker/app/providers.dart';
import 'package:my_fin_tracker/app/theme.dart';
import 'package:my_fin_tracker/data/database.dart';
import 'package:my_fin_tracker/data/sample_data.dart';
import 'package:my_fin_tracker/features/home/home_screen.dart';
import 'package:my_fin_tracker/features/more/more_screen.dart';
import 'package:my_fin_tracker/features/save/save_screen.dart';
import 'package:my_fin_tracker/features/spend/spend_screen.dart';
import 'package:my_fin_tracker/ledger/ledger.dart';

/// Draws each tab at Galaxy S24 size (384 × 832 dp) with the example data.
/// A layout overflow or exception fails the test.
void main() {
  late Ledger sample;
  late Ledger empty;

  setUpAll(() async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    final db = AppDatabase(DatabaseConnection(NativeDatabase.memory(),
        closeStreamsSynchronously: true));
    empty = await Ledger.load(db);
    await loadSampleData(db);
    sample = await Ledger.load(db);
    await db.close();
  });

  Future<void> pump(WidgetTester tester, Widget screen, Ledger ledger,
      {Brightness brightness = Brightness.light}) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 1080 / 384;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        ledgerProvider.overrideWith((ref) => Stream.value(ledger)),
        todayProvider.overrideWithValue(DateTime(2026, 10, 8)),
      ],
      child: MaterialApp(
        theme: buildTheme(brightness),
        home: Scaffold(body: screen),
      ),
    ));
    await tester.pumpAndSettle();
  }

  for (final brightness in Brightness.values) {
    group('${brightness.name} theme', () {
      testWidgets('Home shows the October figures', (tester) async {
        await pump(tester, const HomeScreen(), sample, brightness: brightness);
        expect(find.text('October 2026'), findsOneWidget);
        expect(find.text('৳24,420'), findsWidgets);
        expect(find.text('≈ ৳1,018 a day for 24 days'), findsOneWidget);
        expect(find.text('৳1,23,970'), findsOneWidget);
        expect(find.text('৳1,32,920'), findsNWidgets(2));
        expect(find.text('✓ Balanced'), findsOneWidget);
        await tester.scrollUntilVisible(find.text('৳4,28,770'), 300);
        expect(find.text('৳4,28,770'), findsOneWidget);
      });

      testWidgets('Spend shows budget against actual', (tester) async {
        await pump(tester, const SpendScreen(), sample, brightness: brightness);
        expect(find.text('৳32,700'), findsOneWidget);
        expect(find.text('of ৳54,280'), findsOneWidget);
        expect(find.text('Fixed'), findsOneWidget);
        expect(find.text('due 15 Oct'), findsOneWidget);
      });

      testWidgets('Save shows goals and loans', (tester) async {
        await pump(tester, const SaveScreen(), sample, brightness: brightness);
        expect(find.text('৳68,000'), findsOneWidget);
        expect(find.text('৳2,250 owed back'), findsOneWidget);
        expect(find.text('Behind'), findsOneWidget);
        expect(find.text('On track'), findsOneWidget);
        await tester.scrollUntilVisible(find.text('Karim'), 300);
        expect(find.text('Karim'), findsOneWidget);
      });

      testWidgets('More lists accounts', (tester) async {
        await pump(tester, const MoreScreen(), sample, brightness: brightness);
        expect(find.textContaining('Bank', findRichText: true), findsWidgets);
        expect(find.text('Load example'), findsOneWidget);
      });
    });
  }

  testWidgets('Home before any entries', (tester) async {
    await pump(tester, const HomeScreen(), empty);
    expect(find.text('No entries yet'), findsOneWidget);
  });
}
