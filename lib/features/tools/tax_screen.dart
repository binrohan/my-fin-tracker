import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/money.dart';
import '../../data/ledger_repository.dart';
import '../../ledger/enums.dart';
import '../../ledger/ledger.dart';
import '../../ledger/tax.dart';
import '../../ui/forms.dart';
import '../../ui/widgets.dart';
import 'tax_rules_screen.dart';
import 'tool_fields.dart';

/// A simplified income tax estimate for one income year (July to June),
/// with every step shown.
class TaxScreen extends ConsumerStatefulWidget {
  const TaxScreen({super.key, this.year});

  /// The income year to show; the current one when null.
  final IncomeYear? year;

  @override
  ConsumerState<TaxScreen> createState() => _TaxScreenState();
}

class _TaxScreenState extends ConsumerState<TaxScreen> {
  late final LedgerRepository _repo;
  late IncomeYear _year;
  late SettingSaver _saver;
  SavedTaxInputs? _saved;

  /// Show the working for recorded income only, not the projection.
  bool _recorded = false;

  @override
  void initState() {
    super.initState();
    // Read now: ref can't be used once the screen is closing.
    _repo = ref.read(repositoryProvider);
    _year = widget.year ?? IncomeYear.of(ref.read(todayProvider));
    _saver = _saverFor(_year);
  }

  SettingSaver _saverFor(IncomeYear year) =>
      SettingSaver((v) => _repo.setSetting(SavedTaxInputs.settingKey(year), v));

  @override
  void dispose() {
    _saver.flush();
    super.dispose();
  }

