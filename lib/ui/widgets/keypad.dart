import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../logic/base_conv.dart';
import 'fx.dart';

/// On-screen keypad that only shows the digits valid in [base].
class BaseKeypad extends StatelessWidget {
  const BaseKeypad({
    super.key,
    required this.base,
    required this.controller,
    this.allowPoint = true,
    this.allowMinus = true,
    this.onSubmit,
    this.maxLength = 64,
  });
  final int base;
  final TextEditingController controller;
  final bool allowPoint;
  final bool allowMinus;
  final VoidCallback? onSubmit;
  final int maxLength;

  void _insert(String s) {
    final v = controller.value;
    final text = v.text;
    if (text.length >= maxLength) return;
    var sel = v.selection;
    if (!sel.isValid) sel = TextSelection.collapsed(offset: text.length);
    if (s == '-') {
      // Toggle sign at the start.
      final t = text.startsWith('-') ? text.substring(1) : '-$text';
      controller.value = TextEditingValue(
          text: t, selection: TextSelection.collapsed(offset: t.length));
      hapticTick();
      return;
    }
    if (s == '.' && text.contains('.')) return;
    final t = text.replaceRange(sel.start, sel.end, s);
    controller.value = TextEditingValue(
        text: t, selection: TextSelection.collapsed(offset: sel.start + s.length));
    hapticTick();
  }

  void _back() {
    final v = controller.value;
    final text = v.text;
    if (text.isEmpty) return;
    var sel = v.selection;
    if (!sel.isValid) sel = TextSelection.collapsed(offset: text.length);
    String t;
    int off;
    if (sel.isCollapsed) {
      if (sel.start == 0) return;
      t = text.replaceRange(sel.start - 1, sel.start, '');
      off = sel.start - 1;
    } else {
      t = text.replaceRange(sel.start, sel.end, '');
      off = sel.start;
    }
    controller.value =
        TextEditingValue(text: t, selection: TextSelection.collapsed(offset: off));
    hapticTick();
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final digits = [for (var i = 0; i < base; i++) digitChar(i)];
    final cols = base <= 10 ? 5 : (base <= 16 ? 7 : 8);

    Widget key(String label,
        {VoidCallback? onTap, VoidCallback? onLong, Color? fg, Color? bg, IconData? icon}) {
      return Padding(
        padding: const EdgeInsets.all(2.5),
        child: Material(
          color: bg ?? context.bc.panelHi,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(5),
            side: BorderSide(color: cs.outlineVariant),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(5),
            onTap: onTap,
            onLongPress: onLong,
            child: SizedBox(
              height: 42,
              child: Center(
                child: icon != null
                    ? Icon(icon, size: 20, color: fg ?? cs.onSurface)
                    : Text(label,
                        style: termStyle(size: 28, color: fg ?? cs.onSurface)),
              ),
            ),
          ),
        ),
      );
    }

    final keys = <Widget>[
      for (final d in digits) key(d, onTap: () => _insert(d)),
      if (allowPoint) key('.', onTap: () => _insert('.'), fg: cs.onSurfaceVariant),
      if (allowMinus) key('±', onTap: () => _insert('-'), fg: cs.onSurfaceVariant),
      key('', icon: Icons.backspace_outlined, onTap: _back,
          onLong: () {
            controller.clear();
            hapticTick();
          },
          fg: context.bc.accent),
      if (onSubmit != null)
        key('', icon: Icons.keyboard_return, onTap: onSubmit,
            bg: cs.primary, fg: cs.onPrimary),
    ];

    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth / cols;
      return Wrap(
        children: [for (final k in keys) SizedBox(width: w, child: k)],
      );
    });
  }
}
