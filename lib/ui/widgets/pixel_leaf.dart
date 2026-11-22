import 'dart:math';

import 'package:flutter/material.dart';

import '../../app/settings.dart';
import '../../app/theme.dart';

/// 16×16 pixel-art basil leaf.
const List<String> kLeafGrid = [
  '................',
  '............ooo.',
  '.........ooolvo.',
  '......ooollgvdo.',
  '.....olvgggvdo..',
  '....olggvgvdvo..',
  '...olggggvdddo..',
  '...ovgggvdddo...',
  '...olvgvdvddo...',
  '..olggvdddvo....',
  '..oggvdddddo....',
  '..ogvdvdddo.....',
  '..ovdddvoo......',
  '..sooooo........',
  '.s..............',
  's...............',
];

Map<String, Color> leafPalette(bool dark) => {
      'o': dark ? const Color(0xFF1C7A3A) : const Color(0xFF0A3C1A),
      'd': const Color(0xFF166E30),
      'g': const Color(0xFF2EAA4A),
      'l': const Color(0xFF8CFF96),
      'v': const Color(0xFF12602A),
      's': dark ? const Color(0xFF2EAA4A) : const Color(0xFF1E7832),
    };

class PixelLeaf extends StatelessWidget {
  const PixelLeaf({super.key, this.size = 32, this.glow = true});
  final double size;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _LeafPainter(leafPalette(context.isDark),
            glow: glow && context.isDark, glowColor: context.bc.glow),
      ),
    );
  }
}

class _LeafPainter extends CustomPainter {
  _LeafPainter(this.pal, {required this.glow, required this.glowColor});
  final Map<String, Color> pal;
  final bool glow;
  final Color glowColor;

  @override
  void paint(Canvas canvas, Size size) {
    final px = size.width / 16;
    if (glow) {
      final p = Paint()
        ..color = glowColor.withAlpha(70)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, px * 1.6);
      canvas.drawCircle(Offset(size.width * .55, size.height * .45),
          size.width * .32, p);
    }
    final paint = Paint()..isAntiAlias = false;
    for (var y = 0; y < 16; y++) {
      final row = kLeafGrid[y];
      for (var x = 0; x < 16; x++) {
        final c = pal[row[x]];
        if (c == null) continue;
        paint.color = c;
        // +0.5 overlap avoids hairline gaps between pixels.
        canvas.drawRect(Rect.fromLTWH(x * px, y * px, px + .5, px + .5), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_LeafPainter old) =>
      old.pal != pal || old.glow != glow;
}

/// Logo: leaf + "BASIL" in pixel font, with a short glitch on tap.
class BasilLogo extends StatefulWidget {
  const BasilLogo({super.key, this.size = 28, this.showText = true});
  final double size;
  final bool showText;

  @override
  State<BasilLogo> createState() => _BasilLogoState();
}

class _BasilLogoState extends State<BasilLogo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 420));
  final _r = Random();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    return GestureDetector(
      onTap: () {
        if (AppSettings.instance.animations) _c.forward(from: 0);
      },
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final active = _c.isAnimating;
          final dx = active ? (_r.nextDouble() - .5) * 4 : 0.0;
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Transform.translate(
                offset: Offset(dx, 0),
                child: PixelLeaf(size: widget.size),
              ),
              if (widget.showText) ...[
                const SizedBox(width: 10),
                Stack(
                  children: [
                    if (active)
                      Transform.translate(
                        offset: Offset(-dx * 1.5, 0),
                        child: Text('BASIL',
                            style: pixelStyle(
                                size: widget.size * .72,
                                weight: FontWeight.w700,
                                color: context.bc.bad.withAlpha(150))),
                      ),
                    Text('BASIL',
                        style: pixelStyle(
                            size: widget.size * .72,
                            weight: FontWeight.w700,
                            color: cs.primary)),
                  ],
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
