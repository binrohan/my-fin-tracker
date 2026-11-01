import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../ledger/enums.dart';
import 'default_data.dart';

part 'database.g.dart';

/// Where money is: Bank, Cash, bKash, a DPS, a person.
class Accounts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get type => textEnum<AccountType>()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  BoolColumn get archived => boolean().withDefault(const Constant(false))();
}

/// What money is for: Spending, Monthly Savings, a goal, Investments.
class Funds extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get kind => textEnum<FundKind>()();
  IntColumn get targetAmount => integer().nullable()();
  DateTimeColumn get targetDate => dateTime().nullable()();
  DateTimeColumn get achievedAt => dateTime().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  BoolColumn get archived => boolean().withDefault(const Constant(false))();
}

/// Expense and income categories. A category with a parent is a
/// sub-category (Fixed › House Rent).
@DataClassName('CategoryRow')
class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get parentId => integer().nullable().references(Categories, #id)();
  TextColumn get name => text()();
  TextColumn get kind => textEnum<CategoryKind>()();
  BoolColumn get isFixed => boolean().withDefault(const Constant(false))();

  /// Day of the month a fixed bill is due.
  IntColumn get dueDay => integer().nullable()();

  /// Savings pot or goal that receives this category's unused budget when
  /// a month is closed.
  IntColumn get savingsFundId => integer().nullable().references(Funds, #id)();

  /// Set for a slot: a category that exists for one month only, funded by
  /// moving budget from other categories.
  IntColumn get slotYear => integer().nullable()();
  IntColumn get slotMonth => integer().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  BoolColumn get archived => boolean().withDefault(const Constant(false))();
}

class Loans extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get kind => textEnum<LoanKind>()();

  /// The person for [LoanKind.lent] and [LoanKind.borrowed].
  IntColumn get personAccountId => integer().nullable().references(Accounts, #id)();

  /// Own savings: the fund borrowed from. People: the fund the money left
  /// from or went into, and returns to.
  IntColumn get fundId => integer().references(Funds, #id)();
  IntColumn get principal => integer()();

  /// Charge rate in basis points: 500 = 5%.
  IntColumn get chargeRateBp => integer().withDefault(const Constant(0))();
  IntColumn get charge => integer().withDefault(const Constant(0))();

  /// Already repaid before the loan was entered in the app.
  IntColumn get openingRepaid => integer().withDefault(const Constant(0))();
  DateTimeColumn get date => dateTime()();
  DateTimeColumn get dueDate => dateTime().nullable()();
  TextColumn get note => text().withDefault(const Constant(''))();
  DateTimeColumn get closedAt => dateTime().nullable()();
}

/// One user action. Its effect on balances lives in [Postings].
class Entries extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get date => dateTime()();
  TextColumn get type => textEnum<EntryType>()();

  /// The amount as the user entered it, always positive.
  IntColumn get amount => integer()();
  IntColumn get categoryId => integer().nullable().references(Categories, #id)();
  IntColumn get loanId => integer().nullable().references(Loans, #id)();

  /// Project or countdown tag (trackers arrive in Phase 4).
  IntColumn get trackerId => integer().nullable()();
  TextColumn get note => text().withDefault(const Constant(''))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// File name of a receipt photo in the app's receipts folder.
  TextColumn get receipt => text().nullable()();

  /// A move that saves part of [categoryId]'s budget to a pot during the
  /// month: it lowers that month's budget. (Month-close moves don't.)
  BoolColumn get budgetSave => boolean().nullable()();
}

/// A signed amount on one (account, fund) pair. Every balance in the app is
/// a sum of postings.
class Postings extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get entryId => integer().references(Entries, #id, onDelete: KeyAction.cascade)();
  IntColumn get accountId => integer().references(Accounts, #id)();
  IntColumn get fundId => integer().references(Funds, #id)();
  IntColumn get amount => integer()();
}

class Budgets extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get year => integer()();
  IntColumn get month => integer()();
  IntColumn get categoryId => integer().references(Categories, #id)();
  IntColumn get amount => integer()();

  @override
  List<Set<Column>> get uniqueKeys => [
    {year, month, categoryId},
  ];
}

/// A month you have closed, with the bank balance you confirmed.
class MonthCloses extends Table {
  IntColumn get year => integer()();
  IntColumn get month => integer()();
  DateTimeColumn get closedAt => dateTime()();
  IntColumn get confirmedBank => integer().nullable()();

  @override
  Set<Column> get primaryKey => {year, month};
}

/// Extra facts about an investment account (DPS, FDR, savings
/// certificate, shares). Its value is the account balance.
class InvestmentDetails extends Table {
  IntColumn get accountId => integer().references(Accounts, #id, onDelete: KeyAction.cascade)();
  TextColumn get kind => textEnum<InvestmentKind>()();
  DateTimeColumn get startDate => dateTime().nullable()();
  DateTimeColumn get maturityDate => dateTime().nullable()();

  /// Yearly rate in basis points: 1150 = 11.5%.
  IntColumn get rateBp => integer().nullable()();

  /// Monthly instalment for a DPS.
  IntColumn get instalment => integer().nullable()();
  IntColumn get totalInstalments => integer().nullable()();

  /// Instalments paid before the account was entered in the app.
  IntColumn get openingInstalments => integer().withDefault(const Constant(0))();
  TextColumn get note => text().withDefault(const Constant(''))();

  @override
  Set<Column> get primaryKey => {accountId};
}

/// The Buying register: major purchases, for the annual report.
class Purchases extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// The expense that paid for it. Deleting the expense deletes the record.
  IntColumn get entryId =>
      integer().nullable().references(Entries, #id, onDelete: KeyAction.cascade)();
  TextColumn get item => text()();
  DateTimeColumn get date => dateTime()();
  IntColumn get amount => integer()();
  TextColumn get shop => text().withDefault(const Constant(''))();
  DateTimeColumn get warrantyUntil => dateTime().nullable()();
  TextColumn get note => text().withDefault(const Constant(''))();
}

/// A long-term project (how much it cost so far) or a countdown budget
/// (how much is left). Entries are tagged with [Entries.trackerId].
class Trackers extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get kind => textEnum<TrackerKind>()();
  IntColumn get budget => integer().nullable()();

  /// Spent before the tracker was entered in the app.
  IntColumn get openingSpent => integer().withDefault(const Constant(0))();
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get endDate => dateTime().nullable()();
  BoolColumn get archived => boolean().withDefault(const Constant(false))();
}

/// Money spent on a tracker that did not come from your accounts: paid by
/// someone else, or cash the app doesn't track. Counts on the tracker only.
class TrackerAmounts extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get trackerId => integer().references(Trackers, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get date => dateTime()();
  IntColumn get amount => integer()();
  TextColumn get note => text().withDefault(const Constant(''))();
}

/// Budget moved from one category to another for one month only (for a
/// slot, or to cover an overspent category). The month's total budget
/// never changes; the Monthly plan is not touched.
class BudgetMoves extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get year => integer()();
  IntColumn get month => integer()();
  IntColumn get fromCategoryId =>
      integer().references(Categories, #id, onDelete: KeyAction.cascade)();
  IntColumn get toCategoryId =>
      integer().references(Categories, #id, onDelete: KeyAction.cascade)();
  IntColumn get amount => integer()();
  DateTimeColumn get date => dateTime()();
  TextColumn get note => text().withDefault(const Constant(''))();
}

class Settings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

@DriftDatabase(
  tables: [
    Accounts,
    Funds,
    Categories,
    Loans,
    Entries,
    Postings,
    Budgets,
    MonthCloses,
    Settings,
    InvestmentDetails,
    Purchases,
    Trackers,
    BudgetMoves,
    TrackerAmounts,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openOnDevice());

  static QueryExecutor _openOnDevice() => driftDatabase(name: 'my_fin_tracker');

  @override
  int get schemaVersion => 8;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await insertDefaultData(this);
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        // Phase 4: investments, buying register, trackers.
        await m.createTable(investmentDetails);
        await m.createTable(purchases);
        await m.createTable(trackers);
      }
      if (from < 3) {
        // Unused budget of a category saved to a pot at month close.
        await m.addColumn(categories, categories.savingsFundId);
      }
      if (from < 4) {
        // Slots and month-only budget moves.
        await m.addColumn(categories, categories.slotYear);
        await m.addColumn(categories, categories.slotMonth);
        await m.createTable(budgetMoves);
      }
      if (from < 5) {
        // Receipt photos.
        await m.addColumn(entries, entries.receipt);
      }
      if (from < 6) {
        // Budget saved to a pot during the month.
        await m.addColumn(entries, entries.budgetSave);
      }
      if (from < 7) {
        // Tracker amounts from outside your accounts.
        await m.createTable(trackerAmounts);
      }
      if (from < 8) {
        // No schema change: "This month", "Floating" and the Misc section.
        await setupFloatingAndMisc(this, DateTime.now());
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  /// Deletes every row and puts back the default accounts, funds and
  /// categories.
  Future<void> resetAllData() => transaction(() async {
    await deleteEverything();
    await insertDefaultData(this);
  });

  /// Deletes every row, leaving empty tables. Used by reset and restore.
  Future<void> deleteEverything() => transaction(() async {
    // Children before parents so foreign keys stay valid.
    for (final TableInfo table in [
      budgetMoves,
      trackerAmounts,
      purchases,
      investmentDetails,
      trackers,
      postings,
      entries,
      budgets,
      loans,
      monthCloses,
      settings,
    ]) {
      await delete(table).go();
    }
    await (delete(categories)..where((c) => c.parentId.isNotNull())).go();
    await delete(categories).go();
    await delete(funds).go();
    await delete(accounts).go();
  });
}
