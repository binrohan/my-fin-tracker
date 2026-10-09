import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/money.dart';
import '../../data/database.dart';
import '../../ledger/enums.dart';
import '../../ledger/ledger.dart';
import '../../ui/forms.dart';
import '../../ui/widgets.dart';
import '../entries/entries_screen.dart';
import '../save/move_sheet.dart';

String investmentKindLabel(InvestmentKind k) => switch (k) {
  InvestmentKind.dps => 'DPS',
  InvestmentKind.fdr => 'FDR',
  InvestmentKind.savingsCertificate => 'Savings certificate',
  InvestmentKind.shares => 'Shares',
  InvestmentKind.other => 'Other',
};

String maturityText(InvestmentStatus i, DateTime today) {
  final days = i.daysToMaturity(today);
  if (days == null) return 'No maturity date';
  final date = DateFormat.yMMMd().format(i.details!.maturityDate!);
  if (days < 0) return 'Matured $date';
  if (days == 0) return 'Matures today';
  if (days <= 60) return 'Matures in $days days ($date)';
  return 'Matures $date';
}

class InvestmentsScreen extends ConsumerWidget {
  const InvestmentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(todayProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Investments')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addInvestment(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Add investment'),
      ),
      body: LedgerBuilder(
        builder: (context, ledger) {
          final status = StatusColors.of(context);
          final list = ledger.investments();
          final total = list.fold<Poisha>(0, (t, i) => t + i.value);
          final growth = list.fold<Poisha>(0, (t, i) => t + i.growth);
          return PageList(
            children: [
              SectionCard(
                children: [
                  const Label('Total value'),
                  Money(total, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800)),
                  if (growth != 0)
                    Text(
                      '${formatTaka(growth, showPlus: true)} growth recorded',
                      style: TextStyle(color: growth > 0 ? status.good : status.bad),
                    ),
                ],
              ),
              if (list.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Add your DPS, FDR, savings certificates or shares to see them in your '
                    'net worth and get a reminder before they mature.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: status.muted),
                  ),
                ),
              for (final i in list) InvestmentCard(status: i, today: today),
            ],
          );
        },
      ),
    );
  }
}

class InvestmentCard extends StatelessWidget {
  const InvestmentCard({super.key, required this.status, required this.today});

  final InvestmentStatus status;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final colors = StatusColors.of(context);
    final i = status;
    final d = i.details;
    final days = i.daysToMaturity(today);
    final soon = days != null && days <= 30;
    return SectionCard(
      onTap: () => openScreen(context, InvestmentScreen(accountId: i.account.id)),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                i.account.name,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
            ),
            if (d != null) StatusChip(investmentKindLabel(d.kind), tone: ChipTone.accent),
          ],
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Expanded(
              child: Money(
                i.value,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
            ),
            if (i.growth != 0)
              Money(i.growth, showPlus: true, color: i.growth > 0 ? colors.good : colors.bad),
          ],
        ),
        if (d?.totalInstalments != null && d!.totalInstalments! > 0) ...[
          Bar(i.instalmentsPaid / d.totalInstalments!),
          Text(
            '${i.instalmentsPaid} of ${d.totalInstalments} instalments'
            '${d.instalment == null ? '' : ' · ${formatTaka(d.instalment!)}/mo'}',
          ),
        ],
        Text(
          [
            maturityText(i, today),
            if (d?.rateBp != null) '${formatPercentBp(d!.rateBp!)} a year',
          ].join(' · '),
          style: TextStyle(color: soon ? colors.warn : colors.muted, fontSize: 13),
        ),
      ],
    );
  }
}

/// One investment: value, details, and what you can do with it.
class InvestmentScreen extends ConsumerWidget {
  const InvestmentScreen({super.key, required this.accountId});

