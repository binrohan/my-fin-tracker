import 'dart:convert';
import 'dart:math' as math;

import '../core/money.dart';
import '../core/period.dart';
import 'enums.dart';
import 'ledger.dart';

/// A simplified Bangladesh personal income tax estimate. The income year
/// runs July to June. Every rate and limit is editable, because the Finance
/// Act changes them most years.

enum TaxpayerKind {
  general('General'),
  womanOrSenior('Woman, or 65 and over'),
  disabled('Person with a disability'),
  freedomFighter('Gazetted freedom fighter');

  const TaxpayerKind(this.label);
  final String label;
}

/// [width] of income taxed at [rateBp]; the last band has no width.
class TaxSlab {
  const TaxSlab(this.width, this.rateBp);

  final Poisha? width;
  final int rateBp;

  Map<String, dynamic> toJson() => {'width': width, 'rate': rateBp};
  factory TaxSlab.fromJson(Map<String, dynamic> j) => TaxSlab(j['width'] as int?, j['rate'] as int);
}

class TaxRules {
  const TaxRules({
    required this.label,
    required this.thresholds,
    required this.slabs,
    required this.salaryExemptDivisor,
    required this.salaryExemptCap,
    required this.rebateBp,
    required this.rebateIncomeCapBp,
    required this.rebateCap,
    required this.minimumTax,
  });

  static const settingKey = 'tax_rules';

  /// As reported for the Finance Act 2026 (assessment year 2026-27). Check
  /// them against NBR before relying on the result.
  static final defaults = TaxRules(
    label: 'Finance Act 2026, as reported',
    thresholds: {
      TaxpayerKind.general: taka(400000),
      TaxpayerKind.womanOrSenior: taka(450000),
      TaxpayerKind.disabled: taka(500000),
      TaxpayerKind.freedomFighter: taka(525000),
    },
    slabs: [
      TaxSlab(taka(300000), 1000),
      TaxSlab(taka(400000), 1500),
      TaxSlab(taka(500000), 2000),
      TaxSlab(taka(2000000), 2500),
      const TaxSlab(null, 3000),
    ],
    salaryExemptDivisor: 3,
    salaryExemptCap: taka(500000),
    rebateBp: 1500,
    rebateIncomeCapBp: 300,
    rebateCap: taka(1000000),
    minimumTax: taka(5000),
  );

  factory TaxRules.parse(String? json) {
    if (json == null || json.isEmpty) return defaults;
    try {
      final j = jsonDecode(json) as Map<String, dynamic>;
      return TaxRules(
        label: j['label'] as String? ?? 'Your rates',
        thresholds: {
          for (final k in TaxpayerKind.values)
            k: (j['thresholds'] as Map<String, dynamic>)[k.name] as int? ?? defaults.thresholds[k]!,
        },
        slabs: [for (final s in j['slabs'] as List) TaxSlab.fromJson(s as Map<String, dynamic>)],
        salaryExemptDivisor: j['exemptDivisor'] as int,
        salaryExemptCap: j['exemptCap'] as int,
        rebateBp: j['rebate'] as int,
        rebateIncomeCapBp: j['rebateIncomeCap'] as int,
        rebateCap: j['rebateCap'] as int,
        minimumTax: j['minimum'] as int,
      );
    } catch (_) {
      return defaults;
    }
  }

  final String label;
  final Map<TaxpayerKind, Poisha> thresholds;

  /// Bands above the tax-free threshold, in order.
  final List<TaxSlab> slabs;

  /// One part in this many of salary is tax free, up to [salaryExemptCap].
  /// 0 turns the exemption off.
  final int salaryExemptDivisor;
  final Poisha salaryExemptCap;

  /// Rebate on investment: [rebateBp] of what you invested, at most
  /// [rebateIncomeCapBp] of taxable income and at most [rebateCap].
  final int rebateBp;
  final int rebateIncomeCapBp;
  final Poisha rebateCap;

  /// Payable by anyone over the threshold, whatever the slabs give.
  final Poisha minimumTax;

  String encode() => jsonEncode({
    'label': label,
    'thresholds': {for (final e in thresholds.entries) e.key.name: e.value},
    'slabs': [for (final s in slabs) s.toJson()],
    'exemptDivisor': salaryExemptDivisor,
    'exemptCap': salaryExemptCap,
    'rebate': rebateBp,
    'rebateIncomeCap': rebateIncomeCapBp,
    'rebateCap': rebateCap,
    'minimum': minimumTax,
  });

