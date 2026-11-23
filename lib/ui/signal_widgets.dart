import 'dart:math';

import 'package:flutter/material.dart';

import '../app/settings.dart';
import 'common.dart';
import 'widgets/pixel_leaf.dart';

// ---------------------------------------------------------------------------
// Analog vs digital
// ---------------------------------------------------------------------------

/// One slider moves an analog needle (smooth) and a digital display
/// (in steps), so the difference is visible at a glance.
class AnalogDigital extends StatefulWidget {
  const AnalogDigital({super.key});

  @override
  State<AnalogDigital> createState() => _AnalogDigitalState();
}

class _AnalogDigitalState extends State<AnalogDigital> {
  double v = 21.37;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final label = pixelStyle(size: 10, color: cs.onSurfaceVariant);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(children: [
                Text(tr('ANALOGICO', 'ANALOG'), style: label),
                const SizedBox(height: 8),
                SizedBox(
                  height: 96,
                  width: double.infinity,
                  child: CustomPaint(painter: _GaugePainter(v / 40, cs.primary, cs.outline, context.bc.accent)),
                ),
                Text(tr('passa per tutti i valori', 'goes through every value'),
                    textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
              ]),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(children: [
                Text(tr('DIGITALE', 'DIGITAL'), style: label),
                const SizedBox(height: 8),
                Container(
                  height: 96,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: context.bc.panelHi,
                    borderRadius: appLook.br(6),
                    border: Border.all(color: cs.outlineVariant),
                  ),
                  child: Text('${v.round()}°', style: termStyle(size: 56, color: cs.primary)),
                ),
                const SizedBox(height: 4),
                Text(tr('va a passi', 'moves in steps'),
                    textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
              ]),
            ),
          ],
        ),
        Slider(value: v, min: 0, max: 40, onChanged: (x) => setState(() => v = x)),
        Text(
          tr('Temperatura vera: ${v.toStringAsFixed(2)}°. Il display mostra solo numeri interi.',
              'Real temperature: ${v.toStringAsFixed(2)}°. The display only shows whole numbers.'),
          style: monoStyle(size: 13, color: cs.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _GaugePainter extends CustomPainter {
  _GaugePainter(this.t, this.color, this.line, this.needle);
  final double t;
  final Color color;
  final Color line;
  final Color needle;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height - 8);
    final r = min(size.width / 2 - 8, size.height - 16);
    final arc = Paint()
      ..color = line
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawArc(Rect.fromCircle(center: c, radius: r), pi, pi, false, arc);
    final tick = Paint()
      ..color = color.withAlpha(160)
      ..strokeWidth = 2;
    for (var i = 0; i <= 8; i++) {
      final a = pi + pi * i / 8;
      final o = c + Offset(cos(a), sin(a)) * r;
      final inner = c + Offset(cos(a), sin(a)) * (r - (i.isEven ? 10 : 6));
      canvas.drawLine(inner, o, tick);
    }
    final a = pi + pi * t.clamp(0, 1);
    final p = Paint()
      ..color = needle
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(c, c + Offset(cos(a), sin(a)) * (r - 4), p);
    canvas.drawCircle(c, 5, Paint()..color = needle);
  }

  @override
  bool shouldRepaint(_GaugePainter old) => old.t != t || old.color != color;
}

// ---------------------------------------------------------------------------
// From signal to numbers
// ---------------------------------------------------------------------------

/// The signal used in class: a smooth curve from t = 0 to t = 12.
const _knots = <Offset>[
  Offset(0, 1.7), Offset(.5, 2.6), Offset(1, 3.1), Offset(1.5, 3.45), Offset(2, 3.8),
  Offset(2.35, 3.85), Offset(3, 2.8), Offset(3.5, 1.6), Offset(4.1, .75), Offset(5, 2.1),
  Offset(6, 3.85), Offset(7, 5.05), Offset(8, 6.25), Offset(9, 4.75), Offset(9.7, 3.95),
  Offset(10, 4.1), Offset(11, 5.3), Offset(12, 5.85),
];

