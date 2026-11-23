import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/settings.dart';
import '../../app/theme.dart';
import 'fx.dart';

const int kMinBase = 2;
const int kMaxBase = 36;

String baseTag(int b) => switch (b) {
      2 => 'BIN',
      8 => 'OCT',
      10 => 'DEC',
      16 => 'HEX',
      _ => 'B$b',
    };

String baseName(int b) => switch (b) {
      2 => tr('binario', 'binary'),
      8 => tr('ottale', 'octal'),
      10 => tr('decimale', 'decimal'),
      16 => tr('esadecimale', 'hexadecimal'),
      _ => tr('base $b', 'base $b'),
    };

class _AllDevicesScroll extends MaterialScrollBehavior {
  const _AllDevicesScroll();
  @override
  Set<PointerDeviceKind> get dragDevices => PointerDeviceKind.values.toSet();
}

/// Scrollable 3D wheel to pick a base 2-36. Works with touch, mouse drag,
/// mouse wheel, tap on an item and arrow keys.
class BaseWheel extends StatefulWidget {
  const BaseWheel({
    super.key,
    required this.value,
    required this.onChanged,
    required this.label,
    this.height = 156,
    this.min = kMinBase,
    this.max = kMaxBase,
  });
  final int value;
  final ValueChanged<int> onChanged;
  final String label;
  final double height;
  final int min;
  final int max;

  @override
  State<BaseWheel> createState() => _BaseWheelState();
}

class _BaseWheelState extends State<BaseWheel> {
  late final FixedExtentScrollController _c =
      FixedExtentScrollController(initialItem: widget.value - widget.min);
  final _focus = FocusNode();
  int _current = 0;
  static const double _extent = 42;

  @override
  void initState() {
    super.initState();
    _current = widget.value;
  }

  @override
  void didUpdateWidget(BaseWheel old) {
    super.didUpdateWidget(old);
    if (widget.value != _current) {
      _current = widget.value;
      if (_c.hasClients) {
        _c.animateToItem(widget.value - widget.min,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic);
      }
    }
  }