  TaxRules copyWith({
    String? label,
    Map<TaxpayerKind, Poisha>? thresholds,
    List<TaxSlab>? slabs,
    int? salaryExemptDivisor,
    Poisha? salaryExemptCap,
    int? rebateBp,
    int? rebateIncomeCapBp,
    Poisha? rebateCap,
    Poisha? minimumTax,
  }) => TaxRules(
    label: label ?? this.label,
    thresholds: thresholds ?? this.thresholds,
    slabs: slabs ?? this.slabs,
    salaryExemptDivisor: salaryExemptDivisor ?? this.salaryExemptDivisor,
    salaryExemptCap: salaryExemptCap ?? this.salaryExemptCap,
    rebateBp: rebateBp ?? this.rebateBp,
    rebateIncomeCapBp: rebateIncomeCapBp ?? this.rebateIncomeCapBp,
    rebateCap: rebateCap ?? this.rebateCap,
    minimumTax: minimumTax ?? this.minimumTax,
  );
}

class TaxInputs {
  const TaxInputs({
    this.salary = 0,
    this.otherIncome = 0,
    this.investment = 0,
    this.alreadyPaid = 0,
    this.kind = TaxpayerKind.general,
  });

  final Poisha salary;
  final Poisha otherIncome;

  /// DPS, savings certificates, insurance premium, provident fund, listed
  /// shares and the like, made in the income year.
  final Poisha investment;

  /// Deducted at source (from salary, bank interest) or paid in advance.
  final Poisha alreadyPaid;
  final TaxpayerKind kind;
}

/// One band of the slab table.
class TaxBand {
  const TaxBand({required this.from, required this.amount, required this.rateBp});

  final Poisha from;
  final Poisha amount;
  final int rateBp;

  Poisha get tax => (amount * rateBp / 10000).round();
}

class TaxResult {
  const TaxResult({
    required this.inputs,
    required this.exemption,
    required this.threshold,
    required this.bands,
    required this.rebate,
    required this.minimumTax,
  });

  final TaxInputs inputs;
  final Poisha exemption;
  final Poisha threshold;
  final List<TaxBand> bands;
  final Poisha rebate;
  final Poisha minimumTax;

  Poisha get grossIncome => inputs.salary + inputs.otherIncome;
  Poisha get taxable => math.max(0, grossIncome - exemption);
  Poisha get slabTax => bands.fold(0, (t, b) => t + b.tax);
  Poisha get afterRebate => math.max(0, slabTax - rebate);

  /// True when the minimum tax is more than the slabs give.
  bool get minimumApplies => taxable > threshold && afterRebate < minimumTax;

  Poisha get tax => taxable <= threshold ? 0 : math.max(afterRebate, minimumTax);

  /// Still to pay (negative: a refund).
  Poisha get payable => tax - inputs.alreadyPaid;
}

TaxResult computeTax(TaxRules rules, TaxInputs inputs) {
  final exemption = rules.salaryExemptDivisor <= 0
      ? 0
      : math.min(inputs.salary ~/ rules.salaryExemptDivisor, rules.salaryExemptCap);
  final taxable = math.max(0, inputs.salary + inputs.otherIncome - exemption);
  final threshold = rules.thresholds[inputs.kind]!;

  final bands = <TaxBand>[TaxBand(from: 0, amount: math.min(taxable, threshold), rateBp: 0)];
  var at = threshold;
  for (final slab in rules.slabs) {
    if (taxable <= at) break;
    final width = slab.width == null ? taxable - at : math.min(slab.width!, taxable - at);
    bands.add(TaxBand(from: at, amount: width, rateBp: slab.rateBp));
    at += width;
  }

  final rebate = [
    (inputs.investment * rules.rebateBp / 10000).round(),
    (taxable * rules.rebateIncomeCapBp / 10000).round(),
    rules.rebateCap,
  ].reduce(math.min);
  final slabTax = bands.fold<Poisha>(0, (t, b) => t + b.tax);
  return TaxResult(
    inputs: inputs,
    exemption: exemption,
    threshold: threshold,
    bands: bands,
    rebate: math.min(rebate, slabTax),
    minimumTax: rules.minimumTax,
  );
}

/// July to June. The income year that [today] falls in.
class IncomeYear {
  const IncomeYear(this.startYear);

  factory IncomeYear.of(DateTime today) =>
      IncomeYear(today.month >= 7 ? today.year : today.year - 1);

  final int startYear;

