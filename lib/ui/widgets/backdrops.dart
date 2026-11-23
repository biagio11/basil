import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../app/theme.dart';

/// Shared ticker for the animated backdrops, throttled to about 20 fps.
mixin _Throttled<T extends StatefulWidget> on State<T>, SingleTickerProviderStateMixin<T> {
  late final Ticker _ticker = createTicker(_onTick);
  final repaint = ValueNotifier<int>(0);
  Duration _last = Duration.zero;
  double time = 0;

  bool get running;
  double get speedFactor;
  void step(double dt);

  void syncTicker() {
    if (running && !_ticker.isActive) _ticker.start();
    if (!running && _ticker.isActive) _ticker.stop();
  }

  void _onTick(Duration t) {
    final dt = (t - _last).inMicroseconds / 1e6;
    if (dt < 1 / 20) return;
    _last = t;
    final d = dt.clamp(0, .2) * speedFactor;
    time += d;
    step(d);
    repaint.value++;
  }

  @override
  void dispose() {
    _ticker.dispose();
    repaint.dispose();
    super.dispose();
  }
}

/// A quiet grid of lines that slowly scrolls, like graph paper on a screen.
class GridBackdrop extends StatefulWidget {
  const GridBackdrop({super.key, required this.enabled, this.opacity = 1, this.density = 1, this.speed = 1});
  final bool enabled;
  final double opacity;
  final int density;
  final int speed;

  @override
  State<GridBackdrop> createState() => _GridBackdropState();
}

class _GridBackdropState extends State<GridBackdrop>
    with SingleTickerProviderStateMixin, _Throttled {
  @override
  bool get running => widget.enabled;
  @override
  double get speedFactor => const [.5, 1.0, 2.0][widget.speed];
  @override
  void step(double dt) {}

  @override
  void initState() {
    super.initState();
    syncTicker();
  }

  @override
  void didUpdateWidget(GridBackdrop old) {
    super.didUpdateWidget(old);
    syncTicker();
  }

  @override
  Widget build(BuildContext context) {
    final cell = const [64.0, 40.0, 26.0][widget.density];
    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          size: Size.infinite,
          painter: _GridPainter(this, context.bc.glow, cell,
              (context.isDark ? .3 : .2) * widget.opacity),
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  _GridPainter(this.s, this.color, this.cell, this.strength) : super(repaint: s.repaint);
  final _GridBackdropState s;
  final Color color;
  final double cell;
  final double strength;

  @override
  void paint(Canvas canvas, Size size) {
    final off = (s.time * 6) % cell;
    final line = Paint()
      ..color = color.withValues(alpha: strength * .55)
      ..strokeWidth = 1;
    final dot = Paint()..color = color.withValues(alpha: strength);
    for (double x = -cell + off; x < size.width + cell; x += cell) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), line);
    }
    for (double y = -cell + off; y < size.height + cell; y += cell) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), line);
    }
    for (double x = -cell + off; x < size.width + cell; x += cell) {
      for (double y = -cell + off; y < size.height + cell; y += cell) {
        canvas.drawRect(Rect.fromCenter(center: Offset(x, y), width: 3, height: 3), dot);
      }
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) =>
      old.color != color || old.cell != cell || old.strength != strength;
}

/// Bits that float up slowly and fade, like bubbles of 0 and 1.
class BitsBackdrop extends StatefulWidget {
  const BitsBackdrop({super.key, required this.enabled, this.opacity = 1, this.density = 1, this.speed = 1, this.glyphs = 2});
  final bool enabled;
  final double opacity;
  final int density;
  final int speed;
  final int glyphs;

  @override
  State<BitsBackdrop> createState() => _BitsBackdropState();
}

class _Bit {
  _Bit(this.x, this.y, this.v, this.size, this.glyph, this.phase);
  double x, y, v, size, phase;
  int glyph;
}

class _BitsBackdropState extends State<BitsBackdrop>
    with SingleTickerProviderStateMixin, _Throttled {
  final _rng = Random(11);
  final List<_Bit> bits = [];
  Size _size = Size.zero;

  @override
  bool get running => widget.enabled;
  @override
  double get speedFactor => const [.5, 1.0, 2.0][widget.speed];

  @override
  void initState() {
    super.initState();
    syncTicker();
  }

  @override
  void didUpdateWidget(BitsBackdrop old) {
    super.didUpdateWidget(old);
    if (old.density != widget.density || old.glyphs != widget.glyphs) bits.clear();
    syncTicker();
  }

  _Bit _make(Size s, {bool anywhere = false}) => _Bit(
        _rng.nextDouble() * s.width,
        anywhere ? _rng.nextDouble() * s.height : s.height + 20,
        14 + _rng.nextDouble() * 26,
        14 + _rng.nextDouble() * 22,
        _rng.nextInt(widget.glyphs),
        _rng.nextDouble() * pi * 2,
      );

  void _ensure(Size s) {
    if (s == _size && bits.isNotEmpty) return;
    _size = s;
    bits.clear();
    final per = const [12000.0, 6000.0, 2800.0][widget.density];
    final n = (s.width * s.height / per).clamp(8, 220).round();
    for (var i = 0; i < n; i++) {
      bits.add(_make(s, anywhere: true));
    }
  }

  @override
  void step(double dt) {
    for (var i = 0; i < bits.length; i++) {
      final b = bits[i];
      b.y -= b.v * dt;
      if (b.y < -30) bits[i] = _make(_size);
    }
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: LayoutBuilder(builder: (context, c) {
          _ensure(Size(c.maxWidth, c.maxHeight));
          return CustomPaint(
            size: Size(c.maxWidth, c.maxHeight),
            painter: _BitsPainter(this, context.bc.glow,
                (context.isDark ? .75 : .45) * widget.opacity),
          );
        }),
      ),
    );
  }
}

