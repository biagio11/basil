import 'package:flutter/material.dart';

import '../app/settings.dart';
import '../app/theme.dart';
import '../logic/base_conv.dart';
import 'widgets/fx.dart';

export '../app/theme.dart' show monoStyle, termStyle, pixelStyle, BasilThemeX;

const _subDigits = '₀₁₂₃₄₅₆₇₈₉';
final _mathRe = RegExp(r'\^(\(?[-−]?[0-9A-Za-zÀ-ÿ]+\)?)|([₀-₉]+)');

/// Plain text where `x^y` becomes a raised small exponent and unicode
/// subscript digits (101₂) become a lowered small base, like on paper.
List<InlineSpan> mathSpans(String s, TextStyle style) {
  if (!s.contains('^') && !s.contains(RegExp('[₀-₉]'))) {
    return [TextSpan(text: s)];
  }
  final out = <InlineSpan>[];
  final size = style.fontSize ?? 14;
  final small = style.copyWith(fontSize: size * .66, height: 1);
  var idx = 0;
  for (final m in _mathRe.allMatches(s)) {
    if (m.start > idx) out.add(TextSpan(text: s.substring(idx, m.start)));
    final sup = m.group(1);
    final text = sup != null
        ? sup.replaceAll(RegExp(r'^\(|\)$'), '')
        : m.group(2)!.split('').map((c) => _subDigits.indexOf(c).toString()).join();
    out.add(WidgetSpan(
      alignment: PlaceholderAlignment.baseline,
      baseline: TextBaseline.alphabetic,
      child: Transform.translate(
        offset: Offset(0, sup != null ? -size * .42 : size * .2),
        child: Text(text, style: small, textScaler: TextScaler.noScaling),
      ),
    ));
    idx = m.end;
  }
  if (idx < s.length) out.add(TextSpan(text: s.substring(idx)));
  return out;
}

/// A [Text] that draws exponents and bases as real small numbers.
class MathText extends StatelessWidget {
  const MathText(this.text, {super.key, this.style, this.textAlign, this.maxLines, this.overflow});
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context) {
    final st = DefaultTextStyle.of(context).style.merge(style);
    // RichText scales inline widgets itself, so the plain size goes in.
    return Text.rich(
      TextSpan(style: style, children: mathSpans(text, st)),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}

/// Tiny markup: **bold** and `code`, plus exponents and bases.
List<InlineSpan> parseRich(String s, TextStyle code, TextStyle bold, {TextStyle base = const TextStyle()}) {
  final spans = <InlineSpan>[];
  final re = RegExp(r'\*\*(.+?)\*\*|`(.+?)`');
  var idx = 0;
  for (final m in re.allMatches(s)) {
    if (m.start > idx) spans.addAll(mathSpans(s.substring(idx, m.start), base));
    final b = m.group(1);
    final mono = m.group(2);
    if (b != null) {
      spans.add(TextSpan(style: bold, children: mathSpans(b, base.merge(bold))));
    } else {
      spans.add(TextSpan(style: code, children: mathSpans(mono!, base.merge(code))));
    }
    idx = m.end;
  }
  if (idx < s.length) spans.addAll(mathSpans(s.substring(idx), base));
  return spans;
}

class RichLine extends StatelessWidget {
  const RichLine(this.text,
      {super.key, this.size = 17, this.align = TextAlign.start, this.color});
  final String text;
  final double size;
  final TextAlign align;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final base = (theme.textTheme.bodyLarge ?? const TextStyle())
        .copyWith(fontSize: size, height: 1.5, color: color);
    final code = monoStyle(
            size: size, weight: FontWeight.w700, color: theme.colorScheme.primary)
        .copyWith(backgroundColor: theme.colorScheme.primary.withAlpha(22));
    final bold = TextStyle(
        fontWeight: FontWeight.w800, color: color ?? theme.colorScheme.onSurface);
    return Text.rich(
      TextSpan(style: base, children: parseRich(text, code, bold, base: base)),
      textAlign: align,
    );
  }
}

