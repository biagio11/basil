import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:qr/qr.dart';

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

String get _siteShort => kSiteUrl.replaceFirst('https://', '');

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
  late final String _name = 'basil-${_stamp()}';
  Future<Uint8List?>? _pngJob;
  Uint8List? _pdf;
  bool _busy = false;
  String? _status;
  bool _statusBad = false;

  @override
  void initState() {
    super.initState();
    // Render the story once, right after the first frame, so the share
    // buttons answer at once (browsers only allow sharing soon after a tap).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _pngJob = _render();
    });
  }

  Future<Uint8List?> _render() async {
    // Wait for fonts and the first paint to settle.
    await WidgetsBinding.instance.endOfFrame;
    await Future<void>.delayed(const Duration(milliseconds: 60));
    final b = _key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (b == null) return null;
    final img = await b.toImage(pixelRatio: 1080 / 360);
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
    img.dispose();
    return bytes?.buffer.asUint8List();
  }

  Future<Uint8List> _image() async {
    var png = await (_pngJob ??= _render());
    if (png == null) {
      _pngJob = _render();
      png = await _pngJob;
    }
    if (png == null) throw StateError('render');
    return png;
  }

  Future<Uint8List> _pdfBytes() async => _pdf ??= await widget.data.buildPdf();

  void _say(String msg, {bool bad = false}) {
    if (!mounted) return;
    setState(() {
      _status = msg;
      _statusBad = bad;
    });
  }

  Future<void> _run(Future<void> Function() job, {VoidCallback? onError}) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _status = null;
    });
    try {
      await job();
    } catch (_) {
      onError?.call();
      _say(tr('Non è riuscito. Riprova, oppure salva l’immagine e condividila dalla galleria.',
              'That did not work. Try again, or save the image and share it from your gallery.'),
          bad: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _report(ShareOutcome o, {required String what}) {
    switch (o) {
      case ShareOutcome.shared:
        _say(tr('Fatto.', 'Done.'));
      case ShareOutcome.dismissed:
        _say(tr('Condivisione annullata.', 'Sharing cancelled.'));
      case ShareOutcome.downloaded:
        _say(tr('Questo browser non condivide file: $what è stato scaricato.',
            'This browser cannot share files, so the $what was downloaded.'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final h = MediaQuery.sizeOf(context).height;
    final d = widget.data;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: (h * .5).clamp(240.0, 540.0),
                  child: FittedBox(
                    child: RepaintBoundary(key: _key, child: StoryCard(data: d)),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  tr('Formato storia 9:16 per Instagram e TikTok. Il QR porta a Basil.',
                      'Story format 9:16 for Instagram and TikTok. The QR leads to Basil.'),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _busy
                      ? null
                      : () => _run(() async {
                            final png = await _image();
                            final o = await shareFile(png, '$_name.png', 'image/png',
                                text: tr('Il mio risultato su Basil. Allenati anche tu: $kSiteUrl',
                                    'My Basil result. Train too: $kSiteUrl'));
                            _report(o, what: tr('l’immagine', 'image'));
                          }),
                  icon: const Icon(Icons.ios_share, size: 18),
                  label: Text(tr('Condividi immagine', 'Share image')),
                ),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _busy
                          ? null
                          : () => _run(() async {
                                final png = await _image();
                                await saveFile(png, '$_name.png', 'image/png');
                                if (kIsWeb) _say(tr('Immagine scaricata.', 'Image downloaded.'));
                              }),
                      icon: const Icon(Icons.download, size: 18),
                      label: Text(tr('Salva', 'Save')),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _busy
                          ? null
                          : () async {
                              try {
                                await Clipboard.setData(const ClipboardData(text: kSiteUrl))
                                    .timeout(const Duration(seconds: 2));
                                _say(tr('Link copiato. Su Instagram aggiungilo con lo sticker Link.',
                                    'Link copied. On Instagram add it with the Link sticker.'));
                              } catch (_) {
                                _say(tr('Non posso copiare qui. Il link è $_siteShort',
                                    'Cannot copy here. The link is $_siteShort'));
                              }
                            },
                      icon: const Icon(Icons.link, size: 18),
                      label: Text(tr('Copia link', 'Copy link')),
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
                              // Open the tab inside the tap, or browsers block it.
                              final w = reserveWindow();
                              _run(() async {
                                final pdf = await _pdfBytes();
                                if (kIsWeb) {
                                  await showPdf(pdf, '$_name.pdf', window: w);
                                  _say(tr('PDF aperto in una nuova scheda (o scaricato).',
                                      'PDF opened in a new tab (or downloaded).'));
                                } else {
                                  _report(await shareFile(pdf, '$_name.pdf', 'application/pdf'), what: 'PDF');
                                }
                              }, onError: () => closeReserved(w));
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
                                  final pdf = await _pdfBytes();
                                  await showPdf(pdf, '$_name.pdf');
                                }),
                        icon: const Icon(Icons.print_outlined, size: 18),
                        label: Text(tr('Stampa', 'Print')),
                      ),
                    ),
                  ],
                ]),
                const SizedBox(height: 10),
                SizedBox(
                  height: 36,
                  child: _busy
                      ? const Center(child: LinearProgressIndicator(minHeight: 2))
                      : (_status == null
                          ? null
                          : Text(_status!,
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12.5, color: _statusBad ? context.bc.bad : cs.onSurfaceVariant))),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 360×640 card, exported as 1080×1920. Always dark, like a terminal.
class StoryCard extends StatelessWidget {
  const StoryCard({super.key, required this.data});
  final ShareData data;

