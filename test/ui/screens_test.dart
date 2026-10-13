import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:my_fin_tracker/app/appearance.dart';
import 'package:my_fin_tracker/app/providers.dart';
import 'package:my_fin_tracker/app/theme.dart';
import 'package:my_fin_tracker/data/database.dart';
import 'package:my_fin_tracker/data/sample_data.dart';
import 'package:my_fin_tracker/features/buying/buying_screen.dart';
import 'package:my_fin_tracker/features/cash/cash_screen.dart';
import 'package:my_fin_tracker/features/investments/investments_screen.dart';
import 'package:my_fin_tracker/features/plan/monthly_plan_screen.dart';
import 'package:my_fin_tracker/features/reports/reports_screen.dart';
import 'package:my_fin_tracker/features/setup/categories_screen.dart';
import 'package:my_fin_tracker/features/setup/starting_balances_screen.dart';
import 'package:my_fin_tracker/features/home/month_tasks.dart';
import 'package:my_fin_tracker/data/setup_repository.dart';
import 'package:my_fin_tracker/core/period.dart';
import 'package:my_fin_tracker/features/trackers/trackers_screen.dart';
import 'package:my_fin_tracker/features/home/home_screen.dart';
import 'package:my_fin_tracker/data/ledger_repository.dart';
import 'package:my_fin_tracker/core/money.dart';
import 'package:my_fin_tracker/features/loans/loans_screen.dart';
import 'package:my_fin_tracker/features/save/fund_screen.dart';
import 'package:my_fin_tracker/features/more/more_screen.dart';
import 'package:my_fin_tracker/features/save/save_screen.dart';
import 'package:my_fin_tracker/features/spend/spend_screen.dart';
import 'package:my_fin_tracker/ledger/ledger.dart';
import 'package:my_fin_tracker/ledger/allocation.dart';
import 'package:my_fin_tracker/features/plan/record_income_sheet.dart';