/// Value of the signal at time [t] (Catmull Rom through the knots).
double signalAt(double t) {
  t = t.clamp(0, 12);
  var i = 0;
  while (i < _knots.length - 2 && _knots[i + 1].dx < t) {
    i++;
  }
  final p1 = _knots[i], p2 = _knots[i + 1];
  final p0 = i > 0 ? _knots[i - 1] : p1;
  final p3 = i + 2 < _knots.length ? _knots[i + 2] : p2;
  final u = (t - p1.dx) / (p2.dx - p1.dx);
  // Tangents scaled to the uneven spacing of the knots.
  final m1 = (p2.dy - p0.dy) / (p2.dx - p0.dx == 0 ? 1 : p2.dx - p0.dx) * (p2.dx - p1.dx);
  final m2 = (p3.dy - p1.dy) / (p3.dx - p1.dx == 0 ? 1 : p3.dx - p1.dx) * (p2.dx - p1.dx);
  final u2 = u * u, u3 = u2 * u;
  return (2 * u3 - 3 * u2 + 1) * p1.dy + (u3 - 2 * u2 + u) * m1 + (-2 * u3 + 3 * u2) * p2.dy + (u3 - u2) * m2;
}

/// Samples and quantised levels for a grid step of 1 (fine = false) or 1/2.
({List<double> t, List<double> raw, List<int> level, int bits}) sampleSignal({bool fine = false}) {
  final n = fine ? 24 : 12;
  final step = fine ? .5 : 1.0;
  final t = [for (var k = 1; k <= n; k++) k * step];
  final raw = [for (final x in t) signalAt(x)];
  // Round half up, as in class: at the middle line or above, go up.
  final level = [for (final r in raw) (r / step + 1e-9).floor() + ((r / step) % 1 >= .5 - 1e-9 ? 1 : 0)];
  return (t: t, raw: raw, level: level, bits: fine ? 4 : 3);
}

/// Step by step: signal, grid, sampling, quantisation, numbers.
class SignalLab extends StatefulWidget {
  const SignalLab({super.key, this.initialStep = 0, this.showResolution = true});
  final int initialStep;
  final bool showResolution;

  @override
  State<SignalLab> createState() => _SignalLabState();
}

class _SignalLabState extends State<SignalLab> {
  late int step = widget.initialStep;
  bool fine = false;
  bool bars = false;

