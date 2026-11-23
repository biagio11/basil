import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/settings.dart';
import '../logic/base_conv.dart';
import '../logic/base_ops.dart';
import '../logic/numbers.dart';
import 'common.dart';
import 'converter_screen.dart' show isTouchLayout;
import 'explain.dart';
import 'widgets/base_wheel.dart';
import 'widgets/fx.dart';
import 'widgets/keypad.dart';

class CalcModel {
  CalcModel._();
  static final instance = CalcModel._();
  final a = TextEditingController(text: '1011');
  final b = TextEditingController(text: '110');
  Op op = Op.add;
  int base = 2;
}

const int _maxOpDigits = 32;

class CalcScreen extends StatefulWidget {
  const CalcScreen({super.key});

  @override
  State<CalcScreen> createState() => _CalcScreenState();
}

class _CalcScreenState extends State<CalcScreen> {
  final m = CalcModel.instance;
  final s = AppSettings.instance;
  final _fa = FocusNode();
  final _fb = FocusNode();
  late TextEditingController _active = m.a;
  bool _keypadOpen = true;

  @override
  void initState() {
    super.initState();
    m.a.addListener(_r);
    m.b.addListener(_r);
    _fa.addListener(() {
      if (_fa.hasFocus) setState(() => _active = m.a);
    });
    _fb.addListener(() {
      if (_fb.hasFocus) setState(() => _active = m.b);
    });
  }

  @override
  void dispose() {
    m.a.removeListener(_r);
    m.b.removeListener(_r);
    _fa.dispose();
    _fb.dispose();
    super.dispose();
  }

  void _r() => setState(() {});

  String? _err(String text) {
    final t = text.trim();
    if (t.isEmpty) return tr('Scrivi un numero', 'Type a number');
    final p = parseNumber(t, m.base, allowFraction: false);
    if (!p.ok) {
      if (p.error == ParseError.badFormat) {
        return tr('Solo numeri interi', 'Whole numbers only');
      }
      return parseErrorText(p, m.base);
    }
    if (p.value!.negative) return tr('Solo numeri positivi', 'Positive numbers only');
    if (p.value!.intDigits.length > _maxOpDigits) {
      return tr('Max $_maxOpDigits cifre', 'Max $_maxOpDigits digits');
    }
    return null;
  }

  String _clean(String t) => parseNumber(t, m.base, allowFraction: false).value!.intDigits;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final wide = MediaQuery.sizeOf(context).width >= 980;
    final touch = isTouchLayout(context);
    final useKeypad = touch && s.keypad;
    final ea = _err(m.a.text);
    final eb = _err(m.b.text);
    final ok = ea == null && eb == null;
    String? divZero;
    if (ok && m.op == Op.div && parseInBase(_clean(m.b.text), m.base) == BigInt.zero) {
      divZero = tr('Non si può dividere per zero', 'You cannot divide by zero');
    }