  final int accountId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(todayProvider);
    return LedgerBuilder(
      builder: (context, ledger) {
        final account = ledger.accounts[accountId];
        if (account == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Removed.')),
          );
        }
        final i = ledger.investmentStatus(account);
        final fund = ledger.funds.values.firstWhere(
          (f) => f.kind == FundKind.investment,
          orElse: () => ledger.spendingFund,
        );
        final bank = defaultAccount(ledger, AccountType.bank).id;
        final history = [
          for (final e in ledger.entries)
            if (ledger.postingsOf(e.id).any((p) => p.accountId == account.id)) e,
        ];
        final colors = StatusColors.of(context);

        return Scaffold(
          appBar: AppBar(
            title: Text(account.name),
            actions: [
              IconButton(
                tooltip: 'Edit details',
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => _editDetails(context, ref, i),
              ),
            ],
          ),
          body: PageList(
            children: [
              InvestmentCard(status: i, today: today),
              SectionCard(
                children: [
                  AmountRow('Put in', i.invested),
                  AmountRow('Growth', i.growth, signed: true),
                  AmountRow('Value now', i.value, total: true),
                  if (i.details?.startDate != null)
                    Text(
                      'Started ${DateFormat.yMMMd().format(i.details!.startDate!)}',
                      style: TextStyle(color: colors.muted),
                    ),
                  if ((i.details?.note ?? '').isNotEmpty)
                    Text(i.details!.note, style: TextStyle(color: colors.muted)),
                ],
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    icon: const Icon(Icons.add),
                    label: Text(
                      i.details?.kind == InvestmentKind.dps ? 'Pay instalment' : 'Add money',
                    ),
                    onPressed: () => showMoveSheet(
                      context,
                      title: '${account.name}: pay in',
                      from: (account: bank, fund: ledger.spendingFund.id),
                      to: (account: account.id, fund: fund.id),
                      lockTo: true,
                      action: 'Pay',
                      suggested: i.details?.instalment,
                      note: i.details?.kind == InvestmentKind.dps
                          ? 'DPS instalment ${i.instalmentsPaid + 1}'
                                '${i.details?.totalInstalments == null ? '' : ' of ${i.details!.totalInstalments}'}'
                          : '',
                    ),
                  ),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.trending_up),
                    label: const Text('Update value'),
                    onPressed: () => _updateValue(context, ref, ledger, i, fund.id),
                  ),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.account_balance_outlined),
                    label: Text(
                      (i.daysToMaturity(today) ?? 1) <= 0 ? 'Matured: take out' : 'Withdraw',
                    ),
                    onPressed: i.value <= 0
                        ? null
                        : () => showMoveSheet(
                            context,
                            title: 'Take money out of ${account.name}',
                            hint: 'Moves it to your bank. Choose Monthly Savings or Spending as its purpose.',
                            from: (account: account.id, fund: fund.id),
                            to: (
                              account: bank,
                              fund:
                                  ledger.fundsOfKind(FundKind.savings).firstOrNull?.id ??
                                  ledger.spendingFund.id,
                            ),
                            lockFrom: true,
                            action: 'Withdraw',
                            suggested: i.value,
                            note: 'From ${account.name}',
                          ),
                  ),
                ],
              ),
              if (i.value == 0 && !account.archived)
                TextButton(
                  onPressed: () =>
                      ref.read(setupRepositoryProvider).updateAccount(account.id, archived: true),
                  child: const Text('Close this investment (archive it)'),
                ),
              SectionCard(
                children: [
                  const Label('History'),
                  for (final e in history.take(60))
                    InkWell(
                      onTap: () => showEntryDetails(context, e),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: AmountRow(
                          entryTitle(ledger, e),
                          ledger
                              .postingsOf(e.id)
                              .where((p) => p.accountId == account.id)
                              .fold(0, (t, p) => t + p.amount),
                          signed: true,
                          detail: DateFormat.yMMMd().format(e.date),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _updateValue(
    BuildContext context,
    WidgetRef ref,
    Ledger ledger,
    InvestmentStatus i,
    int fund,
  ) async {
    final value = TextEditingController(text: amountText(i.value));
    final ok = await showModalBottomSheet<bool>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final v = parseTaka(value.text);
          return SheetBody(
            title: 'Current value of ${i.account.name}',
            children: [
              Text(
                'From your bank statement or broker app. The difference is recorded as growth.',
                style: TextStyle(color: StatusColors.of(context).muted),
              ),
              AmountRow('Recorded now', i.value),
              AmountField(
                controller: value,
                label: 'Value today',
                autofocus: true,
                onChanged: (_) => setState(() {}),
              ),
              if (v != null && v != i.value) AmountRow('Change', v - i.value, signed: true),
              FilledButton(
                onPressed: v == null || v == i.value ? null : () => Navigator.pop(context, true),
                child: const Text('Save value'),
              ),
            ],
          );
        },
      ),
    );
    if (ok != true) return;
    await ref
        .read(repositoryProvider)
        .updateInvestmentValue(
          accountId: i.account.id,
          investmentFund: fund,
          currentValue: i.value,
          newValue: parseTaka(value.text)!,
          date: ref.read(todayProvider),
        );
  }
}

/// Add a new investment, or edit the details of an existing one.
Future<void> _addInvestment(BuildContext context, WidgetRef ref) =>
    _investmentForm(context, ref, null);

Future<void> _editDetails(BuildContext context, WidgetRef ref, InvestmentStatus i) =>
    _investmentForm(context, ref, i);

