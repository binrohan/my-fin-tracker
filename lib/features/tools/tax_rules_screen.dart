import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/money.dart';
import '../../ledger/tax.dart';
import '../../ui/forms.dart';
import '../../ui/widgets.dart';
import 'tool_fields.dart';

/// Edit the thresholds, slabs and limits when a new Finance Act changes
/// them.
class TaxRulesScreen extends ConsumerStatefulWidget {
  const TaxRulesScreen({super.key});

  @override
  ConsumerState<TaxRulesScreen> createState() => _TaxRulesScreenState();
}

class _TaxRulesScreenState extends ConsumerState<TaxRulesScreen> {
  TaxRules? _rules;

  /// Bumped when fields must start again (a slab removed, defaults back).
  int _generation = 0;

  int _bp(double percent) => (percent * 100).round();
  double _percent(int bp) => bp / 100;

  @override
  Widget build(BuildContext context) {
    final ledger = ref.watch(ledgerProvider).value;
    final status = StatusColors.of(context);
    final rules = _rules ??= ledger == null
        ? TaxRules.defaults
        : TaxRules.parse(ledger.settings[TaxRules.settingKey]);
    void set(TaxRules r) => setState(() => _rules = r);

    return Scaffold(
      appBar: AppBar(title: const Text('Rates and slabs')),
      body: KeyedSubtree(
        key: ValueKey(_generation),
        child: PageList(
          children: [
            Text(
              'Defaults are the Finance Act 2026 figures as reported. Change them when the '
              'law changes.',
              style: TextStyle(color: status.muted),
            ),
            SectionCard(
              children: [
                const Label('Tax free up to'),
                for (final k in TaxpayerKind.values)
                  OverridableAmount(
                    label: k.label,
                    value: rules.thresholds[k],
                    onChanged: (v) =>
                        set(rules.copyWith(thresholds: {...rules.thresholds, k: v ?? 0})),
                  ),
              ],
            ),
            SectionCard(
              children: [
                const Label('Slabs above that'),
                for (final (i, slab) in rules.slabs.indexed)
                  Row(
                    spacing: 8,
                    children: [
                      Expanded(
                        flex: 3,
                        child: slab.width == null
                            ? const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 12),
                                child: Text('The rest'),
                              )
                            : OverridableAmount(
                                label: 'Next',
                                value: slab.width,
                                onChanged: (v) => set(
                                  rules.copyWith(
                                    slabs: [...rules.slabs]..[i] = TaxSlab(v ?? 0, slab.rateBp),
                                  ),
                                ),
                              ),
                      ),
                      Expanded(
                        flex: 2,
                        child: NumberField(
                          label: 'Rate',
                          suffix: '%',
                          value: _percent(slab.rateBp),
                          onChanged: (v) => set(
                            rules.copyWith(
                              slabs: [...rules.slabs]..[i] = TaxSlab(slab.width, _bp(v)),
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Remove this slab',
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: slab.width == null
                            ? null
                            : () => setState(() {
                                _rules = rules.copyWith(slabs: [...rules.slabs]..removeAt(i));
                                _generation++;
                              }),
                      ),
                    ],
                  ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => set(
                      rules.copyWith(
                        slabs: [...rules.slabs]
                          ..insert(rules.slabs.length - 1, TaxSlab(taka(100000), 0)),
                      ),
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text('Add a slab'),
                  ),
                ),
              ],
            ),
            SectionCard(
              children: [
                const Label('Salary exemption'),
                NumberField(
                  label: 'Tax free: one part in',
                  value: rules.salaryExemptDivisor.toDouble(),
                  onChanged: (v) => set(rules.copyWith(salaryExemptDivisor: v.round())),
                ),
                OverridableAmount(
                  label: 'At most',
                  value: rules.salaryExemptCap,
                  onChanged: (v) => set(rules.copyWith(salaryExemptCap: v ?? 0)),
                ),
              ],
            ),
            SectionCard(
              children: [
                const Label('Investment rebate'),
                NumberField(
                  label: 'Rebate on investment',
                  suffix: '%',
                  value: _percent(rules.rebateBp),
                  onChanged: (v) => set(rules.copyWith(rebateBp: _bp(v))),
                ),
                NumberField(
                  label: 'At most, of taxable income',
                  suffix: '%',
                  value: _percent(rules.rebateIncomeCapBp),
                  onChanged: (v) => set(rules.copyWith(rebateIncomeCapBp: _bp(v))),
                ),
                OverridableAmount(
                  label: 'And at most',
                  value: rules.rebateCap,
                  onChanged: (v) => set(rules.copyWith(rebateCap: v ?? 0)),
                ),
              ],
            ),
            SectionCard(
              children: [
                const Label('Minimum tax'),
                OverridableAmount(
                  label: 'Over the tax-free limit, at least',
                  value: rules.minimumTax,
                  onChanged: (v) => set(rules.copyWith(minimumTax: v ?? 0)),
                ),
              ],
            ),
            FilledButton(
              onPressed: () async {
                await ref
                    .read(repositoryProvider)
                    .setSetting(TaxRules.settingKey, rules.copyWith(label: 'your rates').encode());
                if (context.mounted) {
                  Navigator.pop(context);
                  showSnack(context, 'Tax rates saved');
                }
              },
              child: const Text('Save'),
            ),
            OutlinedButton(
              onPressed: () async {
                if (!await confirm(
                  context,
                  title: 'Back to the default rates?',
                  body: 'Your changes to rates and slabs will be replaced.',
                  action: 'Reset',
                )) {
                  return;
                }
                await ref
                    .read(repositoryProvider)
                    .setSetting(TaxRules.settingKey, TaxRules.defaults.encode());
                setState(() {
                  _rules = TaxRules.defaults;
                  _generation++;
                });
              },
              child: const Text('Use the default rates'),
            ),
          ],
        ),
      ),
    );
  }
}
