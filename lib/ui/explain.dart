import 'dart:math';

import 'package:flutter/material.dart';

import '../app/settings.dart';
import '../logic/base_conv.dart';
import '../logic/base_ops.dart';
import '../logic/numbers.dart';
import 'common.dart';
import 'widgets/fx.dart';

/// Step-by-step explanation of converting [n] to base [to].
class ConversionExplanation extends StatelessWidget {
  const ConversionExplanation({super.key, required this.n, required this.to});
  final ParsedNumber n;
  final int to;

  @override
  Widget build(BuildContext context) {
    final from = n.base;
    final method = methodFor(from, to, hasFraction: n.hasFraction);
    final res = convertNumber(n, to);
    final children = <Widget>[];
    var step = 1;

    if (n.negative && !n.isZero) {
      children.add(InfoCard(
        child: RichLine(tr(
            'Il segno **−** resta com’è: convertiamo `${n.display.substring(1)}` e rimettiamo il meno davanti.',
            'The **−** sign stays as it is: we convert `${n.display.substring(1)}` and put the minus back in front.'),
            size: 15),
      ));
      children.add(const SizedBox(height: 12));
    }

    final tooLong = n.intDigits.length > 40 ||
        (from != 10 && to != 10 && n.intDigits.length > 24);
    if (tooLong && method != ConvMethod.grouping) {
      children.add(RichLine(
          tr('Numero molto lungo: il risultato è esatto, ma i passaggi sarebbero centinaia. '
              'Prova con un numero più corto per vedere la spiegazione.',
              'Very long number: the result is exact, but there would be hundreds of steps. '
              'Try a shorter number to see the explanation.'),
          size: 15));
      return _wrap(children);
    }

    switch (method) {
      case ConvMethod.same:
        children.add(RichLine(
            tr('Stessa base: il numero non cambia.', 'Same base: the number does not change.'),
            size: 15));
      case ConvMethod.grouping:
        final m = groupShortcut(n.intDigits, from, to)!;
        final big = from == 2 ? to : from;
        children.add(StepLabel(tr(
            'Scorciatoia: $big = 2^${m.groupSize}, quindi ogni cifra ↔ ${m.groupSize} bit',
            'Shortcut: $big = 2^${m.groupSize}, so each digit ↔ ${m.groupSize} bits')));
        children.add(GroupStrip(m));
        children.add(const SizedBox(height: 8));
        children.add(RichLine(
            m.toBinary
                ? tr('Ogni cifra diventa ${m.groupSize} bit; poi togli gli zeri iniziali.',
                    'Each digit becomes ${m.groupSize} bits; then drop leading zeros.')
                : tr('Raggruppa i bit a ${m.groupSize} a ${m.groupSize} **da destra** (aggiungi zeri a sinistra se serve).',
                    'Group the bits ${m.groupSize} at a time **from the right** (pad with zeros on the left).'),
            size: 14));
      case ConvMethod.viaBinary:
        final m1 = groupShortcut(n.intDigits, from, 2)!;
        final bits = stripLeadingZeros(m1.bitGroups.join());
        final m2 = groupShortcut(bits, 2, to)!;
        children.add(StepLabel(
            tr('base $from → base 2 (${m1.groupSize} bit per cifra)',
                'base $from → base 2 (${m1.groupSize} bits per digit)'),
            n: step++));
        children.add(GroupStrip(m1));
        children.add(const SizedBox(height: 14));
        children.add(StepLabel(
            tr('base 2 → base $to (gruppi di ${m2.groupSize} bit da destra)',
                'base 2 → base $to (groups of ${m2.groupSize} bits from the right)'),
            n: step++));
        children.add(GroupStrip(m2));
      case ConvMethod.toDecimal:
        children.addAll(_toDecimal(context, n, step));
      case ConvMethod.fromDecimal:
        children.addAll(_fromDecimal(context, n.intValue, n.fracNum, n.fracDen, to, step));
      case ConvMethod.viaDecimal:
        children.addAll(_toDecimal(context, n, step++, label: true));
        children.add(const SizedBox(height: 14));
        children.addAll(_fromDecimal(context, n.intValue, n.fracNum, n.fracDen, to, step,
            label: true));
    }

    children.add(const SizedBox(height: 14));
    children.add(Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: context.cs.primary, width: 3)),
        color: context.cs.primary.withAlpha(18),
      ),
      child: SelectableText(
        '${n.display}${subscript(from)} = ${res.display}${subscript(to)}',
        style: monoStyle(size: 18, weight: FontWeight.w800, color: context.cs.primary),
      ),
    ));
    if (res.repeat.isNotEmpty) {
      children.add(Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(
            tr('Le cifre tra parentesi (${res.repeat}) si ripetono all’infinito.',
                'The digits in brackets (${res.repeat}) repeat forever.'),
            style: Theme.of(context).textTheme.bodySmall),
      ));
    } else if (res.truncated) {
      children.add(Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(
            tr('La parte decimale continua: mostrate le prime $kMaxFracDigits cifre.',
                'The fractional part goes on: showing the first $kMaxFracDigits digits.'),
            style: Theme.of(context).textTheme.bodySmall),
      ));
    }
    return _wrap(children);
  }

  Widget _wrap(List<Widget> c) => Column(
      crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: c);

  List<Widget> _toDecimal(BuildContext context, ParsedNumber n, int step,
      {bool label = false}) {
    final out = <Widget>[];
    final from = n.base;
    out.add(StepLabel(
        tr('base $from → base 10: cifra × $from^posizione', 'base $from → base 10: digit × $from^position'),
        n: label || n.hasFraction ? step : null));
    out.add(PowerTable(digits: n.intDigits, base: from, showSum: true));
    if (n.hasFraction) {
      out.add(const SizedBox(height: 12));
      out.add(Text(tr('Dopo la virgola: pesi negativi', 'After the point: negative weights'),
          style: Theme.of(context).textTheme.bodySmall));
      out.add(const SizedBox(height: 6));
      out.add(FracPowerTable(digits: n.fracDigits, base: from));
      final intV = n.intValue;
      out.add(const SizedBox(height: 6));
      out.add(Text(
          '$intV + ${ratToDecimal(n.fracNum, n.fracDen)} = ${ratToDecimal(intV * n.fracDen + n.fracNum, n.fracDen)}',
          style: monoStyle(size: 17, weight: FontWeight.w800)));
    }
    return out;
  }

  List<Widget> _fromDecimal(BuildContext context, BigInt intV, BigInt fracNum,
      BigInt fracDen, int to, int step,
      {bool label = false}) {
    final out = <Widget>[];
    final hasFrac = fracNum != BigInt.zero;
    final steps = divisionSteps(intV, to);
    out.add(StepLabel(
        tr('base 10 → base $to: dividi per $to', 'base 10 → base $to: divide by $to'),
        n: label || hasFrac ? step : null));
    if (steps.length > 70) {
      out.add(RichLine(
          tr('${steps.length} divisioni: troppe da mostrare.', '${steps.length} divisions: too many to show.'),
          size: 14));
    } else {
      out.add(DivisionTable(number: intV, base: to, showResult: true));
    }
    if (hasFrac) {
      out.add(const SizedBox(height: 14));
      out.add(StepLabel(
          tr('Parte dopo la virgola: moltiplica per $to', 'Fractional part: multiply by $to'),
          n: step + 1));
      out.add(MulFracTable(num: fracNum, den: fracDen, base: to));
    }
    return out;
  }
}