class _BitsPainter extends CustomPainter {
  _BitsPainter(this.s, this.color, this.strength) : super(repaint: s.repaint);
  final _BitsBackdropState s;
  final Color color;
  final double strength;

  static const _chars = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  static final Map<String, ui.Paragraph> _cache = {};

  ui.Paragraph _p(int g, int size, int alpha) {
    final key = '$g-$size-$alpha-${color.toARGB32()}';
    return _cache.putIfAbsent(key, () {
      final pb = ui.ParagraphBuilder(ui.ParagraphStyle(fontFamily: kTerm, fontSize: size.toDouble()))
        ..pushStyle(ui.TextStyle(color: color.withAlpha(alpha), fontFamily: kTerm))
        ..addText(_chars[g]);
      return pb.build()..layout(const ui.ParagraphConstraints(width: 40));
    });
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (_cache.length > 600) _cache.clear();
    for (final b in s.bits) {
      // Fade in at the bottom and out near the top.
      final f = (b.y / size.height).clamp(0.0, 1.0);
      final fade = sin(f * pi);
      final wob = sin(s.time * 1.3 + b.phase) * 6;
      final a = (255 * strength * fade / 16).round() * 16;
      if (a <= 0) continue;
      canvas.drawParagraph(_p(b.glyph, (b.size / 4).round() * 4, a.clamp(0, 255)), Offset(b.x + wob, b.y));
    }
  }

  @override
  bool shouldRepaint(_BitsPainter old) => old.color != color || old.strength != strength;
}

/// Twinkling pixels, like a night sky made of single lit cells.
class StarsBackdrop extends StatefulWidget {
  const StarsBackdrop({super.key, required this.enabled, this.opacity = 1, this.density = 1, this.speed = 1});
  final bool enabled;
  final double opacity;
  final int density;
  final int speed;

  @override
  State<StarsBackdrop> createState() => _StarsBackdropState();
}

class _Star {
  _Star(this.x, this.y, this.size, this.phase, this.rate);
  final double x, y, size, phase, rate;
}

class _StarsBackdropState extends State<StarsBackdrop>
    with SingleTickerProviderStateMixin, _Throttled {
  final _rng = Random(5);
  final List<_Star> stars = [];
  Size _size = Size.zero;

  @override
  bool get running => widget.enabled;
  @override
  double get speedFactor => const [.5, 1.0, 2.0][widget.speed];
  @override
  void step(double dt) {}

  @override
  void initState() {
    super.initState();
    syncTicker();
  }

  @override
  void didUpdateWidget(StarsBackdrop old) {
    super.didUpdateWidget(old);
    if (old.density != widget.density) stars.clear();
    syncTicker();
  }

  void _ensure(Size s) {
    if (s == _size && stars.isNotEmpty) return;
    _size = s;
    stars.clear();
    final per = const [5000.0, 2500.0, 1200.0][widget.density];
    final n = (s.width * s.height / per).clamp(20, 900).round();
    for (var i = 0; i < n; i++) {
      stars.add(_Star(
        (_rng.nextDouble() * s.width / 3).floorToDouble() * 3,
        (_rng.nextDouble() * s.height / 3).floorToDouble() * 3,
        _rng.nextDouble() < .12 ? 3 : 2,
        _rng.nextDouble() * pi * 2,
        .6 + _rng.nextDouble() * 1.8,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: LayoutBuilder(builder: (context, c) {
          _ensure(Size(c.maxWidth, c.maxHeight));
          return CustomPaint(
            size: Size(c.maxWidth, c.maxHeight),
            painter: _StarsPainter(this, context.bc.glow,
                (context.isDark ? .95 : .55) * widget.opacity),
          );
        }),
      ),
    );
  }
}

class _StarsPainter extends CustomPainter {
  _StarsPainter(this.s, this.color, this.strength) : super(repaint: s.repaint);
  final _StarsBackdropState s;
  final Color color;
  final double strength;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..isAntiAlias = false;
    for (final st in s.stars) {
      final tw = .5 + .5 * sin(s.time * st.rate + st.phase);
      p.color = color.withValues(alpha: (strength * (.25 + .75 * tw * tw)).clamp(0, 1));
      canvas.drawRect(Rect.fromLTWH(st.x, st.y, st.size, st.size), p);
    }
  }

  @override
  bool shouldRepaint(_StarsPainter old) => old.color != color || old.strength != strength;
}

/// Darkens the corners like an old monitor.
class Vignette extends StatelessWidget {
  const Vignette({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = context.isDark;
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            radius: 1.15,
            colors: [
              Colors.transparent,
              Colors.transparent,
              Colors.black.withValues(alpha: dark ? .55 : .14),
            ],
            stops: const [0, .6, 1],
          ),
        ),
      ),
    );
  }
}
