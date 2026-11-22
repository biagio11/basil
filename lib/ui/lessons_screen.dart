import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/settings.dart';
import '../content/lessons.dart';
import '../logic/base_conv.dart';
import 'common.dart';
import 'widgets/fx.dart';

class LessonsScreen extends StatelessWidget {
  const LessonsScreen({super.key, required this.onOpenPractice});
  final VoidCallback onOpenPractice;

  @override
  Widget build(BuildContext context) {
    final lessons = buildLessons(onOpenPractice: onOpenPractice);
    final cs = context.cs;
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(14, 4, 14, 28),
          children: [
            Appear(
              child: TypeText(tr('impara le basi, un passo alla volta', 'learn number bases, one step at a time'),
                  style: monoStyle(size: 14, color: cs.onSurfaceVariant)),
            ),
            const SizedBox(height: 14),
            for (var i = 0; i < lessons.length; i++)
              Appear(
                delay: 50 * i,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _LessonCard(
                    index: i + 1,
                    lesson: lessons[i],
                    onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                      builder: (_) => LessonPlayer(
                          lessonId: lessons[i].id, onOpenPractice: onOpenPractice),
                    )),
                  ),
                ),
              ),
            Appear(
              delay: 160,
              child: _LessonCard(
                index: 0,
                lesson: Lesson(
                  id: 'sheet',
                  title: tr('Tabella rapida', 'Cheat sheet'),
                  subtitle: tr('0-31 in BIN/OCT/DEC/HEX e potenze di 2',
                      '0-31 in BIN/OCT/DEC/HEX and powers of 2'),
                  icon: Icons.table_chart_outlined,
                  slides: const [],
                ),
                onTap: () => Navigator.of(context)
                    .push(MaterialPageRoute<void>(builder: (_) => const CheatSheet())),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              tr('Nelle lezioni usa le frecce ← → per cambiare slide. Con «Modo classe» '
                  'i quiz non rispondono al tocco: si vota per alzata di mano e poi si '
                  'rivela la risposta.',
                  'In lessons use the ← → arrow keys to change slide. In "Class mode" '
                  'quizzes do not react to taps: the class votes by show of hands, '
                  'then you reveal the answer.'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _LessonCard extends StatelessWidget {
  const _LessonCard({required this.index, required this.lesson, required this.onTap});
  final int index;
  final Lesson lesson;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    return Material(
      color: context.bc.panel,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: BorderSide(color: cs.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: cs.primaryContainer.withAlpha(context.isDark ? 140 : 255),
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(color: cs.primary.withAlpha(100)),
                ),
                child: index > 0
                    ? Text(index.toString().padLeft(2, '0'),
                        style: termStyle(size: 34, color: cs.primary))
                    : Icon(lesson.icon, color: cs.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(lesson.title, style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Text(lesson.subtitle, style: Theme.of(context).textTheme.bodySmall),
                    if (lesson.slides.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text('${lesson.slides.length} slide',
                          style: pixelStyle(size: 9, color: cs.onSurfaceVariant)),
                    ],
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: cs.primary),
            ],
          ),
        ),
      ),
    );
  }
}

class LessonPlayer extends StatefulWidget {
  const LessonPlayer({super.key, required this.lessonId, required this.onOpenPractice});
  final String lessonId;
  final VoidCallback onOpenPractice;

  @override
  State<LessonPlayer> createState() => _LessonPlayerState();
}

class _LessonPlayerState extends State<LessonPlayer> {
  final PageController _pc = PageController();
  int _index = 0;
  bool _classMode = false;

  Lesson get _lesson => buildLessons(onOpenPractice: widget.onOpenPractice)
      .firstWhere((l) => l.id == widget.lessonId);

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  void _go(int i, int count) {
    if (i < 0 || i >= count) return;
    _pc.animateToPage(i, duration: const Duration(milliseconds: 260), curve: Curves.easeOutCubic);
  }

