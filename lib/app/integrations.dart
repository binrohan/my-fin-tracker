import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';
import 'package:local_auth/local_auth.dart';
import 'package:quick_actions/quick_actions.dart';

import '../core/money.dart';
import '../core/period.dart';
import '../data/auto_backup.dart';
import '../data/ledger_repository.dart';
import '../features/quick_add/quick_add_sheet.dart';
import '../ledger/free_to_spend.dart';
import '../ledger/ledger.dart';
import '../ledger/sms.dart';
import 'providers.dart';
import 'router.dart';
import 'theme.dart';

const appLockSetting = 'app_lock';

/// Lock again after this long in the background.
const _relockAfter = Duration(minutes: 1);

const _widgetClass = 'com.myfin.my_fin_tracker.QuickAddWidget';
const _freeWidgetClass = 'com.myfin.my_fin_tracker.FreeToSpendWidget';
const _glanceWidgetClass = 'com.myfin.my_fin_tracker.MonthGlanceWidget';

/// Everything that connects the app to the phone: the fingerprint lock,
/// the app-icon shortcut, the home-screen widget and the weekly backup.
class AppIntegrations extends ConsumerStatefulWidget {
  const AppIntegrations({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AppIntegrations> createState() => _AppIntegrationsState();
}

class _AppIntegrationsState extends ConsumerState<AppIntegrations> with WidgetsBindingObserver {
  final _auth = LocalAuthentication();
  bool _locked = true;
  bool _checkedLock = false;
  bool _authenticating = false;
  DateTime? _pausedAt;

  /// Quick add asked for by a shortcut or the widget, opened once unlocked.
  bool _pendingQuickAdd = false;
  QuickAddMode? _pendingMode;
  StreamSubscription<Uri?>? _widgetTaps;
  bool _backupChecked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    const QuickActions()
      ..initialize((type) {
        if (type == 'add_expense') _requestQuickAdd();
      })
      ..setShortcutItems(const [
        ShortcutItem(
          type: 'add_expense',
          localizedTitle: 'Add expense',
          icon: 'ic_shortcut_add_dark',
        ),
      ]);

    HomeWidget.initiallyLaunchedFromHomeWidget().then(_onWidgetUri).catchError((_) {});
    _widgetTaps = HomeWidget.widgetClicked.listen(_onWidgetUri, onError: (_) {});
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _widgetTaps?.cancel();
    super.dispose();
  }

  void _onWidgetUri(Uri? uri) {
    if (uri?.host != 'quickadd') return;
    _requestQuickAdd(mode: uri?.queryParameters['mode'] == 'income' ? QuickAddMode.income : null);
  }

  void _requestQuickAdd({QuickAddMode? mode}) {
    _pendingQuickAdd = true;
    _pendingMode = mode;
    _openPending();
  }

  void _openPending() {
    if (!_pendingQuickAdd || _locked) return;
    final context = rootNavigatorKey.currentContext;
    if (context == null) {
      // The router is not built yet; try again after this frame.
      WidgetsBinding.instance.addPostFrameCallback((_) => _openPending());
      return;
    }
    _pendingQuickAdd = false;
    showQuickAdd(context, mode: _pendingMode);
    _pendingMode = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _pausedAt = DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      final ledger = ref.read(ledgerProvider).value;
      if (ledger != null) _releaseIfDue(ledger);
      // New bank or bKash messages may have arrived.
      if (ledger?.settings[smsOnSetting] == 'true') ref.invalidate(smsInboxProvider);
      final away = _pausedAt == null ? Duration.zero : DateTime.now().difference(_pausedAt!);
      _pausedAt = null;
      final lockOn = ref.read(ledgerProvider).value?.settings[appLockSetting] == 'true';
      if (lockOn && away >= _relockAfter && !_authenticating) {
        setState(() => _locked = true);
        _unlock();
      }
    }
  }

