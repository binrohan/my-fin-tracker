import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/appearance.dart';
import '../../app/integrations.dart';
import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../data/default_data.dart';
import '../../data/ledger_repository.dart';
import '../../data/sample_data.dart';
import '../../ledger/insights.dart';
import '../../ledger/sms.dart';
import '../../ledger/ledger.dart';
import '../../ui/forms.dart';
import '../../ui/widgets.dart';
import '../../core/money.dart';
import '../../core/period.dart';
import '../buying/buying_screen.dart';
import '../cash/cash_screen.dart';
import '../investments/investments_screen.dart';
import '../trackers/trackers_screen.dart';
import '../entries/entries_screen.dart';
import '../loans/loans_screen.dart';
import '../reports/reports_screen.dart';
import '../home/home_screen.dart';
import '../home/month_tasks.dart';
import '../plan/monthly_plan_screen.dart';
import '../setup/accounts_screen.dart';
import '../setup/categories_screen.dart';
import '../setup/starting_balances_screen.dart';
import '../sms/sms_screen.dart';
import '../tools/afford_screen.dart';
import '../tools/tax_screen.dart';
import '../tools/zakat_screen.dart';
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
        final plan = ledger.planFor(Period.of(ref.watch(todayProvider)));

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
              onTap: () => openScreen(context, const ReportsScreen()),
              children: [
                Row(
                  children: [
                    const Icon(Icons.picture_as_pdf_outlined),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Reports & export',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    Text('PDF · CSV', style: TextStyle(color: status.muted)),
                    const Icon(Icons.chevron_right),
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
                  'Monthly plan',
                  plan.plannedIncome == 0
                      ? 'Income, how it is split, expense budget'
                      : '${formatTaka(plan.plannedIncome)} income · ${formatTaka(plan.total)} set aside',
                  () => openScreen(context, const MonthlyPlanScreen()),
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
                const Label('Tools'),
                item(
                  Icons.shopping_cart_checkout,
                  'Can I afford it?',
                  'Check a price against this month and your savings',
                  () => openScreen(context, const AffordScreen()),
                ),
                item(
                  Icons.volunteer_activism_outlined,
                  'Zakat',
                  'On your savings, investments, gold and silver',
                  () => openScreen(context, const ZakatScreen()),
                ),
                item(
                  Icons.account_balance_outlined,
                  'Income tax',
                  'Estimate for the July–June income year',
                  () => openScreen(context, const TaxScreen()),
                ),
              ],
            ),
            SectionCard(
              children: [
                const Label('Rules'),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: const Icon(Icons.fingerprint),
                  title: const Text('App lock'),
                  subtitle: const Text('Fingerprint or phone PIN to open the app'),
                  value: ledger.settings[appLockSetting] == 'true',
                  onChanged: (on) async {
                    final repo = ref.read(repositoryProvider);
                    if (!on) {
                      await repo.setSetting(appLockSetting, 'false');
                      return;
                    }
                    if (await confirmAppLockAvailable()) {
                      await repo.setSetting(appLockSetting, 'true');
                    } else if (context.mounted) {
                      showSnack(
                        context,
                        'Set up a fingerprint or screen lock in your phone Settings first',
                      );
                    }
                  },
                ),
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
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: const Icon(Icons.sms_outlined),
                  title: const Text('Suggest entries from SMS'),
                  subtitle: const Text('Bank and bKash messages, read on this phone only'),
                  value: ledger.settings[smsOnSetting] == 'true',
                  onChanged: (on) async {
                    if (!on) {
                      await ref.read(repositoryProvider).setSetting(smsOnSetting, 'false');
                      return;
                    }
                    if (!await turnOnSms(ref) && context.mounted) {
                      showSnack(context, 'Allow SMS access to use suggestions');
                    }
                  },
                ),
                if (ledger.settings[smsOnSetting] == 'true')
                  item(
                    Icons.mark_chat_read_outlined,
                    'Bank messages',
                    'Review messages and choose senders',
                    () => openScreen(context, const SmsScreen()),
                  ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: const Icon(Icons.insights_outlined),
                  title: const Text('Compare with last month'),
                  subtitle: const Text('On the Expenses tab and in the monthly report'),
                  value: ledger.settings[insightsOffSetting] != 'true',
                  onChanged: (on) =>
                      ref.read(repositoryProvider).setSetting(insightsOffSetting, '${!on}'),
                ),
              ],
            ),
            const _AppearanceCard(),
            const _AboutCard(),
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
                'My Fin Tracker ${ref.watch(packageInfoProvider).value?.version ?? ''}',
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