  void _showJumpList(Lesson lesson) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.75),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: lesson.slides.length,
              itemBuilder: (_, i) => ListTile(
                leading: Text((i + 1).toString().padLeft(2, '0'),
                    style: termStyle(size: 24, color: context.cs.primary)),
                title: Text(lesson.slides[i].title),
                selected: i == _index,
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _pc.jumpToPage(i);
                },
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final lesson = _lesson;
    final slides = lesson.slides;
    final count = slides.length;
    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is! KeyDownEvent) return KeyEventResult.ignored;
        if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
          _go(_index + 1, count);
          return KeyEventResult.handled;
        }
        if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
          _go(_index - 1, count);
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(lesson.title),
          actions: [
            Tooltip(
              message: tr('Modo classe: i quiz si rivelano con un pulsante',
                  'Class mode: quizzes are revealed with a button'),
              child: Row(children: [
                const Icon(Icons.co_present_outlined, size: 20),
                Switch(value: _classMode, onChanged: (v) => setState(() => _classMode = v)),
              ]),
            ),
            IconButton(
              tooltip: tr('Elenco slide', 'Slide list'),
              onPressed: () => _showJumpList(lesson),
              icon: const Icon(Icons.list),
            ),
          ],
        ),
        body: Column(
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(end: (_index + 1) / count),
              duration: const Duration(milliseconds: 300),
              builder: (_, v, _) => LinearProgressIndicator(value: v, minHeight: 3),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pc,
                itemCount: count,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) => _SlideView(slide: slides[i], classMode: _classMode, n: i + 1),
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
                child: Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: _index > 0 ? () => _go(_index - 1, count) : null,
                      icon: const Icon(Icons.arrow_back, size: 18),
                      label: Text(tr('Indietro', 'Back')),
                    ),
                    Expanded(
                      child: Text('${_index + 1} / $count',
                          textAlign: TextAlign.center, style: termStyle(size: 26)),
                    ),
                    FilledButton.icon(
                      onPressed: _index < count - 1
                          ? () => _go(_index + 1, count)
                          : () => Navigator.of(context).pop(),
                      icon: Icon(_index < count - 1 ? Icons.arrow_forward : Icons.check, size: 18),
                      label: Text(_index < count - 1 ? tr('Avanti', 'Next') : tr('Fine', 'Done')),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SlideView extends StatelessWidget {
  const _SlideView({required this.slide, required this.classMode, required this.n});
  final Slide slide;
  final bool classMode;
  final int n;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 12),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Appear(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('#${n.toString().padLeft(2, '0')}',
                    style: pixelStyle(size: 11, color: context.cs.primary)),
                const SizedBox(height: 6),
                Text(slide.title, style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 16),
                slide.build(context, classMode),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CheatSheet extends StatelessWidget {
  const CheatSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    TextStyle h = pixelStyle(size: 10, color: cs.primary);
    Widget c(String s, {TextStyle? st}) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          child: Text(s, style: st ?? monoStyle(size: 15)),
        );
    return Scaffold(
      appBar: AppBar(title: Text(tr('Tabella rapida', 'Cheat sheet'))),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: ListView(
            padding: const EdgeInsets.all(14),
            children: [
              Panel(
                title: 'DEC · BIN · OCT · HEX',
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Table(
                    defaultColumnWidth: const IntrinsicColumnWidth(),
                    children: [
                      TableRow(children: [c('DEC', st: h), c('BIN', st: h), c('OCT', st: h), c('HEX', st: h)]),
                      for (var i = 0; i < 32; i++)
                        TableRow(
                          decoration: BoxDecoration(
                              color: i.isEven ? Colors.transparent : context.bc.panelHi),
                          children: [
                            c('$i', st: monoStyle(size: 15, weight: FontWeight.w800)),
                            c(toBaseInt(i, 2).padLeft(5, '0')),
                            c(toBaseInt(i, 8)),
                            c(toBaseInt(i, 16), st: monoStyle(size: 15, color: context.bc.accent, weight: FontWeight.w700)),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Panel(
                title: tr('Potenze di 2', 'Powers of 2'),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (var k = 0; k <= 16; k++)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: context.bc.panelHi,
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(color: cs.outlineVariant),
                        ),
                        child: Text('2^$k = ${1 << k}', style: monoStyle(size: 14, weight: FontWeight.w700)),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Panel(
                title: tr('Massimi utili', 'Handy maximums'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final b in const [4, 8, 16, 32])
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                            '$b bit: 0 … ${(BigInt.one << b) - BigInt.one}   (${tr('con segno', 'signed')}: ${-(BigInt.one << (b - 1))} … ${(BigInt.one << (b - 1)) - BigInt.one})',
                            style: monoStyle(size: 13)),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