Future<void> _investmentForm(
  BuildContext context,
  WidgetRef ref,
  InvestmentStatus? existing,
) async {
  final ledger = ref.read(ledgerProvider).value;
  if (ledger == null) return;
  final d = existing?.details;
  final name = TextEditingController(text: existing?.account.name);
  var kind = d?.kind ?? InvestmentKind.dps;
  DateTime? start = d?.startDate;
  DateTime? maturity = d?.maturityDate;
  final rate = TextEditingController(
    text: d?.rateBp == null ? '' : formatPercentBp(d!.rateBp!).replaceAll('%', ''),
  );
  final instalment = TextEditingController(text: amountText(d?.instalment ?? 0));
  final total = TextEditingController(text: d?.totalInstalments?.toString() ?? '');
  final paid = TextEditingController(
    text: d == null || d.openingInstalments == 0 ? '' : '${d.openingInstalments}',
  );
  final value = TextEditingController();
  final note = TextEditingController(text: d?.note ?? '');
  final today = ref.read(todayProvider);

  final ok = await showModalBottomSheet<bool>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
        Widget date(String label, DateTime? v, ValueChanged<DateTime> set) => PickerField(
          label: label,
          value: v == null ? 'Not set' : DateFormat.yMMMd().format(v),
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: v ?? today,
              firstDate: DateTime(1990),
              lastDate: DateTime(today.year + 40),
            );
            if (picked != null) setState(() => set(picked));
          },
        );
        final isDps = kind == InvestmentKind.dps;
        return SheetBody(
          title: existing == null ? 'Add investment' : 'Edit ${existing.account.name}',
          children: [
            TextField(
              controller: name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'e.g. DPS · Dutch-Bangla',
                border: OutlineInputBorder(),
              ),
            ),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final k in InvestmentKind.values)
                  ChoiceChip(
                    label: Text(investmentKindLabel(k)),
                    selected: k == kind,
                    onSelected: (_) => setState(() => kind = k),
                  ),
              ],
            ),
            Row(
              spacing: 8,
              children: [
                Expanded(child: date('Started', start, (v) => start = v)),
                Expanded(child: date('Matures', maturity, (v) => maturity = v)),
              ],
            ),
            TextField(
              controller: rate,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
              decoration: const InputDecoration(
                labelText: 'Rate a year (optional)',
                suffixText: '%',
                isDense: true,
                border: OutlineInputBorder(),
              ),
            ),
            if (isDps) ...[
              AmountField(controller: instalment, label: 'Monthly instalment'),
              Row(
                spacing: 8,
                children: [
                  Expanded(
                    child: TextField(
                      controller: total,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        labelText: 'Instalments in total',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: paid,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        labelText: 'Paid before the app',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (existing == null)
              AmountField(controller: value, label: 'Value today (what is already in it)'),
            TextField(
              controller: note,
              decoration: const InputDecoration(
                labelText: 'Note (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save')),
          ],
        );
      },
    ),
  );
  if (ok != true || name.text.trim().isEmpty) return;
  final rateBp = double.tryParse(rate.text) == null
      ? null
      : (double.parse(rate.text) * 100).round();
  final isDps = kind == InvestmentKind.dps;
  final repo = ref.read(repositoryProvider);
  if (existing == null) {
    final fund = ledger.funds.values.firstWhere(
      (f) => f.kind == FundKind.investment,
      orElse: () => ledger.spendingFund,
    );
    await repo.addInvestment(
      name: name.text,
      kind: kind,
      startDate: start,
      maturityDate: maturity,
      rateBp: rateBp,
      instalment: isDps ? parseTaka(instalment.text) : null,
      totalInstalments: isDps ? int.tryParse(total.text) : null,
      openingInstalments: isDps ? int.tryParse(paid.text) ?? 0 : 0,
      currentValue: parseTaka(value.text) ?? 0,
      asOf: today.subtract(const Duration(days: 1)),
      investmentFund: fund.id,
      note: note.text.trim(),
    );
  } else {
    await ref.read(setupRepositoryProvider).updateAccount(existing.account.id, name: name.text);
    await repo.saveInvestmentDetails(
      InvestmentDetailsCompanion.insert(
        accountId: Value(existing.account.id),
        kind: kind,
        startDate: Value(start),
        maturityDate: Value(maturity),
        rateBp: Value(rateBp),
        instalment: Value(isDps ? parseTaka(instalment.text) : null),
        totalInstalments: Value(isDps ? int.tryParse(total.text) : null),
        openingInstalments: Value(isDps ? int.tryParse(paid.text) ?? 0 : 0),
        note: Value(note.text.trim()),
      ),
    );
  }
}
