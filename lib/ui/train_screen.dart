import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/files.dart';
import '../app/pdf_docs.dart';
import '../app/settings.dart';
import '../logic/base_ops.dart';
import '../logic/exercises.dart';
import 'common.dart';
import 'converter_screen.dart' show isTouchLayout;
import 'share_sheet.dart';
import 'widgets/base_wheel.dart';
import 'widgets/fx.dart';
import 'widgets/keypad.dart';

class TrainScreen extends StatefulWidget {
  const TrainScreen({super.key});

  @override
  State<TrainScreen> createState() => _TrainScreenState();
}

class _TrainScreenState extends State<TrainScreen> {
  int _view = 0;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 4, 14, 10),
              child: SizedBox(
                width: double.infinity,
                child: SegmentedButton<int>(
                  showSelectedIcon: false,
                  segments: [
                    ButtonSegment(
                        value: 0,
                        icon: const Icon(Icons.timer_outlined, size: 18),
                        label: Text(tr('SFIDA', 'CHALLENGE'))),
                    ButtonSegment(
                        value: 1,
                        icon: const Icon(Icons.edit_note, size: 18),
                        label: Text(tr('PRATICA', 'PRACTICE'))),
                    ButtonSegment(
                        value: 2,
                        icon: const Icon(Icons.emoji_events_outlined, size: 18),
                        label: Text(tr('RECORD', 'RECORDS'))),
                  ],
                  selected: {_view},
                  onSelectionChanged: (v) {
                    hapticTick();
                    setState(() => _view = v.first);
                  },
                ),
              ),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: switch (_view) {
                  0 => const _ChallengeSetup(key: ValueKey(0)),
                  1 => const _PracticeView(key: ValueKey(1)),
                  _ => const _RecordsView(key: ValueKey(2)),
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Answer input shared by practice and challenge
// ---------------------------------------------------------------------------

class _AnswerInput extends StatelessWidget {
  const _AnswerInput({
    required this.controller,
    required this.focus,
    required this.base,
    required this.onSubmit,
    this.state,
  });
  final TextEditingController controller;
  final FocusNode focus;
  final int base;
  final VoidCallback onSubmit;
  final bool? state; // null = neutral, true = right, false = wrong

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final bc = context.bc;
    final useKeypad = isTouchLayout(context) && AppSettings.instance.keypad;
    final color = state == null ? cs.primary : (state! ? bc.ok : bc.bad);
    return TextField(
      controller: controller,
      focusNode: focus,
      autofocus: !useKeypad,
      keyboardType: useKeypad ? TextInputType.none : TextInputType.visiblePassword,
      showCursor: true,
      autocorrect: false,
      enableSuggestions: false,
      textCapitalization: TextCapitalization.characters,
      textInputAction: TextInputAction.done,
      onSubmitted: (_) => onSubmit(),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9A-Za-z \-]')),
        LengthLimitingTextInputFormatter(64),
      ],
      style: termStyle(size: 38, color: state == null ? cs.onSurface : color, height: 1.1),
      decoration: InputDecoration(
        hintText: tr('risposta in base $base', 'answer in base $base'),
        hintStyle: TextStyle(fontSize: 14, color: cs.onSurfaceVariant),
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 12, right: 6),
          child: Text('>', style: termStyle(size: 34, color: color)),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        suffixText: subscriptOf(base),
        enabledBorder: OutlineInputBorder(
          borderRadius: appLook.br(6),
          borderSide: BorderSide(color: state == null ? cs.outline : color, width: state == null ? 1 : 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: appLook.br(6),
          borderSide: BorderSide(color: color, width: 2),
        ),
      ),
    );
  }
}

