import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../logic/base_conv.dart';
import '../logic/binary_ops.dart';
import '../app/settings.dart';
import 'common.dart';

// ---------------------------------------------------------------------------
// Bit toggler: tap bits, see the value
// ---------------------------------------------------------------------------

class BitToggler extends StatefulWidget {
  const BitToggler({super.key});

  @override
  State<BitToggler> createState() => _BitTogglerState();
}

class _BitTogglerState extends State<BitToggler> {
  int bits = 4;
  final List<bool> on = List<bool>.filled(8, false); // index 0 = weight 1

  int get value {
    var v = 0;
    for (var i = 0; i < bits; i++) {
      if (on[i]) v += 1 << i;
    }
    return v;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final terms = [
      for (var i = bits - 1; i >= 0; i--)
        if (on[i]) '${1 << i}'
    ];
    final expr = terms.isEmpty ? '0' : terms.join(' + ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(tr('Numero di bit:', 'Number of bits:')),
            IconButton(
              onPressed: bits > 1 ? () => setState(() => bits--) : null,
              icon: const Icon(Icons.remove_circle_outline),
            ),
            Text('$bits',
                style: monoStyle(size: 22, weight: FontWeight.bold)),
            IconButton(
              onPressed: bits < 8 ? () => setState(() => bits++) : null,
              icon: const Icon(Icons.add_circle_outline),
            ),
          ],
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (var i = bits - 1; i >= 0; i--)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Column(
                    children: [
                      Text('${1 << i}',
                          style: monoStyle(size: 16, color: cs.primary)),
                      const SizedBox(height: 4),
                      InkWell(
                        borderRadius: BorderRadius.circular(5),
                        onTap: () => setState(() => on[i] = !on[i]),
                        child: Container(
                          width: 48,
                          height: 56,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: on[i] ? cs.primary : context.bc.panelHi,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            on[i] ? '1' : '0',
                            style: monoStyle(
                              size: 26,
                              weight: FontWeight.bold,
                              color: on[i] ? cs.onPrimary : cs.onSurface,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('2^$i', style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        InfoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$expr = $value',
                  style: monoStyle(size: 22, weight: FontWeight.bold)),
              const SizedBox(height: 8),
              RichLine(
                tr('Con **$bits bit** hai 2^$bits = **${1 << bits}** combinazioni '
                    '(da 0 a ${(1 << bits) - 1}).',
                    'With **$bits bits** you get 2^$bits = **${1 << bits}** combinations '
                    '(from 0 to ${(1 << bits) - 1}).'),
                size: 16,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// RGB mixer
// ---------------------------------------------------------------------------

class RgbMixer extends StatefulWidget {
  const RgbMixer({super.key});

  @override
  State<RgbMixer> createState() => _RgbMixerState();
}

class _RgbMixerState extends State<RgbMixer> {
  int r = 255;
  int g = 128;
  int b = 0;

  String _hex2(int v) => toBaseInt(v, 16).padLeft(2, '0');

  String _bin8(int v) {
    final s = v.toRadixString(2).padLeft(8, '0');
    return '${s.substring(0, 4)} ${s.substring(4)}';
  }

  Widget _channel(String name, Color color, int v, ValueChanged<int> onChanged) {
    return Row(
      children: [
        SizedBox(
          width: 20,
          child: Text(name, style: monoStyle(size: 18, weight: FontWeight.bold)),
        ),
        Expanded(
          child: Slider(
            value: v.toDouble(),
            min: 0,
            max: 255,
            divisions: 255,
            activeColor: color,
            onChanged: (x) => setState(() => onChanged(x.round())),
          ),
        ),
        SizedBox(
          width: 190,
          child: Text(
            '${v.toString().padLeft(3)} = ${_hex2(v)} = ${_bin8(v)}',
            style: monoStyle(size: 14),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 90,
          decoration: BoxDecoration(
            color: Color.fromRGBO(r, g, b, 1),
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(height: 10),
        Text(rgbToHex(r, g, b),
            style: monoStyle(size: 30, weight: FontWeight.bold)),
        const SizedBox(height: 6),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: 560,
            child: Column(
              children: [
                _channel('R', Colors.red, r, (v) => r = v),
                _channel('G', Colors.green, g, (v) => g = v),
                _channel('B', Colors.blue, b, (v) => b = v),
              ],
            ),
          ),
        ),
        Text(tr('decimale = esadecimale = binario (un byte per canale)', 'decimal = hexadecimal = binary (one byte per channel)'),
            style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Overflow counter
// ---------------------------------------------------------------------------

class OverflowCounter extends StatefulWidget {
  const OverflowCounter({super.key});

  @override
  State<OverflowCounter> createState() => _OverflowCounterState();
}

class _OverflowCounterState extends State<OverflowCounter> {
  int bits = 8;
  int value = 250;
  String message = '';

  int get maxValue => (1 << bits) - 1;

  void _setBits(int b) {
    setState(() {
      bits = b;
      value = maxValue - 5;
      message = '';
    });
  }

  void _add(int n) {
    final raw = value + n;
    setState(() {
      value = wrapAdd(value, n, bits);
      message = raw > maxValue
          ? tr('Overflow! $raw non entra in $bits bit (massimo $maxValue): '
              'il bit in più va perso e resta $value.',
              'Overflow! $raw does not fit in $bits bits (max $maxValue): '
              'the extra bit is lost and $value is left.')
          : '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final binary = value.toRadixString(2).padLeft(bits, '0');
    final cells = binary.split('');
    final highlight = <int, Color>{
      for (var i = 0; i < cells.length; i++)
        if (cells[i] == '1') i: cs.primaryContainer
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          children: [
            for (final b in const [4, 8, 16])
              ChoiceChip(
                label: Text('$b bit'),
                selected: bits == b,
                onSelected: (_) => _setBits(b),
              ),
          ],
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DigitRow(cells, cell: bits > 8 ? 26 : 34, highlight: highlight),
        ),
        const SizedBox(height: 8),
        Text(tr('valore = $value   (massimo con $bits bit: $maxValue)', 'value = $value   (max with $bits bits: $maxValue)'),
            style: monoStyle(size: 18, weight: FontWeight.bold)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          children: [
            FilledButton(onPressed: () => _add(1), child: const Text('+ 1')),
            FilledButton.tonal(
                onPressed: () => _add(3), child: const Text('+ 3')),
            OutlinedButton(
                onPressed: () => _setBits(bits), child: Text(tr('Reimposta', 'Reset'))),
          ],
        ),
        const SizedBox(height: 12),
        if (message.isNotEmpty)
          InfoCard(
            color: context.bc.bad.withAlpha(36),
            child: RichLine('**$message**', size: 17),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// x2 / ÷2 = shifting
// ---------------------------------------------------------------------------

class ShiftDemo extends StatefulWidget {
  const ShiftDemo({super.key, this.showMul = true, this.showDiv = true});
  final bool showMul;
  final bool showDiv;

  @override
  State<ShiftDemo> createState() => _ShiftDemoState();
}

class _ShiftDemoState extends State<ShiftDemo> {
  static const String start = '1101';
  String s = start;
  String note = '';

  void _mul() {
    if (s == '0' || s.length >= 14) return;
    setState(() {
      s = '${s}0';
      note = tr('Aggiungo uno 0 a destra: il numero raddoppia.', 'Append a 0 on the right: the number doubles.');
    });
  }

  void _div() {
    setState(() {
      if (s.length > 1) {
        final dropped = s.substring(s.length - 1);
        s = s.substring(0, s.length - 1);
        note = tr('Cancello l’ultima cifra ($dropped): quella cifra è il resto.', 'Drop the last digit ($dropped): that digit is the remainder.');
      } else {
        note = tr('Resto ${s == '1' ? '1' : '0'}: il quoziente è 0.', 'Remainder ${s == '1' ? '1' : '0'}: the quotient is 0.');
        s = '0';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DigitRow(s.split(''), size: 26),
        ),
        const SizedBox(height: 6),
        Text('${withBase(s, 2)} = ${parseInBase(s, 2)} in base 10',
            style: monoStyle(size: 18, weight: FontWeight.bold)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          children: [
            if (widget.showMul)
              FilledButton(onPressed: _mul, child: const Text('× 10₂  (× 2)')),
            if (widget.showDiv)
              FilledButton.tonal(
                  onPressed: _div, child: const Text('÷ 10₂  (÷ 2)')),
            OutlinedButton(
              onPressed: () => setState(() {
                s = start;
                note = '';
              }),
              child: Text(tr('Reimposta', 'Reset')),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (note.isNotEmpty) RichLine(note, size: 17),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Hex <-> binary groups (editable)
// ---------------------------------------------------------------------------

class HexBinGroups extends StatefulWidget {
  const HexBinGroups({super.key});

  @override
  State<HexBinGroups> createState() => _HexBinGroupsState();
}

class _HexBinGroupsState extends State<HexBinGroups> {
  final _hex = TextEditingController(text: '2D');
  final _bin = TextEditingController(text: '101101');

  @override
  void dispose() {
    _hex.dispose();
    _bin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hexMap = groupShortcut(_hex.text, 16, 2);
    final binMap = groupShortcut(_bin.text, 2, 16);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(tr('Esadecimale → binario', 'Hexadecimal → binary'),
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 6),
        TextField(
          controller: _hex,
          maxLength: 8,
          textCapitalization: TextCapitalization.characters,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp('[0-9A-Fa-f]'))
          ],
          decoration: const InputDecoration(
              border: OutlineInputBorder(), counterText: '', isDense: true),
          style: monoStyle(size: 20),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 8),
        if (hexMap != null) GroupStrip(hexMap),
        const SizedBox(height: 18),
        Text(tr('Binario → esadecimale', 'Binary → hexadecimal'),
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 6),
        TextField(
          controller: _bin,
          maxLength: 20,
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp('[01]'))],
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
              border: OutlineInputBorder(), counterText: '', isDense: true),
          style: monoStyle(size: 20),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 8),
        if (binMap != null) GroupStrip(binMap),
        const SizedBox(height: 6),
        Text(tr('I bit si raggruppano da destra; se manca qualcosa a sinistra si '
            'aggiungono zeri.', 'Bits are grouped from the right; missing bits on the left are filled with zeros.'),
            style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Column walk: binary addition / subtraction one column at a time
// ---------------------------------------------------------------------------

enum WalkOp { add, sub }

class _Col {
  const _Col(this.bit, this.carryOut, this.text);
  final int bit;
  final int carryOut;
  final String text;
}

class ColumnWalk extends StatefulWidget {
  const ColumnWalk({
    super.key,
    required this.op,
    required this.initialA,
    required this.initialB,
  });
  final WalkOp op;
  final String initialA;
  final String initialB;

  @override
  State<ColumnWalk> createState() => _ColumnWalkState();
}

class _ColumnWalkState extends State<ColumnWalk> {
  late final TextEditingController _a;
  late final TextEditingController _b;
  int step = 0; // columns processed so far

  @override
  void initState() {
    super.initState();
    _a = TextEditingController(text: widget.initialA);
    _b = TextEditingController(text: widget.initialB);
  }

  @override
  void dispose() {
    _a.dispose();
    _b.dispose();
    super.dispose();
  }

  bool get _isAdd => widget.op == WalkOp.add;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final x = _a.text;
    final y = _b.text;
    String? error;
    if (x.isEmpty || y.isEmpty) {
      error = tr('Scrivi due numeri binari.', 'Type two binary numbers.');
    } else if (!_isAdd && parseInBase(x, 2) < parseInBase(y, 2)) {
      error = tr('Il primo numero deve essere maggiore o uguale al secondo.', 'The first number must be greater than or equal to the second.');
    }

    Widget inputs() {
      Widget field(TextEditingController c, String label) => SizedBox(
            width: 150,
            child: TextField(
              controller: c,
              maxLength: 8,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp('[01]'))],
              decoration: InputDecoration(
                labelText: label,
                counterText: '',
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              style: monoStyle(size: 20),
              onChanged: (_) => setState(() => step = 0),
            ),
          );
      return Wrap(
        spacing: 12,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          field(_a, tr('Primo numero', 'First number')),
          Text(_isAdd ? '+' : '−', style: monoStyle(size: 26)),
          field(_b, tr('Secondo numero', 'Second number')),
        ],
      );
    }

    if (error != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          inputs(),
          const SizedBox(height: 12),
          Text(error, style: TextStyle(color: cs.error)),
        ],
      );
    }

    // Build the columns.
    final List<_Col> cols;
    final String result;
    final String pa;
    final String pb;
    if (_isAdd) {
      final r = addBinary(x, y);
      pa = r.a;
      pb = r.b;
      result = r.result;
      cols = [
        for (final c in r.columns)
          _Col(c.bit, c.carryOut, '${tr('Colonna', 'Column')} ${c.position}: ${addColumnText(c)}')
      ];
    } else {
      final r = subBinary(x, y);
      pa = r.a;
      pb = r.b;
      result = r.result;
      cols = [
        for (final c in r.columns)
          _Col(c.bit, c.borrowOut, '${tr('Colonna', 'Column')} ${c.position}: ${subColumnText(c)}')
      ];
    }

    final n = cols.length;
    final total = n + 1;
    final done = step >= n;

    List<String> carryRow = List<String>.filled(total, ' ');
    List<String> aRow = padCells(pa, total);
    List<String> bRow = padCells(pb, total);
    bRow[0] = _isAdd ? '+' : '−';
    List<String> resRow = List<String>.filled(total, ' ');
    for (var p = 0; p < step && p < n; p++) {
      resRow[total - 1 - p] = '${cols[p].bit}';
      if (cols[p].carryOut == 1) carryRow[total - 2 - p] = '1';
    }
    if (done && _isAdd && result.length == n + 1) {
      resRow[0] = result[0];
    }

    final hl = <int, Color>{};
    if (step > 0 && step <= n) {
      hl[total - step] = cs.primaryContainer;
    }

    Widget row(List<String> cells, {Color? color, bool bold = false, Map<int, Color>? h}) =>
        DigitRow(cells, cell: 36, size: 22, color: color, bold: bold, highlight: h ?? const {});

    final dx = parseInBase(x, 2);
    final dy = parseInBase(y, 2);
    final dres = _isAdd ? dx + dy : dx - dy;
    final sign = _isAdd ? '+' : '−';
    final check =
        '${tr('Verifica in base 10', 'Check in base 10')}: $dx $sign $dy = $dres = ${withBase(stripLeadingZeros(result), 2)}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        inputs(),
        const SizedBox(height: 14),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                SizedBox(
                    width: 70,
                    child: Text(_isAdd ? tr('riporto', 'carry') : tr('prestito', 'borrow'),
                        style: Theme.of(context).textTheme.bodySmall)),
                row(carryRow, color: context.bc.accent, bold: true),
              ]),
              Row(children: [const SizedBox(width: 70), row(aRow, h: hl)]),
              Row(children: [const SizedBox(width: 70), row(bRow, h: hl)]),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: SizedBox(
                  width: 70 + total * 36.0,
                  child: Divider(height: 2, thickness: 2, color: cs.onSurface),
                ),
              ),
              Row(children: [
                const SizedBox(width: 70),
                row(resRow, color: cs.primary, bold: true, h: hl),
              ]),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          children: [
            FilledButton.icon(
              onPressed: done ? null : () => setState(() => step++),
              icon: const Icon(Icons.skip_next),
              label: Text(tr('Passo avanti', 'Next step')),
            ),
            OutlinedButton(
              onPressed: done ? null : () => setState(() => step = n),
              child: Text(tr('Tutto', 'All')),
            ),
            OutlinedButton(
              onPressed: step == 0 ? null : () => setState(() => step = 0),
              child: Text(tr('Ricomincia', 'Restart')),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (step == 0)
          RichLine(tr('Premi **Passo avanti**: si parte dalla colonna più a destra.', 'Press **Next step**: we start from the rightmost column.'),
              size: 17)
        else
          InfoCard(
            color: cs.primaryContainer,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichLine(cols[min(step, n) - 1].text, size: 17),
                if (done) ...[
                  const SizedBox(height: 8),
                  RichLine('**$check**', size: 17),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Static multiplication layout
// ---------------------------------------------------------------------------

class MulView extends StatelessWidget {
  const MulView({super.key, required this.a, required this.b});
  final String a;
  final String b;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final r = mulBinary(a, b);
    var total = max(r.result.length, max(a.length, b.length));
    for (final row in r.rows) {
      total = max(total, row.length);
    }
    total += 1;

    Widget line() => SizedBox(
          width: total * 34.0,
          child: Divider(height: 2, thickness: 2, color: cs.onSurface),
        );

    final bRow = padCells(b, total);
    bRow[0] = '×';
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DigitRow(padCells(a, total)),
          DigitRow(bRow),
          line(),
          for (var i = 0; i < r.rows.length; i++)
            DigitRow(padCells(r.rows[i], total), color: context.bc.accent),
          line(),
          DigitRow(padCells(r.result, total), color: cs.primary, bold: true),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Static long division in binary
// ---------------------------------------------------------------------------

class DivBinView extends StatelessWidget {
  const DivBinView({super.key, required this.dividend, required this.divisor});
  final String dividend;
  final String divisor;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final r = divBinary(dividend, divisor);
    final small = Theme.of(context).textTheme.bodySmall;
    Widget head(String s) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          child: Text(s, style: small),
        );
    Widget cell(String s, {Color? color, bool bold = false}) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: Text(s,
              style: monoStyle(
                  size: 19, color: color, weight: bold ? FontWeight.bold : null)),
        );
    final dd = parseInBase(dividend, 2);
    final dv = parseInBase(divisor, 2);
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
                head(tr('$divisor sta?', 'fits $divisor?')),
                head(tr('resto', 'remainder')),
              ]),
              for (final s in r.steps)
                TableRow(children: [
                  cell(s.broughtDown),
                  cell(toBase(s.current, 2)),
                  cell(s.qBit == 1 ? tr('sì → 1', 'yes → 1') : tr('no → 0', 'no → 0'),
                      color: s.qBit == 1 ? context.bc.ok : null, bold: true),
                  cell(toBase(s.remainder, 2)),
                ]),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(tr('Quoziente ${r.quotient}, resto ${r.remainder}', 'Quotient ${r.quotient}, remainder ${r.remainder}'),
            style: monoStyle(size: 20, weight: FontWeight.bold, color: cs.primary)),
        const SizedBox(height: 4),
        Text(tr('Verifica: $dd ÷ $dv = ${dd ~/ dv}  resto ${dd % dv}', 'Check: $dd ÷ $dv = ${dd ~/ dv}  remainder ${dd % dv}'),
            style: small),
      ],
    );
  }
}
