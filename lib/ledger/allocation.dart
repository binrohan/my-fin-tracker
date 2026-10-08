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

/// What to set aside when a salary (or another chosen income) arrives.
class AllocationPlan {
  const AllocationPlan({this.categoryId, this.items = const []});

  static const settingKey = 'allocation_plan';

  factory AllocationPlan.parse(String? json) {
    if (json == null || json.isEmpty) return const AllocationPlan();
    final map = jsonDecode(json) as Map<String, dynamic>;
    return AllocationPlan(
      categoryId: map['category'] as int?,
      items: [
        for (final item in map['items'] as List) AllocationItem.fromJson(item as Map<String, dynamic>),
      ],
    );
  }

  /// The income category that triggers the plan, usually Salary.
  final int? categoryId;
  final List<AllocationItem> items;

  Poisha get total => items.fold(0, (t, i) => t + i.amount);
  bool get isEmpty => items.isEmpty;

  String encode() => jsonEncode({
        'category': categoryId,
        'items': [for (final i in items) i.toJson()],
      });
}
