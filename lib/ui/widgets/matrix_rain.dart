import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../app/theme.dart';

/// Falling base-16 glyphs ("digital rain"), drawn very faintly behind the UI.
/// Throttled to ~20 fps and paused when animations are off.
class MatrixRain extends StatefulWidget {
  const MatrixRain({super.key, required this.enabled, this.opacity = 1});
  final bool enabled;
  final double opacity;

  @override
  State<MatrixRain> createState() => _MatrixRainState();
}

class _Drop {
  _Drop(this.col, this.y, this.speed, this.len);
  int col;
  double y;
  double speed;
  int len;
}

class _MatrixRainState extends State<MatrixRain>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_tick);
  final _repaint = ValueNotifier<int>(0);
  final _rng = Random(7);
  final List<_Drop> _drops = [];
  Duration _last = Duration.zero;
  Size _size = Size.zero;
  static const double cell = 18;

  @override
  void initState() {
    super.initState();
    if (widget.enabled) _ticker.start();
  }

  @override
  void didUpdateWidget(MatrixRain old) {
    super.didUpdateWidget(old);
    if (widget.enabled && !_ticker.isActive) _ticker.start();
    if (!widget.enabled && _ticker.isActive) _ticker.stop();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _repaint.dispose();
    super.dispose();
  }

  void _ensureDrops(Size s) {
    if (s == _size && _drops.isNotEmpty) return;
    _size = s;
    _drops.clear();
    final cols = (s.width / cell).ceil();
    final rows = s.height / cell;
    for (var c = 0; c < cols; c++) {
      if (_rng.nextDouble() < .45) continue; // sparse
      _drops.add(_Drop(c, _rng.nextDouble() * rows * 1.5 - rows * .5,
          4 + _rng.nextDouble() * 9, 6 + _rng.nextInt(14)));
    }
  }

  void _tick(Duration t) {
    final dt = (t - _last).inMicroseconds / 1e6;
    if (dt < 1 / 20) return;
    _last = t;
    final rows = _size.height / cell;
    for (final d in _drops) {
      d.y += d.speed * dt.clamp(0, .2);
      if (d.y - d.len > rows) {
        d.y = -_rng.nextDouble() * 10;
        d.speed = 4 + _rng.nextDouble() * 9;
        d.len = 6 + _rng.nextInt(14);
      }
    }
    _repaint.value++;
  }

  @override
  Widget build(BuildContext context) {
    final color = context.bc.glow;
    final dark = context.isDark;
    return IgnorePointer(
      child: RepaintBoundary(
        child: LayoutBuilder(builder: (context, c) {
          _ensureDrops(Size(c.maxWidth, c.maxHeight));
          return CustomPaint(
            size: Size(c.maxWidth, c.maxHeight),
            painter: _RainPainter(
              drops: _drops,
              repaint: _repaint,
              color: color,
              strength: (dark ? .55 : .32) * widget.opacity,
            ),
          );
        }),
      ),
    );
  }
}

class _RainPainter extends CustomPainter {
  _RainPainter({
    required this.drops,
    required ValueNotifier<int> repaint,
    required this.color,
    required this.strength,
  })  : _frame = repaint,
        super(repaint: repaint);

  final List<_Drop> drops;
  final ValueNotifier<int> _frame;
  final Color color;
  final double strength;

  static const _glyphs = '0123456789ABCDEF';
  static final Map<String, ui.Paragraph> _cache = {};

  ui.Paragraph _glyph(int g, int level, Color color) {
    final key = '$g-$level-${color.toARGB32()}';
    return _cache.putIfAbsent(key, () {
      final alpha = const [255, 150, 90, 45][level];
      final pb = ui.ParagraphBuilder(ui.ParagraphStyle(
        fontFamily: kTerm,
        fontSize: 18,
      ))
        ..pushStyle(ui.TextStyle(
            color: level == 0
                ? Color.lerp(color, Colors.white, .55)!.withAlpha(alpha)
                : color.withAlpha(alpha),
            fontFamily: kTerm))
        ..addText(_glyphs[g]);
      final p = pb.build()..layout(const ui.ParagraphConstraints(width: 20));
      return p;
    });
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (strength <= 0) return;
    if (_cache.length > 400) _cache.clear();
    canvas.saveLayer(Offset.zero & size,
        Paint()..color = Colors.white.withValues(alpha: strength));
    final frame = _frame.value;
    const cell = _MatrixRainState.cell;
    for (final d in drops) {
      final head = d.y.floor();
      for (var k = 0; k < d.len; k++) {
        final row = head - k;
        if (row < 0) break;
        final y = row * cell;
        if (y > size.height) continue;
        final level = k == 0 ? 0 : (k < d.len * .35 ? 1 : (k < d.len * .7 ? 2 : 3));
        // Glyphs flicker now and then.
        final seed = (d.col * 73856093) ^ (row * 19349663) ^ ((frame ~/ (6 + k % 5)) * (k == 0 ? 1 : 0));
        final g = seed.abs() % 16;
        canvas.drawParagraph(_glyph(g, level, color), Offset(d.col * cell + 3, y));
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_RainPainter old) =>
      old.color != color || old.strength != strength;
}
