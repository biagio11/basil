import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/settings.dart';
import '../logic/base_conv.dart';
import '../logic/numbers.dart';
import 'common.dart';
import 'explain.dart';
import 'widgets/base_wheel.dart';
import 'widgets/fx.dart';
import 'widgets/keypad.dart';

/// Converter state survives tab switches and language changes.
class ConverterModel {
  ConverterModel._();
  static final instance = ConverterModel._();
  final controller = TextEditingController(text: '45');
}

bool isTouchLayout(BuildContext context) {
  final p = Theme.of(context).platform;
  return p == TargetPlatform.android || p == TargetPlatform.iOS;
}

class ConverterScreen extends StatefulWidget {
  const ConverterScreen({super.key});

  @override
  State<ConverterScreen> createState() => _ConverterScreenState();
}

class _ConverterScreenState extends State<ConverterScreen> {
  final s = AppSettings.instance;
  TextEditingController get _c => ConverterModel.instance.controller;
  final _focus = FocusNode();
  late int _from = s.fromBase;
  late int _to = s.toBase;
  bool _keypadOpen = true;

  @override
  void initState() {
    super.initState();
    _c.addListener(_onText);
  }

  @override
  void dispose() {
    _c.removeListener(_onText);
    _focus.dispose();
    super.dispose();
  }

  void _onText() => setState(() {});

  void _setFrom(int b) {
    if (b == _from) return;
    setState(() => _from = b);
    s.setBases(_from, _to);
  }

  void _setTo(int b) {
    if (b == _to) return;
    setState(() => _to = b);
    s.setBases(_from, _to);
  }

