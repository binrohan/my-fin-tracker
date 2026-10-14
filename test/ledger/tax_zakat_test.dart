import 'package:flutter_test/flutter_test.dart';
import 'package:my_fin_tracker/core/money.dart';
import 'package:my_fin_tracker/ledger/tax.dart';
import 'package:my_fin_tracker/ledger/zakat.dart';

void main() {
  final rules = TaxRules.defaults;

  group('income tax', () {
    test('a salary of 12 lakh with a DPS', () {
      final r = computeTax(
        rules,
        TaxInputs(salary: taka(1200000), investment: taka(120000), alreadyPaid: taka(20000)),
      );
      expect(r.exemption, taka(400000), reason: 'one third, under the 5 lakh cap');
      expect(r.taxable, taka(800000));
      expect(
        [for (final b in r.bands) (b.amount, b.tax)],
        [(taka(400000), 0), (taka(300000), taka(30000)), (taka(100000), taka(15000))],
      );
      expect(r.slabTax, taka(45000));
      expect(r.rebate, taka(18000), reason: '15% of 1,20,000 is under 3% of 8 lakh');
      expect(r.tax, taka(27000));
      expect(r.payable, taka(7000));
    });

    test('just over the limit pays the minimum', () {
      final r = computeTax(rules, TaxInputs(otherIncome: taka(410000)));
      expect(r.slabTax, taka(1000));
      expect(r.minimumApplies, isTrue);
      expect(r.tax, taka(5000));
    });

    test('within the limit pays nothing', () {
      final r = computeTax(rules, TaxInputs(salary: taka(600000)));
      expect(r.taxable, taka(400000));
      expect(r.tax, 0);
    });

    test('a higher limit for women and seniors', () {
      final r = computeTax(
        rules,
        TaxInputs(otherIncome: taka(450000), kind: TaxpayerKind.womanOrSenior),
      );
      expect(r.tax, 0);
    });

    test('every slab, and the capped exemption', () {
      final r = computeTax(rules, TaxInputs(salary: taka(10000000)));
      expect(r.exemption, taka(500000));
      expect(r.bands.last.amount, taka(5900000));
      expect(r.slabTax, taka(2460000));
    });

    test('rates survive saving', () {
      final edited = rules.copyWith(
        thresholds: {...rules.thresholds, TaxpayerKind.general: taka(375000)},
        rebateBp: 1000,
      );
      final back = TaxRules.parse(edited.encode());
      expect(back.thresholds[TaxpayerKind.general], taka(375000));
      expect(back.rebateBp, 1000);
      expect(
        back.slabs.map((s) => (s.width, s.rateBp)),
        rules.slabs.map((s) => (s.width, s.rateBp)),
      );
      expect(TaxRules.parse('not json').minimumTax, rules.minimumTax);
    });

    test('the income year runs July to June', () {
      final y = IncomeYear.of(DateTime(2026, 10, 14));
      expect(y.label, '2026-27');
      expect(y.monthsAfter(DateTime(2026, 10, 14)), 8, reason: 'November to June');
      expect(IncomeYear.of(DateTime(2027, 6, 30)).startYear, 2026);
      expect(IncomeYear.of(DateTime(2027, 7, 1)).startYear, 2027);
    });

    test('saved inputs fall back to the app', () {
      const app = TaxFromApp(
        salarySoFar: 100,
        salaryPlanned: 800,
        otherSoFar: 50,
        investedSoFar: 10,
        investPlanned: 80,
        monthsToCome: 8,
      );
      final saved = SavedTaxInputs.parse(
        const SavedTaxInputs(salary: 1000, kind: TaxpayerKind.disabled).encode(),
      );
      final i = saved.resolve(app);
      expect(
        (i.salary, i.otherIncome, i.investment, i.kind),
        (1000, 50, 90, TaxpayerKind.disabled),
      );
    });
  });

  group('zakat', () {
    const app = ZakatFromApp(cash: 40000000, investments: 10000000, owedToYou: 0, debts: 0);

    test('2.5% of net wealth over the silver nisab', () {
      final r = ZakatResult(ZakatInputs(silverPrice: taka(250)), app);
      expect(r.nisab, (612.36 * 25000).round());
      expect(r.net, taka(500000));
      expect(r.zakat, taka(12500));
    });

    test('below the gold nisab nothing is due', () {
      final r = ZakatResult(
        ZakatInputs(goldPrice: taka(15000), basis: NisabBasis.gold, debts: taka(100000)),
        app,
      );
      expect(r.nisab, taka(1312200));
      expect(r.net, taka(400000));
      expect(r.due, isFalse);
      expect(r.zakat, 0);
    });

    test('gold you own counts, and no price means no answer yet', () {
      final r = ZakatResult(const ZakatInputs(goldGrams: 11.664, goldPrice: 1500000), app);
      expect(r.gold, 17496000);
      expect(r.nisab, isNull, reason: 'silver price not entered');
      final back = ZakatInputs.parse(r.inputs.encode());
      expect(back.goldGrams, 11.664);
      expect(back.cash, isNull);
    });
  });
}
