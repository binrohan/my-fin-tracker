import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/money.dart';
import '../../data/ledger_repository.dart';
import '../../ledger/ledger.dart';
import '../../ledger/tax.dart';
import '../../ui/forms.dart';
import '../../ui/widgets.dart';
import 'tax_rules_screen.dart';
import 'tool_fields.dart';

/// A simplified income tax estimate for one income year (July to June),
/// with every step shown.
class TaxScreen extends ConsumerStatefulWidget {
  const TaxScreen({super.key});

  @override
  ConsumerState<TaxScreen> createState() => _TaxScreenState();
}

class _TaxScreenState extends ConsumerState<TaxScreen> {
  late final LedgerRepository _repo;
  late IncomeYear _year;
  late SettingSaver _saver;
  SavedTaxInputs? _saved;

  /// Show the steps for income up to today instead of the whole year.
  bool _soFar = false;

  @override
  void initState() {
    super.initState();
    // Read now: ref can't be used once the screen is closing.
    _repo = ref.read(repositoryProvider);
    _year = IncomeYear.of(ref.read(todayProvider));
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

  void _switchYear(IncomeYear year) {
    _saver.flush();
    setState(() {
      _year = year;
      _saver = _saverFor(year);
      _saved = null;
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Income tax'),
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
    // As if the year ended today: only what your entries show so far.
    final soFar = computeTax(
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
    final lastDay = _year.end.subtract(const Duration(days: 1));
    final current = IncomeYear.of(today);
    final month = DateFormat.yMMM();

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

    final salaryHelp = app.monthsToCome == 0
        ? 'Received ${formatTaka(app.salarySoFar)}'
        : 'Received ${formatTaka(app.salarySoFar)} so far + plan '
              '${formatTaka(app.salaryPlanned)} for ${app.monthsToCome} more months';
    final investHelp = app.monthsToCome == 0 || app.investPlanned == 0
        ? 'Put into investments: ${formatTaka(app.investedSoFar)}'
        : 'Invested ${formatTaka(app.investedSoFar)} so far + plan '
              '${formatTaka(app.investPlanned)}';

    return PageList(
      children: [
        // Key by year so the fields start again with that year's figures.
        KeyedSubtree(
          key: ValueKey(_year.startYear),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 12,
            children: [
              SegmentedButton<int>(
                segments: [
                  for (final y in [current.startYear - 1, current.startYear])
                    ButtonSegment(value: y, label: Text(IncomeYear(y).label)),
                ],
                selected: {_year.startYear},
                showSelectedIcon: false,
                onSelectionChanged: (v) => _switchYear(IncomeYear(v.single)),
              ),
              Text(
                'Income year ${month.format(_year.start)} to '
                '${month.format(_year.end.subtract(const Duration(days: 1)))}',
                style: muted,
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
                    fromApp: app.otherSoFar,
                    value: s.otherIncome,
                    helper: 'Other income recorded this year',
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
        if (running)
          SectionCard(
            children: [
              const Label('Tax for this income year'),
              AmountRow(
                'Full year',
                fullYear.tax,
                detail: 'to ${day.format(lastDay)}, with your plan',
              ),
              AmountRow('Up to today', soFar.tax, detail: 'income to ${day.format(today)}'),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: false, label: Text('Full year')),
                  ButtonSegment(value: true, label: Text('Up to today')),
                ],
                selected: {_soFar},
                showSelectedIcon: false,
                onSelectionChanged: (v) => setState(() => _soFar = v.single),
              ),
              if (_soFar)
                Text(
                  'Tax on the income your entries show so far, as if the year ended today. '
                  'Your own figures above are for the full year and are not used here.',
                  style: muted,
                ),
            ],
          ),
        _Steps(result: running && _soFar ? soFar : fullYear, rules: rules),
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