  static List<(String, String)> get _names => [
        (tr('Segnale', 'Signal'), tr('Il tempo in orizzontale, il valore in verticale.', 'Time across, value up.')),
        (tr('Griglia', 'Grid'), tr('Quadretti di lato u, nel tempo e nel valore.', 'Squares of side u, in time and in value.')),
        (tr('Campioni', 'Samples'),
            tr('Misuriamo la curva alla fine di ogni intervallo: u, 2u, 3u…', 'We measure the curve at the end of each step: u, 2u, 3u…')),
        (tr('Quantizza', 'Quantise'),
            tr('Ogni campione va alla riga più vicina. A metà o sopra si sale.', 'Each sample goes to the nearest line. Halfway or above goes up.')),
        (tr('Numeri', 'Numbers'),
            tr('Restano solo numeri, che scriviamo in binario.', 'Only numbers are left, and we write them in binary.')),
      ];

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final s = sampleSignal(fine: fine);
    final names = _names;
    final total = s.level.length * s.bits;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [
            for (var i = 0; i < names.length; i++)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ChoiceChip(
                  label: Text('${i + 1}. ${names[i].$1}'),
                  selected: step == i,
                  showCheckmark: false,
                  onSelected: (_) => setState(() => step = i),
                ),
              ),
          ]),
        ),
        const SizedBox(height: 8),
        AspectRatio(
          aspectRatio: 1.9,
          child: Container(
            decoration: BoxDecoration(
              color: context.bc.panel,
              borderRadius: appLook.br(6),
              border: Border.all(color: cs.outlineVariant),
            ),
            child: ClipRRect(
              borderRadius: appLook.br(6),
              child: CustomPaint(
                painter: _SignalPainter(
                  step: step,
                  fine: fine,
                  bars: bars,
                  samples: s,
                  curve: const Color(0xFFE5484D),
                  grid: cs.outlineVariant,
                  half: cs.outline.withAlpha(110),
                  dot: context.bc.ok,
                  ink: cs.onSurface,
                  muted: cs.onSurfaceVariant,
                  accent: cs.primary,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: Text(names[step].$2, style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant))),
          IconButton(
            tooltip: tr('Indietro', 'Back'),
            onPressed: step == 0 ? null : () => setState(() => step--),
            icon: const Icon(Icons.chevron_left),
          ),
          IconButton.filledTonal(
            tooltip: tr('Avanti', 'Next'),
            onPressed: step == names.length - 1 ? null : () => setState(() => step++),
            icon: const Icon(Icons.chevron_right),
          ),
        ]),
        if (widget.showResolution || step == 4)
          Wrap(spacing: 8, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
            if (widget.showResolution) ...[
              ChoiceChip(
                label: Text(tr('quadretto u', 'square u')),
                selected: !fine,
                onSelected: (_) => setState(() => fine = false),
              ),
              ChoiceChip(
                label: Text(tr('quadretto u/2', 'square u/2')),
                selected: fine,
                onSelected: (_) => setState(() => fine = true),
              ),
            ],
            if (step == 4)
              FilterChip(
                label: Text(tr('istogramma', 'bar chart')),
                selected: bars,
                onSelected: (v) => setState(() => bars = v),
              ),
          ]),
        if (step >= 3) ...[
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Table(
              defaultColumnWidth: const IntrinsicColumnWidth(),
              border: TableBorder.all(color: cs.outlineVariant),
              children: [
                _row(context, tr('campione', 'sample'), [for (var i = 1; i <= s.level.length; i++) '$i'], head: true),
                _row(context, tr('valore', 'value'), [for (final l in s.level) '$l']),
                if (step == 4)
                  _row(context, tr('binario', 'binary'),
                      [for (final l in s.level) l.toRadixString(2).padLeft(s.bits, '0')],
                      color: cs.primary),
              ],
            ),
          ),
          const SizedBox(height: 8),
          RichLine(
            tr('**${s.level.length} campioni**, livelli da 0 a ${(1 << s.bits) - 1}, quindi **${s.bits} bit** per '
                    'campione: **$total bit** in tutto.',
                '**${s.level.length} samples**, levels 0 to ${(1 << s.bits) - 1}, so **${s.bits} bits** per sample: '
                    '**$total bits** in total.'),
            size: 15,
          ),
        ],
      ],
    );
  }

  TableRow _row(BuildContext context, String name, List<String> cells, {bool head = false, Color? color}) {
    final cs = context.cs;
    Widget c(String t, {bool first = false}) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
          child: Text(t,
              style: first
                  ? pixelStyle(size: 9, color: cs.onSurfaceVariant)
                  : monoStyle(
                      size: 13,
                      weight: head ? FontWeight.w500 : FontWeight.w800,
                      color: head ? cs.onSurfaceVariant : (color ?? cs.onSurface))),
        );
    return TableRow(children: [c(name.toUpperCase(), first: true), for (final t in cells) c(t)]);
  }
}

class _SignalPainter extends CustomPainter {
  _SignalPainter({
    required this.step,
    required this.fine,
    required this.bars,
    required this.samples,
    required this.curve,
    required this.grid,
    required this.half,
    required this.dot,
    required this.ink,
    required this.muted,
    required this.accent,
  });
  final int step;
  final bool fine;
  final bool bars;
  final ({List<double> t, List<double> raw, List<int> level, int bits}) samples;
  final Color curve, grid, half, dot, ink, muted, accent;