  void _update(SavedTaxInputs saved) {
    setState(() => _saved = saved);
    _saver(saved.encode());
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.year == null ? 'Income tax' : 'Income tax ${_year.label}'),
      actions: [
        IconButton(
          tooltip: 'Rates and slabs',
          icon: const Icon(Icons.tune),
          onPressed: () => openScreen(context, const TaxRulesScreen()),
        ),
      ],
    ),
    body: LedgerBuilder(builder: _body),
  );

  Widget _body(BuildContext context, Ledger ledger) {
    final today = ref.watch(todayProvider);
    final status = StatusColors.of(context);
    final muted = TextStyle(color: status.muted, fontSize: 13);
    final rules = TaxRules.parse(ledger.settings[TaxRules.settingKey]);
    final s = _saved ??= SavedTaxInputs.parse(ledger.settings[SavedTaxInputs.settingKey(_year)]);
    final app = TaxFromApp.of(ledger, _year, today);
    final fullYear = computeTax(rules, s.resolve(app));
    // Only the income entries in the app: no estimates, no plan, no typed figures.
    final recorded = computeTax(
      rules,
      TaxInputs(
        salary: app.salarySoFar,
        otherIncome: app.otherSoFar,
        investment: app.investedSoFar,
        alreadyPaid: s.alreadyPaid,
        kind: s.kind,
      ),
    );
    final running = _year.contains(today);
    final day = DateFormat.yMMMd();
    final current = IncomeYear.of(today);
    final month = DateFormat.yMMM();
    // A year's return is due on 30 November after it ends (Tax Day).
    final due = DateTime(_year.end.year, 11, 30);
    final last = IncomeYear(current.startYear - 1);
    final lastDue = DateTime(last.end.year, 11, 30);

    SavedTaxInputs edit({
      Poisha? Function()? salary,
      Poisha? Function()? other,
      Poisha? Function()? investment,
      Poisha? paid,
      TaxpayerKind? kind,
    }) => SavedTaxInputs(
      salary: salary == null ? s.salary : salary(),
      otherIncome: other == null ? s.otherIncome : other(),
      investment: investment == null ? s.investment : investment(),
      alreadyPaid: paid ?? s.alreadyPaid,
      kind: kind ?? s.kind,
    );

    String months(int n) => n == 1 ? '1 month' : '$n months';
    String parts(Poisha actual, Poisha estimated, Poisha planned, {int? before, int? after}) => [
      'Recorded ${formatTaka(actual)}',
      if (estimated > 0)
        'estimated ${formatTaka(estimated)}${before == null || before == 0 ? '' : ' for ${months(before)} before your entries'}',
      if (planned > 0)
        'plan ${formatTaka(planned)}${after == null || after == 0 ? '' : ' for ${months(after)} to come'}',
    ].join(' + ');
    final salaryHelp = parts(
      app.salarySoFar,
      app.salaryEstimated,
      app.salaryPlanned,
      before: app.monthsEstimated,
      after: app.monthsToCome,
    );
    final otherHelp = parts(app.otherSoFar, app.otherEstimated, app.otherPlanned);
    final investHelp = parts(app.investedSoFar, app.investEstimated, app.investPlanned);

    return PageList(
      children: [
        // Key by year so the fields start again with that year's figures.
        KeyedSubtree(
          key: ValueKey(_year.startYear),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 12,
            children: [
              Text(
                'Income year ${month.format(_year.start)} to '
                '${month.format(_year.end.subtract(const Duration(days: 1)))}'
                '${running ? '' : ' · return due ${day.format(due)}'}',
                style: muted,
              ),
              SectionCard(
                children: [
                  Label('Tax for ${_year.label}'),
                  AmountRow('Projected', fullYear.tax),
                  AmountRow('Recorded', recorded.tax),
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(value: false, label: Text('Projected')),
                      ButtonSegment(value: true, label: Text('Recorded')),
                    ],
                    selected: {_recorded},
                    showSelectedIcon: false,
                    onSelectionChanged: (v) => setState(() => _recorded = v.single),
                  ),
                ],
              ),
              SectionCard(
                children: [
                  const Label('Income for the year'),
                  OverridableAmount(
                    label: 'Salary',
                    fromApp: app.salary,
                    value: s.salary,
                    helper: salaryHelp,
                    onChanged: (v) => _update(edit(salary: () => v)),
                  ),
                  OverridableAmount(
                    label: 'Other taxable income',
                    fromApp: app.other,
                    value: s.otherIncome,
                    helper: otherHelp,
                    onChanged: (v) => _update(edit(other: () => v)),
                  ),
                  PickerField(
                    label: 'Taxpayer',
                    value: s.kind.label,
                    onTap: () async {
                      final kind = await showDialog<TaxpayerKind>(
                        context: context,
                        builder: (context) => SimpleDialog(
                          title: const Text('Taxpayer'),
                          children: [
                            for (final k in TaxpayerKind.values)
                              SimpleDialogOption(
                                onPressed: () => Navigator.pop(context, k),
                                child: Text(
                                  '${k.label} · tax free up to '
                                  '${formatTaka(rules.thresholds[k]!)}',
                                ),
                              ),
                          ],
                        ),
                      );
                      if (kind != null) _update(edit(kind: kind));
                    },
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      style: TextButton.styleFrom(padding: EdgeInsets.zero),
                      onPressed: () => showIncomeTaxTypes(context),
                      icon: const Icon(Icons.rule, size: 18),
                      label: const Text('Which incomes are taxable'),
                    ),
                  ),
                ],
              ),
              SectionCard(
                children: [
                  const Label('Investment and tax paid'),
                  OverridableAmount(
                    label: 'Eligible investment',
                    fromApp: app.investment,
                    value: s.investment,
                    helper: '$investHelp. DPS, savings certificates, insurance, PF, listed shares.',
                    onChanged: (v) => _update(edit(investment: () => v)),
                  ),
                  OverridableAmount(
                    label: 'Tax already paid',
                    value: s.alreadyPaid,
                    helper: 'Deducted from salary or interest, or paid in advance',
                    onChanged: (v) => _update(edit(paid: v ?? 0)),
                  ),
                ],
              ),
            ],
          ),
        ),
        _Steps(result: _recorded ? recorded : fullYear, rules: rules),
        // Last year, while its return can still be filed.
        if (widget.year == null && !today.isAfter(lastDue))
          Card(
            margin: EdgeInsets.zero,
            child: ListTile(
              leading: const Icon(Icons.history),
              title: Text('Last year, ${last.label}'),
              subtitle: Text('Return due ${day.format(lastDue)}'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => openScreen(context, TaxScreen(year: last)),
            ),
          ),
        Text(
          'An estimate using ${rules.label}. Check the current rates with NBR or a tax '
          'adviser before you file. Change rates and slabs with the button at the top.',
          style: muted,
        ),
      ],
    );
  }
}

