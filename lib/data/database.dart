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

class Settings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

@DriftDatabase(
  tables: [Accounts, Funds, Categories, Loans, Entries, Postings, Budgets, MonthCloses, Settings],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openOnDevice());

  static QueryExecutor _openOnDevice() => driftDatabase(name: 'my_fin_tracker');

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await insertDefaultData(this);
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
    for (final TableInfo table in [postings, entries, budgets, loans, monthCloses, settings]) {
      await delete(table).go();
    }
    await (delete(categories)..where((c) => c.parentId.isNotNull())).go();
    await delete(categories).go();
    await delete(funds).go();
    await delete(accounts).go();
  });
}