  @override
  void paint(Canvas canvas, Size size) {
    const left = 26.0, bottom = 20.0, top = 8.0, right = 10.0;
    final w = size.width - left - right;
    final h = size.height - top - bottom;
    Offset at(double t, double v) => Offset(left + t / 12 * w, top + h - v / 7.5 * h);
    final unit = fine ? .5 : 1.0;

    final label = TextStyle(color: muted, fontSize: 9, fontFamily: 'JetBrainsMono');
    void text(String s, Offset o, {TextAlign align = TextAlign.center, TextStyle? st}) {
      final tp = TextPainter(text: TextSpan(text: s, style: st ?? label), textDirection: TextDirection.ltr)..layout();
      final dx = align == TextAlign.center ? -tp.width / 2 : (align == TextAlign.right ? -tp.width : 0);
      tp.paint(canvas, o + Offset(dx.toDouble(), -tp.height / 2));
    }

    // Axes and labels.
    final axis = Paint()
      ..color = muted
      ..strokeWidth = 1;
    canvas.drawLine(at(0, 0), at(12, 0), axis);
    canvas.drawLine(at(0, 0), at(0, 7.5), axis);
    for (var v = 0; v <= 7; v++) {
      text('$v', at(0, v.toDouble()) - const Offset(8, 0), align: TextAlign.right);
    }
    for (var t = 0; t <= 12; t += 2) {
      text(t == 0 ? '0' : '${t}u', at(t.toDouble(), 0) + const Offset(0, 10));
    }

    // Grid.
    if (step >= 1) {
      final g = Paint()
        ..color = grid
        ..strokeWidth = 1;
      for (double t = unit; t <= 12.001; t += unit) {
        canvas.drawLine(at(t, 0), at(t, 7.5), g);
      }
      for (double v = unit; v <= 7.501; v += unit) {
        canvas.drawLine(at(0, v), at(12, v), g);
      }
      if (step == 3) {
        final d = Paint()
          ..color = half
          ..strokeWidth = 1;
        for (double v = unit / 2; v <= 7.5; v += unit) {
          for (double x = 0; x < 12; x += .25) {
            canvas.drawLine(at(x, v), at(x + .12, v), d);
          }
        }
      }
      // The little arrow for u.
      final p0 = at(0, 0) + const Offset(0, -10), p1 = at(unit, 0) + const Offset(0, -10);
      final ap = Paint()
        ..color = ink
        ..strokeWidth = 1.2;
      canvas.drawLine(p0, p1, ap);
      text(fine ? 'u/2' : 'u', Offset((p0.dx + p1.dx) / 2 + 8, p0.dy - 8), st: label.copyWith(color: ink, fontWeight: FontWeight.w800));
    }

    // The curve (faint once it has been replaced by numbers).
    final path = Path();
    for (var i = 0; i <= 240; i++) {
      final t = i / 20;
      final p = at(t, signalAt(t));
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(
        path,
        Paint()
          ..color = step >= 4 ? curve.withAlpha(80) : curve
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2);

    final n = samples.t.length;
    // Samples.
    if (step >= 2 && step < 4) {
      final dash = Paint()
        ..color = dot.withAlpha(150)
        ..strokeWidth = 1;
      for (var i = 0; i < n; i++) {
        final p = at(samples.t[i], samples.raw[i]);
        if (step == 2) {
          for (double y = p.dy; y < at(0, 0).dy; y += 5) {
            canvas.drawLine(Offset(p.dx, y), Offset(p.dx, min(y + 2.5, at(0, 0).dy)), dash);
          }
        }
        canvas.drawCircle(p, fine ? 2.6 : 3.4, Paint()..color = dot);
      }
    }
    // Quantised points.
    if (step == 3) {
      for (var i = 0; i < n; i++) {
        final q = at(samples.t[i], samples.level[i] * unit);
        canvas.drawRect(Rect.fromCenter(center: q, width: 6, height: 6), Paint()..color = ink);
        if (!fine) text('${samples.level[i]}', q + const Offset(0, -10), st: label.copyWith(color: ink, fontWeight: FontWeight.w800));
      }
    }
    // Staircase or bars.
    if (step == 4) {
      if (bars) {
        final bw = w / 12 * unit * .6;
        for (var i = 0; i < n; i++) {
          final q = at(samples.t[i], samples.level[i] * unit);
          canvas.drawRect(Rect.fromLTRB(q.dx - bw / 2, q.dy, q.dx + bw / 2, at(0, 0).dy), Paint()..color = accent.withAlpha(200));
        }
      } else {
        final st = Path();
        for (var i = 0; i < n; i++) {
          final v = samples.level[i] * unit;
          final a = at(samples.t[i] - unit, v), b = at(samples.t[i], v);
          i == 0 ? st.moveTo(a.dx, a.dy) : st.lineTo(a.dx, a.dy);
          st.lineTo(b.dx, b.dy);
        }
        canvas.drawPath(
            st,
            Paint()
              ..color = ink
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2);
        for (var i = 0; i < n; i++) {
          canvas.drawRect(Rect.fromCenter(center: at(samples.t[i], samples.level[i] * unit), width: 5, height: 5),
              Paint()..color = ink);
        }
      }
    }
  }

  @override
  bool shouldRepaint(_SignalPainter old) =>
      old.step != step || old.fine != fine || old.bars != bars || old.ink != ink || old.accent != accent;
}

// ---------------------------------------------------------------------------
// Images: pixels and colour depth
// ---------------------------------------------------------------------------

/// The basil leaf as a tiny image: fewer pixels or fewer colours make it
/// worse but smaller. Tap a pixel to read its colour code.
class PixelLab extends StatefulWidget {
  const PixelLab({super.key});