/// digit × base^(−k) table for the fractional part.
class FracPowerTable extends StatelessWidget {
  const FracPowerTable({super.key, required this.digits, required this.base});
  final String digits;
  final int base;

  @override
  Widget build(BuildContext context) {
    final terms = fracTerms(digits, base);
    final small = Theme.of(context).textTheme.bodySmall;
    Widget c(String s, {Color? color, bool bold = false}) => Container(
          constraints: const BoxConstraints(minWidth: 70),
          height: 34,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Text(s,
              style: monoStyle(
                  size: 15, color: color, weight: bold ? FontWeight.w800 : FontWeight.w500)),
        );
    Widget l(String s) =>
        SizedBox(width: 112, height: 34, child: Align(alignment: Alignment.centerLeft, child: Text(s, style: small)));
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            l(tr('cifra', 'digit')),
            for (final t in terms) c(t.digit, color: context.cs.primary, bold: true)
          ]),
          Row(children: [l(tr('peso', 'weight')), for (final t in terms) c('$base^-${t.k}')]),
          Row(children: [
            l('= '),
            for (final t in terms) c(ratToDecimal(BigInt.one, t.den, maxDigits: 6))
          ]),
          Row(children: [
            l(tr('cifra × peso', 'digit × weight')),
            for (final t in terms)
              c(ratToDecimal(BigInt.from(t.digitVal), t.den, maxDigits: 6),
                  color: context.bc.accent, bold: true)
          ]),
        ],
      ),
    );
  }
}

/// "0.375 × 2 = 0.75 → 0" table for the fractional part.
class MulFracTable extends StatelessWidget {
  const MulFracTable({super.key, required this.num, required this.den, required this.base});
  final BigInt num;
  final BigInt den;
  final int base;