    Widget field(TextEditingController c, FocusNode f, String label, String? err) {
      return TextField(
        controller: c,
        focusNode: f,
        keyboardType: useKeypad ? TextInputType.none : TextInputType.visiblePassword,
        showCursor: true,
        autocorrect: false,
        enableSuggestions: false,
        textCapitalization: TextCapitalization.characters,
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9A-Za-z _]')),
          LengthLimitingTextInputFormatter(_maxOpDigits + 8),
        ],
        style: termStyle(size: 34, color: cs.onSurface, height: 1.1),
        decoration: InputDecoration(
          labelText: label,
          errorText: c.text.isEmpty ? null : err,
          errorMaxLines: 2,
          suffixIcon: c.text.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close, size: 18), onPressed: () => c.clear()),
        ),
      );
    }

    final inputs = Panel(
      title: tr('Operazione in base ${m.base}', 'Operation in base ${m.base}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          field(m.a, _fa, 'A', ea),
          const SizedBox(height: 10),
          Row(
            children: [
              for (final o in Op.values)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: _OpButton(
                      op: o,
                      selected: m.op == o,
                      onTap: () {
                        hapticTick();
                        setState(() => m.op = o);
                      },
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          field(m.b, _fb, 'B', eb),
        ],
      ),
    );

    final baseWheel = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 150,
          child: BaseWheel(
            value: m.base,
            label: tr('base', 'base'),
            height: 130,
            onChanged: (b) => setState(() => m.base = b),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                QuickBases(value: m.base, onPick: (b) => setState(() => m.base = b)),
                const SizedBox(height: 10),
                Text(
                  tr('Cifre valide: ${validDigitsLabel(m.base)}. Sottrazione con risultato negativo e divisione con resto sono gestite.',
                      'Valid digits: ${validDigitsLabel(m.base)}. Negative differences and division remainders are handled.'),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ],
    );

    Widget result;
    Widget? detail;
    if (!ok || divZero != null) {
      result = Panel(
        title: tr('Risultato', 'Result'),
        child: Text(divZero ?? '-',
            style: termStyle(size: 30, color: divZero != null ? context.bc.bad : cs.onSurfaceVariant)),
      );
    } else {
      final a = _clean(m.a.text);
      final b = _clean(m.b.text);
      final da = parseInBase(a, m.base);
      final db = parseInBase(b, m.base);
      String main;
      String dec;
      String copy;
      switch (m.op) {
        case Op.add:
          final r = addBase(a, b, m.base);
          main = r.result;
          copy = main;
          dec = '$da + $db = ${da + db}';
          detail = ColumnOpView(r: r);
        case Op.sub:
          final r = subBase(a, b, m.base);
          main = (r.negative ? '-' : '') + r.result;
          copy = main;
          dec = '$da − $db = ${da - db}';
          detail = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (r.negative)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: InfoCard(
                    child: RichLine(
                        tr('B è più grande di A: calcolo **B − A** e metto il segno meno.',
                            'B is bigger than A: compute **B − A** and add a minus sign.'),
                        size: 14),
                  ),
                ),
              ColumnOpView(r: r),
            ],
          );
        case Op.mul:
          final r = mulBase(a, b, m.base);
          main = r.result;
          copy = main;
          dec = '$da × $db = ${da * db}';
          detail = MulBaseView(r: r);
        case Op.div:
          final r = divBase(a, b, m.base);
          main = r.quotient;
          copy = main;
          final remTxt = r.remainder == '0' ? '' : tr('  resto ${r.remainder}', '  rem ${r.remainder}');
          main = '$main$remTxt';
          dec = '$da ÷ $db = ${da ~/ db}${da % db == BigInt.zero ? '' : tr(' resto ${da % db}', ' remainder ${da % db}')}';
          detail = DivBaseView(r: r);
      }
      result = Panel(
        title: '${tr('Risultato', 'Result')} · ${tr('base', 'base')} ${m.base}',
        highlight: true,
        trailing: IconButton(
          tooltip: tr('Copia', 'Copy'),
          visualDensity: VisualDensity.compact,
          iconSize: 18,
          onPressed: () => copyText(context, copy),
          icon: const Icon(Icons.copy),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ScrambleText(main,
                style: termStyle(size: main.length > 24 ? 32 : 44, color: cs.primary)),
            const SizedBox(height: 4),
            Text('${tr('in base 10', 'in base 10')}: $dec',
                style: monoStyle(size: 13, color: cs.onSurfaceVariant)),
          ],
        ),
      );
    }

    final mode = SegmentedButton<bool>(
      showSelectedIcon: false,
      segments: [
        ButtonSegment(value: false, icon: const Icon(Icons.bolt, size: 18), label: Text(tr('VELOCE', 'QUICK'))),
        ButtonSegment(value: true, icon: const Icon(Icons.school_outlined, size: 18), label: Text(tr('SPIEGA', 'EXPLAIN'))),
      ],
      selected: {s.explain},
      onSelectionChanged: (v) => setState(() => s.setExplain(v.first)),
    );

    final explainPanel = (s.explain && detail != null)
        ? Panel(title: tr('Procedimento', 'Working'), child: detail)
        : const SizedBox.shrink();

    final keypad = useKeypad
        ? Container(
            decoration: BoxDecoration(
              color: context.bc.panel,
              border: Border(top: BorderSide(color: cs.outlineVariant)),
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              InkWell(
                onTap: () => setState(() => _keypadOpen = !_keypadOpen),
                child: SizedBox(
                  height: 26,
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(_keypadOpen ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up,
                        size: 18, color: cs.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text('${tr('TASTIERINO', 'KEYPAD')} → ${_active == m.a ? 'A' : 'B'}',
                        style: pixelStyle(size: 9, color: cs.onSurfaceVariant)),
                  ]),
                ),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                child: _keypadOpen
                    ? Padding(
                        padding: const EdgeInsets.fromLTRB(6, 0, 6, 6),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 560),
                          child: BaseKeypad(
                            base: m.base,
                            controller: _active,
                            allowPoint: false,
                            allowMinus: false,
                            maxLength: _maxOpDigits,
                            onSubmit: () => setState(() {
                              _active = _active == m.a ? m.b : m.a;
                              (_active == m.a ? _fa : _fb).requestFocus();
                            }),
                          ),
                        ),
                      )
                    : const SizedBox(width: double.infinity),
              ),
            ]),
          )
        : null;

    if (wide) {
      return Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1240),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 470,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 10, 32),
                  children: [
                    Appear(child: inputs),
                    const SizedBox(height: 14),
                    Appear(delay: 60, child: baseWheel),
                    const SizedBox(height: 14),
                    Appear(delay: 120, child: result),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(10, 8, 20, 32),
                  children: [mode, const SizedBox(height: 14), explainPanel],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(14, 4, 14, 24),
                children: [
                  Appear(child: inputs),
                  const SizedBox(height: 12),
                  Appear(delay: 60, child: baseWheel),
                  const SizedBox(height: 12),
                  Appear(delay: 120, child: result),
                  const SizedBox(height: 12),
                  mode,
                  const SizedBox(height: 12),
                  explainPanel,
                ],
              ),
            ),
          ),
        ),
        ?keypad,
      ],
    );
  }
}

class _OpButton extends StatelessWidget {
  const _OpButton({required this.op, required this.selected, required this.onTap});
  final Op op;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    return Material(
      color: selected ? cs.primary : context.bc.panelHi,
      shape: RoundedRectangleBorder(
        borderRadius: appLook.br(5),
        side: BorderSide(color: selected ? cs.primary : cs.outlineVariant),
      ),
      child: InkWell(
        borderRadius: appLook.br(5),
        onTap: onTap,
        child: SizedBox(
          height: 46,
          child: Center(
            child: Text(op.symbol,
                style: monoStyle(
                    size: 24,
                    weight: FontWeight.w800,
                    color: selected ? cs.onPrimary : cs.onSurface)),
          ),
        ),
      ),
    );
  }
}
