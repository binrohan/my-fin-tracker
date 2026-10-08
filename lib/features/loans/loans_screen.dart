import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/money.dart';
import '../../ledger/enums.dart';
import '../../ledger/ledger.dart';
import '../../ui/forms.dart';
import '../../ui/widgets.dart';
import '../entries/entries_screen.dart';
import 'loan_sheets.dart';

/// All loans: from your own savings, and with people.
class LoansScreen extends StatefulWidget {
  const LoansScreen({super.key, this.people = false});

  final bool people;

  @override
  State<LoansScreen> createState() => _LoansScreenState();
}

class _LoansScreenState extends State<LoansScreen> {
  late bool _people = widget.people;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Loans')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showNewLoan(context, kind: _people ? LoanKind.lent : LoanKind.ownSavings),
        icon: const Icon(Icons.add),
        label: const Text('New loan'),
      ),
      body: LedgerBuilder(
        builder: (context, ledger) {
          final status = StatusColors.of(context);
          final all = ledger
              .allLoans()
              .where((s) => (s.loan.kind != LoanKind.ownSavings) == _people)
              .toList();
          final open = all.where((s) => s.remaining > 0);
          final owedToYou = open
              .where((s) => s.loan.kind == LoanKind.lent)
              .fold<Poisha>(0, (t, s) => t + s.remaining);
          final youOwe = open
              .where((s) => s.loan.kind != LoanKind.lent)
              .fold<Poisha>(0, (t, s) => t + s.remaining);

          return PageList(
            children: [
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: false, label: Text('Own savings')),
                  ButtonSegment(value: true, label: Text('People')),
                ],
                selected: {_people},
                showSelectedIcon: false,
                onSelectionChanged: (s) => setState(() => _people = s.single),
              ),
              if (_people)
                Row(
                  spacing: 10,
                  children: [
                    Expanded(
                      child: SectionCard(
                        children: [
                          const Label('They owe you'),
                          Money(
                            owedToYou,
                            color: status.good,
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: SectionCard(
                        children: [
                          const Label('You owe'),
                          Money(
                            youOwe,
                            color: status.bad,
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              else
                SectionCard(
                  children: [
                    const Label('Owed to your savings'),
                    Money(
                      youOwe,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                    ),
                    Text(
                      'Borrowing from your savings adds a ${formatPercentBp(ledger.borrowChargeBp)} charge, '
                      'which goes back to the savings when you repay.',
                      style: TextStyle(color: status.muted),
                    ),
                  ],
                ),
              if (all.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    _people ? 'No loans with people.' : 'Nothing borrowed from your savings.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: status.muted),
                  ),
                ),
              for (final s in all)
                LoanCard(
                  ledger: ledger,
                  status: s,
                  onTap: () => openScreen(context, LoanScreen(loanId: s.loan.id)),
                ),
            ],
          );
        },
      ),
    );
  }
}

class LoanCard extends StatelessWidget {
  const LoanCard({super.key, required this.ledger, required this.status, this.onTap});

  final Ledger ledger;
  final LoanStatus status;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = StatusColors.of(context);
    final loan = status.loan;
    final closed = status.remaining <= 0;
    final (chip, tone) = closed
        ? ('Paid', ChipTone.good)
        : switch (loan.kind) {
            LoanKind.ownSavings => ('Own savings', ChipTone.warn),
            LoanKind.lent => ('Lent', ChipTone.good),
            LoanKind.borrowed => ('Borrowed', ChipTone.bad),
          };
    final overdue = !closed && loan.dueDate != null && loan.dueDate!.isBefore(DateTime.now());
    return SectionCard(
      onTap: onTap,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                loanTitle(ledger, status),
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
            ),
            if (overdue)
              const Padding(
                padding: EdgeInsets.only(right: 6),
                child: StatusChip('Overdue', tone: ChipTone.bad),
              ),
            StatusChip(chip, tone: tone),
          ],
        ),
        Text(
          [
            DateFormat.yMMMd().format(loan.date),
            loan.chargeRateBp == 0 ? 'no charge' : 'charge ${formatPercentBp(loan.chargeRateBp)}',
            if (loan.dueDate != null) 'due ${DateFormat.yMMMd().format(loan.dueDate!)}',
          ].join(' · '),
          style: TextStyle(color: colors.muted, fontSize: 13),
        ),
        Bar(status.progress, color: colors.good),
        Row(
          children: [
            Expanded(child: Text('${formatTaka(status.repaid)} of ${formatTaka(status.due)} paid')),
            Money(
              status.remaining,
              color: closed
                  ? colors.muted
                  : (loan.kind == LoanKind.lent ? colors.good : colors.bad),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ],
    );
  }
}

/// One loan with its timeline.
class LoanScreen extends ConsumerWidget {
  const LoanScreen({super.key, required this.loanId});

  final int loanId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LedgerBuilder(
      builder: (context, ledger) {
        final loan = ledger.loans.where((l) => l.id == loanId).firstOrNull;
        if (loan == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('This loan was deleted.')),
          );
        }
        final s = ledger.loanStatus(loan);
        final colors = StatusColors.of(context);
        final entries = ledger.loanEntries(loan.id);

        return Scaffold(
          appBar: AppBar(
            title: Text(loanTitle(ledger, s)),
            actions: [
              IconButton(
                tooltip: 'Delete loan',
                icon: const Icon(Icons.delete_outline),
                onPressed: () async {
                  final ok = await confirm(
                    context,
                    title: 'Delete this loan?',
                    body: 'The loan and all its repayments are removed from every balance.',
                    action: 'Delete',
                    destructive: true,
                  );
                  if (!ok || !context.mounted) return;
                  await ref.read(repositoryProvider).deleteLoan(loan.id);
                  if (context.mounted) {
                    Navigator.pop(context);
                    showSnack(context, 'Loan deleted');
                  }
                },
              ),
            ],
          ),
          body: PageList(
            children: [
              LoanCard(ledger: ledger, status: s),
              SectionCard(
                children: [
                  AmountRow(loan.kind == LoanKind.lent ? 'Lent' : 'Borrowed', loan.principal),
                  if (loan.charge > 0)
                    AmountRow('Charge ${formatPercentBp(loan.chargeRateBp)}', loan.charge),
                  AmountRow('Total due', s.due, total: true),
                  if (loan.openingRepaid > 0)
                    AmountRow('Paid before using the app', loan.openingRepaid),
                  if (loan.note.isNotEmpty) Text(loan.note, style: TextStyle(color: colors.muted)),
                ],
              ),
              if (s.remaining > 0)
                FilledButton(
                  onPressed: () => showRepay(context, s),
                  child: Text(loan.kind == LoanKind.lent ? 'Record money received' : 'Pay back'),
                ),
              SectionCard(
                children: [
                  const Label('Timeline'),
                  for (final e in entries)
                    InkWell(
                      onTap: () => showEntryDetails(context, e),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: AmountRow(
                          entryTitle(ledger, e),
                          e.amount,
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
}