class _Steps extends StatelessWidget {
  const _Steps({required this.result, required this.rules});

  final TaxResult result;
  final TaxRules rules;

  @override
  Widget build(BuildContext context) {
    final r = result;
    final status = StatusColors.of(context);
    String pct(int bp) => formatPercentBp(bp);
    return SectionCard(
      color: Theme.of(context).colorScheme.primaryContainer,
      children: [
        const Label('How it is worked out'),
        AmountRow('Total income', r.grossIncome),
        if (r.exemption > 0)
          AmountRow(
            'Salary exemption',
            -r.exemption,
            detail:
                '1/${rules.salaryExemptDivisor} of salary, at most '
                '${formatTaka(rules.salaryExemptCap)}',
          ),
        AmountRow('Taxable income', r.taxable, total: true),
        for (final (i, b) in r.bands.indexed)
          if (b.amount > 0)
            AmountRow(
              '${i == 0 ? 'First' : (rules.slabs[i - 1].width == null ? 'Remaining' : 'Next')} '
              '${formatTaka(b.amount)} at ${pct(b.rateBp)}',
              b.tax,
            ),
        AmountRow('Tax on the slabs', r.slabTax, total: true),
        if (r.rebate > 0)
          AmountRow(
            'Investment rebate',
            -r.rebate,
            detail:
                '${pct(rules.rebateBp)} of investment, at most '
                '${pct(rules.rebateIncomeCapBp)} of income',
          ),
        if (r.minimumApplies) AmountRow('Minimum tax applies', r.minimumTax),
        AmountRow('Tax for the year', r.tax, total: true),
        if (r.tax == 0)
          Text(
            'Taxable income is within the tax-free limit of ${formatTaka(r.threshold)}.',
            style: TextStyle(color: status.good),
          ),
        if (r.inputs.alreadyPaid > 0) ...[
          AmountRow('Already paid', -r.inputs.alreadyPaid),
          AmountRow(r.payable >= 0 ? 'Still to pay' : 'Refund due', r.payable.abs(), total: true),
        ],
      ],
    );
  }
}

/// Salary, other taxable or not taxable, for each income category.
Future<void> showIncomeTaxTypes(BuildContext context) => showModalBottomSheet(
  context: context,
  useRootNavigator: true,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (_) => Consumer(
    builder: (context, ref, _) {
      final ledger = ref.watch(ledgerProvider).value;
      if (ledger == null) return const SizedBox(height: 200);
      final incomes = ledger.leafCategories(CategoryKind.income);
      return SheetBody(
        title: 'Which incomes are taxable',
        children: [
          Text(
            'Salary gets the salary exemption. Other taxable income is taxed in full. '
            'Not taxable is left out (gifts, money paid back to you).',
            style: TextStyle(color: StatusColors.of(context).muted, fontSize: 13),
          ),
          for (final c in incomes) ...[
            Text(c.name, style: const TextStyle(fontWeight: FontWeight.w600)),
            SegmentedButton<IncomeTaxType>(
              segments: [
                for (final t in IncomeTaxType.values) ButtonSegment(value: t, label: Text(t.label)),
              ],
              selected: {incomeTaxType(ledger, c.id)},
              showSelectedIcon: false,
              onSelectionChanged: (v) => ref
                  .read(repositoryProvider)
                  .setSetting(incomeTaxTypesSetting, encodeIncomeTaxType(ledger, c.id, v.single)),
            ),
          ],
        ],
      );
    },
  ),
);
