import 'dart:convert';
import 'dart:math' as math;

import '../core/money.dart';
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
  });
}

/// The app's own figures, used where you haven't typed one.
class ZakatFromApp {
  const ZakatFromApp({
    required this.cash,
    required this.investments,
    required this.owedToYou,
    required this.debts,
  });

  factory ZakatFromApp.of(Ledger ledger) {
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
}