  DateTime get start => DateTime(startYear, 7);
  DateTime get end => DateTime(startYear + 1, 7);
  bool contains(DateTime d) => !d.isBefore(start) && d.isBefore(end);

  /// "2026-27"
  String get label => '$startYear-${(startYear + 1) % 100}';

  /// Months of the year after the one [today] is in.
  int monthsAfter(DateTime today) {
    final p = Period.of(today);
    return (end.year * 12 + end.month) - (p.year * 12 + p.month) - 1;
  }
}

/// What the app can tell about an income year: income and investments
/// recorded so far, plus the monthly plan for the months still to come.
class TaxFromApp {
  const TaxFromApp({
    required this.salarySoFar,
    required this.salaryPlanned,
    required this.otherSoFar,
    required this.investedSoFar,
    required this.investPlanned,
    required this.monthsToCome,
  });

  factory TaxFromApp.of(Ledger ledger, IncomeYear year, DateTime today) {
    final plan = ledger.plan;
    final mainId = plan.categoryId;
    final inYear = ledger.entries.where((e) => year.contains(e.date) && !e.date.isAfter(today));
    Poisha salary = 0, other = 0;
    for (final e in inYear.where((e) => e.type == EntryType.income)) {
      if (e.categoryId == mainId) {
        salary += e.amount;
      } else {
        other += e.amount;
      }
    }
    Poisha invested = 0;
    for (var p = Period.of(year.start); p.compareTo(Period.of(today)) <= 0; p = p.next) {
      invested += ledger.summary(p).invested;
    }
    final monthly = plan.sourceFor(mainId)?.amount ?? 0;
    final investMonthly = plan.items
        .where((i) => ledger.accounts[i.accountId]?.type == AccountType.investment)
        .fold<Poisha>(0, (t, i) => t + i.amount);
    // Months still to come, counting this one if its salary hasn't arrived.
    final thisMonth = Period.of(today);
    final paidThisMonth = inYear.any(
      (e) => e.type == EntryType.income && e.categoryId == mainId && thisMonth.contains(e.date),
    );
    final months = year.contains(today) ? year.monthsAfter(today) + (paidThisMonth ? 0 : 1) : 0;
    return TaxFromApp(
      salarySoFar: salary,
      salaryPlanned: monthly * months,
      otherSoFar: other,
      investedSoFar: math.max(0, invested),
      investPlanned: investMonthly * months,
      monthsToCome: months,
    );
  }

  final Poisha salarySoFar;
  final Poisha salaryPlanned;
  final Poisha otherSoFar;
  final Poisha investedSoFar;
  final Poisha investPlanned;

  /// Months whose salary is still to come, this one included if unpaid.
  final int monthsToCome;

  Poisha get salary => salarySoFar + salaryPlanned;
  Poisha get investment => investedSoFar + investPlanned;
}

/// What you typed on the Tax screen for one income year. Amounts left null
/// follow the app ([TaxFromApp]).
class SavedTaxInputs {
  const SavedTaxInputs({
    this.salary,
    this.otherIncome,
    this.investment,
    this.alreadyPaid = 0,
    this.kind = TaxpayerKind.general,
  });

  static String settingKey(IncomeYear year) => 'tax_inputs_${year.startYear}';

  factory SavedTaxInputs.parse(String? json) {
    if (json == null || json.isEmpty) return const SavedTaxInputs();
    try {
      final j = jsonDecode(json) as Map<String, dynamic>;
      return SavedTaxInputs(
        salary: j['salary'] as int?,
        otherIncome: j['other'] as int?,
        investment: j['investment'] as int?,
        alreadyPaid: j['paid'] as int? ?? 0,
        kind: TaxpayerKind.values.asNameMap()[j['kind']] ?? TaxpayerKind.general,
      );
    } catch (_) {
      return const SavedTaxInputs();
    }
  }

  final Poisha? salary;
  final Poisha? otherIncome;
  final Poisha? investment;
  final Poisha alreadyPaid;
  final TaxpayerKind kind;

  TaxInputs resolve(TaxFromApp app) => TaxInputs(
    salary: salary ?? app.salary,
    otherIncome: otherIncome ?? app.otherSoFar,
    investment: investment ?? app.investment,
    alreadyPaid: alreadyPaid,
    kind: kind,
  );

  String encode() => jsonEncode({
    'salary': ?salary,
    'other': ?otherIncome,
    'investment': ?investment,
    'paid': alreadyPaid,
    'kind': kind.name,
  });
}
