import 'package:drift/drift.dart';

import '../ledger/enums.dart';
import 'database.dart';

/// Default borrow charge for own-savings loans, in basis points (5%).
const int defaultBorrowChargeBp = 500;

/// What a fresh install starts with. Everything here can be renamed,
/// archived or extended in Settings.
Future<void> insertDefaultData(AppDatabase db) async {
  var order = 0;
  for (final (name, type) in [
    ('Bank', AccountType.bank),
    ('Cash', AccountType.cash),
    ('bKash', AccountType.wallet),
  ]) {
    await db.into(db.accounts).insert(
        AccountsCompanion.insert(name: name, type: type, sortOrder: Value(order++)));
  }

  order = 0;
  for (final (name, kind) in [
    ('Spending', FundKind.spending),
    ('Monthly Savings', FundKind.savings),
    ('Investments', FundKind.investment),
  ]) {
    await db.into(db.funds).insert(
        FundsCompanion.insert(name: name, kind: kind, sortOrder: Value(order++)));
  }

  Future<int> category(String name, CategoryKind kind,
          {int? parentId, bool isFixed = false, int? dueDay}) =>
      db.into(db.categories).insert(CategoriesCompanion.insert(
            name: name,
            kind: kind,
            parentId: Value(parentId),
            isFixed: Value(isFixed),
            dueDay: Value(dueDay),
            sortOrder: Value(order++),
          ));

  order = 0;
  final fixed = await category('Fixed', CategoryKind.expense, isFixed: true);
  for (final (name, due) in [
    ('House Rent', 1),
    ('Electricity', 15),
    ('Gas', 5),
    ('Internet', 5),
    ('Water & Service', 10),
  ]) {
    await category(name, CategoryKind.expense,
        parentId: fixed, isFixed: true, dueDay: due);
  }
  for (final name in ['Ration', 'Random', 'Mine']) {
    await category(name, CategoryKind.expense);
  }
  for (final name in ['Salary', 'Bonus', 'Other income']) {
    await category(name, CategoryKind.income);
  }

  for (final (key, value) in [
    ('borrow_charge_bp', '$defaultBorrowChargeBp'),
    ('month_leftover', 'carry_forward'),
    ('currency', 'BDT'),
  ]) {
    await db.into(db.settings).insert(SettingsCompanion.insert(key: key, value: value));
  }
}