  @override
  State<PixelLab> createState() => _PixelLabState();
}

class _PixelLabState extends State<PixelLab> {
  int res = 16; // 16, 8 or 4 pixels per side
  int depth = 24; // 1, 2, 8 or 24 bits per pixel
  (int, int)? picked;

  List<List<Color>> _image(Color bg) {
    final pal = leafPalette(false, const Look());
    final full = [
      for (final row in kLeafGrid) [for (final ch in row.split('')) pal[ch] ?? bg]
    ];
    final k = 16 ~/ res;
    final out = <List<Color>>[];
    for (var y = 0; y < res; y++) {
      final row = <Color>[];
      for (var x = 0; x < res; x++) {
        var r = 0.0, g = 0.0, b = 0.0;
        for (var dy = 0; dy < k; dy++) {
          for (var dx = 0; dx < k; dx++) {
            final c = full[y * k + dy][x * k + dx];
            r += c.r;
            g += c.g;
            b += c.b;
          }
        }
        final m = (k * k).toDouble();
        row.add(_reduce(Color.from(alpha: 1, red: r / m, green: g / m, blue: b / m)));
      }
      out.add(row);
    }
    return out;
  }

  Color _reduce(Color c) {
    if (depth == 24) return c;
    final lum = .299 * c.r + .587 * c.g + .114 * c.b;
    if (depth == 1) return lum > .55 ? Colors.white : Colors.black;
    if (depth == 2) {
      final l = (lum * 3).round() / 3;
      return Color.from(alpha: 1, red: l, green: l, blue: l);
    }
    // 8 bit: 3 bits red, 3 green, 2 blue.
    double q(double v, int levels) => (v * (levels - 1)).round() / (levels - 1);
    return Color.from(alpha: 1, red: q(c.r, 8), green: q(c.g, 8), blue: q(c.b, 4));
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    const bg = Color(0xFFF4F1E8);
    final img = _image(bg);
    final bits = res * res * depth;
    final p = picked;
    final pc = p == null || p.$1 >= res || p.$2 >= res ? null : img[p.$2][p.$1];
    String hex(Color c) =>
        '#${[c.r, c.g, c.b].map((v) => (v * 255).round().toRadixString(16).padLeft(2, '0')).join().toUpperCase()}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 152,
              height: 152,
              child: LayoutBuilder(builder: (context, c) {
                final cell = c.maxWidth / res;
                return GestureDetector(
                  onTapDown: (d) => setState(() => picked = (
                        (d.localPosition.dx / cell).floor().clamp(0, res - 1),
                        (d.localPosition.dy / cell).floor().clamp(0, res - 1),
                      )),
                  child: CustomPaint(
                    size: Size.square(c.maxWidth),
                    painter: _PixelsPainter(img, p, cs.primary),
                  ),
                );
              }),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$res × $res = ${res * res} pixel', style: monoStyle(size: 14, weight: FontWeight.w700)),
                  Text('× $depth bit', style: monoStyle(size: 14, weight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text('= $bits bit', style: monoStyle(size: 17, weight: FontWeight.w800, color: cs.primary)),
                  Text('= ${bits / 8 == (bits ~/ 8) ? bits ~/ 8 : (bits / 8).toStringAsFixed(1)} byte',
                      style: monoStyle(size: 14, color: cs.onSurfaceVariant)),
                  const SizedBox(height: 10),
                  if (pc != null) ...[
                    Row(children: [
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: pc,
                          border: Border.all(color: cs.outline),
                          borderRadius: appLook.br(3),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(hex(pc), style: monoStyle(size: 15, weight: FontWeight.w800)),
                    ]),
                    Text('pixel (${p!.$1}, ${p.$2})',
                        style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                  ] else
                    Text(tr('Tocca un pixel per leggere il suo colore.', 'Tap a pixel to read its colour.'),
                        style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(tr('Risoluzione', 'Resolution'), style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Wrap(spacing: 8, children: [
          for (final r in const [16, 8, 4])
            ChoiceChip(
              label: Text('$r × $r'),
              selected: res == r,
              onSelected: (_) => setState(() {
                res = r;
                picked = null;
              }),
            ),
        ]),
        const SizedBox(height: 8),
        Text(tr('Profondità di colore', 'Colour depth'), style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Wrap(spacing: 8, runSpacing: 6, children: [
          for (final (d, it, en) in const [
            (1, '1 bit · 2 colori', '1 bit · 2 colours'),
            (2, '2 bit · 4 grigi', '2 bits · 4 greys'),
            (8, '8 bit · 256 colori', '8 bits · 256 colours'),
            (24, '24 bit · 16 milioni', '24 bits · 16 million'),
          ])
            ChoiceChip(
              label: Text(tr(it, en)),
              selected: depth == d,
              onSelected: (_) => setState(() => depth = d),
            ),
        ]),
      ],
    );
  }
}

class _PixelsPainter extends CustomPainter {
  _PixelsPainter(this.img, this.picked, this.mark);
  final List<List<Color>> img;
  final (int, int)? picked;
  final Color mark;

  @override
  void paint(Canvas canvas, Size size) {
    final n = img.length;
    final cell = size.width / n;
    final p = Paint()..isAntiAlias = false;
    for (var y = 0; y < n; y++) {
      for (var x = 0; x < n; x++) {
        p.color = img[y][x];
        canvas.drawRect(Rect.fromLTWH(x * cell, y * cell, cell + .5, cell + .5), p);
      }
    }
    if (n <= 16) {
      final g = Paint()
        ..color = const Color(0x22000000)
        ..strokeWidth = 1;
      for (var i = 1; i < n; i++) {
        canvas.drawLine(Offset(i * cell, 0), Offset(i * cell, size.height), g);
        canvas.drawLine(Offset(0, i * cell), Offset(size.width, i * cell), g);
      }
    }
    final pk = picked;
    if (pk != null && pk.$1 < n && pk.$2 < n) {
      canvas.drawRect(
          Rect.fromLTWH(pk.$1 * cell, pk.$2 * cell, cell, cell),
          Paint()
            ..color = mark
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5);
    }
    canvas.drawRect(
        Offset.zero & size,
        Paint()
          ..color = const Color(0x44000000)
          ..style = PaintingStyle.stroke);
  }

  @override
  bool shouldRepaint(_PixelsPainter old) => true;
}

// ---------------------------------------------------------------------------
// Colours in base 16
// ---------------------------------------------------------------------------

/// Three sliders for red, green and blue, with the colour written in base 16
/// and in binary.
class ColorMixer extends StatefulWidget {
  const ColorMixer({super.key});

  @override
  State<ColorMixer> createState() => _ColorMixerState();
}

class _ColorMixerState extends State<ColorMixer> {
  int r = 0x3D, g = 0xFF, b = 0x7A;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final color = Color.fromARGB(255, r, g, b);
    String h(int v) => v.toRadixString(16).padLeft(2, '0').toUpperCase();
    Widget slider(String name, int v, Color c, ValueChanged<int> f) => Row(children: [
          SizedBox(width: 18, child: Text(name, style: monoStyle(size: 14, weight: FontWeight.w800, color: c))),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(activeTrackColor: c, thumbColor: c),
              child: Slider(value: v.toDouble(), min: 0, max: 255, divisions: 255, onChanged: (x) => f(x.round())),
            ),
          ),
          SizedBox(width: 36, child: Text('$v', textAlign: TextAlign.right, style: monoStyle(size: 14))),
          const SizedBox(width: 8),
          Text(h(v), style: monoStyle(size: 15, weight: FontWeight.w800, color: c)),
        ]);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: color,
              borderRadius: appLook.br(8),
              border: Border.all(color: cs.outline),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text.rich(TextSpan(style: termStyle(size: 36), children: [
                TextSpan(text: '#', style: TextStyle(color: cs.onSurfaceVariant)),
                TextSpan(text: h(r), style: const TextStyle(color: Color(0xFFE5484D))),
                TextSpan(text: h(g), style: const TextStyle(color: Color(0xFF30A46C))),
                TextSpan(text: h(b), style: const TextStyle(color: Color(0xFF3E63DD))),
              ])),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  '${r.toRadixString(2).padLeft(8, '0')} ${g.toRadixString(2).padLeft(8, '0')} ${b.toRadixString(2).padLeft(8, '0')}',
                  style: monoStyle(size: 12, color: cs.onSurfaceVariant),
                ),
              ),
            ]),
          ),
        ]),
        const SizedBox(height: 8),
        slider('R', r, const Color(0xFFE5484D), (v) => setState(() => r = v)),
        slider('G', g, const Color(0xFF30A46C), (v) => setState(() => g = v)),
        slider('B', b, const Color(0xFF3E63DD), (v) => setState(() => b = v)),
        const SizedBox(height: 4),
        Wrap(spacing: 8, runSpacing: 6, children: [
          for (final (name, c) in [
            (tr('rosso', 'red'), 0xFF0000),
            (tr('verde', 'green'), 0x00FF00),
            (tr('blu', 'blue'), 0x0000FF),
            (tr('giallo', 'yellow'), 0xFFFF00),
            (tr('bianco', 'white'), 0xFFFFFF),
            (tr('nero', 'black'), 0x000000),
          ])
            ActionChip(
              label: Text(name),
              onPressed: () => setState(() {
                r = c >> 16 & 255;
                g = c >> 8 & 255;
                b = c & 255;
              }),
            ),
        ]),
      ],
    );
  }
}