  void _swap() {
    final p = parseNumber(_c.text, _from);
    setState(() {
      final f = _from;
      _from = _to;
      _to = f;
      if (p.ok) {
        final r = convertNumber(p.value!, _from);
        if (r.repeat.isEmpty && !r.truncated) {
          _c.text = r.plain;
          _c.selection = TextSelection.collapsed(offset: _c.text.length);
        }
      }
    });
    s.setBases(_from, _to);
    hapticTick();
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final t = data?.text?.trim() ?? '';
    if (t.isEmpty) return;
    _c.text = t.length > kMaxInputLength ? t.substring(0, kMaxInputLength) : t;
    _c.selection = TextSelection.collapsed(offset: _c.text.length);
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 980;
    final touch = isTouchLayout(context);
    final useKeypad = touch && s.keypad;
    final parse = parseNumber(_c.text, _from);
    final res = parse.ok ? convertNumber(parse.value!, _to) : null;

    final input = _inputPanel(context, parse, useKeypad);
    final wheels = _wheels(context);
    final output = _outputPanel(context, parse, res);
    final mode = _modeSwitch(context);
    final detail = parse.ok
        ? (s.explain
            ? Panel(
                key: const ValueKey('explain'),
                title: tr('Spiegazione', 'Explanation'),
                child: ConversionExplanation(n: parse.value!, to: _to),
              )
            : _allBases(context, parse.value!))
        : const SizedBox.shrink();

    final keypad = useKeypad
        ? _KeypadDock(
            open: _keypadOpen,
            onToggle: () => setState(() => _keypadOpen = !_keypadOpen),
            child: BaseKeypad(base: _from, controller: _c, maxLength: kMaxInputLength),
          )
        : null;

    if (wide) {
      return Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1240),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 470,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 10, 32),
                  children: [
                    Appear(child: input),
                    const SizedBox(height: 14),
                    Appear(delay: 60, child: wheels),
                    const SizedBox(height: 14),
                    Appear(delay: 120, child: output),
                    const SizedBox(height: 14),
                    _shortcutsHint(context),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(10, 8, 20, 32),
                  children: [
                    mode,
                    const SizedBox(height: 14),
                    AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220), child: detail),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(14, 4, 14, 24),
                children: [
                  Appear(child: input),
                  const SizedBox(height: 12),
                  Appear(delay: 60, child: wheels),
                  const SizedBox(height: 12),
                  Appear(delay: 120, child: output),
                  const SizedBox(height: 12),
                  mode,
                  const SizedBox(height: 12),
                  AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220), child: detail),
                ],
              ),
            ),
          ),
        ),
        ?keypad,
      ],
    );
  }

  Widget _shortcutsHint(BuildContext context) {
    if (isTouchLayout(context)) return const SizedBox.shrink();
    return Text(
      tr('Suggerimento: scorri le ruote con la rotellina del mouse o con ↑ ↓, '
          'clicca l’etichetta per la griglia di tutte le basi.',
          'Tip: spin the wheels with the mouse wheel or ↑ ↓, click the label '
          'for a grid of every base.'),
      style: Theme.of(context).textTheme.bodySmall,
    );
  }

  Widget _inputPanel(BuildContext context, NumberParse parse, bool useKeypad) {
    final cs = context.cs;
    final err = !parse.ok && _c.text.trim().isNotEmpty;
    return Panel(
      title: '${tr('Numero', 'Number')} · ${tr('base', 'base')} $_from ${baseTag(_from)}',
      highlight: _focus.hasFocus,
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        IconButton(
          tooltip: tr('Incolla', 'Paste'),
          visualDensity: VisualDensity.compact,
          iconSize: 18,
          onPressed: _paste,
          icon: const Icon(Icons.content_paste),
        ),
        IconButton(
          tooltip: tr('Cancella', 'Clear'),
          visualDensity: VisualDensity.compact,
          iconSize: 18,
          onPressed: () => _c.clear(),
          icon: const Icon(Icons.backspace_outlined),
        ),
        if (isTouchLayout(context))
          IconButton(
            tooltip: useKeypad
                ? tr('Usa la tastiera del telefono', 'Use the phone keyboard')
                : tr('Usa il tastierino Basil', 'Use the Basil keypad'),
            visualDensity: VisualDensity.compact,
            iconSize: 18,
            onPressed: () => setState(() {
              s.setKeypad(!s.keypad);
              _focus.unfocus();
            }),
            icon: Icon(useKeypad ? Icons.keyboard_outlined : Icons.dialpad),
          ),
      ]),
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Focus(
            onFocusChange: (_) => setState(() {}),
            child: TextField(
              controller: _c,
              focusNode: _focus,
              keyboardType: useKeypad ? TextInputType.none : TextInputType.visiblePassword,
              showCursor: true,
              autocorrect: false,
              enableSuggestions: false,
              enableIMEPersonalizedLearning: false,
              textCapitalization: TextCapitalization.characters,
              maxLines: 3,
              minLines: 1,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9A-Za-z.,\-+ _−]')),
                LengthLimitingTextInputFormatter(kMaxInputLength),
              ],
              style: termStyle(size: 42, color: err ? context.bc.bad : cs.onSurface, height: 1.1),
              cursorColor: cs.primary,
              cursorWidth: 12,
              decoration: InputDecoration(
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                hintText: '0',
                hintStyle: termStyle(size: 42, color: cs.onSurfaceVariant.withAlpha(90)),
                contentPadding: const EdgeInsets.symmetric(vertical: 4),
              ),
            ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: Text(
              err
                  ? parseErrorText(parse, _from)
                  : tr('cifre valide: ${validDigitsLabel(_from)}',
                      'valid digits: ${validDigitsLabel(_from)}'),
              key: ValueKey(err ? 'e${parse.error}${parse.badChar}' : 'ok$_from'),
              style: TextStyle(
                  fontSize: 12,
                  color: err ? context.bc.bad : cs.onSurfaceVariant,
                  fontWeight: err ? FontWeight.w700 : FontWeight.w400),
            ),
          ),
        ],
      ),
    );
  }

  Widget _wheels(BuildContext context) {
    final cs = context.cs;
    final h = MediaQuery.sizeOf(context).height < 900 ? 126.0 : 156.0;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(children: [
            BaseWheel(value: _from, height: h, onChanged: _setFrom, label: tr('da base', 'from base')),
            const SizedBox(height: 8),
            QuickBases(value: _from, onPick: _setFrom),
          ]),
        ),
        Padding(
          padding: EdgeInsets.only(top: 26 + h / 2 - 23, left: 8, right: 8),
          child: Tooltip(
            message: tr('Inverti', 'Swap'),
            child: Material(
              color: cs.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              child: InkWell(
                borderRadius: BorderRadius.circular(6),
                onTap: _swap,
                child: const SizedBox(
                  width: 46,
                  height: 46,
                  child: _SwapIcon(),
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: Column(children: [
            BaseWheel(value: _to, height: h, onChanged: _setTo, label: tr('a base', 'to base')),
            const SizedBox(height: 8),
            QuickBases(value: _to, onPick: _setTo),
          ]),
        ),
      ],
    );
  }

  Widget _outputPanel(BuildContext context, NumberParse parse, ConvResult? res) {
    final cs = context.cs;
    final text = res == null
        ? '-'
        : (s.groupDigits && !res.hasFraction
            ? groupDigits(res.display, groupSizeFor(_to))
            : res.display);
    final decimal = parse.ok && _from != 10 && _to != 10
        ? convertNumber(parse.value!, 10).display
        : null;
    return Panel(
      title: '${tr('Risultato', 'Result')} · ${tr('base', 'base')} $_to ${baseTag(_to)}',
      highlight: res != null,
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        IconButton(
          tooltip: tr('Raggruppa cifre', 'Group digits'),
          visualDensity: VisualDensity.compact,
          iconSize: 18,
          isSelected: s.groupDigits,
          onPressed: () => setState(() => s.setGroupDigits(!s.groupDigits)),
          icon: const Icon(Icons.space_bar),
        ),
        IconButton(
          tooltip: tr('Copia', 'Copy'),
          visualDensity: VisualDensity.compact,
          iconSize: 18,
          onPressed: res == null ? null : () => copyText(context, res.plain),
          icon: const Icon(Icons.copy),
        ),
      ]),
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onLongPress: res == null ? null : () => copyText(context, res.plain),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Flexible(
                  child: ScrambleText(
                    text,
                    style: termStyle(
                        size: text.length > 28 ? 32 : 46,
                        color: res == null ? cs.onSurfaceVariant : cs.primary,
                        height: 1.05),
                  ),
                ),
                if (res != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 4),
                    child: Text(subscript(_to),
                        style: monoStyle(size: 16, color: cs.onSurfaceVariant)),
                  ),
              ],
            ),
          ),
          if (decimal != null) ...[
            const SizedBox(height: 4),
            Text('= $decimal ${tr('in base 10', 'in base 10')}',
                style: monoStyle(size: 13, color: cs.onSurfaceVariant)),
          ],
          if (res != null && res.repeat.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(tr('(…) = cifre periodiche', '(…) = repeating digits'),
                style: TextStyle(fontSize: 12, color: context.bc.accent)),
          ],
        ],
      ),
    );
  }

  Widget _modeSwitch(BuildContext context) {
    return SegmentedButton<bool>(
      showSelectedIcon: false,
      segments: [
        ButtonSegment(
            value: false,
            icon: const Icon(Icons.bolt, size: 18),
            label: Text(tr('VELOCE', 'QUICK'))),
        ButtonSegment(
            value: true,
            icon: const Icon(Icons.school_outlined, size: 18),
            label: Text(tr('SPIEGA', 'EXPLAIN'))),
      ],
      selected: {s.explain},
      onSelectionChanged: (v) {
        hapticTick();
        setState(() => s.setExplain(v.first));
      },
    );
  }

  Widget _allBases(BuildContext context, ParsedNumber n) {
    final cs = context.cs;
    final bases = <int>{2, 8, 10, 16, _from, _to}.toList()..sort();
    return Panel(
      key: const ValueKey('all'),
      title: tr('Tutte le basi', 'All bases'),
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          for (final b in bases)
            InkWell(
              onTap: () => copyText(context, convertNumber(n, b).plain),
              onLongPress: () => _setTo(b),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                child: Row(
                  children: [
                    SizedBox(
                      width: 48,
                      child: Text(baseTag(b),
                          style: pixelStyle(
                              size: 11,
                              color: b == _to ? cs.primary : cs.onSurfaceVariant)),
                    ),
                    Expanded(
                      child: Text(
                        groupDigits(convertNumber(n, b).display,
                            s.groupDigits ? groupSizeFor(b) : 0),
                        style: termStyle(
                            size: 26, color: b == _from ? cs.onSurfaceVariant : cs.onSurface),
                      ),
                    ),
                    Icon(Icons.copy, size: 14, color: cs.onSurfaceVariant),
                  ],
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 8),
            child: Text(
                tr('Tocca per copiare · tieni premuto per usarla come destinazione',
                    'Tap to copy · long-press to make it the target'),
                style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}

class _SwapIcon extends StatelessWidget {
  const _SwapIcon();
  @override
  Widget build(BuildContext context) =>
      Icon(Icons.swap_horiz, color: context.cs.onPrimary, size: 26);
}

class _KeypadDock extends StatelessWidget {
  const _KeypadDock({required this.open, required this.onToggle, required this.child});
  final bool open;
  final VoidCallback onToggle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    return Container(
      decoration: BoxDecoration(
        color: context.bc.panel,
        border: Border(top: BorderSide(color: cs.outlineVariant)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: onToggle,
            child: SizedBox(
              height: 26,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(open ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up,
                      size: 18, color: cs.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(tr('TASTIERINO', 'KEYPAD'),
                      style: pixelStyle(size: 9, color: cs.onSurfaceVariant)),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            child: open
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(6, 0, 6, 6),
                    child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 560), child: child),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}
