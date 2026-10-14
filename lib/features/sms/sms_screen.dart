import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/money.dart';
import '../../core/period.dart';
import '../../data/sms_inbox.dart';
import '../../ledger/ledger.dart';
import '../../ledger/sms.dart';
import '../../ui/forms.dart';
import '../../ui/widgets.dart';
import '../quick_add/quick_add_sheet.dart';

/// Turns SMS suggestions on: asks Android for permission and starts from
/// the 1st of this month. False if permission was refused.
Future<bool> turnOnSms(WidgetRef ref) async {
  if (!await SmsInbox.requestPermission()) return false;
  final repo = ref.read(repositoryProvider);
  final ledger = ref.read(ledgerProvider).value;
  if (ledger?.settings[smsSinceSetting] == null) {
    await repo.setSetting(
      smsSinceSetting,
      Period.of(ref.read(todayProvider)).start.toIso8601String(),
    );
  }
  await repo.setSetting(smsOnSetting, 'true');
  ref.invalidate(smsInboxProvider);
  return true;
}

/// Bank and bKash messages waiting to become entries.
class SmsScreen extends ConsumerWidget {
  const SmsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suggestions = ref.watch(smsSuggestionsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bank messages'),
        actions: [
          if (suggestions.isNotEmpty)
            TextButton(
              onPressed: () async {
                if (!await confirm(
                  context,
                  title: 'Dismiss all ${suggestions.length}?',
                  body: 'They won\'t be suggested again. Nothing is added.',
                  action: 'Dismiss all',
                )) {
                  return;
                }
                await _markHandled(ref, suggestions.map((s) => s.money.key));
              },
              child: const Text('Dismiss all'),
            ),
        ],
      ),
      body: LedgerBuilder(
        builder: (context, ledger) {
          final status = StatusColors.of(context);
          final on = ledger.settings[smsOnSetting] == 'true';
          final loading = ref.watch(smsInboxProvider).isLoading;
          return PageList(
            children: [
              if (!on)
                SectionCard(
                  children: [
                    const Text(
                      'Suggest entries from bank and bKash messages',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      'The app reads messages from the senders below, on this phone only, and '
                      'offers each payment as an entry for you to check and save.',
                      style: TextStyle(color: status.muted),
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: FilledButton(
                        onPressed: () async {
                          if (!await turnOnSms(ref) && context.mounted) {
                            showSnack(context, 'Allow SMS access to use suggestions');
                          }
                        },
                        child: const Text('Turn on'),
                      ),
                    ),
                  ],
                )
              else if (suggestions.isEmpty)
                SectionCard(
                  children: [
                    Text(
                      loading
                          ? 'Reading messages…'
                          : 'Nothing new. Every message is added or dismissed.',
                      style: TextStyle(color: status.muted),
                    ),
                  ],
                ),
              for (final s in suggestions) _SuggestionCard(ledger: ledger, s: s),
              _Senders(ledger: ledger),
            ],
          );
        },
      ),
    );
  }
}

Future<void> _markHandled(WidgetRef ref, Iterable<String> keys) async {
  final ledger = ref.read(ledgerProvider).value;
  if (ledger == null) return;
  await ref
      .read(repositoryProvider)
      .setSetting(smsHandledSetting, encodeSmsHandled({...smsHandled(ledger), ...keys}));
}

class _SuggestionCard extends ConsumerWidget {
  const _SuggestionCard({required this.ledger, required this.s});

  final Ledger ledger;
  final SmsSuggestion s;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = StatusColors.of(context);
    final m = s.money;
    final (verb, icon, mode) = switch (m.kind) {
      SmsKind.expense => ('Paid', Icons.arrow_upward, QuickAddMode.expense),
      SmsKind.income => ('Received', Icons.arrow_downward, QuickAddMode.income),
      SmsKind.toCash => ('To cash', Icons.payments_outlined, QuickAddMode.move),
    };
    final account = ledger.accounts[s.accountId]?.name;
    final note = [?m.party, if (m.fee > 0) 'fee ${formatTaka(m.fee)}'].join(' · ');

