import 'package:flutter/material.dart';

import '../app/settings.dart';
import '../logic/signed.dart';
import 'common.dart';
import 'widgets/fx.dart';

/// Tap the bits and see how the same pattern reads in every representation.
class SignedBits extends StatefulWidget {
  const SignedBits({super.key, this.initial = 0xFB});
  final int initial;

  @override
  State<SignedBits> createState() => _SignedBitsState();
}

class _SignedBitsState extends State<SignedBits> {
  int bits = 8;
  late int v = widget.initial;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final bc = context.bc;
    final mask = (1 << bits) - 1;
    final x = v & mask;
    final pattern = x.toRadixString(2).padLeft(bits, '0');

    Widget row(String name, String value, {bool hi = false}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(children: [
            Expanded(child: Text(name, style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant))),
            Text(value,
                style: monoStyle(
                    size: 18, weight: FontWeight.w800, color: hi ? cs.primary : cs.onSurface)),
          ]),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(spacing: 8, children: [
          for (final b in const [4, 8])
            ChoiceChip(
              label: Text('$b bit'),
              selected: bits == b,
              onSelected: (_) => setState(() => bits = b),
            ),
        ]),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (var i = 0; i < bits; i++)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Column(children: [
                    Text(i == 0 ? tr('segno', 'sign') : '',
                        style: TextStyle(fontSize: 10, color: bc.accent)),
                    const SizedBox(height: 2),
                    InkWell(
                      borderRadius: BorderRadius.circular(5),
                      onTap: () {
                        hapticTick();
                        setState(() => v = x ^ (1 << (bits - 1 - i)));
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 38,
                        height: 48,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: pattern[i] == '1' ? cs.primary : bc.panelHi,
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(color: i == 0 ? bc.accent : cs.outlineVariant, width: i == 0 ? 2 : 1),
                        ),
                        child: Text(pattern[i],
                            style: monoStyle(
                                size: 22,
                                weight: FontWeight.w800,
                                color: pattern[i] == '1' ? cs.onPrimary : cs.onSurface)),
                      ),
                    ),
                  ]),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        InfoCard(
          child: Column(children: [
            row(tr('senza segno', 'unsigned'), '$x'),
            row(tr('modulo e segno', 'sign and magnitude'), signMagnitudeValue(x, bits)),
            row(tr('complemento a 1', 'one’s complement'), onesValue(x, bits)),
            row(tr('complemento a 2', 'two’s complement'), '${twosValue(x, bits)}', hi: true),
          ]),
        ),
      ],
    );
  }
}

/// −n in two's complement, step by step: binary, invert, add one.
class TwosSteps extends StatefulWidget {
  const TwosSteps({super.key, this.initial = -5});
  final int initial;

  @override
  State<TwosSteps> createState() => _TwosStepsState();
}

class _TwosStepsState extends State<TwosSteps> {
  late int n = widget.initial;
  static const bits = 8;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final bc = context.bc;
    final steps = twosSteps(n, bits);
    Widget line(String label, String bitsText, {Color? color, bool bold = false}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(children: [
            SizedBox(width: 150, child: Text(label, style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant))),
            Text(bitsText,
                style: monoStyle(size: 20, color: color, weight: bold ? FontWeight.w800 : FontWeight.w500)),
          ]),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          IconButton.outlined(
            onPressed: n > -128 ? () => setState(() => n--) : null,
            icon: const Icon(Icons.remove),
          ),
          SizedBox(
            width: 90,
            child: Text('$n', textAlign: TextAlign.center, style: termStyle(size: 44, color: cs.primary)),
          ),
          IconButton.outlined(
            onPressed: n < 127 ? () => setState(() => n++) : null,
            icon: const Icon(Icons.add),
          ),
          const SizedBox(width: 10),
          Text(tr('su 8 bit', 'on 8 bits'), style: TextStyle(color: cs.onSurfaceVariant)),
        ]),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: n >= 0
                ? [
                    line(tr('positivo: binario', 'positive: binary'), steps.magnitude, color: cs.primary, bold: true),
                  ]
                : [
                    line('|$n| ${tr('in binario', 'in binary')}', steps.magnitude),
                    line(tr('inverto i bit', 'invert the bits'), steps.inverted, color: bc.accent),
                    line(tr('+ 1', '+ 1'), '1'.padLeft(bits, '0')),
                    line(tr('risultato', 'result'), steps.result, color: cs.primary, bold: true),
                  ],
          ),
        ),
        const SizedBox(height: 6),
        RichLine(
          n >= 0
              ? tr('I positivi si scrivono come sempre, con lo 0 davanti.',
                  'Positive numbers are written as usual, with a leading 0.')
              : tr('Verifica: `${steps.result}` letto con peso −128 sul primo bit vale **$n**.',
                  'Check: `${steps.result}` read with weight −128 on the first bit is **$n**.'),
          size: 14,
        ),
      ],
    );
  }
}