  @override
  Widget build(BuildContext context) {
    final l = appLook;
    final green = l.tone(const Color(0xFF3DFF7A));
    final amber = l.mono ? const Color(0xFFFFB000) : l.tone(const Color(0xFFFFB000));
    final fg = l.tone(const Color(0xFFD3F8DA));
    final muted = l.tone(const Color(0xFF8FB89A));
    final line = l.tone(const Color(0xFF1B3322));
    final pct = data.total == 0 ? 0 : (data.correct * 100 / data.total).round();
    final avg = data.total == 0 ? 0.0 : data.millis / data.total / 1000;
    final mono = TextStyle(fontFamily: 'JetBrainsMono', color: fg, height: 1.35);

    Widget stat(String v, String label, Color c) => Expanded(
          child: Column(children: [
            FittedBox(fit: BoxFit.scaleDown, child: Text(v, maxLines: 1, style: termStyle(size: 34, color: c))),
            const SizedBox(height: 2),
            Text(label.toUpperCase(), style: pixelStyle(size: 8, color: muted)),
          ]),
        );

    return Theme(
      data: buildTheme(Brightness.dark),
      child: SizedBox(
        width: 360,
        height: 640,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [for (final c in const [Color(0xFF0B2414), Color(0xFF060B07), Color(0xFF040805)]) l.tone(c)],
            ),
          ),
          child: CustomPaint(
            painter: _GridPainter(l.tone(const Color(0x143DFF7A))),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 60, 28, 34),
              child: Column(
                children: [
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const PixelLeaf(size: 40),
                    const SizedBox(width: 10),
                    Text('BASIL', style: pixelStyle(size: 24, color: green, weight: FontWeight.w700)),
                  ]),
                  const SizedBox(height: 34),
                  Text(tr('> SFIDA COMPLETATA', '> CHALLENGE COMPLETE'), style: pixelStyle(size: 10, color: muted)),
                  const SizedBox(height: 8),
                  Text(data.label,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: mono.copyWith(fontSize: 12)),
                  const SizedBox(height: 26),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(formatMillis(data.millis), maxLines: 1, style: termStyle(size: 84, color: green)),
                  ),
                  Text(tr('TEMPO', 'TIME'), style: pixelStyle(size: 9, color: muted)),
                  const SizedBox(height: 22),
                  Container(height: 1, color: line),
                  const SizedBox(height: 16),
                  Row(children: [
                    stat('${data.correct}/${data.total}', tr('giuste', 'correct'), fg),
                    stat('$pct%', tr('precisione', 'accuracy'), pct >= 80 ? green : amber),
                    stat('${avg.toStringAsFixed(1)}s', tr('a domanda', 'each'), fg),
                  ]),
                  const SizedBox(height: 18),
                  if (data.newBest)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: amber.withAlpha(30),
                        border: Border.all(color: amber),
                        borderRadius: appLook.br(4),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.emoji_events, size: 14, color: amber),
                        const SizedBox(width: 6),
                        Text(tr('NUOVO RECORD', 'NEW RECORD'), style: pixelStyle(size: 10, color: amber)),
                      ]),
                    ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(90),
                      border: Border.all(color: line),
                      borderRadius: appLook.br(8),
                    ),
                    child: Row(children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        color: Colors.white,
                        child: const SizedBox.square(dimension: 76, child: QrBox(data: kSiteUrl)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(tr('ALLENATI ANCHE TU', 'TRAIN TOO'), style: pixelStyle(size: 10, color: green)),
                            const SizedBox(height: 6),
                            Text(tr('Basi, conversioni e operazioni. Gratis, senza account.',
                                    'Bases, conversions and operations. Free, no account.'),
                                style: mono.copyWith(fontSize: 10.5, color: muted)),
                            const SizedBox(height: 6),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(_siteShort,
                                  maxLines: 1, style: mono.copyWith(fontSize: 12, fontWeight: FontWeight.w800)),
                            ),
                          ],
                        ),
                      ),
                    ]),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A QR code drawn as plain squares (black on whatever is behind it).
class QrBox extends StatelessWidget {
  const QrBox({super.key, required this.data, this.color = Colors.black});
  final String data;
  final Color color;

  @override
  Widget build(BuildContext context) => CustomPaint(painter: _QrPainter(data, color));
}

class _QrPainter extends CustomPainter {
  _QrPainter(this.data, this.color);
  final String data;
  final Color color;
  static final Map<String, QrImage> _cache = {};

  @override
  void paint(Canvas canvas, Size size) {
    final img = _cache.putIfAbsent(
        data, () => QrImage(QrCode.fromData(data: data, errorCorrectLevel: QrErrorCorrectLevel.M)));
    final n = img.moduleCount;
    final cell = size.shortestSide / n;
    final p = Paint()
      ..color = color
      ..isAntiAlias = false;
    for (var y = 0; y < n; y++) {
      for (var x = 0; x < n; x++) {
        if (img.isDark(y, x)) {
          canvas.drawRect(Rect.fromLTWH(x * cell, y * cell, cell + .3, cell + .3), p);
        }
      }
    }
  }

  @override
  bool shouldRepaint(_QrPainter old) => old.data != data || old.color != color;
}

class _GridPainter extends CustomPainter {
  _GridPainter(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = color;
    for (double x = 0; x < size.width; x += 18) {
      canvas.drawRect(Rect.fromLTWH(x, 0, 1, size.height), p);
    }
    for (double y = 0; y < size.height; y += 18) {
      canvas.drawRect(Rect.fromLTWH(0, y, size.width, 1), p);
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) => old.color != color;
}
