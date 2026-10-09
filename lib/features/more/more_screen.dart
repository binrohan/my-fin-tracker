import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../data/default_data.dart';
import '../../data/sample_data.dart';
import '../../ledger/allocation.dart';
import '../../ledger/ledger.dart';
import '../../ui/forms.dart';
import '../../ui/widgets.dart';
import '../../core/money.dart';
import '../buying/buying_screen.dart';
import '../cash/cash_screen.dart';
import '../investments/investments_screen.dart';
import '../trackers/trackers_screen.dart';
import '../entries/entries_screen.dart';
import '../loans/loans_screen.dart';
import '../home/month_tasks.dart';
import '../setup/accounts_screen.dart';
import '../setup/allocation_screen.dart';
import '../setup/budgets_screen.dart';
import '../setup/categories_screen.dart';
import '../setup/starting_balances_screen.dart';
import 'backup_screen.dart';

const borrowChargeSetting = 'borrow_charge_bp';

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LedgerBuilder(
      builder: (context, ledger) {
        final status = StatusColors.of(context);
        final last = DateTime.tryParse(ledger.settings[lastBackupSetting] ?? '');
        final days = last == null ? null : DateTime.now().difference(last).inDays;
        final chargeBp =
            int.tryParse(ledger.setting(borrowChargeSetting, '$defaultBorrowChargeBp')) ??
            defaultBorrowChargeBp;
        final plan = AllocationPlan.parse(ledger.settings[AllocationPlan.settingKey]);

        Widget item(IconData icon, String title, String? subtitle, VoidCallback onTap) => ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(icon),
          title: Text(title),
          subtitle: subtitle == null ? null : Text(subtitle),
          trailing: const Icon(Icons.chevron_right),
          onTap: onTap,
        );

        return PageList(
          children: [
            const ScreenHeader('More', subtitle: 'Your data lives on this phone'),
            SectionCard(
              color: days == null || days > 7 ? status.warnSoft : null,
              onTap: () => openScreen(context, const BackupScreen()),
              children: [
                Row(
                  children: [
                    const Icon(Icons.backup_outlined),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Backup & restore',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    if (days == null)
                      const StatusChip('No backup yet', tone: ChipTone.bad)
                    else
                      StatusChip(
                        days == 0 ? 'Today' : '$days days ago',
                        tone: days <= 7 ? ChipTone.good : ChipTone.warn,
                      ),
                  ],
                ),
              ],
            ),
            SectionCard(
              children: [
                const Label('Set up'),
                item(
                  Icons.account_balance_wallet_outlined,
                  'Starting balances',
                  'What you have on the day you begin',
                  () => openScreen(context, const StartingBalancesScreen()),
                ),
                item(
                  Icons.account_balance_outlined,
                  'Accounts & pots',
                  'Bank, cash, wallets, savings, goals',
                  () => openScreen(context, const AccountsScreen()),
                ),
                item(
                  Icons.category_outlined,
                  'Categories',
                  'Expense and income categories, fixed bills',
                  () => openScreen(context, const CategoriesScreen()),
                ),
                item(
                  Icons.pie_chart_outline,
                  'Budgets',
                  'Monthly amount per category',
                  () => openScreen(context, const BudgetsScreen()),
                ),
                item(
                  Icons.call_split,
                  'Salary plan',
                  plan.isEmpty ? 'Not set' : '${formatTaka(plan.total)} set aside each salary',
                  () => openScreen(context, const AllocationScreen()),
                ),
                item(
                  Icons.handshake_outlined,
                  'Loans',
                  'From your savings and with people',
                  () => openScreen(context, const LoansScreen()),
                ),
                item(
                  Icons.trending_up,
                  'Investments',
                  'DPS, FDR, savings certificates, shares',
                  () => openScreen(context, const InvestmentsScreen()),
                ),
                item(
                  Icons.shopping_bag_outlined,
                  'Buying',
                  'Major purchases and warranties',
                  () => openScreen(context, const BuyingScreen()),
                ),
                item(
                  Icons.flag_outlined,
                  'Trackers',
                  'Projects and countdown budgets',
                  () => openScreen(context, const TrackersScreen()),
                ),
                item(
                  Icons.payments_outlined,
                  'Cash drawer',
                  'Cash by sector, count notes',
                  () => openScreen(context, const CashScreen()),
                ),
                item(
                  Icons.list_alt,
                  'All entries',
                  'See, edit or delete anything you entered',
                  () => openScreen(context, const EntriesScreen()),
                ),
              ],
            ),
            SectionCard(
              children: [
                const Label('Rules'),
                item(
                  Icons.percent,
                  'Charge when borrowing from savings',
                  '${formatPercentBp(chargeBp)} of the amount',
                  () => _editCharge(context, ref, chargeBp),
                ),
                item(
                  Icons.event_repeat,
                  'Leftover at month end',
                  ledger.setting(leftoverSetting, leftoverCarry) == leftoverToSavings
                      ? 'Move to savings'
                      : 'Carry forward to next month',
                  () => _editLeftover(context, ref, ledger),
                ),
              ],
            ),
            SectionCard(
              children: [
                const Label('Example data'),
                Text(
                  'Loads September and early October 2026 from the plan, so you can see every '
                  'screen with numbers. This replaces everything in the app.',
                  style: TextStyle(color: status.muted),
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.tonal(
                      onPressed: () async {
                        if (!await confirm(
                          context,
                          title: 'Load example data?',
                          body: 'All entries in the app will be replaced by the example months.',
                          action: 'Load',
                        )) {
                          return;
                        }
                        await loadSampleData(ref.read(databaseProvider));
                        if (context.mounted) showSnack(context, 'Example data loaded');
                      },
                      child: const Text('Load example'),
                    ),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(foregroundColor: status.bad),
                      onPressed: () async {
                        if (!await confirm(
                          context,
                          title: 'Delete all data?',
                          body:
                              'Every entry, loan and budget will be deleted. This can\'t be undone. '
                              'Make a backup first if you might need it.',
                          action: 'Delete all',
                          destructive: true,
                        )) {
                          return;
                        }
                        await ref.read(databaseProvider).resetAllData();
                        if (context.mounted) showSnack(context, 'All data deleted');
                      },
                      child: const Text('Delete all data'),
                    ),
                  ],
                ),
              ],
            ),
            Center(
              child: Text(
                'My Fin Tracker · Phase 4',
                style: TextStyle(color: status.muted, fontSize: 12),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _editCharge(BuildContext context, WidgetRef ref, int currentBp) async {
    final field = TextEditingController(text: formatPercentBp(currentBp).replaceAll('%', ''));
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Charge when borrowing'),
        content: TextField(
          controller: field,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
          decoration: const InputDecoration(
            suffixText: '%',
            helperText: 'Used for new loans from savings',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, field.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    final percent = double.tryParse(value ?? '');
    if (percent == null || percent < 0 || percent > 100) return;
    await ref
        .read(repositoryProvider)
        .setSetting(borrowChargeSetting, '${(percent * 100).round()}');
  }

  Future<void> _editLeftover(BuildContext context, WidgetRef ref, Ledger ledger) async {
    final value = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Leftover at month end'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, leftoverCarry),
            child: const Text('Carry forward to next month'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, leftoverToSavings),
            child: const Text('Move to savings'),
          ),
        ],
      ),
    );
    if (value != null) await ref.read(repositoryProvider).setSetting(leftoverSetting, value);
  }
}