/// A card with a soft tinted background.
class InfoCard extends StatelessWidget {
  const InfoCard({super.key, required this.child, this.color, this.padding, this.border});
  final Widget child;
  final Color? color;
  final EdgeInsets? padding;
  final Color? border;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color ?? context.bc.panelHi,
        borderRadius: appLook.br(6),
        border: Border.all(color: border ?? context.cs.outlineVariant),
      ),
      child: child,
    );
  }
}

List<String> padCells(String s, int total) => s.padLeft(total, ' ').split('');

/// A row of fixed-width character cells (keeps digits aligned in columns).
class DigitRow extends StatelessWidget {
  const DigitRow(
    this.cells, {
    super.key,
    this.cell = 34,
    this.size = 22,
    this.color,
    this.bold = false,
    this.highlight = const {},
  });
  final List<String> cells;
  final double cell;
  final double size;
  final Color? color;
  final bool bold;
  final Map<int, Color> highlight;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < cells.length; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: cell,
            height: cell * 1.2,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: highlight[i] ?? Colors.transparent,
              borderRadius: appLook.br(4),
            ),
            child: Text(
              cells[i],
              style: monoStyle(
                size: size,
                color: color,
                weight: bold ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Quiz (A/B/C/D)
// ---------------------------------------------------------------------------

class QuizCard extends StatefulWidget {
  const QuizCard({
    super.key,
    required this.question,
    required this.options,
    required this.correct,
    required this.explanation,
    this.classMode = false,
  });
  final String question;
  final List<String> options;
  final int correct;
  final String explanation;

  /// In class mode options are not tappable: the teacher polls the class
  /// and then reveals the answer.
  final bool classMode;

  @override
  State<QuizCard> createState() => _QuizCardState();
}

class _QuizCardState extends State<QuizCard> {
  int? _selected;
  bool _revealed = false;
  int _shake = 0;

  @override
  Widget build(BuildContext context) {
    const letters = ['A', 'B', 'C', 'D', 'E', 'F'];
    final canTap = !widget.classMode && !_revealed;
    final right = _selected == widget.correct;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichLine(widget.question, size: 19),
        const SizedBox(height: 16),
        Shake(
          trigger: _shake,
          child: Column(children: [
            for (var i = 0; i < widget.options.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _optionTile(context, i, letters[i], canTap),
              ),
          ]),
        ),
        const SizedBox(height: 4),
        if (widget.classMode && !_revealed)
          FilledButton.icon(
            onPressed: () => setState(() => _revealed = true),
            icon: const Icon(Icons.visibility),
            label: Text(tr('Rivela risposta', 'Reveal answer')),
          ),
        if (_revealed) ...[
          const SizedBox(height: 6),
          Appear(
            child: InfoCard(
              color: (_selected == null || right ? context.bc.ok : context.bc.bad)
                  .withAlpha(28),
              border: _selected == null || right ? context.bc.ok : context.bc.bad,
              child: RichLine(
                (_selected == null
                        ? ''
                        : right
                            ? tr('**Esatto!** ', '**Correct!** ')
                            : tr('**Non proprio.** ', '**Not quite.** ')) +
                    tr('Risposta giusta: **${letters[widget.correct]}**. ',
                        'Right answer: **${letters[widget.correct]}**. ') +
                    widget.explanation,
                size: 16,
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => setState(() {
              _revealed = false;
              _selected = null;
            }),
            icon: const Icon(Icons.refresh),
            label: Text(tr('Riprova', 'Try again')),
          ),
        ],
      ],
    );
  }

  Widget _optionTile(BuildContext context, int i, String letter, bool canTap) {
    final cs = context.cs;
    final bc = context.bc;
    Color bg = bc.panelHi;
    Color border = cs.outlineVariant;
    IconData? icon;
    if (_revealed) {
      if (i == widget.correct) {
        bg = bc.ok.withAlpha(36);
        border = bc.ok;
        icon = Icons.check_circle;
      } else if (i == _selected) {
        bg = bc.bad.withAlpha(36);
        border = bc.bad;
        icon = Icons.cancel;
      }
    }
    return Material(
      color: bg,
      shape: RoundedRectangleBorder(
        borderRadius: appLook.br(6),
        side: BorderSide(color: border, width: 1.5),
      ),
      child: InkWell(
        borderRadius: appLook.br(6),
        onTap: canTap
            ? () {
                final ok = i == widget.correct;
                ok ? hapticOk() : hapticBad();
                setState(() {
                  _selected = i;
                  _revealed = true;
                  if (!ok) _shake++;
                });
              }
            : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: cs.primary,
                  borderRadius: appLook.br(4),
                ),
                child: Text(letter,
                    style: pixelStyle(size: 13, color: cs.onPrimary)),
              ),
              const SizedBox(width: 14),
              Expanded(child: RichLine(widget.options[i], size: 18)),
              if (icon != null)
                Icon(icon, color: i == widget.correct ? bc.ok : bc.bad),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// base b -> 10 : digit × b^position
// ---------------------------------------------------------------------------

class PowerTable extends StatelessWidget {
  const PowerTable({
    super.key,
    required this.digits,
    required this.base,
    this.stage = 4,
    this.showSum = true,
  });

  /// 0: digits, 1: + positions, 2: + weights, 3: + digit × weight, 4: + sum.
  final int stage;
  final String digits;
  final int base;
  final bool showSum;

  @override
  Widget build(BuildContext context) {
    final terms = expansionTerms(digits, base);
    final total = terms.fold<BigInt>(BigInt.zero, (a, t) => a + t.product);
    final cs = context.cs;
    final small = Theme.of(context).textTheme.bodySmall;
    final wide = terms.any((t) => t.product.toString().length > 6);

    Widget cellText(String s, {Color? color, bool bold = false, double size = 17}) {
      return Container(
        constraints: BoxConstraints(minWidth: wide ? 84 : 58),
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        alignment: Alignment.center,
        child: MathText(s,
            style: monoStyle(
                size: size,
                color: color,
                weight: bold ? FontWeight.w800 : FontWeight.w500)),
      );
    }

    Widget label(String s) => SizedBox(
          width: 112,
          height: 38,
          child: Align(alignment: Alignment.centerLeft, child: MathText(s, style: small)),
        );

    Widget rowFor(int visibleFrom, String lab, List<Widget> cells) {
      return AnimatedOpacity(
        opacity: stage >= visibleFrom ? 1 : 0,
        duration: const Duration(milliseconds: 250),
        child: Row(children: [label(lab), ...cells]),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              rowFor(0, tr('cifra', 'digit'), [
                for (final t in terms)
                  cellText(t.digitVal >= 10 ? '${t.digit}=${t.digitVal}' : t.digit,
                      bold: true, color: cs.primary, size: t.digitVal >= 10 ? 16 : 22),
              ]),
              rowFor(1, tr('posizione', 'position'), [
                for (final t in terms) cellText('${t.position}'),
              ]),
              rowFor(2, tr('peso ($base^pos)', 'weight ($base^pos)'), [
                for (final t in terms) cellText('${t.weight}'),
              ]),
              rowFor(3, tr('cifra × peso', 'digit × weight'), [
                for (final t in terms)
                  cellText('${t.product}', color: context.bc.accent, bold: true),
              ]),
            ],
          ),
        ),
        if (showSum) ...[
          const SizedBox(height: 6),
          AnimatedOpacity(
            opacity: stage >= 4 ? 1 : 0,
            duration: const Duration(milliseconds: 250),
            child: Text(
              '${terms.map((t) => t.product).join(' + ')} = $total',
              style: monoStyle(size: 18, weight: FontWeight.w800),
            ),
          ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// base 10 -> b : repeated division
// ---------------------------------------------------------------------------

class DivisionTable extends StatelessWidget {
  const DivisionTable({
    super.key,
    required this.number,
    required this.base,
    this.upTo,
    this.showResult = false,
  });
  final BigInt number;
  final int base;

  /// Index of the last division to show (null = all).
  final int? upTo;
  final bool showResult;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final accent = context.bc.accent;
    final steps = divisionSteps(number, base);
    final count = ((upTo ?? steps.length - 1) + 1).clamp(0, steps.length).toInt();
    final shown = steps.take(count).toList();
    final result = toBase(number, base);

    TextStyle st({Color? color, bool bold = false}) =>
        monoStyle(size: 18, color: color, weight: bold ? FontWeight.w800 : null);

    Widget cell(String s, TextStyle style) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          child: Text(s, style: style),
        );

    final rows = <TableRow>[];
    for (var i = 0; i < shown.length; i++) {
      final s = shown[i];
      final isLast = i == shown.length - 1 && !showResult;
      final rColor = showResult || isLast ? accent : null;
      final rText = s.remainder >= 10
          ? '${s.remainder} (${digitChar(s.remainder)})'
          : '${s.remainder}';
      rows.add(TableRow(
        decoration: isLast
            ? BoxDecoration(
                color: cs.primaryContainer.withAlpha(140),
                borderRadius: appLook.br(4),
              )
            : null,
        children: [
          cell('${s.dividend}', st(bold: isLast)),
          cell('÷ ${s.base}', st()),
          cell('= ${s.quotient}', st(bold: isLast)),
          cell(tr('resto ', 'rem ') + rText, st(color: rColor, bold: true)),
        ],
      ));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Table(defaultColumnWidth: const IntrinsicColumnWidth(), children: rows),
              if (showResult && shown.length > 1)
                Padding(
                  padding: const EdgeInsets.only(left: 4, top: 6),
                  child: Column(
                    children: [
                      Icon(Icons.arrow_upward, color: accent, size: 18),
                      Container(
                          width: 2, height: (shown.length - 1) * 30.0, color: accent),
                    ],
                  ),
                ),
            ],
          ),
        ),
        if (showResult) ...[
          const SizedBox(height: 8),
          Text(
            tr('Leggi i resti dal basso verso l’alto', 'Read the remainders from bottom to top'),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 4),
          MathText(
            '$number = ${withBase(result, base)}',
            style: monoStyle(size: 21, weight: FontWeight.w800, color: cs.primary),
          ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Grouping strip (2 <-> 4 / 8 / 16 / 32)
// ---------------------------------------------------------------------------

class GroupStrip extends StatelessWidget {
  const GroupStrip(this.mapping, {super.key});
  final GroupMapping mapping;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final n = mapping.digits.length;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < n; i++)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: cs.primaryContainer.withAlpha(context.isDark ? 120 : 255),
                borderRadius: appLook.br(5),
                border: Border.all(color: cs.primary.withAlpha(90)),
              ),
              child: Column(
                children: [
                  Text(
                    mapping.toBinary ? mapping.digits[i] : mapping.bitGroups[i],
                    style: monoStyle(size: 19, weight: FontWeight.w800),
                  ),
                  Icon(Icons.arrow_downward, size: 16, color: cs.onSurfaceVariant),
                  Text(
                    mapping.toBinary ? mapping.bitGroups[i] : mapping.digits[i],
                    style: monoStyle(
                        size: 19, weight: FontWeight.w800, color: context.bc.accent),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Small label above a block of an explanation ("STEP 1 · ...").
class StepLabel extends StatelessWidget {
  const StepLabel(this.text, {super.key, this.n});
  final String text;
  final int? n;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 10),
      child: Row(
        children: [
          if (n != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: cs.primary,
                borderRadius: appLook.br(3),
              ),
              child: Text('${tr('PASSO', 'STEP')} $n',
                  style: pixelStyle(size: 9, color: cs.onPrimary)),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: MathText(text,
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}
