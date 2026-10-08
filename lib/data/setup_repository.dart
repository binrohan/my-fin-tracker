import 'package:drift/drift.dart';

import '../ledger/enums.dart';
import 'database.dart';

/// Adding, renaming and archiving accounts, funds and categories.
/// Archiving hides an item from pickers but keeps its history.
class SetupRepository {
  SetupRepository(this.db);

  final AppDatabase db;

  Future<int> _nextOrder(TableInfo table, GeneratedColumn<int> sortOrder) async {
    final max = sortOrder.max();
    final row = await (db.selectOnly(table)..addColumns([max])).getSingle();
    return (row.read(max) ?? -1) + 1;
  }

  Future<int> addAccount(String name, AccountType type) async => db.into(db.accounts).insert(
      AccountsCompanion.insert(
          name: name.trim(),
          type: type,
          sortOrder: Value(await _nextOrder(db.accounts, db.accounts.sortOrder))));

  Future<void> updateAccount(int id, {String? name, bool? archived}) =>
      (db.update(db.accounts)..where((a) => a.id.equals(id))).write(AccountsCompanion(
        name: name == null ? const Value.absent() : Value(name.trim()),
        archived: archived == null ? const Value.absent() : Value(archived),
      ));

  Future<int> addFund(String name, FundKind kind, {int? target, DateTime? targetDate}) async =>
      db.into(db.funds).insert(FundsCompanion.insert(
            name: name.trim(),
            kind: kind,
            targetAmount: Value(target),
            targetDate: Value(targetDate),
            sortOrder: Value(await _nextOrder(db.funds, db.funds.sortOrder)),
          ));

  Future<void> updateFund(
    int id, {
    String? name,
    Value<int?> target = const Value.absent(),
    Value<DateTime?> targetDate = const Value.absent(),
    bool? archived,
  }) =>
      (db.update(db.funds)..where((f) => f.id.equals(id))).write(FundsCompanion(
        name: name == null ? const Value.absent() : Value(name.trim()),
        targetAmount: target,
        targetDate: targetDate,
        archived: archived == null ? const Value.absent() : Value(archived),
      ));

  Future<int> addCategory(String name, CategoryKind kind,
          {int? parentId, bool isFixed = false, int? dueDay}) async =>
      db.into(db.categories).insert(CategoriesCompanion.insert(
            name: name.trim(),
            kind: kind,
            parentId: Value(parentId),
            isFixed: Value(isFixed),
            dueDay: Value(dueDay),
            sortOrder: Value(await _nextOrder(db.categories, db.categories.sortOrder)),
          ));

  Future<void> updateCategory(
    int id, {
    String? name,
    bool? isFixed,
    Value<int?> dueDay = const Value.absent(),
    bool? archived,
  }) =>
      (db.update(db.categories)..where((c) => c.id.equals(id))).write(CategoriesCompanion(
        name: name == null ? const Value.absent() : Value(name.trim()),
        isFixed: isFixed == null ? const Value.absent() : Value(isFixed),
        dueDay: dueDay,
        archived: archived == null ? const Value.absent() : Value(archived),
      ));
}