  Future<void> _unlock() async {
    if (_authenticating) return;
    _authenticating = true;
    try {
      final ok = await _auth.authenticate(
        localizedReason: 'Unlock My Fin Tracker',
        persistAcrossBackgrounding: true,
      );
      if (ok && mounted) {
        setState(() => _locked = false);
        _openPending();
      }
    } catch (_) {
      // No fingerprint or PIN set up, or the prompt was cancelled: stay on
      // the lock screen, which offers to try again.
    } finally {
      _authenticating = false;
    }
  }

  void _onLedger(Ledger ledger) {
    final lockOn = ledger.settings[appLockSetting] == 'true';
    if (!_checkedLock) {
      _checkedLock = true;
      if (lockOn) {
        _unlock();
      } else {
        setState(() => _locked = false);
        _openPending();
      }
    } else if (!lockOn && _locked) {
      setState(() => _locked = false);
      _openPending();
    }
    _updateWidget(ledger, hideAmount: lockOn);
    _releaseIfDue(ledger);
    if (!_backupChecked) {
      _backupChecked = true;
      _autoBackup(ledger);
    }
  }

  bool _releasing = false;

  /// On or after the 1st, income held for this month is released into
  /// Spending (and the plan's split runs). Safe to call often: the
  /// repository checks again inside its transaction.
  Future<void> _releaseIfDue(Ledger ledger) async {
    final now = DateTime.now();
    // A salary parked whole by an older version, not split yet.
    final catchUp = [Period.of(now), Period.of(now).previous].any(
      (m) =>
          ledger.settings[LedgerRepository.splitOnReleaseKey(m.next)] !=
              LedgerRepository.splitDone &&
          ledger.heldIncomes(m).any((e) => e.categoryId == ledger.latestPlan.categoryId),
    );
    if (_releasing || (ledger.releaseDue(now).isEmpty && !catchUp)) return;
    _releasing = true;
    try {
      // A salary held whole under the old rules: split it now, keep only
      // its spending part parked.
      if (catchUp) {
        final split = await ref.read(repositoryProvider).splitHeldSalary(now);
        final context = rootNavigatorKey.currentContext;
        if (split != null && context != null && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              duration: const Duration(seconds: 8),
              content: Text(
                'Salary split as planned: ${formatTaka(split.setAside)} to your pots'
                '${split.unplanned > 0 ? ', ${formatTaka(split.unplanned)} to Unplanned' : ''}',
              ),
            ),
          );
        }
      }
      if (ledger.releaseDue(now).isEmpty) return;
      final result = await ref.read(repositoryProvider).releaseHeldIncome(now);
      final context = rootNavigatorKey.currentContext;
      if (result.released > 0 && context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            duration: const Duration(seconds: 8),
            content: Text(
              '${Period.of(now).label}: ${formatTaka(result.released)} income released'
              '${result.setAside > 0 ? ', ${formatTaka(result.setAside)} set aside as planned' : ''}',
            ),
          ),
        );
      }
    } catch (_) {
      // Tried again on the next change or app start.
    } finally {
      _releasing = false;
    }
  }

  Future<void> _autoBackup(Ledger ledger) async {
    try {
      await AutoBackup(
        ref.read(databaseProvider),
        receipts: await ref.read(receiptStoreProvider.future),
      ).runIfDue(ledger, folder: await AutoBackup.defaultFolder());
    } catch (_) {
      // A failed automatic backup must never stop the app; the backup
      // reminder on Home stays until one succeeds.
    }
  }

  Future<void> _updateWidget(Ledger ledger, {required bool hideAmount}) async {
    try {
      final today = ref.read(todayProvider);
      final s = ledger.summary(Period.of(today));
      final perDay = s.perDay(today);
      await HomeWidget.saveWidgetData<String>('title', 'Left to spend · ${s.period.shortLabel}');
      await HomeWidget.saveWidgetData<String>(
        'amount',
        hideAmount ? 'Locked' : formatTaka(s.leftToSpend),
      );
      await HomeWidget.saveWidgetData<String>(
        'detail',
        hideAmount || perDay == null || perDay <= 0
            ? 'Tap + to add an expense'
            : '≈ ${formatTaka(perDay)} a day',
      );
      await HomeWidget.updateWidget(qualifiedAndroidName: _widgetClass);
      await _updateFreeWidgets(ledger, today, hideAmount: hideAmount);
    } catch (_) {
      // No widget support (tests, desktop): nothing to update.
    }
  }

  /// The Free to spend widget (3×1) and Month at a glance (4×2).
  Future<void> _updateFreeWidgets(Ledger ledger, DateTime today, {required bool hideAmount}) async {
    final f = FreeToSpend.of(ledger, today);
    final p = f.summary.period;
    final free = hideAmount
        ? 'Locked'
        : f.free >= 0
        ? formatTaka(f.free)
        : 'Short ${formatTaka(-f.free)}';
    final perDay = f.perDay == null ? null : '≈ ${formatTaka(f.perDay!)} a day';
    final bills = f.bills + f.slots;

    await HomeWidget.saveWidgetData<String>('free_title', 'Free to spend · ${p.shortLabel}');
    await HomeWidget.saveWidgetData<String>('free_amount', free);
    await HomeWidget.saveWidgetData<String>(
      'free_detail',
      hideAmount
          ? 'Open the app to see it'
          : [
              ?perDay,
              if (bills > 0) 'after ${formatTaka(bills)} bills' else 'no bills left',
            ].join(' · '),
    );
    await HomeWidget.updateWidget(qualifiedAndroidName: _freeWidgetClass);

    final next = f.next;
    await HomeWidget.saveWidgetData<String>(
      'g_month',
      '${p.label.split(' ').first} · day ${today.day} of ${p.daysInMonth}',
    );
    await HomeWidget.saveWidgetData<String>('g_amount', free);
    await HomeWidget.saveWidgetData<String>(
      'g_perday',
      hideAmount ? 'Free to spend' : 'Free to spend${perDay == null ? '' : ' · $perDay'}',
    );
    await HomeWidget.saveWidgetData<String>(
      'g_spent',
      hideAmount || f.summary.budget <= 0
          ? 'Budget'
          : 'Spent ${formatTaka(f.summary.expenses)} of ${formatTaka(f.summary.budget)}',
    );
    await HomeWidget.saveWidgetData<int>(
      'g_progress',
      hideAmount ? 0 : (f.spentShare * 100).round(),
    );
    await HomeWidget.saveWidgetData<String>(
      'g_next',
      hideAmount
          ? ''
          : next == null
          ? 'No bills left this month'
          : 'Next: ${next.name} · ${next.date.day} ${DateFormat.MMM().format(next.date)} · '
                '${formatTaka(next.amount)}',
    );
    await HomeWidget.updateWidget(qualifiedAndroidName: _glanceWidgetClass);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(ledgerProvider, (_, next) {
      final ledger = next.value;
      if (ledger != null) _onLedger(ledger);
    });
    final ledger = ref.watch(ledgerProvider).value;
    if (ledger != null && !_checkedLock) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_checkedLock) _onLedger(ledger);
      });
    }
    return Stack(
      children: [
        widget.child,
        if (_locked) _LockScreen(onUnlock: _unlock, ready: _checkedLock),
      ],
    );
  }
}

class _LockScreen extends StatelessWidget {
  const _LockScreen({required this.onUnlock, required this.ready});

  final VoidCallback onUnlock;

  /// False while the app is still reading whether the lock is on.
  final bool ready;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Positioned.fill(
      child: Material(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: SafeArea(
          child: Center(
            child: !ready
                ? const SizedBox.shrink()
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    spacing: 16,
                    children: [
                      Icon(Icons.lock_outline, size: 56, color: scheme.primary),
                      Text('My Fin Tracker', style: Theme.of(context).textTheme.titleLarge),
                      Text('Locked', style: TextStyle(color: StatusColors.of(context).muted)),
                      FilledButton.icon(
                        onPressed: onUnlock,
                        icon: const Icon(Icons.fingerprint),
                        label: const Text('Unlock'),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

/// Checks that the phone can lock the app, by asking once now.
Future<bool> confirmAppLockAvailable() async {
  final auth = LocalAuthentication();
  try {
    if (!await auth.isDeviceSupported()) return false;
    return await auth.authenticate(localizedReason: 'Turn on the app lock');
  } catch (_) {
    return false;
  }
}
