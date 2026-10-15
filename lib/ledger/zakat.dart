import 'dart:convert';
import 'dart:math' as math;

import '../core/money.dart';
import '../core/period.dart';
import 'enums.dart';
import 'ledger.dart';

/// Nisab in grams, by the common reckoning (7.5 tola gold, 52.5 tola
/// silver).
const goldNisabGrams = 87.48;
const silverNisabGrams = 612.36;

/// 2.5%.
const zakatRateBp = 250;

enum NisabBasis { silver, gold }

/// What you entered on the Zakat screen. Amounts left null follow your
/// entries in the app.
class ZakatInputs {
  const ZakatInputs({
    this.cash,
    this.investments,
    this.owedToYou,
    this.debts,
    this.goldGrams = 0,
    this.silverGrams = 0,
    this.goldPrice = 0,
    this.silverPrice = 0,
    this.other = 0,
    this.basis = NisabBasis.silver,
    this.zakatDate,
    this.monthlyGrowth,
    this.pricesAt,
  });

  static const settingKey = 'zakat_inputs';

  factory ZakatInputs.parse(String? json) {
    if (json == null || json.isEmpty) return const ZakatInputs();
    try {
      final j = jsonDecode(json) as Map<String, dynamic>;
      return ZakatInputs(
        cash: j['cash'] as int?,
        investments: j['investments'] as int?,
        owedToYou: j['owed'] as int?,
        debts: j['debts'] as int?,
        goldGrams: (j['goldGrams'] as num?)?.toDouble() ?? 0,
        silverGrams: (j['silverGrams'] as num?)?.toDouble() ?? 0,
        goldPrice: j['goldPrice'] as int? ?? 0,
        silverPrice: j['silverPrice'] as int? ?? 0,
        other: j['other'] as int? ?? 0,
        basis: j['basis'] == 'gold' ? NisabBasis.gold : NisabBasis.silver,
        zakatDate: DateTime.tryParse(j['date'] as String? ?? ''),
        monthlyGrowth: j['growth'] as int?,
        pricesAt: DateTime.tryParse(j['pricesAt'] as String? ?? ''),
      );
    } catch (_) {
      return const ZakatInputs();
    }
  }

  final Poisha? cash;
  final Poisha? investments;
  final Poisha? owedToYou;
  final Poisha? debts;
  final double goldGrams;
  final double silverGrams;

  /// Price of one gram, in poisha.
  final Poisha goldPrice;
  final Poisha silverPrice;

  /// Business stock, foreign currency and anything else zakatable.
  final Poisha other;
  final NisabBasis basis;

  /// The day zakat is due, as you set it. Once it has passed, the same
  /// date next year is used.
  final DateTime? zakatDate;

  /// How much your wealth grows a month; null follows the app.
  final Poisha? monthlyGrowth;

  /// When the gold and silver prices were last fetched.
  final DateTime? pricesAt;

  /// The next zakat day on or after [today].
  DateTime? nextDate(DateTime today) {
    var d = zakatDate;
    if (d == null) return null;
    final day = DateTime(today.year, today.month, today.day);
    var years = 1;
    final first = d;
    while (d!.isBefore(day)) {
      d = DateTime(first.year + years, first.month, first.day);
      years++;
    }
    return d;
  }

  ZakatInputs copyWith({
    Poisha? Function()? cash,
    Poisha? Function()? investments,
    Poisha? Function()? owedToYou,
    Poisha? Function()? debts,
    double? goldGrams,
    double? silverGrams,
    Poisha? goldPrice,
    Poisha? silverPrice,
    Poisha? other,
    NisabBasis? basis,
    DateTime? Function()? zakatDate,
    Poisha? Function()? monthlyGrowth,
    DateTime? Function()? pricesAt,
  }) => ZakatInputs(
    cash: cash == null ? this.cash : cash(),
    investments: investments == null ? this.investments : investments(),
    owedToYou: owedToYou == null ? this.owedToYou : owedToYou(),
    debts: debts == null ? this.debts : debts(),
    goldGrams: goldGrams ?? this.goldGrams,
    silverGrams: silverGrams ?? this.silverGrams,
    goldPrice: goldPrice ?? this.goldPrice,
    silverPrice: silverPrice ?? this.silverPrice,
    other: other ?? this.other,
    basis: basis ?? this.basis,
    zakatDate: zakatDate == null ? this.zakatDate : zakatDate(),
    monthlyGrowth: monthlyGrowth == null ? this.monthlyGrowth : monthlyGrowth(),
    pricesAt: pricesAt == null ? this.pricesAt : pricesAt(),
  );

