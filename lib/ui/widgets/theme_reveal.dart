import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../app/settings.dart';
import 'fx.dart';

/// Switches theme with a circular reveal: the old screen is kept as a
/// snapshot on top and a growing hole uncovers the new theme underneath.
class ThemeReveal extends StatefulWidget {
  const ThemeReveal({super.key, required this.child});
  final Widget child;

  static ThemeRevealState? of(BuildContext context) =>
      context.findAncestorStateOfType<ThemeRevealState>();

  @override
  State<ThemeReveal> createState() => ThemeRevealState();
}

class ThemeRevealState extends State<ThemeReveal> with SingleTickerProviderStateMixin {
  final _key = GlobalKey();
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 620));
  ui.Image? _img;
  Offset _center = Offset.zero;

  @override
  void dispose() {
    _c.dispose();
    _img?.dispose();
    super.dispose();
  }

  Future<void> run(VoidCallback apply, {Offset? from}) async {
    final b = _key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (!animationsOn(context) || _c.isAnimating || b == null || !b.hasSize) {
      apply();
      return;
    }
    try {
      final img = await b.toImage(pixelRatio: MediaQuery.devicePixelRatioOf(context));
      if (!mounted) return;
      setState(() {
        _img = img;
        _center = from ?? Offset(b.size.width / 2, 0);
      });
      apply();
      await _c.forward(from: 0);
    } catch (_) {
      apply();
    } finally {
      if (mounted) {
        setState(() {
          _img?.dispose();
          _img = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        RepaintBoundary(key: _key, child: widget.child),
        if (_img != null)
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _c,
                builder: (context, _) => CustomPaint(
                  painter: _RevealPainter(
                    _img!,
                    _center,
                    Curves.easeInOutCubic.transform(_c.value),
                    Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _RevealPainter extends CustomPainter {
  _RevealPainter(this.img, this.center, this.t, this.ring);
  final ui.Image img;
  final Offset center;
  final double t;
  final Color ring;

  @override
  void paint(Canvas canvas, Size size) {
    final far = [
      Offset.zero,
      Offset(size.width, 0),
      Offset(0, size.height),
      Offset(size.width, size.height),
    ].map((p) => (p - center).distance).reduce(max);
    final r = far * t;
    final rect = Offset.zero & size;
    canvas.saveLayer(rect, Paint());
    canvas.drawImageRect(
      img,
      Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()),
      rect,
      Paint()..filterQuality = FilterQuality.medium,
    );
    canvas.drawCircle(center, r, Paint()..blendMode = BlendMode.clear);
    canvas.restore();
    if (t > 0 && t < 1) {
      canvas.drawCircle(
        center,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = ring.withValues(alpha: (1 - t) * .8)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
    }
  }

  @override
  bool shouldRepaint(_RevealPainter old) => old.t != t || old.img != img;
}

/// Changes the theme with the reveal animation, starting from [from].
void switchTheme(BuildContext context, ThemeMode mode, {Offset? from}) {
  final s = AppSettings.instance;
  if (s.themeMode == mode) return;
  final host = ThemeReveal.of(context);
  if (host == null) {
    s.setTheme(mode);
  } else {
    host.run(() => s.setTheme(mode), from: from);
  }
}

/// Global centre of the widget owning [context], for starting the reveal.
Offset? centerOf(BuildContext context) {
  final box = context.findRenderObject() as RenderBox?;
  if (box == null || !box.hasSize) return null;
  return box.localToGlobal(box.size.center(Offset.zero));
}
