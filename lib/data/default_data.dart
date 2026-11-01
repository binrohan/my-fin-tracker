import 'package:drift/drift.dart';

import '../ledger/enums.dart';
import 'database.dart';

/// Default borrow charge for own-savings loans, in basis points (5%).
const int defaultBorrowChargeBp = 500;

/// The setting with the id of the Misc section, which takes whatever the
/// Monthly plan's expenses leave unassigned.
const miscCategorySetting = 'misc_category';

/// The first month (YYYY-MM) Misc has a budget in; none means every month.
const miscFromSetting = 'misc_from';

/// Names the month's money and the floating pot, and adds Misc, for data
/// from before they existed. Safe to run again.
Future<void> setupFloatingAndMisc(AppDatabase db, DateTime now) async {
  Future<void> rename(FundKind kind, String from, String to) =>
      (db.update(db.funds)..where((f) => f.kind.equalsValue(kind) & f.name.equals(from))).write(
        FundsCompanion(name: Value(to)),
      );
  await rename(FundKind.spending, 'Spending', 'This month');
  await rename(FundKind.unplanned, 'Unplanned', 'Floating');

  final known = await (db.select(
    db.settings,
  )..where((s) => s.key.equals(miscCategorySetting))).getSingleOrNull();
  if (known != null) return;
  final existing =
      await (db.select(db.categories)..where(
            (c) =>
                c.name.equals('Misc') &
                c.kind.equalsValue(CategoryKind.expense) &
                c.parentId.isNull() &
                c.slotYear.isNull(),
          ))
          .getSingleOrNull();
  final id =
      existing?.id ??
      await db
          .into(db.categories)
          .insert(
            CategoriesCompanion.insert(
              name: 'Misc',
              kind: CategoryKind.expense,
              sortOrder: const Value(9999),
            ),
          );
  final month = '${now.year}-${now.month.toString().padLeft(2, '0')}';
  for (final (key, value) in [(miscCategorySetting, '$id'), (miscFromSetting, month)]) {
    await db
        .into(db.settings)
        .insert(
          SettingsCompanion.insert(key: key, value: value),
          mode: InsertMode.insertOrReplace,
        );
  }
}

/// What a fresh install starts with. Everything here can be renamed,
/// archived or extended in Settings.
Future<void> insertDefaultData(AppDatabase db) async {
  var order = 0;
  for (final (name, type) in [
    ('Bank', AccountType.bank),
    ('Cash', AccountType.cash),
    ('bKash', AccountType.wallet),
  ]) {
    await db
        .into(db.accounts)
        .insert(AccountsCompanion.insert(name: name, type: type, sortOrder: Value(order++)));
  }

  order = 0;
  for (final (name, kind) in [
    ('This month', FundKind.spending),
    ('Monthly Savings', FundKind.savings),
    ('Investments', FundKind.investment),
  ]) {
    await db
        .into(db.funds)
        .insert(FundsCompanion.insert(name: name, kind: kind, sortOrder: Value(order++)));
  }

  Future<int> category(
    String name,
    CategoryKind kind, {
    int? parentId,
    bool isFixed = false,
    int? dueDay,
  }) => db
      .into(db.categories)
      .insert(
        CategoriesCompanion.insert(
          name: name,
          kind: kind,
          parentId: Value(parentId),
          isFixed: Value(isFixed),
          dueDay: Value(dueDay),
          sortOrder: Value(order++),
        ),
      );

  order = 0;
  final fixed = await category('Fixed', CategoryKind.expense, isFixed: true);
  for (final (name, due) in [
    ('House Rent', 1),
    ('Electricity', 15),
    ('Gas', 5),
    ('Internet', 5),
    ('Water & Service', 10),
  ]) {
    await category(name, CategoryKind.expense, parentId: fixed, isFixed: true, dueDay: due);
  }
  for (final name in ['Ration', 'Random', 'Mine']) {
    await category(name, CategoryKind.expense);
  }
  final misc = await category('Misc', CategoryKind.expense);
  for (final name in ['Salary', 'Bonus', 'Other income']) {
    await category(name, CategoryKind.income);
  }

  for (final (key, value) in [
    ('borrow_charge_bp', '$defaultBorrowChargeBp'),
    ('month_leftover', 'carry_forward'),
    ('currency', 'BDT'),
    (miscCategorySetting, '$misc'),
  ]) {
    await db.into(db.settings).insert(SettingsCompanion.insert(key: key, value: value));
  }
}
