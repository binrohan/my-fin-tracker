import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/money.dart';
import '../../ui/forms.dart';

/// An amount the app can fill in from your entries ([fromApp]); typing
/// one replaces it ([value]) until you tap reset.
class OverridableAmount extends StatefulWidget {
  const OverridableAmount({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.fromApp,
    this.helper,
  });

  final String label;
  final Poisha? fromApp;
  final Poisha? value;

  /// Null when the app's figure is used again.
  final ValueChanged<Poisha?> onChanged;

  /// Shown under the field while the app's figure is used.
  final String? helper;

  @override
  State<OverridableAmount> createState() => _OverridableAmountState();
}

class _OverridableAmountState extends State<OverridableAmount> {
  late final _controller = TextEditingController(
    text: amountText(widget.value ?? widget.fromApp ?? 0),
  );

  @override
  void didUpdateWidget(OverridableAmount old) {
    super.didUpdateWidget(old);
    // Follow the app while its figure is used and the data changes.
    if (widget.value == null && widget.fromApp != old.fromApp) {
      _controller.text = amountText(widget.fromApp ?? 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fromApp = widget.fromApp;
    final own = widget.value != null && fromApp != null && widget.value != fromApp;
    return TextField(
      controller: _controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
      textAlign: TextAlign.end,
      style: const TextStyle(fontFeatures: [FontFeature.tabularFigures()]),
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: '0',
        prefixText: '$takaSymbol ',
        border: const OutlineInputBorder(),
        helperText: own ? 'Yours. The app has ${formatTaka(fromApp)}' : widget.helper,
        helperMaxLines: 3,
        suffixIcon: own
            ? IconButton(
                tooltip: 'Use the app\'s figure',
                icon: const Icon(Icons.restart_alt),
                onPressed: () {
                  _controller.text = amountText(fromApp);
                  widget.onChanged(null);
                },
              )
            : null,
      ),
      onChanged: (text) {
        final parsed = parseTaka(text) ?? 0;
        widget.onChanged(fromApp != null && parsed == fromApp ? null : parsed);
      },
    );
  }
}

/// A plain decimal number such as grams or a percentage.
class NumberField extends StatefulWidget {
  const NumberField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.suffix,
    this.prefix,
  });

  final String label;
  final double value;
  final ValueChanged<double> onChanged;
  final String? suffix;
  final String? prefix;

  @override
  State<NumberField> createState() => _NumberFieldState();
}

class _NumberFieldState extends State<NumberField> {
  late final _controller = TextEditingController(text: formatNumber(widget.value));

  @override
  void didUpdateWidget(NumberField old) {
    super.didUpdateWidget(old);
    // A value set from outside (a fetched price), not by typing here.
    if ((double.tryParse(_controller.text) ?? 0) != widget.value) {
      _controller.text = formatNumber(widget.value);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TextField(
    controller: _controller,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
    textAlign: TextAlign.end,
    decoration: InputDecoration(
      labelText: widget.label,
      hintText: '0',
      suffixText: widget.suffix,
      prefixText: widget.prefix,
      border: const OutlineInputBorder(),
    ),
    onChanged: (text) => widget.onChanged(double.tryParse(text) ?? 0),
  );
}

/// 12.5 → "12.5", 3.0 → "3", 0 → "".
String formatNumber(double v) =>
    v == 0 ? '' : v.toStringAsFixed(3).replaceFirst(RegExp(r'\.?0+$'), '');

/// Saves a setting a moment after the last change, and at once when the
/// screen closes, so typing doesn't rewrite it on every key.
class SettingSaver {
  SettingSaver(this._save);

  final Future<void> Function(String value) _save;
  Timer? _timer;
  String? _pending;

  void call(String value) {
    _pending = value;
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 800), flush);
  }

  void flush() {
    _timer?.cancel();
    final value = _pending;
    _pending = null;
    if (value != null) unawaited(_save(value));
  }
}
