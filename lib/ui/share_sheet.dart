import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../app/config.dart';
import '../app/files.dart';
import '../app/settings.dart';
import '../app/theme.dart' show buildTheme;
import 'common.dart';
import 'widgets/pixel_leaf.dart';

class ShareData {
  ShareData({
    required this.label,
    required this.correct,
    required this.total,
    required this.millis,
    required this.newBest,
    required this.buildPdf,
  });
  final String label;
  final int correct;
  final int total;
  final int millis;
  final bool newBest;
  final Future<Uint8List> Function() buildPdf;
}

String _stamp() {
  final d = DateTime.now();
  String two(int v) => v.toString().padLeft(2, '0');
  return '${d.year}${two(d.month)}${two(d.day)}-${two(d.hour)}${two(d.minute)}';
}

Future<void> showResultShare(BuildContext context, ShareData data) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => _ShareSheet(data: data),
  );
}

class _ShareSheet extends StatefulWidget {
  const _ShareSheet({required this.data});
  final ShareData data;

  @override
  State<_ShareSheet> createState() => _ShareSheetState();
}

class _ShareSheetState extends State<_ShareSheet> {
  final _key = GlobalKey();
  bool _busy = false;

  Future<Uint8List?> _png() async {
    final b = _key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (b == null) return null;
    final img = await b.toImage(pixelRatio: 3);
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
    img.dispose();
    return bytes?.buffer.asUint8List();
  }

  Future<void> _run(Future<void> Function() job) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await job();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(tr('Operazione non riuscita', 'Something went wrong'))));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.sizeOf(context).height;
    final d = widget.data;
    final name = 'basil-${_stamp()}';
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: (h * .52).clamp(260.0, 560.0),
              child: FittedBox(
                child: RepaintBoundary(
                  key: _key,
                  child: StoryCard(data: d),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(tr('Formato storia 9:16, perfetto per Instagram e TikTok',
                    'Story format 9:16, ready for Instagram and TikTok'),
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _busy
                      ? null
                      : () => _run(() async {
                            final png = await _png();
                            if (png == null) return;
                            await shareFile(png, '$name.png', 'image/png',
                                text: tr('Il mio risultato su Basil: $kSiteUrl',
                                    'My Basil result: $kSiteUrl'));
                          }),
                  icon: const Icon(Icons.ios_share, size: 18),
                  label: Text(tr('Condividi', 'Share')),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _busy
                      ? null
                      : () => _run(() async {
                            final png = await _png();
                            if (png == null) return;
                            await saveFile(png, '$name.png', 'image/png');
                          }),
                  icon: const Icon(Icons.download, size: 18),
                  label: Text(tr('Immagine', 'Image')),
                ),
              ),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _busy
                      ? null
                      : () {
                          final w = reserveWindow();
                          _run(() async {
                            final pdf = await d.buildPdf();
                            if (kIsWeb) {
                              await showPdf(pdf, '$name.pdf', window: w);
                            } else {
                              await shareFile(pdf, '$name.pdf', 'application/pdf');
                            }
                          });
                        },
                  icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                  label: const Text('PDF'),
                ),
              ),
              if (!kIsWeb) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _busy
                        ? null
                        : () => _run(() async {
                              final pdf = await d.buildPdf();
                              await showPdf(pdf, '$name.pdf');
                            }),
                    icon: const Icon(Icons.print_outlined, size: 18),
                    label: Text(tr('Stampa', 'Print')),
                  ),
                ),
              ],
            ]),
            if (_busy) ...[
              const SizedBox(height: 10),
              const LinearProgressIndicator(minHeight: 2),
            ],
          ],
        ),
      ),
    );
  }
}

/// 360×640 card, exported at 3x (1080×1920). Always dark, like a terminal.
class StoryCard extends StatelessWidget {
  const StoryCard({super.key, required this.data});
  final ShareData data;

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF3DFF7A);
    const amber = Color(0xFFFFB000);
    const fg = Color(0xFFD3F8DA);
    const muted = Color(0xFF8FB89A);
    final pct = data.total == 0 ? 0 : (data.correct * 100 / data.total).round();
    final avg = data.total == 0 ? 0.0 : data.millis / data.total / 1000;

    Widget stat(String v, String l, Color c) => Column(children: [
          Text(v, style: termStyle(size: 40, color: c)),
          const SizedBox(height: 2),
          Text(l.toUpperCase(), style: pixelStyle(size: 9, color: muted)),
        ]);

    return Theme(
      data: buildDarkFor(context),
      child: SizedBox(
        width: 360,
        height: 640,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF0B2414), Color(0xFF060B07), Color(0xFF040805)],
            ),
          ),
          child: CustomPaint(
            painter: _GridPainter(),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 56, 28, 40),
              child: Column(
                children: [
                  const PixelLeaf(size: 92),
                  const SizedBox(height: 12),
                  Text('BASIL',
                      style: pixelStyle(size: 30, color: green, weight: FontWeight.w700)),
                  const SizedBox(height: 26),
                  Text(tr('> SFIDA COMPLETATA', '> CHALLENGE COMPLETE'),
                      style: pixelStyle(size: 12, color: muted)),
                  const SizedBox(height: 8),
                  Text(data.label,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontFamily: 'JetBrainsMono', fontSize: 12, color: fg, height: 1.4)),
                  const Spacer(),
                  Text(formatMillis(data.millis), style: termStyle(size: 92, color: green)),
                  Text(tr('TEMPO', 'TIME'), style: pixelStyle(size: 10, color: muted)),
                  const SizedBox(height: 26),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      stat('${data.correct}/${data.total}', tr('giuste', 'correct'), fg),
                      stat('$pct%', tr('precisione', 'accuracy'), pct >= 80 ? green : amber),
                      stat('${avg.toStringAsFixed(1)}s', tr('media', 'avg'), fg),
                    ],
                  ),
                  const SizedBox(height: 22),
                  if (data.newBest)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        border: Border.all(color: amber),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(tr('NUOVO RECORD', 'NEW RECORD'),
                          style: pixelStyle(size: 12, color: amber)),
                    ),
                  const Spacer(),
                  Text(kSiteUrl.replaceFirst('https://', ''),
                      style: const TextStyle(
                          fontFamily: 'JetBrainsMono', fontSize: 12, color: muted)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

ThemeData buildDarkFor(BuildContext context) => _dark ??= buildTheme(Brightness.dark);
ThemeData? _dark;

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = const Color(0x143DFF7A);
    for (double x = 0; x < size.width; x += 18) {
      canvas.drawRect(Rect.fromLTWH(x, 0, 1, size.height), p);
    }
    for (double y = 0; y < size.height; y += 18) {
      canvas.drawRect(Rect.fromLTWH(0, y, size.width, 1), p);
    }
  }

  @override
  bool shouldRepaint(_GridPainter oldDelegate) => false;
}