/// Light / dark / system, colour scheme, and pitch black for OLED.
class _AppearanceCard extends ConsumerWidget {
  const _AppearanceCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final look = ref.watch(appearanceProvider);
    // Read when tapped, so drawing the card doesn't open the database.
    LedgerRepository repo() => ref.read(repositoryProvider);
    final status = StatusColors.of(context);
    final darkNow = Theme.of(context).brightness == Brightness.dark;
    final homeStyle = ref.watch(ledgerProvider).value?.settings[homeStyleSetting] == homeAfterBills
        ? homeAfterBills
        : homeStandard;

    return SectionCard(
      children: [
        const Label('Appearance'),
        SegmentedButton<ThemeMode>(
          segments: const [
            ButtonSegment(
              value: ThemeMode.system,
              icon: Icon(Icons.brightness_auto_outlined),
              label: Text('System'),
            ),
            ButtonSegment(
              value: ThemeMode.light,
              icon: Icon(Icons.light_mode_outlined),
              label: Text('Light'),
            ),
            ButtonSegment(
              value: ThemeMode.dark,
              icon: Icon(Icons.dark_mode_outlined),
              label: Text('Dark'),
            ),
          ],
          selected: {look.mode},
          showSelectedIcon: false,
          onSelectionChanged: (s) => repo().setSetting(Appearance.modeKey, s.single.name),
        ),
        const SizedBox(height: 4),
        Text('Home page', style: TextStyle(color: status.muted)),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: homeStandard, label: Text('Standard')),
            ButtonSegment(value: homeAfterBills, label: Text('After bills')),
          ],
          selected: {homeStyle},
          showSelectedIcon: false,
          onSelectionChanged: (s) => repo().setSetting(homeStyleSetting, s.single),
        ),
        Text(
          homeStyle == homeAfterBills
              ? 'Shows what is free once the fixed bills still to pay are taken off, '
                    'with the sum and a Bills to pay list.'
              : 'Shows everything left to spend this month, bills included.',
          style: TextStyle(color: status.muted, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text('Colour', style: TextStyle(color: status.muted)),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final p in AppPalette.values)
              ChoiceChip(
                avatar: _Swatch(
                  color: buildTheme(Theme.of(context).brightness, palette: p).colorScheme.primary,
                ),
                label: Text(p.label),
                selected: look.palette == p,
                onSelected: (_) => repo().setSetting(Appearance.paletteKey, p.name),
              ),
          ],
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Pitch black'),
          subtitle: Text(
            look.mode == ThemeMode.light
                ? 'Used in dark mode. Black background saves battery on OLED screens.'
                : 'Black background in dark mode; saves battery on OLED screens.',
          ),
          value: look.pureBlack,
          onChanged: (v) => repo().setSetting(Appearance.pureBlackKey, '$v'),
        ),
        if (look.pureBlack && !darkNow && look.mode != ThemeMode.light)
          Text(
            'Your phone is in light mode now; pitch black shows when it switches to dark.',
            style: TextStyle(color: status.muted, fontSize: 12),
          ),
      ],
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: 16,
    height: 16,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}

class _AboutCard extends ConsumerWidget {
  const _AboutCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final info = ref.watch(packageInfoProvider).value;
    final status = StatusColors.of(context);
    final version = info == null ? '' : '${info.version} (build ${info.buildNumber})';
    return SectionCard(
      children: [
        const Label('About'),
        const Text('My Fin Tracker', style: TextStyle(fontWeight: FontWeight.w700)),
        Text('Version $version', style: TextStyle(color: status.muted)),
        Text(
          'Personal finance for your phone: spending, savings, loans and reports in one place. '
          'Works offline. Your data stays on this phone unless you share a backup.',
          style: TextStyle(color: status.muted),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            style: TextButton.styleFrom(padding: EdgeInsets.zero),
            onPressed: () => showLicensePage(
              context: context,
              applicationName: 'My Fin Tracker',
              applicationVersion: version,
            ),
            child: const Text('Open-source licences'),
          ),
        ),
      ],
    );
  }
}