String subscriptOf(int n) {
  const subs = '₀₁₂₃₄₅₆₇₈₉';
  return n.toString().split('').map((c) => subs[int.parse(c)]).join();
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({required this.ex});
  final Exercise ex;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(ex.category.toUpperCase(), style: pixelStyle(size: 10, color: cs.onSurfaceVariant)),
        const SizedBox(height: 8),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.end,
          children: [
            Text(ex.question, style: termStyle(size: ex.question.length > 18 ? 34 : 46, color: cs.primary)),
            Padding(
              padding: const EdgeInsets.only(left: 2, bottom: 4),
              child: Text('${ex.questionBase}',
                  style: monoStyle(size: 17, weight: FontWeight.w700, color: cs.onSurfaceVariant)),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(ex.prompt, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}

Widget _keypadFor(BuildContext context, int base, TextEditingController c, VoidCallback submit) {
  if (!(isTouchLayout(context) && AppSettings.instance.keypad)) return const SizedBox.shrink();
  return Container(
    padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
    decoration: BoxDecoration(
      color: context.bc.panel,
      border: Border(top: BorderSide(color: context.cs.outlineVariant)),
    ),
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 560),
      child: BaseKeypad(
          base: base, controller: c, allowPoint: false, allowMinus: false, onSubmit: submit),
    ),
  );
}

// ---------------------------------------------------------------------------
// Practice (untimed, with hints and worked solutions)
// ---------------------------------------------------------------------------

class _PracticeView extends StatefulWidget {
  const _PracticeView({super.key});

  @override
  State<_PracticeView> createState() => _PracticeViewState();
}

class _PracticeViewState extends State<_PracticeView> {
  final _gen = ExerciseGenerator();
  final _c = TextEditingController();
  final _focus = FocusNode();
  Topic _topic = Topic.binDec;
  Difficulty _diff = Difficulty.easy;
  late Exercise _ex = _gen.topic(_topic, _diff);
  bool? _state;
  bool _hint = false;
  bool _solution = false;
  int _right = 0;
  int _tried = 0;
  int _streak = 0;
  int _shake = 0;

  @override
  void dispose() {
    _c.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _next() {
    setState(() {
      _ex = _gen.topic(_topic, _diff);
      _c.clear();
      _state = null;
      _hint = false;
      _solution = false;
    });
    if (!(isTouchLayout(context) && AppSettings.instance.keypad)) _focus.requestFocus();
  }

  void _check() {
    if (_state == true) {
      _next();
      return;
    }
    if (_c.text.trim().isEmpty) return;
    final ok = _ex.check(_c.text);
    setState(() {
      if (_state == null) _tried++;
      if (ok) {
        if (_state == null) _right++;
        _streak++;
        hapticOk();
      } else {
        _streak = 0;
        _shake++;
        hapticBad();
      }
      _state = ok;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final bc = context.bc;
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 24),
            children: [
              SizedBox(
                height: 38,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    for (final t in Topic.values)
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text(t.label, style: const TextStyle(fontSize: 12)),
                          selected: _topic == t,
                          onSelected: (_) {
                            _topic = t;
                            _next();
                          },
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _DifficultyPicker(value: _diff, onChanged: (d) {
                    _diff = d;
                    _next();
                  })),
                  const SizedBox(width: 10),
                  _Stat(label: tr('giuste', 'right'), value: '$_right/$_tried'),
                  const SizedBox(width: 6),
                  _Stat(label: tr('serie', 'streak'), value: '$_streak', hot: _streak >= 3),
                ],
              ),
              const SizedBox(height: 12),
              Panel(
                title: tr('Esercizio', 'Exercise'),
                highlight: _state == true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _QuestionCard(ex: _ex),
                    const SizedBox(height: 14),
                    Shake(
                      trigger: _shake,
                      child: _AnswerInput(
                          controller: _c, focus: _focus, base: _ex.answerBase,
                          onSubmit: _check, state: _state),
                    ),
                    const SizedBox(height: 10),
                    if (_state == true)
                      Appear(child: Text(tr('Esatto! ', 'Correct! ') + _ex.answerDisplay,
                          style: TextStyle(color: bc.ok, fontWeight: FontWeight.w800)))
                    else if (_state == false)
                      Appear(child: Text(tr('Non ancora: riprova o guarda la soluzione.',
                          'Not yet: try again or look at the solution.'),
                          style: TextStyle(color: bc.bad, fontWeight: FontWeight.w700))),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FilledButton.icon(
                          onPressed: _check,
                          icon: Icon(_state == true ? Icons.arrow_forward : Icons.check, size: 18),
                          label: Text(_state == true ? tr('Prossimo', 'Next') : tr('Controlla', 'Check')),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => setState(() => _hint = !_hint),
                          icon: const Icon(Icons.lightbulb_outline, size: 18),
                          label: Text(tr('Aiuto', 'Hint')),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => setState(() => _solution = !_solution),
                          icon: const Icon(Icons.visibility_outlined, size: 18),
                          label: Text(tr('Soluzione', 'Solution')),
                        ),
                        if (_state != true)
                          TextButton(onPressed: _next, child: Text(tr('Salta', 'Skip'))),
                      ],
                    ),
                    if (_hint) ...[
                      const SizedBox(height: 12),
                      Appear(child: InfoCard(child: RichLine(_ex.hint, size: 14))),
                    ],
                    if (_solution) ...[
                      const SizedBox(height: 12),
                      Appear(child: _SolutionBox(ex: _ex)),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                tr('Puoi scrivere la risposta con o senza zeri iniziali, maiuscole o minuscole.',
                    'You can type the answer with or without leading zeros, upper or lower case.'),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ),
        _keypadFor(context, _ex.answerBase, _c, _check),
      ],
    );
  }
}