/// Draws each tab at Galaxy S24 size (384 × 832 dp) with the example data.
/// A layout overflow or exception fails the test.
void main() {
  late Ledger sample;
  late Ledger empty;

  setUpAll(() async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    final db = AppDatabase(
      DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true),
    );
    empty = await Ledger.load(db);
    await loadSampleData(db);
    sample = await Ledger.load(db);
    await db.close();
  });

  Future<void> pump(
    WidgetTester tester,
    Widget screen,
    Ledger ledger, {
    Brightness brightness = Brightness.light,
    bool fullScreen = false,
  }) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 1080 / 384;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ledgerProvider.overrideWith((ref) => Stream.value(ledger)),
          todayProvider.overrideWithValue(DateTime(2026, 10, 8)),
          packageInfoProvider.overrideWith(
            (ref) async => PackageInfo(
              appName: 'My Fin Tracker',
              packageName: 'com.myfin.my_fin_tracker',
              version: '1.0.6',
              buildNumber: '13',
            ),
          ),
        ],
        child: MaterialApp(
          theme: buildTheme(brightness),
          home: fullScreen ? screen : Scaffold(body: screen),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final brightness in Brightness.values) {
    group('${brightness.name} theme', () {
      testWidgets('Home shows the October figures', (tester) async {
        await pump(tester, const HomeScreen(), sample, brightness: brightness);
        expect(find.text('October 2026'), findsOneWidget);
        expect(find.text('৳24,420'), findsWidgets);
        expect(find.text('≈ ৳1,018 a day for 24 days'), findsOneWidget);
        expect(find.text('Balanced'), findsOneWidget);
        expect(find.text('September 2026 is over'), findsOneWidget);
        expect(find.text('NEEDS ATTENTION'), findsOneWidget);
        expect(find.text('No backup yet'), findsOneWidget);
        expect(find.text('Water & Service due in 2 days'), findsOneWidget);
        await tester.scrollUntilVisible(find.text('৳1,23,970'), 300);
        expect(find.text('৳1,23,970'), findsOneWidget);
        await tester.scrollUntilVisible(find.text('৳1,32,920').last, 300);
        expect(find.text('৳1,32,920'), findsNWidgets(2));
        await tester.scrollUntilVisible(find.text('৳4,28,770'), 300);
        expect(find.text('৳4,28,770'), findsOneWidget);
      });

      testWidgets('Spend shows budget against actual', (tester) async {
        await pump(tester, const SpendScreen(), sample, brightness: brightness);
        expect(find.text('৳32,700'), findsOneWidget);
        expect(find.text('of ৳54,280'), findsOneWidget);
        expect(find.text('Fixed'), findsOneWidget);
        expect(find.text('due 15 Oct'), findsOneWidget);
        await tester.scrollUntilVisible(find.text('Pay 2 remaining fixed bills · ৳4,000'), 300);
        expect(find.text('Pay 2 remaining fixed bills · ৳4,000'), findsOneWidget);
      });

      testWidgets('Save shows goals and loans', (tester) async {
        await pump(tester, const SaveScreen(), sample, brightness: brightness);
        expect(find.text('৳68,000'), findsOneWidget);
        expect(find.text('৳2,250 owed back'), findsOneWidget);
        expect(find.text('Behind'), findsOneWidget);
        expect(find.text('On track'), findsOneWidget);
        await tester.scrollUntilVisible(find.text('Lent to Karim'), 300);
        expect(find.text('Lent to Karim'), findsOneWidget);
      });

      testWidgets('More lists setup and backup', (tester) async {
        await pump(tester, const MoreScreen(), sample, brightness: brightness);
        expect(find.text('Backup & restore'), findsOneWidget);
        expect(find.text('No backup yet'), findsOneWidget);
        expect(find.text('Starting balances'), findsOneWidget);
        await tester.scrollUntilVisible(find.text('5% of the amount'), 300);
        expect(find.text('5% of the amount'), findsOneWidget);
        await tester.scrollUntilVisible(find.text('Load example'), 300);
        expect(find.text('Load example'), findsOneWidget);
      });
    });
  }

  group('Phase 3 screens', () {
    int fund(String name) => sample.funds.values.firstWhere((f) => f.name == name).id;

    for (final brightness in Brightness.values) {
      testWidgets('goal screen (${brightness.name})', (tester) async {
        await pump(
          tester,
          FundScreen(fundId: fund('New Laptop')),
          sample,
          brightness: brightness,
          fullScreen: true,
        );
        expect(find.text('New Laptop'), findsOneWidget);
        expect(find.text('৳26,500'), findsWidgets);
        expect(find.text('Buy it'), findsOneWidget);
        expect(find.text('Behind'), findsOneWidget);
      });

      testWidgets('savings screen (${brightness.name})', (tester) async {
        await pump(
          tester,
          FundScreen(fundId: fund('Monthly Savings')),
          sample,
          brightness: brightness,
          fullScreen: true,
        );
        expect(find.text('৳2,250 borrowed, to be paid back'), findsOneWidget);
        expect(find.text('Borrow'), findsOneWidget);
      });

      testWidgets('loans, both tabs (${brightness.name})', (tester) async {
        await pump(tester, const LoansScreen(), sample, brightness: brightness, fullScreen: true);
        expect(find.text('From Monthly Savings'), findsOneWidget);
        await tester.tap(find.text('People'));
        await tester.pumpAndSettle();
        expect(find.text('Lent to Karim'), findsOneWidget);
        expect(find.text('Borrowed from Brother'), findsOneWidget);
        expect(find.text('৳6,000'), findsWidgets);
        expect(find.text('৳10,000'), findsWidgets);
      });

      testWidgets('one loan (${brightness.name})', (tester) async {
        final own = sample.loans.firstWhere((l) => l.personAccountId == null);
        await pump(
          tester,
          LoanScreen(loanId: own.id),
          sample,
          brightness: brightness,
          fullScreen: true,
        );
        expect(find.text('Pay back'), findsOneWidget);
        expect(find.text('Charge 5%'), findsOneWidget);
        await tester.scrollUntilVisible(find.text('TIMELINE'), 300);
        expect(find.text('TIMELINE'), findsOneWidget);
      });

      testWidgets('cash drawer (${brightness.name})', (tester) async {
        await pump(tester, const CashScreen(), sample, brightness: brightness, fullScreen: true);
        expect(find.text('৳7,300'), findsOneWidget);
        expect(find.text('Motorbike'), findsOneWidget);
        expect(find.text('Count cash'), findsOneWidget);
        await tester.tap(find.text('Count cash'));
        await tester.pumpAndSettle();
        expect(find.text('৳1000'), findsOneWidget);
      });
    }
  });

  group('Phase 4 screens', () {
    for (final brightness in Brightness.values) {
      testWidgets('investments (${brightness.name})', (tester) async {
        await pump(
          tester,
          const InvestmentsScreen(),
          sample,
          brightness: brightness,
          fullScreen: true,
        );
        expect(find.text('৳2,99,850'), findsOneWidget);
        expect(find.text('DPS · Bank'), findsOneWidget);
        expect(find.text('19 of 60 instalments · ৳5,000/mo'), findsOneWidget);
        expect(find.textContaining('7.5% a year'), findsOneWidget);
      });

      testWidgets('one investment (${brightness.name})', (tester) async {
        final dps = sample.accounts.values.firstWhere((a) => a.name == 'DPS · Bank');
        await pump(
          tester,
          InvestmentScreen(accountId: dps.id),
          sample,
          brightness: brightness,
          fullScreen: true,
        );
        expect(find.text('Pay instalment'), findsOneWidget);
        expect(find.text('Update value'), findsOneWidget);
      });

      testWidgets('buying (${brightness.name})', (tester) async {
        await pump(tester, const BuyingScreen(), sample, brightness: brightness, fullScreen: true);
        expect(find.text('৳65,900'), findsOneWidget);
        expect(find.text('Ceiling fan'), findsOneWidget);
        expect(find.text('Refrigerator'), findsOneWidget);
        expect(find.text('Warranty until Sep 2028'), findsOneWidget);
      });

      testWidgets('trackers (${brightness.name})', (tester) async {
        await pump(
          tester,
          const TrackersScreen(),
          sample,
          brightness: brightness,
          fullScreen: true,
        );
        expect(find.text('Sylhet Trip'), findsOneWidget);
        expect(find.text('71 days to go'), findsOneWidget);
        expect(find.text('৳21,000'), findsOneWidget);
        expect(find.text('৳38,750'), findsOneWidget);
      });

      testWidgets('one tracker (${brightness.name})', (tester) async {
        final office = sample.trackers.values.firstWhere((t) => t.name == 'Home Office Setup');
        await pump(
          tester,
          TrackerScreen(trackerId: office.id),
          sample,
          brightness: brightness,
          fullScreen: true,
        );
        expect(find.text('Before the app'), findsOneWidget);
        expect(find.text('৳37,500'), findsOneWidget);
        final lamp = find.textContaining('Desk lamp  Sep 18', findRichText: true);
        await tester.scrollUntilVisible(lamp, 300);
        expect(lamp, findsOneWidget);
      });
    }
  });

  group('Phase 5 screens', () {
    for (final brightness in Brightness.values) {
      testWidgets('reports list (${brightness.name})', (tester) async {
        await pump(tester, const ReportsScreen(), sample, brightness: brightness, fullScreen: true);
        expect(find.text('October 2026'), findsOneWidget);
        expect(find.text('In progress'), findsOneWidget);
        expect(find.text('September 2026'), findsOneWidget);
        expect(find.text('Not closed yet'), findsOneWidget);
        await tester.scrollUntilVisible(find.text('Everything'), 300);
        expect(find.text('2026'), findsWidgets);
      });

      testWidgets('each report is its own button for screen readers (${brightness.name})', (
        tester,
      ) async {
        final handle = tester.ensureSemantics();
        await pump(tester, const ReportsScreen(), sample, brightness: brightness, fullScreen: true);
        await tester.scrollUntilVisible(find.text('Year so far'), 300);
        for (final label in ['September 2026', 'Year so far']) {
          final node = tester.getSemantics(find.text(label));
          expect(
            node.getSemanticsData().hasAction(SemanticsAction.tap),
            isTrue,
            reason: '$label should be tappable on its own',
          );
        }
        handle.dispose();
      });

      testWidgets('spend chart (${brightness.name})', (tester) async {
        await pump(tester, const SpendScreen(), sample, brightness: brightness);
        await tester.scrollUntilVisible(find.text('LAST 6 MONTHS'), 300);
        expect(find.text('Sep'), findsOneWidget);
        expect(find.text('Oct'), findsOneWidget);
        expect(
          find.bySemanticsLabel(RegExp(r'Spending by month\. Sep: ৳54,380 of ৳54,280')),
          findsOneWidget,
        );
      });
    }
  });

  group('Appearance', () {
    testWidgets('section and about card', (tester) async {
      await pump(tester, const MoreScreen(), sample);
      await tester.scrollUntilVisible(find.text('Pitch black'), 300);
      expect(find.text('System'), findsOneWidget);
      expect(find.text('Ocean blue'), findsOneWidget);
      expect(find.text('Plum'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Version 1.0.6 (build 13)'), 300);
      expect(find.text('Open-source licences'), findsOneWidget);
    });

    test('settings are read with safe defaults', () {
      expect(Appearance.fromSettings({}).mode, ThemeMode.system);
      final a = Appearance.fromSettings({
        Appearance.modeKey: 'dark',
        Appearance.paletteKey: 'plum',
        Appearance.pureBlackKey: 'true',
      });
      expect(a.mode, ThemeMode.dark);
      expect(a.palette, AppPalette.plum);
      expect(a.pureBlack, isTrue);
      expect(
        Appearance.fromSettings({Appearance.paletteKey: 'nonsense'}).palette,
        AppPalette.green,
      );
    });

    test('pitch black is black only in dark mode', () {
      expect(buildTheme(Brightness.dark, pureBlack: true).scaffoldBackgroundColor, Colors.black);
      expect(
        buildTheme(Brightness.light, pureBlack: true).scaffoldBackgroundColor,
        isNot(Colors.black),
      );
      expect(buildTheme(Brightness.dark).scaffoldBackgroundColor, isNot(Colors.black));
      expect(
        buildTheme(Brightness.light, palette: AppPalette.blue).colorScheme.primary,
        isNot(buildTheme(Brightness.light).colorScheme.primary),
      );
    });

    for (final palette in AppPalette.values) {
      testWidgets('home in ${palette.name}, pitch black', (tester) async {
        tester.view.physicalSize = const Size(1080, 2340);
        tester.view.devicePixelRatio = 1080 / 384;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              ledgerProvider.overrideWith((ref) => Stream.value(sample)),
              todayProvider.overrideWithValue(DateTime(2026, 10, 8)),
            ],
            child: MaterialApp(
              theme: buildTheme(Brightness.dark, palette: palette, pureBlack: true),
              home: const Scaffold(body: HomeScreen()),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('৳24,420'), findsWidgets);
      });
    }
  });

  group('Feedback screens', () {
    for (final brightness in Brightness.values) {
      testWidgets('monthly plan, all three tabs (${brightness.name})', (tester) async {
        await pump(
          tester,
          const MonthlyPlanScreen(),
          sample,
          brightness: brightness,
          fullScreen: true,
        );
        expect(find.text('Income'), findsWidgets);
        expect(find.text('Add income source'), findsOneWidget);
        expect(find.text('Usually arrives in'), findsWidgets);
        await tester.tap(find.text('Split'));
        await tester.pumpAndSettle();
        expect(find.text('MONTHLY EXPENSES'), findsOneWidget);
        expect(find.text('New goal'), findsOneWidget);
        await tester.tap(find.text('Expenses'));
        await tester.pumpAndSettle();
        expect(find.text('Fixed'), findsOneWidget);
        expect(find.text('House Rent'), findsOneWidget);
        expect(find.text('Adds up'), findsWidgets);
        await tester.scrollUntilVisible(
          find.text('Add section'),
          300,
          scrollable: find
              .byWidgetPredicate((w) => w is Scrollable && w.axisDirection == AxisDirection.down)
              .last,
        );
        expect(find.text('Add section'), findsOneWidget);
      });

      testWidgets('starting balances (${brightness.name})', (tester) async {
        await pump(
          tester,
          const StartingBalancesScreen(),
          sample,
          brightness: brightness,
          fullScreen: true,
        );
        expect(find.text('YOUR MONEY'), findsOneWidget);
        expect(find.widgetWithText(TextButton, 'Bank account'), findsOneWidget);
        expect(find.widgetWithText(TextButton, 'Mobile wallet'), findsOneWidget);
        await tester.scrollUntilVisible(
          find.text('Add savings'),
          300,
          scrollable: find
              .byWidgetPredicate((w) => w is Scrollable && w.axisDirection == AxisDirection.down)
              .first,
        );
        await tester.ensureVisible(find.text('Add savings'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Add savings'));
        await tester.pumpAndSettle();
        expect(find.text('Savings or goal'), findsOneWidget);
        expect(find.text('Kept in'), findsOneWidget);
      });
    }

    testWidgets('the expense tab shows when subsections do not add up', (tester) async {
      await pump(tester, const MonthlyPlanScreen(initialTab: 2), sample, fullScreen: true);
      final rent = find.ancestor(of: find.text('House Rent'), matching: find.byType(Row)).first;
      await tester.enterText(find.descendant(of: rent, matching: find.byType(TextField)), '24000');
      await tester.pumpAndSettle();
      expect(find.text('৳1,000 left to assign'), findsOneWidget);
    });
  });

  group('Unused budget to a pot', () {
    late Ledger linked;

    setUpAll(() async {
      final db = AppDatabase(
        DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true),
      );
      await loadSampleData(db);
      final l = await Ledger.load(db);
      final mine = l.categories.values.firstWhere((c) => c.name == 'Mine').id;
      final laptop = l.funds.values.firstWhere((f) => f.name == 'New Laptop').id;
      await SetupRepository(db).updateCategory(mine, savingsFundId: Value(laptop));
      linked = await Ledger.load(db);
      await db.close();
    });

    testWidgets('categories show the link and the editor offers it', (tester) async {
      await pump(tester, const CategoriesScreen(), linked, fullScreen: true);
      expect(find.text('Unused → New Laptop'), findsOneWidget);
      await tester.tap(find.text('Mine'));
      await tester.pumpAndSettle();
      expect(find.text('Unused budget goes to (optional)'), findsOneWidget);
      expect(find.text('New Laptop'), findsOneWidget);
    });

    testWidgets('closing September lists what will be saved', (tester) async {
      await pump(
        tester,
        Builder(
          builder: (context) => Center(
            child: TextButton(
              onPressed: () => showCloseMonth(context, const Period(2026, 9)),
              child: const Text('close'),
            ),
          ),
        ),
        linked,
      );
      await tester.tap(find.text('close'));
      await tester.pumpAndSettle();
      expect(find.text('UNUSED BUDGET TO SAVINGS'), findsOneWidget);
      expect(find.text('Mine → New Laptop'), findsOneWidget);
      expect(find.text('৳850'), findsOneWidget);
      expect(find.text('৳9,270'), findsOneWidget, reason: 'carried forward: 10,120 − 850');
    });
  });

  testWidgets('closing a month: split the leftover, the rest carries forward', (tester) async {
    await pump(
      tester,
      Builder(
        builder: (context) => Center(
          child: TextButton(
            onPressed: () => showCloseMonth(context, const Period(2026, 9)),
            child: const Text('close'),
          ),
        ),
      ),
      sample,
    );
    await tester.tap(find.text('close'));
    await tester.pumpAndSettle();
    expect(find.text('THE LEFTOVER: ৳10,120'), findsOneWidget);
    expect(find.text('৳10,120'), findsWidgets);

    await tester.tap(find.text('Move part to savings or a goal'));
    await tester.pumpAndSettle();
    final amount = find.byType(TextField).last;
    await tester.enterText(amount, '3000');
    await tester.pumpAndSettle();
    expect(find.text('৳7,120'), findsOneWidget, reason: 'carried forward');

    await tester.tap(find.text('Move part to savings or a goal'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, '9000');
    await tester.pumpAndSettle();
    expect(find.text('That is ৳1,880 more than the leftover.'), findsOneWidget);
    final close = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Close September 2026'),
    );
    expect(close.onPressed, isNull, reason: 'cannot close while over');
  });

  group('Slots', () {
    late Ledger withSlot;

    setUpAll(() async {
      final db = AppDatabase(
        DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true),
      );
      await loadSampleData(db);
      final l = await Ledger.load(db);
      int cat(String n) => l.categories.values.firstWhere((c) => c.name == n).id;
      await LedgerRepository(db).createSlot(
        const Period(2026, 10),
        name: 'Medical Test',
        from: [
          (category: cat('Mine'), amount: taka(2000)),
          (category: cat('Ration'), amount: taka(6000)),
        ],
        date: DateTime(2026, 10, 8),
      );
      withSlot = await Ledger.load(db);
      await db.close();
    });

    for (final brightness in Brightness.values) {
      testWidgets('Spend shows the slot and where it came from (${brightness.name})', (
        tester,
      ) async {
        await pump(tester, const SpendScreen(), withSlot, brightness: brightness);
        await tester.scrollUntilVisible(find.text('Give back'), 300);
        expect(find.text('Medical Test'), findsWidgets);
        expect(find.text('From Ration ৳6,000 + Mine ৳2,000'), findsOneWidget);
        expect(find.text('Spent ৳0 · left ৳8,000'), findsOneWidget);
        expect(find.text('New slot'), findsOneWidget);
        expect(find.text('Move budget'), findsOneWidget);
      });
    }

    testWidgets('new slot sheet checks what each category has left', (tester) async {
      await pump(tester, const SpendScreen(), sample);
      await tester.scrollUntilVisible(find.text('New slot'), 300);
      await tester.ensureVisible(find.text('New slot'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('New slot'));
      await tester.pumpAndSettle();
      expect(find.text('New slot · October 2026'), findsOneWidget);
      await tester.enterText(find.byType(TextField).first, 'Medical Test');
      await tester.enterText(find.byType(TextField).last, '50000');
      await tester.pumpAndSettle();
      expect(find.textContaining('Only ৳'), findsOneWidget);
      final create = tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Create slot'));
      expect(create.onPressed, isNull);
    });

    testWidgets('closing the month returns what is left in a slot', (tester) async {
      await pump(
        tester,
        Builder(
          builder: (context) => Center(
            child: TextButton(
              onPressed: () => showCloseMonth(context, const Period(2026, 10)),
              child: const Text('close'),
            ),
          ),
        ),
        withSlot,
      );
      await tester.tap(find.text('close'));
      await tester.pumpAndSettle();
      expect(find.text('SLOTS WITH MONEY LEFT'), findsOneWidget);
      expect(find.textContaining('back to Ration, Mine', findRichText: true), findsOneWidget);
    });
  });

  group('Income for next month', () {
    late Ledger held;
    late IncomeSource salarySource;

    setUpAll(() async {
      final db = AppDatabase(
        DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true),
      );
      await loadSampleData(db);
      var l = await Ledger.load(db);
      final salary = l.categories.values.firstWhere((c) => c.name == 'Salary').id;
      final bank = l.accounts.values.firstWhere((a) => a.name == 'Bank').id;
      salarySource = IncomeSource(
        categoryId: salary,
        amount: taka(85000),
        day: 26,
        accountId: bank,
        forNextMonth: true,
      );
      final repo = LedgerRepository(db);
      await repo.setSetting(
        AllocationPlan.settingKey,
        AllocationPlan(categoryId: salary, incomes: [salarySource]).encode(),
      );
      await repo.incomeForNextMonth(
        DateTime(2026, 10, 7),
        taka(85000),
        categoryId: salary,
        account: bank,
      );
      held = await Ledger.load(db);
      await db.close();
    });

    testWidgets('Home: ready for November, October unchanged', (tester) async {
      await pump(tester, const HomeScreen(), held);
      expect(find.text('READY FOR NOVEMBER 2026'), findsOneWidget);
      expect(find.text('৳85,000'), findsWidgets);
      expect(find.text('৳24,420'), findsWidgets, reason: 'left to spend unchanged');
      await tester.scrollUntilVisible(find.text('For next month'), 300);
      expect(find.text('For next month'), findsOneWidget);
    });

    testWidgets('recording it offers "For November", on by default', (tester) async {
      await pump(
        tester,
        Builder(
          builder: (context) => Center(
            child: TextButton(
              onPressed: () => showRecordIncome(context, salarySource),
              child: const Text('record'),
            ),
          ),
        ),
        held,
      );
      await tester.tap(find.text('record'));
      await tester.pumpAndSettle();
      expect(find.text('For November 2026'), findsOneWidget);
      final toggle = tester.widget<SwitchListTile>(
        find.widgetWithText(SwitchListTile, 'For November 2026'),
      );
      expect(toggle.value, isTrue);
    });
  });

  testWidgets('Home before any entries', (tester) async {
    await pump(tester, const HomeScreen(), empty);
    expect(find.text('Welcome'), findsOneWidget);
    expect(find.text('Enter starting balances'), findsOneWidget);
  });
}
