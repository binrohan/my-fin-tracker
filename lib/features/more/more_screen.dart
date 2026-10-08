import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../data/sample_data.dart';
import '../../ledger/enums.dart';
import '../../ui/widgets.dart';

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  Future<bool> _confirm(BuildContext context, String title, String body, String action) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(body),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(action)),
          ],
        ),
      ) ??
      false;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(databaseProvider);
    return LedgerBuilder(builder: (context, ledger) {
      String typeLabel(AccountType t) => switch (t) {
            AccountType.bank => 'Bank',
            AccountType.cash => 'Cash',
            AccountType.wallet => 'Mobile wallet',
            AccountType.investment => 'Investment',
            AccountType.person => 'Person',
          };

      return PageList(children: [
        const ScreenHeader('More', subtitle: 'Your data lives on this phone'),
        SectionCard(children: [
          const Label('Accounts'),
          for (final a in ledger.accounts.values.where((a) => !a.archived))
            AmountRow(a.name, ledger.accountBalance(a.id), detail: typeLabel(a.type)),
        ]),
        SectionCard(children: [
          const Label('Example data'),
          Text(
            'Loads September and early October 2026 from the plan, so you can see every '
            'screen with numbers. This replaces everything in the app.',
            style: TextStyle(color: StatusColors.of(context).muted),
          ),
          Wrap(spacing: 8, runSpacing: 8, children: [
            FilledButton(
              onPressed: () async {
                if (!await _confirm(context, 'Load example data?',
                    'All entries in the app will be replaced by the example months.', 'Load')) {
                  return;
                }
                await loadSampleData(db);
                if (context.mounted) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(const SnackBar(content: Text('Example data loaded')));
                }
              },
              child: const Text('Load example'),
            ),
            OutlinedButton(
              onPressed: () async {
                if (!await _confirm(context, 'Delete all data?',
                    'Every entry, loan and budget will be deleted. This can\'t be undone.',
                    'Delete all')) {
                  return;
                }
                await db.resetAllData();
                if (context.mounted) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(const SnackBar(content: Text('All data deleted')));
                }
              },
              child: const Text('Delete all data'),
            ),
          ]),
        ]),
        SectionCard(children: [
          const Label('Coming next'),
          for (final line in [
            'Quick add, budgets, month close and backup',
            'Savings, goals, loans and the cash drawer',
            'Investments, purchases and trackers',
            'Monthly PDF report',
          ])
            Text('•  $line'),
        ]),
        Center(
          child: Text('My Fin Tracker · Phase 1',
              style: TextStyle(color: StatusColors.of(context).muted, fontSize: 12)),
        ),
      ]);
    });
  }
}
