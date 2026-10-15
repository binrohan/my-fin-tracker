import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/money.dart';
import '../../data/metal_prices.dart';
import '../../ledger/ledger.dart';
import '../../ledger/zakat.dart';
import '../../ui/forms.dart';
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
  bool _fetching = false;

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

  Future<void> _fetchPrices() async {
    setState(() => _fetching = true);
    try {
      final prices = await MetalPrices.fetch();
      if (!mounted) return;
      _update(
        _inputs!.copyWith(
          goldPrice: prices.gold,
          silverPrice: prices.silver,
          pricesAt: () => prices.date,
        ),
      );
    } on Exception catch (e) {
      if (mounted) showSnack(context, '$e');
    } finally {
      if (mounted) setState(() => _fetching = false);
    }
  }

  Future<void> _pickDate(DateTime today) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _inputs!.nextDate(today) ?? today,
      firstDate: DateTime(today.year - 2),
      lastDate: DateTime(today.year + 3),
      helpText: 'Zakat date',
    );
    if (picked != null) _update(_inputs!.copyWith(zakatDate: () => picked));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Zakat')),
    body: LedgerBuilder(builder: _body),
  );

  Widget _body(BuildContext context, Ledger ledger) {
    final status = StatusColors.of(context);
    final inputs = _inputs ??= ZakatInputs.parse(ledger.settings[ZakatInputs.settingKey]);
    final today = ref.watch(todayProvider);
    final app = ZakatFromApp.of(ledger, today: today);
    final next = inputs.nextDate(today);
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
              onChanged: (v) => _update(_inputs!.copyWith(cash: () => v)),
            ),
            OverridableAmount(
              label: 'Investments',
              fromApp: app.investments,
              value: inputs.investments,
              helper: 'DPS, FDR, savings certificates, shares',
              onChanged: (v) => _update(_inputs!.copyWith(investments: () => v)),
            ),
            OverridableAmount(
              label: 'Owed to you',
              fromApp: app.owedToYou,
              value: inputs.owedToYou,
              helper: 'Loans to people you expect back',
              onChanged: (v) => _update(_inputs!.copyWith(owedToYou: () => v)),
            ),
            OverridableAmount(
              label: 'Anything else',
              value: inputs.other,
              helper: 'Business stock, foreign currency, other savings',
              onChanged: (v) => _update(_inputs!.copyWith(other: v ?? 0)),
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
                    onChanged: (v) => _update(_inputs!.copyWith(goldGrams: v)),
                  ),
                ),
                Expanded(
                  child: NumberField(
                    label: 'Price a gram',
                    prefix: '$takaSymbol ',
                    value: inputs.goldPrice / poishaPerTaka,
                    onChanged: (v) => _update(_inputs!.copyWith(goldPrice: taka(v))),
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
                    onChanged: (v) => _update(_inputs!.copyWith(silverGrams: v)),
                  ),
                ),
                Expanded(
                  child: NumberField(
                    label: 'Price a gram',
                    prefix: '$takaSymbol ',
                    value: inputs.silverPrice / poishaPerTaka,
                    onChanged: (v) => _update(_inputs!.copyWith(silverPrice: taka(v))),
                  ),
                ),
              ],
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: _fetching ? null : _fetchPrices,
                icon: _fetching
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.cloud_download_outlined),
                label: const Text('Get today\'s price'),
              ),
            ),
            Text(
              inputs.pricesAt == null
                  ? 'Fetches the international price of pure gold and silver. Jewellers\' '
                        'prices (BAJUS) are usually higher; type them instead if you prefer. '
                        '1 bhori ≈ 11.66 g.'
                  : 'International price for ${DateFormat.yMMMd().format(inputs.pricesAt!)}, '
                        'pure metal. Jewellers\' prices (BAJUS) are usually higher. '
                        '1 bhori ≈ 11.66 g.',
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
              onChanged: (v) => _update(_inputs!.copyWith(debts: () => v)),
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
              onSelectionChanged: (s) => _update(_inputs!.copyWith(basis: s.single)),
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
        SectionCard(
          children: [
            const Label('Zakat date'),
            PickerField(
              label: 'Next zakat date',
              value: next == null ? 'Not set' : DateFormat.yMMMEd().format(next),
              onTap: () => _pickDate(today),
            ),
            Text(
              'The date you choose. After it passes, the same date next year is used.',
              style: muted,
            ),
            if (next != null)
              OverridableAmount(
                label: 'Wealth grows each month by',
                fromApp: app.monthlyGrowth,
                value: inputs.monthlyGrowth,
                helper: app.monthlyGrowth == null
                    ? 'Not enough history yet; type an amount'
                    : 'Average of your last three months',
                onChanged: (v) => _update(inputs.copyWith(monthlyGrowth: () => v)),
              ),
          ],
        ),
        _Result(r: r, today: today, next: next),
        Text(
          'Zakat is due on wealth held for a full year. This is an estimate; '
          'ask a scholar about your own situation.',
          style: muted,
        ),
      ],
    );
  }
}

class _Result extends StatelessWidget {
  const _Result({required this.r, required this.today, required this.next});

  final ZakatResult r;
  final DateTime today;
  final DateTime? next;

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
          const Label('Zakat today, 2.5% of net'),
          Money(r.zakat, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
        ],
        if (next case final date? when r.nisab != null) ..._projection(context, date, status),
      ],
    );
  }

  List<Widget> _projection(BuildContext context, DateTime date, StatusColors status) {
    final days = date.difference(DateTime(today.year, today.month, today.day)).inDays;
    final net = r.projectedNet(today, date);
    final zakat = r.projectedZakat(today, date);
    final when = DateFormat.yMMMd().format(date);
    return [
      const Divider(),
      Label(days == 0 ? 'Zakat date is today' : 'On $when, in $days days'),
      AmountRow(
        'Expected net',
        net,
        detail: r.monthlyGrowth == 0
            ? 'no change expected'
            : '${formatTaka(r.monthlyGrowth, showPlus: true)} a month',
      ),
      if (zakat == 0)
        Text(
          'Expected to stay below the nisab: no zakat.',
          style: TextStyle(color: status.good, fontWeight: FontWeight.w600),
        )
      else ...[
        Text('Expected zakat', style: TextStyle(color: status.muted)),
        Money(zakat, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
      ],
      Text(
        'At today\'s prices. Work it out again on the day.',
        style: TextStyle(color: status.muted, fontSize: 12),
      ),
    ];
  }
}