  @override
  void dispose() {
    _c.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _go(int base) {
    final b = base.clamp(widget.min, widget.max);
    _c.animateToItem(b - widget.min,
        duration: const Duration(milliseconds: 180), curve: Curves.easeOut);
  }

  void _onSignal(PointerSignalEvent e) {
    if (e is PointerScrollEvent) {
      GestureBinding.instance.pointerSignalResolver.register(e, (event) {
        final dy = (event as PointerScrollEvent).scrollDelta.dy;
        if (dy == 0) return;
        _go(_current + (dy > 0 ? 1 : -1));
      });
    }
  }

  Future<void> _openGrid() async {
    final picked = await showBasePicker(context, _current, widget.label,
        min: widget.min, max: widget.max);
    if (picked != null) _go(picked);
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final count = widget.max - widget.min + 1;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          borderRadius: appLook.br(4),
          onTap: _openGrid,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(widget.label.toUpperCase(),
                    style: pixelStyle(size: 10, color: cs.onSurfaceVariant)),
                const SizedBox(width: 4),
                Icon(Icons.grid_view_rounded, size: 13, color: cs.onSurfaceVariant),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        Focus(
          focusNode: _focus,
          onKeyEvent: (node, e) {
            if (e is! KeyDownEvent && e is! KeyRepeatEvent) {
              return KeyEventResult.ignored;
            }
            if (e.logicalKey == LogicalKeyboardKey.arrowDown) {
              _go(_current + 1);
              return KeyEventResult.handled;
            }
            if (e.logicalKey == LogicalKeyboardKey.arrowUp) {
              _go(_current - 1);
              return KeyEventResult.handled;
            }
            if (e.logicalKey == LogicalKeyboardKey.enter ||
                e.logicalKey == LogicalKeyboardKey.space) {
              _openGrid();
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;
          },
          child: AnimatedBuilder(
            animation: _focus,
            builder: (context, child) => Container(
              height: widget.height,
              decoration: BoxDecoration(
                color: context.bc.panelHi.withAlpha(context.isDark ? 160 : 255),
                borderRadius: appLook.br(6),
                border: Border.all(
                    color: _focus.hasFocus ? cs.primary : cs.outlineVariant),
              ),
              child: child,
            ),
            child: Listener(
              onPointerSignal: _onSignal,
              onPointerDown: (_) => _focus.requestFocus(),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Selection band
                  IgnorePointer(
                    child: Container(
                      height: _extent,
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      decoration: BoxDecoration(
                        color: cs.primaryContainer.withAlpha(context.isDark ? 150 : 200),
                        borderRadius: appLook.br(4),
                        border: Border.all(color: cs.primary.withAlpha(140)),
                      ),
                    ),
                  ),
                  ScrollConfiguration(
                    behavior: const _AllDevicesScroll(),
                    child: ListWheelScrollView.useDelegate(
                      controller: _c,
                      itemExtent: _extent,
                      diameterRatio: 1.25,
                      perspective: 0.004,
                      overAndUnderCenterOpacity: 0.38,
                      physics: const FixedExtentScrollPhysics(),
                      onSelectedItemChanged: (i) {
                        final b = i + widget.min;
                        if (b == _current) return;
                        _current = b;
                        hapticTick();
                        setState(() {});
                        widget.onChanged(b);
                      },
                      childDelegate: ListWheelChildBuilderDelegate(
                        childCount: count,
                        builder: (context, i) {
                          final b = i + widget.min;
                          final sel = b == _current;
                          return GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => _go(b),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 40,
                                  child: Text('$b',
                                      textAlign: TextAlign.right,
                                      style: termStyle(
                                          size: 34,
                                          color: sel ? cs.primary : cs.onSurface)),
                                ),
                                const SizedBox(width: 8),
                                SizedBox(
                                  width: 34,
                                  child: Text(baseTag(b),
                                      style: pixelStyle(
                                          size: 10,
                                          color: sel
                                              ? cs.primary
                                              : cs.onSurfaceVariant)),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Grid of all bases for a one-tap jump.
Future<int?> showBasePicker(BuildContext context, int current, String title,
    {int min = kMinBase, int max = kMaxBase}) {
  return showModalBottomSheet<int>(
    context: context,
    showDragHandle: true,
    builder: (ctx) {
      final cs = ctx.cs;
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title.toUpperCase(),
                  style: pixelStyle(size: 13, color: cs.primary)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (var b = min; b <= max; b++)
                    SizedBox(
                      width: 58,
                      height: 50,
                      child: Material(
                        color: b == current
                            ? cs.primaryContainer
                            : ctx.bc.panelHi,
                        shape: RoundedRectangleBorder(
                          borderRadius: appLook.br(5),
                          side: BorderSide(
                              color: b == current ? cs.primary : cs.outlineVariant),
                        ),
                        child: InkWell(
                          borderRadius: appLook.br(5),
                          onTap: () => Navigator.of(ctx).pop(b),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('$b',
                                  style: termStyle(
                                      size: 26,
                                      color: b == current ? cs.primary : cs.onSurface)),
                              if (b == 2 || b == 8 || b == 10 || b == 16)
                                Text(baseTag(b),
                                    style: pixelStyle(
                                        size: 8, color: cs.onSurfaceVariant)),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// Quick chips for the four common bases.
class QuickBases extends StatelessWidget {
  const QuickBases({super.key, required this.value, required this.onPick});
  final int value;
  final ValueChanged<int> onPick;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    return Row(
      children: [
        for (final b in const [2, 8, 10, 16])
          Expanded(
            child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1.5),
            child: InkWell(
              borderRadius: appLook.br(4),
              onTap: () => onPick(b),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: value == b ? cs.primary : Colors.transparent,
                  borderRadius: appLook.br(4),
                  border: Border.all(
                      color: value == b ? cs.primary : cs.outlineVariant),
                ),
                child: FittedBox(
                  child: Text(baseTag(b),
                      style: pixelStyle(
                          size: 9,
                          color: value == b ? cs.onPrimary : cs.onSurfaceVariant)),
                ),
              ),
            ),
          ),
          ),
      ],
    );
  }
}