  @override
  Widget build(BuildContext context) {
    final steps = mulFracSteps(num, den, base, max: 12);
    final accent = context.bc.accent;
    TextStyle st({Color? c, bool b = false}) =>
        monoStyle(size: 16, color: c, weight: b ? FontWeight.w800 : null);
    Widget cell(String s, TextStyle t) =>
        Padding(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), child: Text(s, style: t));
    final (pre, rep, _) = fractionDigits(num, den, base);
    final digitsShown = steps.map((s) => digitChar(s.digit)).join();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Table(
            defaultColumnWidth: const IntrinsicColumnWidth(),
            children: [
              for (final s in steps)
                TableRow(children: [
                  cell(ratToDecimal(s.num, s.den), st()),
                  cell('× $base', st()),
                  cell('= ${ratToDecimal(s.product, s.den)}', st()),
                  cell('→ ${s.digit >= 10 ? '${s.digit} (${digitChar(s.digit)})' : '${s.digit}'}',
                      st(c: accent, b: true)),
                ]),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
            rep.isNotEmpty
                ? tr('Torna una parte già vista: da qui le cifre si ripetono. Lette dall’alto: 0.$pre($rep)',
                    'A fractional part we have already seen comes back: digits repeat from here. Read top-down: 0.$pre($rep)')
                : steps.length >= 12 && pre.length > steps.length
                    ? tr('…e così via. Lette dall’alto: 0.$digitsShown…', '…and so on. Read top-down: 0.$digitsShown…')
                    : tr('La parte frazionaria è 0: fine. Lette dall’alto: 0.$digitsShown',
                        'The fractional part is 0: done. Read top-down: 0.$digitsShown'),
            style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Column operations in any base
// ---------------------------------------------------------------------------

/// Addition/subtraction laid out in columns with carries, plus a stepper.
class ColumnOpView extends StatefulWidget {
  const ColumnOpView({super.key, required this.r});
  final ColumnOpResult r;

  @override
  State<ColumnOpView> createState() => _ColumnOpViewState();
}

class _ColumnOpViewState extends State<ColumnOpView> {
  int step = -1; // -1 = show everything

  @override
  void didUpdateWidget(ColumnOpView old) {
    super.didUpdateWidget(old);
    if (old.r.a != widget.r.a || old.r.b != widget.r.b || old.r.base != widget.r.base) {
      step = -1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.r;
    final cs = context.cs;
    final n = r.columns.length;
    final shown = step < 0 ? n : step;
    final total = max(n, r.result.length) + 1;
    final isAdd = r.op == Op.add;

    final carry = List<String>.filled(total, ' ');
    final res = List<String>.filled(total, ' ');
    for (var p = 0; p < shown && p < n; p++) {
      final c = r.columns[p];
      res[total - 1 - p] = digitChar(c.digit);
      if (c.carryOut > 0 && total - 2 - p >= 0) carry[total - 2 - p] = '${c.carryOut}';
    }
    if (shown >= n && r.result.length > n) {
      // final carry digit(s) of an addition
      final extra = r.result.substring(0, r.result.length - n);
      for (var i = 0; i < extra.length; i++) {
        res[total - n - extra.length + i] = extra[i];
      }
    }
    if (shown >= n && !isAdd) {
      // show the stripped result aligned right
      final s = r.result.padLeft(n, ' ');
      for (var i = 0; i < n; i++) {
        res[total - n + i] = i < n - r.result.length ? ' ' : s[i];
      }
    }
    final aRow = padCells(r.a, total);
    final bRow = padCells(r.b, total);
    bRow[0] = r.op.symbol;
    final hl = <int, Color>{};
    if (step > 0 && step <= n) hl[total - step] = cs.primaryContainer;
    final cell = total > 14 ? 26.0 : 32.0;
    final fs = total > 14 ? 18.0 : 21.0;

    Widget row(List<String> cells, {Color? color, bool bold = false, Map<int, Color> h = const {}}) =>
        DigitRow(cells, cell: cell, size: fs, color: color, bold: bold, highlight: h);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                SizedBox(
                    width: 74,
                    child: Text(isAdd ? tr('riporto', 'carry') : tr('prestito', 'borrow'),
                        style: Theme.of(context).textTheme.bodySmall)),
                row(carry, color: context.bc.accent, bold: true),
              ]),
              Row(children: [const SizedBox(width: 74), row(aRow, h: hl)]),
              Row(children: [const SizedBox(width: 74), row(bRow, h: hl)]),
              Padding(
                padding: const EdgeInsets.only(left: 74, top: 2, bottom: 2),
                child: Container(width: total * cell, height: 2, color: cs.onSurface),
              ),
              Row(children: [
                const SizedBox(width: 74),
                row(res, color: cs.primary, bold: true, h: hl),
              ]),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.tonalIcon(
              onPressed: step >= 0 && step >= n
                  ? null
                  : () => setState(() => step = step < 0 ? 1 : step + 1),
              icon: const Icon(Icons.skip_next, size: 18),
              label: Text(step < 0 ? tr('Passo passo', 'Step by step') : tr('Avanti', 'Next')),
            ),
            if (step >= 0)
              OutlinedButton(
                onPressed: () => setState(() => step = -1),
                child: Text(tr('Tutto', 'All')),
              ),
          ],
        ),
        const SizedBox(height: 10),
        for (var p = 0; p < (step < 0 ? n : step) && p < n; p++)
          if (step < 0 || p == step - 1 || step < 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Appear(
                child: Text(
                  '${tr('Col', 'Col')} $p · ${columnText(r, r.columns[p])}',
                  style: monoStyle(size: 13, color: p == shown - 1 && step >= 0 ? cs.primary : null),
                ),
              ),
            ),
      ],
    );
  }
}