    return SectionCard(
      children: [
        Row(
          spacing: 12,
          children: [
            CircleAvatar(
              backgroundColor: status.sunk,
              foregroundColor: status.muted,
              child: Icon(icon, size: 20),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    [verb, ?m.party].join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    [?account, DateFormat.MMMd().add_jm().format(m.message.date)].join(' · '),
                    style: TextStyle(color: status.muted, fontSize: 13),
                  ),
                ],
              ),
            ),
            Money(m.amount, style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
        Text(
          m.message.body,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: status.muted, fontSize: 12),
        ),
        if (s.maybeEntered)
          const Align(
            alignment: Alignment.centerLeft,
            child: StatusChip('Maybe already added', tone: ChipTone.warn),
          ),
        Row(
          spacing: 8,
          children: [
            Expanded(
              child: FilledButton.tonal(
                onPressed: () async {
                  final saved = await showQuickAdd(
                    context,
                    prefill: QuickAddPrefill(
                      mode: mode,
                      amount: m.amount,
                      date: DateTime(m.message.date.year, m.message.date.month, m.message.date.day),
                      accountId: s.accountId,
                      note: note,
                    ),
                  );
                  if (saved) await _markHandled(ref, [m.key]);
                },
                child: const Text('Add'),
              ),
            ),
            Expanded(
              child: OutlinedButton(
                onPressed: () => _markHandled(ref, [m.key]),
                child: const Text('Dismiss'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Senders extends ConsumerWidget {
  const _Senders({required this.ledger});

  final Ledger ledger;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final senders = smsSenders(ledger);
    final status = StatusColors.of(context);
    Future<void> save(List<SmsSender> list) =>
        ref.read(repositoryProvider).setSetting(smsSendersSetting, encodeSmsSenders(list));

    return SectionCard(
      children: [
        const Label('Senders'),
        Text(
          'Messages from these senders are read; each goes with an account.',
          style: TextStyle(color: status.muted, fontSize: 13),
        ),
        for (final (i, s) in senders.indexed)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(s.match),
            subtitle: Text(ledger.accounts[s.accountId]?.name ?? 'No account'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              final edited = await _editSender(context, ledger, s);
              if (edited == null) return;
              final list = [...senders];
              if (edited.match.isEmpty) {
                list.removeAt(i);
              } else {
                list[i] = edited;
              }
              await save(list);
            },
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () async {
              final added = await _editSender(context, ledger, null);
              if (added != null && added.match.isNotEmpty) await save([...senders, added]);
            },
            icon: const Icon(Icons.add),
            label: const Text('Add a sender'),
          ),
        ),
      ],
    );
  }

  /// An empty match means "remove".
  Future<SmsSender?> _editSender(BuildContext context, Ledger ledger, SmsSender? s) async {
    final match = TextEditingController(text: s?.match);
    var account = s?.accountId;
    final accounts = ledger.accountsOfType((t) => t.isLiquid).where((a) => !a.archived).toList();
    final ok = await showModalBottomSheet<bool>(
      useRootNavigator: true,
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => SheetBody(
          title: s == null ? 'New sender' : 'Edit sender',
          children: [
            TextField(
              controller: match,
              autofocus: s == null,
              decoration: const InputDecoration(
                labelText: 'Sender name or number',
                hintText: 'e.g. bKash, CityBank, 16216',
                border: OutlineInputBorder(),
              ),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final a in accounts)
                  ChoiceChip(
                    label: Text(a.name),
                    selected: account == a.id,
                    onSelected: (_) => setState(() => account = a.id),
                  ),
              ],
            ),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save')),
            if (s != null)
              OutlinedButton(
                style: OutlinedButton.styleFrom(foregroundColor: StatusColors.of(context).bad),
                onPressed: () {
                  match.clear();
                  Navigator.pop(context, true);
                },
                child: const Text('Remove this sender'),
              ),
          ],
        ),
      ),
    );
    if (ok != true) return null;
    return SmsSender(match.text.trim(), account);
  }
}
