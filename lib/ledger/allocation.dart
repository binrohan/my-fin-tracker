import 'dart:convert';

import '../core/money.dart';

/// One line of the salary plan: move [amount] into [fundId]. [accountId] is
/// set when the money also changes account (a DPS instalment); otherwise it
/// stays in the account the salary arrived in.
class AllocationItem {
  const AllocationItem({required this.fundId, required this.amount, this.accountId});

  factory AllocationItem.fromJson(Map<String, dynamic> json) => AllocationItem(
    fundId: json['fund'] as int,
    amount: json['amount'] as int,
    accountId: json['account'] as int?,
  );

  final int fundId;
  final int? accountId;
  final Poisha amount;

  Map<String, dynamic> toJson() => {'fund': fundId, 'amount': amount, 'account': ?accountId};
}

/// A regular income: how much, around which day of the month, and where
/// it usually arrives.
class IncomeSource {
  const IncomeSource({
    required this.categoryId,
    required this.amount,
    this.day,
    this.accountId,
    this.forNextMonth = false,
  });

  factory IncomeSource.fromJson(Map<String, dynamic> json) => IncomeSource(
    categoryId: json['category'] as int,
    amount: json['amount'] as int,
    day: json['day'] as int?,
    accountId: json['account'] as int?,
    forNextMonth: json['next'] == true,
  );

  final int categoryId;
  final Poisha amount;

  /// Day of the month it usually arrives; the app asks about it from then on.
  final int? day;

  /// Where it usually arrives: a bank account, or cash.
  final int? accountId;

  /// Received this month to spend next month (e.g. salary on the 26th):
  /// held apart, then released into Spending on the 1st.
  final bool forNextMonth;

  Map<String, dynamic> toJson() => {
    'category': categoryId,
    'amount': amount,
    'day': ?day,
    'account': ?accountId,
    if (forNextMonth) 'next': true,
  };
}

/// The monthly plan: what comes in ([incomes]), how much of it is for
/// monthly expenses ([expenseTarget]), and what is set aside to savings,
/// goals and investments ([items]) when the main income ([categoryId])
/// arrives.
class AllocationPlan {
  const AllocationPlan({
    this.categoryId,
    this.items = const [],
    this.incomes = const [],
    this.expenseTarget,
  });

  static const settingKey = 'allocation_plan';

  factory AllocationPlan.parse(String? json) {
    if (json == null || json.isEmpty) return const AllocationPlan();
    final map = jsonDecode(json) as Map<String, dynamic>;
    return AllocationPlan(
      categoryId: map['category'] as int?,
      items: [
        for (final item in (map['items'] as List? ?? const []))
          AllocationItem.fromJson(item as Map<String, dynamic>),
      ],
      incomes: [
        for (final item in (map['incomes'] as List? ?? const []))
          IncomeSource.fromJson(item as Map<String, dynamic>),
      ],
      expenseTarget: map['expenses'] as int?,
    );
  }

  /// The income that triggers setting money aside, usually Salary.
  final int? categoryId;
  final List<AllocationItem> items;
  final List<IncomeSource> incomes;

  /// The part of the income meant for monthly expenses.
  final Poisha? expenseTarget;

  /// Set aside to savings, goals and investments.
  Poisha get total => items.fold(0, (t, i) => t + i.amount);
  bool get isEmpty => items.isEmpty;

  Poisha get plannedIncome => incomes.fold(0, (t, i) => t + i.amount);

  /// The planned source for an income category, if any.
  IncomeSource? sourceFor(int? categoryId) =>
      incomes.where((i) => i.categoryId == categoryId).firstOrNull;

  /// Income not yet given a purpose (negative: more planned than earned).
  Poisha get unassigned => plannedIncome - (expenseTarget ?? 0) - total;

  AllocationPlan copyWith({
    int? categoryId,
    List<AllocationItem>? items,
    List<IncomeSource>? incomes,
    Poisha? expenseTarget,
  }) => AllocationPlan(
    categoryId: categoryId ?? this.categoryId,
    items: items ?? this.items,
    incomes: incomes ?? this.incomes,
    expenseTarget: expenseTarget ?? this.expenseTarget,
  );

  String encode() => jsonEncode({
    'category': categoryId,
    'items': [for (final i in items) i.toJson()],
    'incomes': [for (final i in incomes) i.toJson()],
    'expenses': ?expenseTarget,
  });
}