  String encode() => jsonEncode({
    'cash': ?cash,
    'investments': ?investments,
    'owed': ?owedToYou,
    'debts': ?debts,
    'goldGrams': goldGrams,
    'silverGrams': silverGrams,
    'goldPrice': goldPrice,
    'silverPrice': silverPrice,
    'other': other,
    'basis': basis.name,
    if (zakatDate != null) 'date': zakatDate!.toIso8601String(),
    'growth': ?monthlyGrowth,
    if (pricesAt != null) 'pricesAt': pricesAt!.toIso8601String(),
  });
}

/// The app's own figures, used where you haven't typed one.
class ZakatFromApp {
  const ZakatFromApp({
    required this.cash,
    required this.investments,
    required this.owedToYou,
    required this.debts,
    this.monthlyGrowth,
  });

  factory ZakatFromApp.of(Ledger ledger, {DateTime? today}) {
    Poisha owed = 0, debts = 0;
    for (final a in ledger.accountsOfType((t) => t == AccountType.person)) {
      final b = ledger.accountBalance(a.id);
      if (b > 0) owed += b;
      if (b < 0) debts -= b;
    }
    return ZakatFromApp(
      cash: math.max(0, ledger.liquidTotal()),
      investments: math.max(0, ledger.investmentTotal()),
      owedToYou: owed,
      debts: debts,
      monthlyGrowth: today == null ? null : _monthlyGrowth(ledger, today),
    );
  }

  /// Bank, cash and wallets.
  final Poisha cash;

  /// DPS, FDR, savings certificates, shares.
  final Poisha investments;

  /// Money people owe you.
  final Poisha owedToYou;

  /// Money you owe people.
  final Poisha debts;

  /// How much everything you own grew a month, on average over the last
  /// three finished months (starting balances left out). Null without
  /// history.
  final Poisha? monthlyGrowth;
}

Poisha? _monthlyGrowth(Ledger ledger, DateTime today) {
  final changes = <Poisha>[];
  for (var p = Period.of(today).previous; changes.length < 3; p = p.previous) {
    if (!ledger.entries.any((e) => e.date.isBefore(p.end))) break;
    final lines = ledger.lines.where((l) => p.contains(l.date));
    if (!lines.any((l) => l.type != EntryType.opening)) continue;
    changes.add(
      lines.where((l) => l.type != EntryType.opening).fold<Poisha>(0, (t, l) => t + l.amount),
    );
  }
  if (changes.isEmpty) return null;
  return changes.fold<Poisha>(0, (t, v) => t + v) ~/ changes.length;
}

class ZakatResult {
  ZakatResult(this.inputs, this.app);

  final ZakatInputs inputs;
  final ZakatFromApp app;

  Poisha get cash => inputs.cash ?? app.cash;
  Poisha get investments => inputs.investments ?? app.investments;
  Poisha get owedToYou => inputs.owedToYou ?? app.owedToYou;
  Poisha get debts => inputs.debts ?? app.debts;
  Poisha get gold => (inputs.goldGrams * inputs.goldPrice).round();
  Poisha get silver => (inputs.silverGrams * inputs.silverPrice).round();

  Poisha get assets => cash + investments + owedToYou + gold + silver + inputs.other;
  Poisha get net => math.max(0, assets - debts);

  double get nisabGrams => inputs.basis == NisabBasis.gold ? goldNisabGrams : silverNisabGrams;
  Poisha get nisabPrice => inputs.basis == NisabBasis.gold ? inputs.goldPrice : inputs.silverPrice;

  /// Null until the price of the chosen metal is entered.
  Poisha? get nisab => nisabPrice <= 0 ? null : (nisabGrams * nisabPrice).round();

  bool get due => nisab != null && net >= nisab!;
  Poisha get zakat => due ? (net * zakatRateBp / 10000).round() : 0;

  /// Expected growth a month: yours, or the app's average.
  Poisha get monthlyGrowth => inputs.monthlyGrowth ?? app.monthlyGrowth ?? 0;

  /// Net wealth expected on [date], growing by [monthlyGrowth] from
  /// [today]. Prices stay as they are today.
  Poisha projectedNet(DateTime today, DateTime date) {
    final months = date.difference(today).inDays / (365.25 / 12);
    return math.max(0, net + (monthlyGrowth * math.max(0, months)).round());
  }

  Poisha projectedZakat(DateTime today, DateTime date) {
    final n = projectedNet(today, date);
    return nisab != null && n >= nisab! ? (n * zakatRateBp / 10000).round() : 0;
  }
}
