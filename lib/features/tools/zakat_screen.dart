import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/money.dart';
import '../../ledger/ledger.dart';
import '../../ledger/zakat.dart';
import '../../ui/widgets.dart';
import 'tool_fields.dart';

/// Zakat on what you have today: the app fills in bank, cash, investments
/// and loans; you add gold, silver and their prices.
class ZakatScreen extends ConsumerStatefulWidget {
  const ZakatScreen({super.key});

  @override
  ConsumerState<ZakatScreen> createState() => _ZakatScreenState();
}

class _ZakatScreenState extends ConsumerState<ZakatScreen> {
  late final SettingSaver _saver;
  ZakatInputs? _inputs;

  @override
  void initState() {
    super.initState();
    // Read now: ref can't be used once the screen is closing.
    final repo = ref.read(repositoryProvider);
    _saver = SettingSaver((v) => repo.setSetting(ZakatInputs.settingKey, v));
  }

  @override
  void dispose() {
    _saver.flush();
    super.dispose();
  }

  void _update(ZakatInputs inputs) {
    setState(() => _inputs = inputs);
    _saver(inputs.encode());
  }

  ZakatInputs _with({
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
  }) {
    final i = _inputs!;
    return ZakatInputs(
      cash: cash == null ? i.cash : cash(),
      investments: investments == null ? i.investments : investments(),
      owedToYou: owedToYou == null ? i.owedToYou : owedToYou(),
      debts: debts == null ? i.debts : debts(),
      goldGrams: goldGrams ?? i.goldGrams,
      silverGrams: silverGrams ?? i.silverGrams,
      goldPrice: goldPrice ?? i.goldPrice,
      silverPrice: silverPrice ?? i.silverPrice,
      other: other ?? i.other,
      basis: basis ?? i.basis,
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Zakat')),
    body: LedgerBuilder(builder: _body),
  );

  Widget _body(BuildContext context, Ledger ledger) {
    final status = StatusColors.of(context);
    final inputs = _inputs ??= ZakatInputs.parse(ledger.settings[ZakatInputs.settingKey]);
    final app = ZakatFromApp.of(ledger);
    final r = ZakatResult(inputs, app);
    final muted = TextStyle(color: status.muted, fontSize: 13);

    return PageList(
      children: [
        SectionCard(
          children: [
            const Label('What you have'),
            OverridableAmount(
              label: 'Bank, cash and wallets',
              fromApp: app.cash,
              value: inputs.cash,
              helper: 'From your balances today',
              onChanged: (v) => _update(_with(cash: () => v)),
            ),
            OverridableAmount(
              label: 'Investments',
              fromApp: app.investments,
              value: inputs.investments,
              helper: 'DPS, FDR, savings certificates, shares',
              onChanged: (v) => _update(_with(investments: () => v)),
            ),
            OverridableAmount(
              label: 'Owed to you',
              fromApp: app.owedToYou,
              value: inputs.owedToYou,
              helper: 'Loans to people you expect back',
              onChanged: (v) => _update(_with(owedToYou: () => v)),
            ),
            OverridableAmount(
              label: 'Anything else',
              value: inputs.other,
              helper: 'Business stock, foreign currency, other savings',
              onChanged: (v) => _update(_with(other: v ?? 0)),
            ),
          ],
        ),
        SectionCard(
          children: [
            const Label('Gold and silver'),
            Row(
              spacing: 8,
              children: [
                Expanded(
                  child: NumberField(
                    label: 'Gold',
                    suffix: 'g',
                    value: inputs.goldGrams,
                    onChanged: (v) => _update(_with(goldGrams: v)),
                  ),
                ),
                Expanded(
                  child: NumberField(
                    label: 'Price a gram',
                    prefix: '$takaSymbol ',
                    value: inputs.goldPrice / poishaPerTaka,
                    onChanged: (v) => _update(_with(goldPrice: taka(v))),
                  ),
                ),
              ],
            ),
            Row(
              spacing: 8,
              children: [
                Expanded(
                  child: NumberField(
                    label: 'Silver',
                    suffix: 'g',
                    value: inputs.silverGrams,
                    onChanged: (v) => _update(_with(silverGrams: v)),
                  ),
                ),
                Expanded(
                  child: NumberField(
                    label: 'Price a gram',
                    prefix: '$takaSymbol ',
                    value: inputs.silverPrice / poishaPerTaka,
                    onChanged: (v) => _update(_with(silverPrice: taka(v))),
                  ),
                ),
              ],
            ),
            Text(
              'Use today\'s selling price (BAJUS publishes it). 1 bhori ≈ 11.66 g.',
              style: muted,
            ),
          ],
        ),
        SectionCard(
          children: [
            const Label('What you owe now'),
            OverridableAmount(
              label: 'Debts due',
              fromApp: app.debts,
              value: inputs.debts,
              helper: 'Money you owe people, from your loans',
              onChanged: (v) => _update(_with(debts: () => v)),
            ),
          ],
        ),
        SectionCard(
          children: [
            const Label('Nisab'),
            SegmentedButton<NisabBasis>(
              segments: const [
                ButtonSegment(value: NisabBasis.silver, label: Text('Silver')),
                ButtonSegment(value: NisabBasis.gold, label: Text('Gold')),
              ],
              selected: {inputs.basis},
              showSelectedIcon: false,
              onSelectionChanged: (s) => _update(_with(basis: s.single)),
            ),
            Text(
              r.nisab == null
                  ? '${formatNumber(r.nisabGrams)} g of ${inputs.basis.name}. '
                        'Enter its price a gram above.'
                  : '${formatNumber(r.nisabGrams)} g × ${formatTaka(r.nisabPrice)} = '
                        '${formatTaka(r.nisab!)}',
              style: muted,
            ),
          ],
        ),
        _Result(r: r),
        Text(
          'Zakat is due on wealth held for a full lunar year. This is an estimate; '
          'ask a scholar about your own situation.',
          style: muted,
        ),
      ],
    );
  }
}

class _Result extends StatelessWidget {
  const _Result({required this.r});

  final ZakatResult r;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final status = StatusColors.of(context);
    return SectionCard(
      color: scheme.primaryContainer,
      children: [
        AmountRow('Total wealth', r.assets),
        AmountRow('Less what you owe', -r.debts, signed: r.debts != 0),
        AmountRow('Net', r.net, total: true),
        const SizedBox(height: 4),
        if (r.nisab == null)
          Text('Enter the price of ${r.inputs.basis.name} to check the nisab.')
        else if (!r.due)
          Text(
            'Below the nisab of ${formatTaka(r.nisab!)}: no zakat is due.',
            style: TextStyle(color: status.good, fontWeight: FontWeight.w600),
          )
        else ...[
          const Label('Zakat, 2.5% of net'),
          Money(r.zakat, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
        ],
      ],
    );
  }
}
