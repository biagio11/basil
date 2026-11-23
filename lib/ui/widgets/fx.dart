import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/settings.dart';
import '../../app/theme.dart';

bool animationsOn(BuildContext context) =>
    AppSettings.instance.animations &&
    !(MediaQuery.maybeDisableAnimationsOf(context) ?? false);

void hapticTick() {
  if (AppSettings.instance.haptics) HapticFeedback.selectionClick();
}

void hapticOk() {
  if (AppSettings.instance.haptics) HapticFeedback.lightImpact();
}

void hapticBad() {
  if (AppSettings.instance.haptics) HapticFeedback.heavyImpact();
}

/// Text that "decodes" from random glyphs into its final value.
/// Fast (≈260 ms) so it never slows down a conversion.
class ScrambleText extends StatefulWidget {
  const ScrambleText(this.text,
      {super.key, required this.style, this.textAlign, this.maxLines});
  final String text;
  final TextStyle style;
  final TextAlign? textAlign;
  final int? maxLines;

  @override
  State<ScrambleText> createState() => _ScrambleTextState();
}

class _ScrambleTextState extends State<ScrambleText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 260));
  final _r = Random();
  static const _glyphs = '0123456789ABCDEF#%&@*';

  @override
  void didUpdateWidget(ScrambleText old) {
    super.didUpdateWidget(old);
    if (old.text != widget.text && animationsOn(context)) {
      _c.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        var s = widget.text;
        if (_c.isAnimating && s.length < 400) {
          final fixed = (s.length * _c.value).floor();
          final b = StringBuffer(s.substring(0, fixed));
          for (var i = fixed; i < s.length; i++) {
            final ch = s[i];
            b.write(ch == ' ' || ch == '.' || ch == '-'
                ? ch
                : _glyphs[_r.nextInt(_glyphs.length)]);
          }
          s = b.toString();
        }
        return Text(s,
            style: widget.style,
            textAlign: widget.textAlign,
            maxLines: widget.maxLines,
            softWrap: true);
      },
    );
  }
}

/// Bordered panel with an optional terminal-style header ("> TITLE").
class Panel extends StatelessWidget {
  const Panel({
    super.key,
    required this.child,
    this.title,
    this.trailing,
    this.padding = const EdgeInsets.all(16),
    this.highlight = false,
  });
  final Widget child;
  final String? title;
  final Widget? trailing;
  final EdgeInsets padding;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final bc = context.bc;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      decoration: BoxDecoration(
        color: bc.panel.withAlpha(context.isDark ? 235 : 245),
        borderRadius: appLook.br(6),
        border: Border.all(
            color: highlight ? cs.primary : cs.outlineVariant,
            width: highlight ? 1.5 : 1),
        boxShadow: [
          if (highlight && context.isDark && appLook.glow)
            BoxShadow(color: bc.glow.withAlpha(40), blurRadius: 18),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title != null)
            Container(
              padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: cs.outlineVariant)),
              ),
              child: Row(
                children: [
                  Text('>', style: pixelStyle(size: 12, color: cs.primary)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(title!.toUpperCase(),
                        overflow: TextOverflow.ellipsis,
                        style: pixelStyle(
                            size: 11, color: cs.onSurfaceVariant)),
                  ),
                  ?trailing,
                ],
              ),
            ),
          Padding(padding: padding, child: child),
        ],
      ),
    );
  }
}

/// Blinking block cursor.
class BlinkCursor extends StatefulWidget {
  const BlinkCursor({super.key, this.height = 18, this.width = 9});
  final double height;
  final double width;

  @override
  State<BlinkCursor> createState() => _BlinkCursorState();
}

class _BlinkCursorState extends State<BlinkCursor>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1000));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (animationsOn(context)) {
      _c.repeat();
    } else {
      _c.value = 0;
      _c.stop();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final style = appLook.cursor;
        return Opacity(
          opacity: _c.value < .5 ? 1 : 0,
          child: SizedBox(
            width: widget.width,
            height: widget.height,
            child: Align(
              alignment: style == 'under' ? Alignment.bottomCenter : Alignment.centerLeft,
              child: Container(
                width: style == 'bar' ? 2.5 : widget.width,
                height: style == 'under' ? 3 : widget.height,
                color: context.cs.primary,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Typewriter text: reveals characters one by one once.
class TypeText extends StatefulWidget {
  const TypeText(this.text, {super.key, required this.style, this.cursor = true});
  final String text;
  final TextStyle style;
  final bool cursor;

  @override
  State<TypeText> createState() => _TypeTextState();
}

class _TypeTextState extends State<TypeText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 28 * widget.text.length + 60));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (animationsOn(context)) {
      if (!_c.isAnimating && _c.value == 0) _c.forward();
    } else {
      _c.value = 1;
    }
  }

  @override
  void didUpdateWidget(TypeText old) {
    super.didUpdateWidget(old);
    if (old.text != widget.text) {
      _c.duration = Duration(milliseconds: 28 * widget.text.length + 60);
      if (animationsOn(context)) {
        _c.forward(from: 0);
      } else {
        _c.value = 1;
      }
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final n = (widget.text.length * _c.value).round();
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Flexible(child: Text(widget.text.substring(0, n), style: widget.style)),
            if (widget.cursor) ...[
              const SizedBox(width: 4),
              BlinkCursor(height: (widget.style.fontSize ?? 16) * .9,
                  width: (widget.style.fontSize ?? 16) * .5),
            ],
          ],
        );
      },
    );
  }
}

/// Short horizontal shake (wrong answer feedback).
class Shake extends StatefulWidget {
  const Shake({super.key, required this.child, required this.trigger});
  final Widget child;

  /// Increment to play the shake.
  final int trigger;

  @override
  State<Shake> createState() => _ShakeState();
}

class _ShakeState extends State<Shake> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 360));

  @override
  void didUpdateWidget(Shake old) {
    super.didUpdateWidget(old);
    if (old.trigger != widget.trigger && animationsOn(context)) {
      _c.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (context, child) {
        final v = _c.isAnimating ? sin(_c.value * pi * 6) * 8 * (1 - _c.value) : 0.0;
        return Transform.translate(offset: Offset(v, 0), child: child);
      },
    );
  }
}

/// Fades + slides its child in when first built.
class Appear extends StatelessWidget {
  const Appear({super.key, required this.child, this.delay = 0});
  final Widget child;
  final int delay;

  @override
  Widget build(BuildContext context) {
    if (!animationsOn(context)) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 320 + delay),
      curve: Interval(delay / (320 + delay), 1, curve: Curves.easeOutCubic),
      child: child,
      builder: (context, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(offset: Offset(0, (1 - v) * 14), child: child),
      ),
    );
  }
}

Future<void> copyText(BuildContext context, String text) async {
  await Clipboard.setData(ClipboardData(text: text));
  hapticOk();
  if (!context.mounted) return;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      duration: const Duration(milliseconds: 1400),
      content: Text(tr('Copiato: ', 'Copied: ') +
          (text.length > 40 ? '${text.substring(0, 40)}…' : text)),
    ));
}