class MulBaseView extends StatelessWidget {
  const MulBaseView({super.key, required this.r});
  final MulBaseResult r;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    var total = max(r.result.length, max(r.a.length, r.b.length));
    for (final row in r.rows) {
      total = max(total, row.value.length);
    }
    total += 1;
    final cell = total > 14 ? 24.0 : 30.0;
    final fs = total > 14 ? 17.0 : 20.0;
    Widget line() => Container(width: total * cell, height: 2, color: cs.onSurface,
        margin: const EdgeInsets.symmetric(vertical: 2));
    final bRow = padCells(r.b, total);
    bRow[0] = '×';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DigitRow(padCells(r.a, total), cell: cell, size: fs),
              DigitRow(bRow, cell: cell, size: fs),
              line(),
              for (final row in r.rows)
                DigitRow(padCells(row.value, total), cell: cell, size: fs, color: context.bc.accent),
              if (r.rows.length > 1) ...[
                line(),
                DigitRow(padCells(r.result, total), cell: cell, size: fs, color: cs.primary, bold: true),
              ],
            ],
          ),
        ),
        const SizedBox(height: 10),
        for (var i = 0; i < r.rows.length; i++)
          Text(
              tr('Riga ${i + 1}: ${r.a} × ${digitChar(r.rows[i].digit)}${r.rows[i].shift > 0 ? ', spostata di ${r.rows[i].shift}' : ''} = ${r.rows[i].value}',
                  'Row ${i + 1}: ${r.a} × ${digitChar(r.rows[i].digit)}${r.rows[i].shift > 0 ? ', shifted by ${r.rows[i].shift}' : ''} = ${r.rows[i].value}'),
              style: monoStyle(size: 13)),
        if (r.rows.length > 1)
          Text(tr('Somma delle righe (in base ${r.base}) = ${r.result}',
                  'Sum of the rows (in base ${r.base}) = ${r.result}'),
              style: monoStyle(size: 13, weight: FontWeight.w800)),
      ],
    );
  }
}

class DivBaseView extends StatelessWidget {
  const DivBaseView({super.key, required this.r});
  final DivBaseResult r;

  @override
  Widget build(BuildContext context) {
    final small = Theme.of(context).textTheme.bodySmall;
    Widget head(String s) =>
        Padding(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), child: Text(s, style: small));
    Widget cell(String s, {Color? color, bool bold = false}) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Text(s, style: monoStyle(size: 16, color: color, weight: bold ? FontWeight.w800 : null)),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Table(
            defaultColumnWidth: const IntrinsicColumnWidth(),
            children: [
              TableRow(children: [
                head(tr('abbasso', 'bring down')),
                head(tr('ho', 'have')),
                head(tr('${r.divisor} ci sta', '${r.divisor} fits')),
                head(tr('resto', 'remainder')),
              ]),
              for (final s in r.steps)
                TableRow(children: [
                  cell(s.broughtDown),
                  cell(toBase(s.current, r.base)),
                  cell('${dv(s.qDigit)}×', color: s.qDigit > 0 ? context.bc.ok : null, bold: true),
                  cell(toBase(s.remainder, r.base)),
                ]),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(tr('Le cifre della terza colonna, dall’alto, formano il quoziente.',
                'The digits in the third column, top-down, form the quotient.'),
            style: small),
      ],
    );
  }
}