class _SolutionBox extends StatelessWidget {
  const _SolutionBox({required this.ex});
  final Exercise ex;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    return InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final l in ex.solution)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: MathText(l, style: monoStyle(size: 13)),
            ),
          const SizedBox(height: 6),
          Text('= ${ex.answerDisplay}',
              style: monoStyle(size: 18, weight: FontWeight.w800, color: cs.primary)),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, this.hot = false});
  final String label;
  final String value;
  final bool hot;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: context.bc.panelHi,
        borderRadius: appLook.br(5),
        border: Border.all(color: hot ? context.bc.accent : cs.outlineVariant),
      ),
      child: Column(
        children: [
          Text(value, style: termStyle(size: 24, color: hot ? context.bc.accent : cs.primary)),
          Text(label.toUpperCase(), style: pixelStyle(size: 8, color: cs.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _DifficultyPicker extends StatelessWidget {
  const _DifficultyPicker({required this.value, required this.onChanged});
  final Difficulty value;
  final ValueChanged<Difficulty> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<Difficulty>(
      showSelectedIcon: false,
      style: const ButtonStyle(visualDensity: VisualDensity.compact),
      segments: [
        for (final d in Difficulty.values)
          ButtonSegment(value: d, label: Text(d.label, style: const TextStyle(fontSize: 12))),
      ],
      selected: {value},
      onSelectionChanged: (v) {
        hapticTick();
        onChanged(v.first);
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Timed challenge
// ---------------------------------------------------------------------------

enum ChallengeMode { conversions, operations, mixed, twos }

class ChallengeConfig {
  ChallengeConfig({
    required this.mode,
    required this.from,
    required this.to,
    required this.randomBases,
    required this.opBase,
    required this.ops,
    required this.difficulty,
    required this.count,
  });
  final ChallengeMode mode;
  final int from;
  final int to;
  final bool randomBases;
  final int opBase;
  final Set<Op> ops;
  final Difficulty difficulty;
  final int count;

  String get key {
    final conv = randomBases ? 'rnd' : '$from>$to';
    final o = (ops.map((e) => e.index).toList()..sort()).join();
    return switch (mode) {
      ChallengeMode.conversions => 'c|$conv|${difficulty.index}|$count',
      ChallengeMode.operations => 'o|$opBase|$o|${difficulty.index}|$count',
      ChallengeMode.mixed => 'm|$conv|$opBase|$o|${difficulty.index}|$count',
      ChallengeMode.twos => 't|${difficulty.index}|$count',
    };
  }

  String get label {
    final conv = randomBases ? tr('basi casuali', 'random bases') : '$from → $to';
    final o = ops.map((e) => e.symbol).join(' ');
    final what = switch (mode) {
      ChallengeMode.conversions => '${tr('Conversioni', 'Conversions')} $conv',
      ChallengeMode.operations => '${tr('Operazioni', 'Operations')} $o ${tr('in base', 'in base')} $opBase',
      ChallengeMode.mixed => '${tr('Misto', 'Mixed')} · $conv · $o (b$opBase)',
      ChallengeMode.twos => tr('Complemento a 2', 'Two’s complement'),
    };
    return '$what · ${difficulty.label} · $count';
  }

  Exercise make(ExerciseGenerator g, Random r) {
    Exercise conv() {
      if (randomBases) {
        const common = [2, 8, 10, 16];
        final a = common[r.nextInt(4)];
        var b = common[r.nextInt(4)];
        while (b == a) {
          b = common[r.nextInt(4)];
        }
        return g.conversion(a, b, difficulty);
      }
      return g.conversion(from, to, difficulty);
    }

    Exercise op() {
      final list = ops.isEmpty ? Op.values : ops.toList();
      return g.operation(list[r.nextInt(list.length)], opBase, difficulty);
    }

    return switch (mode) {
      ChallengeMode.conversions => conv(),
      ChallengeMode.operations => op(),
      ChallengeMode.mixed => r.nextBool() ? conv() : op(),
      ChallengeMode.twos => g.twos(difficulty),
    };
  }
}

class _ChallengeSetup extends StatefulWidget {
  const _ChallengeSetup({super.key});

  @override
  State<_ChallengeSetup> createState() => _ChallengeSetupState();
}

class _ChallengeSetupState extends State<_ChallengeSetup> {
  static ChallengeMode _mode = ChallengeMode.conversions;
  static int _from = 10;
  static int _to = 2;
  static bool _random = false;
  static int _opBase = 2;
  static final Set<Op> _ops = {Op.add, Op.sub};
  static Difficulty _diff = Difficulty.easy;
  static int _count = 10;

  ChallengeConfig get _config => ChallengeConfig(
        mode: _mode,
        from: _from,
        to: _to,
        randomBases: _random,
        opBase: _opBase,
        ops: Set.of(_ops),
        difficulty: _diff,
        count: _count,
      );

  bool _making = false;

  /// Paper version of the current setup, with the answer key at the end.
  Future<void> _worksheet() async {
    if (_making) return;
    if (showConvFor(_mode) && !_random && _from == _to) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(tr('Scegli due basi diverse', 'Pick two different bases'))));
      return;
    }
    final w = reserveWindow();
    setState(() => _making = true);
    try {
      final cfg = _config;
      final gen = ExerciseGenerator();
      final rng = Random();
      final seen = <String>{};
      final items = <Exercise>[];
      for (var i = 0; i < cfg.count; i++) {
        var ex = cfg.make(gen, rng);
        for (var k = 0; k < 12 && seen.contains(ex.prompt); k++) {
          ex = cfg.make(gen, rng);
        }
        seen.add(ex.prompt);
        items.add(ex);
      }
      final pdf = await worksheetPdf(items, cfg.label);
      final d = DateTime.now();
      final name = 'basil-scheda-${d.year}${d.month.toString().padLeft(2, '0')}${d.day.toString().padLeft(2, '0')}.pdf';
      await showPdf(pdf, name, window: w);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(tr('Impossibile creare il PDF', 'Could not create the PDF'))));
      }
    } finally {
      if (mounted) setState(() => _making = false);
    }
  }

  void _start() {
    if ((_mode == ChallengeMode.operations || _mode == ChallengeMode.mixed) && _ops.isEmpty) return;
    if (showConvFor(_mode) && !_random && _from == _to) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(tr('Scegli due basi diverse', 'Pick two different bases'))));
      return;
    }
    Navigator.of(context).push(PageRouteBuilder<void>(
      pageBuilder: (_, _, _) => ChallengeRun(config: _config),
      transitionsBuilder: (_, a, _, child) => FadeTransition(opacity: a, child: child),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final best = AppSettings.instance.history.where((r) => r.key == _config.key).fold<TrainingRecord?>(
        null, (b, r) => b == null || r.betterThan(b) ? r : b);
    final showConv = _mode == ChallengeMode.conversions || _mode == ChallengeMode.mixed;
    final showOps = _mode == ChallengeMode.operations || _mode == ChallengeMode.mixed;

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 28),
      children: [
        Appear(
          child: Panel(
            title: tr('1 · Cosa vuoi allenare', '1 · What to train'),
            child: SegmentedButton<ChallengeMode>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(value: ChallengeMode.conversions, label: Text(tr('Conversioni', 'Conversions'), style: const TextStyle(fontSize: 12))),
                ButtonSegment(value: ChallengeMode.operations, label: Text(tr('Operazioni', 'Operations'), style: const TextStyle(fontSize: 12))),
                ButtonSegment(value: ChallengeMode.mixed, label: Text(tr('Misto', 'Mixed'), style: const TextStyle(fontSize: 12))),
                ButtonSegment(value: ChallengeMode.twos, label: Text(tr('Compl. 2', 'Two’s c.'), style: const TextStyle(fontSize: 12))),
              ],
              selected: {_mode},
              onSelectionChanged: (v) => setState(() => _mode = v.first),
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (showConv)
          Appear(
            delay: 40,
            child: Panel(
              title: tr('2 · Basi della conversione', '2 · Conversion bases'),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(tr('casuali', 'random'), style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                Switch(value: _random, onChanged: (v) => setState(() => _random = v)),
              ]),
              child: AnimatedCrossFade(
                duration: const Duration(milliseconds: 220),
                crossFadeState: _random ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                firstChild: Row(
                  children: [
                    Expanded(child: Column(children: [
                      BaseWheel(value: _from, height: 128, label: tr('da', 'from'), onChanged: (b) => setState(() => _from = b)),
                      const SizedBox(height: 6),
                      QuickBases(value: _from, onPick: (b) => setState(() => _from = b)),
                    ])),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: IconButton.filledTonal(
                        onPressed: () => setState(() {
                          final t = _from;
                          _from = _to;
                          _to = t;
                        }),
                        icon: const Icon(Icons.swap_horiz),
                      ),
                    ),
                    Expanded(child: Column(children: [
                      BaseWheel(value: _to, height: 128, label: tr('a', 'to'), onChanged: (b) => setState(() => _to = b)),
                      const SizedBox(height: 6),
                      QuickBases(value: _to, onPick: (b) => setState(() => _to = b)),
                    ])),
                  ],
                ),
                secondChild: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(tr('Ogni domanda usa una coppia casuale tra BIN, OCT, DEC e HEX.',
                      'Each question uses a random pair among BIN, OCT, DEC and HEX.')),
                ),
              ),
            ),
          ),
        if (showConv) const SizedBox(height: 12),
        if (showOps)
          Appear(
            delay: 80,
            child: Panel(
              title: tr('Operazioni', 'Operations'),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 130,
                    child: BaseWheel(value: _opBase, height: 128, label: tr('base', 'base'),
                        onChanged: (b) => setState(() => _opBase = b)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 22),
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final o in Op.values)
                            FilterChip(
                              label: Text(o.symbol, style: monoStyle(size: 18, weight: FontWeight.w800)),
                              selected: _ops.contains(o),
                              onSelected: (v) => setState(() {
                                if (v) {
                                  _ops.add(o);
                                } else if (_ops.length > 1) {
                                  _ops.remove(o);
                                }
                              }),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (showOps) const SizedBox(height: 12),
        Appear(
          delay: 120,
          child: Panel(
            title: tr('3 · Difficoltà e numero di domande', '3 · Difficulty and number of questions'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _DifficultyPicker(value: _diff, onChanged: (d) => setState(() => _diff = d)),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Text('$_count', style: termStyle(size: 44, color: cs.primary)),
                    const SizedBox(width: 8),
                    Text(tr('domande', 'questions'), style: TextStyle(color: cs.onSurfaceVariant)),
                    const Spacer(),
                    IconButton.outlined(
                      onPressed: _count > 1 ? () => setState(() => _count--) : null,
                      icon: const Icon(Icons.remove),
                    ),
                    const SizedBox(width: 6),
                    IconButton.outlined(
                      onPressed: _count < 100 ? () => setState(() => _count++) : null,
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),
                Slider(
                  value: _count.toDouble(),
                  min: 1,
                  max: 100,
                  divisions: 99,
                  label: '$_count',
                  onChanged: (v) {
                    if (v.round() != _count) hapticTick();
                    setState(() => _count = v.round());
                  },
                ),
                Wrap(
                  spacing: 6,
                  children: [
                    for (final n in const [5, 10, 20, 30, 50])
                      ChoiceChip(
                        label: Text('$n'),
                        selected: _count == n,
                        onSelected: (_) => setState(() => _count = n),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (best != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Icon(Icons.emoji_events, size: 18, color: context.bc.accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                      tr('Record: ${best.correct}/${best.total} in ${formatMillis(best.millis)}',
                          'Best: ${best.correct}/${best.total} in ${formatMillis(best.millis)}'),
                      style: monoStyle(size: 14, weight: FontWeight.w700)),
                ),
              ],
            ),
          ),
        SizedBox(
          height: 58,
          child: FilledButton.icon(
            onPressed: _start,
            icon: const Icon(Icons.play_arrow_rounded, size: 28),
            label: Text(tr('VIA!', 'START'), style: pixelStyle(size: 18)),
          ),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: _worksheet,
          icon: const Icon(Icons.print_outlined, size: 18),
          label: Text(tr('Scheda da stampare (PDF)', 'Printable sheet (PDF)')),
        ),
        const SizedBox(height: 8),
        Text(
          tr('Il tempo parte dopo il conto alla rovescia. Risposta sbagliata = si vede quella giusta e si va avanti.',
              'The clock starts after the countdown. Wrong answer = you see the right one and move on.'),
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _Answered {
  _Answered(this.ex, this.given, this.ok, this.millis);
  final Exercise ex;
  final String given;
  final bool ok;
  final int millis;
}

class ChallengeRun extends StatefulWidget {
  const ChallengeRun({super.key, required this.config});
  final ChallengeConfig config;

  @override
  State<ChallengeRun> createState() => _ChallengeRunState();
}

class _ChallengeRunState extends State<ChallengeRun> {
  final _gen = ExerciseGenerator();
  final _rng = Random();
  final _c = TextEditingController();
  final _focus = FocusNode();
  final _watch = Stopwatch();
  final List<_Answered> _done = [];
  Timer? _ticker;
  int _countdown = 3;
  late Exercise _ex;
  int _qStart = 0;
  bool? _flash;
  int _shake = 0;
  bool _finished = false;
  bool _newBest = false;
  TrainingRecord? _prevBest;

  final Set<String> _seen = {};

  /// A new exercise, avoiding repeats within the same run when possible.
  Exercise _fresh() {
    var ex = widget.config.make(_gen, _rng);
    for (var i = 0; i < 12 && _seen.contains(ex.prompt); i++) {
      ex = widget.config.make(_gen, _rng);
    }
    _seen.add(ex.prompt);
    return ex;
  }

  @override
  void initState() {
    super.initState();
    _ex = _fresh();
    _ticker = Timer.periodic(const Duration(milliseconds: 100), (_) => _onTick());
  }

  int _cd = 0;
  void _onTick() {
    if (!mounted) return;
    if (_countdown > 0) {
      _cd++;
      if (_cd % 7 == 0) {
        setState(() => _countdown--);
        if (_countdown == 0) {
          hapticOk();
          _watch.start();
          _qStart = 0;
          if (!(isTouchLayout(context) && AppSettings.instance.keypad)) _focus.requestFocus();
        } else {
          hapticTick();
        }
      }
      return;
    }
    if (!_finished) setState(() {});
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _c.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _submit({bool skip = false}) {
    if (_countdown > 0 || _finished || _flash != null) return;
    if (!skip && _c.text.trim().isEmpty) return;
    final ok = !skip && _ex.check(_c.text);
    final now = _watch.elapsedMilliseconds;
    _done.add(_Answered(_ex, skip ? '-' : _c.text.trim().toUpperCase(), ok, now - _qStart));
    ok ? hapticOk() : hapticBad();
    setState(() {
      _flash = ok;
      if (!ok) _shake++;
    });
    Future.delayed(Duration(milliseconds: ok ? 260 : 1100), () {
      if (!mounted) return;
      if (_done.length >= widget.config.count) {
        _finish();
      } else {
        setState(() {
          _ex = _fresh();
          _c.clear();
          _flash = null;
          _qStart = _watch.elapsedMilliseconds;
        });
        if (!(isTouchLayout(context) && AppSettings.instance.keypad)) _focus.requestFocus();
      }
    });
  }

  void _finish() {
    _watch.stop();
    final correct = _done.where((d) => d.ok).length;
    final rec = TrainingRecord(
      key: widget.config.key,
      label: widget.config.label,
      total: _done.length,
      correct: correct,
      millis: _watch.elapsedMilliseconds,
      when: DateTime.now(),
    );
    for (final r in AppSettings.instance.history) {
      if (r.key == rec.key && (_prevBest == null || r.betterThan(_prevBest!))) _prevBest = r;
    }
    _newBest = AppSettings.instance.addRecord(rec);
    setState(() {
      _finished = true;
      _flash = null;
    });
  }

  Future<bool> _confirmQuit() async {
    if (_finished || _countdown > 0) return true;
    final r = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('Abbandonare la sfida?', 'Quit the challenge?')),
        content: Text(tr('Il risultato non verrà salvato.', 'Your result will not be saved.')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(tr('Continua', 'Keep going'))),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(tr('Esci', 'Quit'))),
        ],
      ),
    );
    return r ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _finished || _countdown > 0,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final nav = Navigator.of(context);
        if (await _confirmQuit()) {
          _ticker?.cancel();
          _finished = true;
          nav.pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_finished ? tr('Risultati', 'Results') : tr('Sfida', 'Challenge')),
        ),
        body: SafeArea(
          top: false,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            child: _countdown > 0
                ? _countdownView(context)
                : _finished
                    ? _results(context)
                    : _question(context),
          ),
        ),
      ),
    );
  }

  Widget _countdownView(BuildContext context) {
    final cs = context.cs;
    return Center(
      key: const ValueKey('cd'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TweenAnimationBuilder<double>(
            key: ValueKey(_countdown),
            tween: Tween(begin: 1.8, end: 1),
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutBack,
            builder: (_, v, child) => Transform.scale(scale: v, child: child),
            child: Text('$_countdown', style: termStyle(size: 160, color: cs.primary)),
          ),
          const SizedBox(height: 12),
          Text(widget.config.label, textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }

  Widget _question(BuildContext context) {
    final cs = context.cs;
    final bc = context.bc;
    final n = widget.config.count;
    // While the answer feedback is showing, keep counting the current question.
    final i = _flash == null ? _done.length : _done.length - 1;
    final right = _done.where((d) => d.ok).length;
    return Column(
      key: const ValueKey('q'),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Row(
            children: [
              Text(formatMillis(_watch.elapsedMilliseconds),
                  style: termStyle(size: 40, color: cs.primary)),
              const Spacer(),
              Text('${min(i + 1, n)}/$n', style: termStyle(size: 30, color: cs.onSurface)),
              const SizedBox(width: 14),
              Icon(Icons.check, size: 18, color: bc.ok),
              Text('$right', style: termStyle(size: 28, color: bc.ok)),
            ],
          ),
        ),
        LinearProgressIndicator(value: i / n, minHeight: 4),
        Expanded(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: KeyedSubtree(key: ValueKey(i), child: _QuestionCard(ex: _ex)),
                  ),
                  const SizedBox(height: 18),
                  Shake(
                    trigger: _shake,
                    child: _AnswerInput(
                        controller: _c, focus: _focus, base: _ex.answerBase,
                        onSubmit: _submit, state: _flash),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 28,
                    child: _flash == false
                        ? Text('${tr('Era', 'It was')}: ${_ex.answerDisplay}',
                            style: monoStyle(size: 16, weight: FontWeight.w800, color: bc.bad))
                        : null,
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => _submit(),
                          icon: const Icon(Icons.keyboard_return, size: 18),
                          label: Text(tr('Invia', 'Submit')),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: () => _submit(skip: true),
                        child: Text(tr('Salta', 'Skip')),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        _keypadFor(context, _ex.answerBase, _c, _submit),
      ],
    );
  }

  Widget _results(BuildContext context) {
    final cs = context.cs;
    final bc = context.bc;
    final total = _done.length;
    final correct = _done.where((d) => d.ok).length;
    final ms = _watch.elapsedMilliseconds;
    final avg = total == 0 ? 0 : ms ~/ total;
    final pct = total == 0 ? 0 : (correct * 100 / total).round();
    final wrong = _done.where((d) => !d.ok).toList();
    final (title, line) = switch (pct) {
      100 => (tr('Perfetto', 'Perfect'), tr('Tutto giusto, niente da ripassare.', 'All correct, nothing to review.')),
      >= 80 => (tr('Ottimo', 'Great'), tr('Quasi tutto giusto. Sotto trovi cosa ripassare.', 'Almost all correct. Below is what to review.')),
      >= 50 => (tr('Ci sei quasi', 'Getting there'), tr('Ripassa gli errori e riprova.', 'Review the mistakes and try again.')),
      _ => (tr('Da ripassare', 'Needs review'), tr('Apri le soluzioni qui sotto, poi riprova con calma.', 'Open the solutions below, then try again calmly.')),
    };
    final prev = _prevBest;
    String? compare;
    if (prev != null) {
      if (_newBest) {
        compare = prev.correct < correct
            ? tr('Record precedente ${prev.correct}/${prev.total}', 'Previous best ${prev.correct}/${prev.total}')
            : tr('${((prev.millis - ms) / 1000).toStringAsFixed(1)}s più veloce del record precedente',
                '${((prev.millis - ms) / 1000).toStringAsFixed(1)}s faster than your previous best');
      } else {
        compare = tr('Record ${prev.correct}/${prev.total} in ${formatMillis(prev.millis)}',
            'Best ${prev.correct}/${prev.total} in ${formatMillis(prev.millis)}');
      }
    }
    final ringColor = pct == 100 ? bc.ok : (pct >= 50 ? cs.primary : bc.accent);

    return Align(
      key: const ValueKey('res'),
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          children: [
            Appear(
              child: Panel(
                title: widget.config.label,
                highlight: _newBest,
                child: Row(
                  children: [
                    _ScoreRing(value: total == 0 ? 0 : correct / total, color: ringColor, label: '$correct/$total'),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(title, style: pixelStyle(size: 17, color: cs.onSurface)),
                              if (_newBest)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: bc.accent.withAlpha(36),
                                    border: Border.all(color: bc.accent.withAlpha(160)),
                                    borderRadius: appLook.br(4),
                                  ),
                                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                                    Icon(Icons.emoji_events, size: 13, color: bc.accent),
                                    const SizedBox(width: 4),
                                    Text(tr('RECORD', 'RECORD'), style: pixelStyle(size: 9, color: bc.accent)),
                                  ]),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(line, style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant, height: 1.35)),
                          if (compare != null) ...[
                            const SizedBox(height: 4),
                            Text(compare, style: monoStyle(size: 12, color: _newBest ? bc.accent : cs.onSurfaceVariant)),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: _ResultStat(value: formatMillis(ms), label: tr('tempo', 'time'))),
              const SizedBox(width: 8),
              Expanded(child: _ResultStat(value: '${(avg / 1000).toStringAsFixed(1)}s', label: tr('a domanda', 'per question'))),
              const SizedBox(width: 8),
              Expanded(child: _ResultStat(value: '$pct%', label: tr('precisione', 'accuracy'), color: ringColor)),
            ]),
            const SizedBox(height: 10),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                for (var i = 0; i < _done.length; i++)
                  Tooltip(
                    message: '${i + 1} · ${(_done[i].millis / 1000).toStringAsFixed(1)}s',
                    child: Container(
                      width: 26,
                      height: 26,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: (_done[i].ok ? bc.ok : bc.bad).withAlpha(36),
                        border: Border.all(color: (_done[i].ok ? bc.ok : bc.bad).withAlpha(150)),
                        borderRadius: appLook.br(4),
                      ),
                      child: Text('${i + 1}',
                          style: monoStyle(size: 11, weight: FontWeight.w800, color: _done[i].ok ? bc.ok : bc.bad)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).pushReplacement(PageRouteBuilder<void>(
                pageBuilder: (_, _, _) => ChallengeRun(config: widget.config),
                transitionsBuilder: (_, a, _, child) => FadeTransition(opacity: a, child: child),
              )),
              icon: const Icon(Icons.replay),
              label: Text(tr('Riprova', 'Try again')),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => showResultShare(
                      context,
                      ShareData(
                        label: widget.config.label,
                        correct: correct,
                        total: total,
                        millis: ms,
                        newBest: _newBest,
                        buildPdf: () => resultsPdf(
                          [for (final d in _done) ResultRow(d.ex, d.given, d.ok, d.millis)],
                          widget.config.label,
                          ms,
                          DateTime.now(),
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.ios_share, size: 18),
                    label: Text(tr('Condividi', 'Share')),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(tr('Fine', 'Done')),
                  ),
                ),
              ],
            ),
            if (wrong.isNotEmpty) ...[
              const SizedBox(height: 22),
              Text(tr('DA RIVEDERE', 'TO REVIEW'), style: pixelStyle(size: 11, color: cs.onSurfaceVariant)),
              const SizedBox(height: 8),
              for (final w in wrong)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Card(
                    child: ExpansionTile(
                      shape: const Border(),
                      title: MathText(w.ex.prompt, style: monoStyle(size: 14, weight: FontWeight.w700)),
                      subtitle: Text(
                          '${tr('tua', 'yours')}: ${w.given}   ·   ${tr('giusta', 'right')}: ${w.ex.answerDisplay}',
                          style: monoStyle(size: 12, color: bc.bad)),
                      childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                      children: [_SolutionBox(ex: w.ex)],
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ResultStat extends StatelessWidget {
  const _ResultStat({required this.value, required this.label, this.color});
  final String value;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: context.bc.panel.withAlpha(context.isDark ? 235 : 245),
        border: Border.all(color: cs.outlineVariant),
        borderRadius: appLook.br(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, maxLines: 1, style: termStyle(size: 30, color: color ?? cs.onSurface)),
          ),
          const SizedBox(height: 2),
          Text(label.toUpperCase(),
              maxLines: 1, overflow: TextOverflow.ellipsis, style: pixelStyle(size: 8, color: cs.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _ScoreRing extends StatelessWidget {
  const _ScoreRing({required this.value, required this.color, required this.label});
  final double value;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    return SizedBox.square(
      dimension: 84,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: value),
        duration: animationsOn(context) ? const Duration(milliseconds: 700) : Duration.zero,
        curve: Curves.easeOutCubic,
        builder: (context, v, _) => Stack(
          fit: StackFit.expand,
          children: [
            CircularProgressIndicator(
              value: v,
              strokeWidth: 7,
              strokeCap: StrokeCap.round,
              color: color,
              backgroundColor: cs.surfaceContainerHighest,
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(label, style: termStyle(size: 28, color: cs.onSurface)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Records
// ---------------------------------------------------------------------------

class _RecordsView extends StatelessWidget {
  const _RecordsView({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppSettings.instance,
      builder: (context, _) {
        final cs = context.cs;
        final all = AppSettings.instance.history;
        if (all.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.emoji_events_outlined, size: 48, color: cs.onSurfaceVariant),
                  const SizedBox(height: 12),
                  Text(tr('Nessuna sfida ancora. Fai la prima!', 'No challenges yet. Do your first one!'),
                      textAlign: TextAlign.center),
                ],
              ),
            ),
          );
        }
        final bestByKey = <String, TrainingRecord>{};
        for (final r in all) {
          final b = bestByKey[r.key];
          if (b == null || r.betterThan(b)) bestByKey[r.key] = r;
        }
        final bests = bestByKey.values.toList()..sort((a, b) => b.when.compareTo(a.when));
        String date(DateTime d) =>
            '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
        return ListView(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 28),
          children: [
            Panel(
              title: tr('Migliori risultati', 'Personal bests'),
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  for (final r in bests)
                    ListTile(
                      leading: Icon(Icons.emoji_events, color: context.bc.accent),
                      title: Text(r.label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(formatMillis(r.millis), style: termStyle(size: 24, color: cs.primary)),
                          Text('${r.correct}/${r.total}', style: monoStyle(size: 11)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Panel(
              title: tr('Storico', 'History'),
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  for (final r in all.take(30))
                    ListTile(
                      dense: true,
                      title: Text(r.label, style: const TextStyle(fontSize: 12)),
                      subtitle: Text(date(r.when), style: const TextStyle(fontSize: 11)),
                      trailing: Text('${r.correct}/${r.total} · ${formatMillis(r.millis)}',
                          style: monoStyle(size: 12, weight: FontWeight.w700)),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Center(
              child: TextButton.icon(
                onPressed: () async {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Text(tr('Cancellare tutti i record?', 'Delete all records?')),
                      content: Text(tr('Sono salvati solo su questo dispositivo: non si possono recuperare.',
                          'They are stored only on this device: they cannot be recovered.')),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(tr('Annulla', 'Cancel'))),
                        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(tr('Cancella', 'Delete'))),
                      ],
                    ),
                  );
                  if (ok == true) AppSettings.instance.clearHistory();
                },
                icon: const Icon(Icons.delete_outline),
                label: Text(tr('Cancella record', 'Clear records')),
              ),
            ),
          ],
        );
      },
    );
  }
}

bool showConvFor(ChallengeMode m) => m == ChallengeMode.conversions || m == ChallengeMode.mixed;
