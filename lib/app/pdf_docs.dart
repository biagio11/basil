/// Printable PDFs: exercise worksheets and challenge results.
/// Black and white on purpose, so they print well on any printer.
library;

import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../logic/exercises.dart';
import 'config.dart';
import 'i18n.dart';

class _Fonts {
  _Fonts(this.body, this.pixel);
  final pw.Font body;
  final pw.Font pixel;
}

_Fonts? _cache;

Future<_Fonts> _fonts() async {
  final c = _cache;
  if (c != null) return c;
  final body = pw.Font.ttf(await rootBundle.load('assets/fonts/JetBrainsMono.ttf'));
  final pixel = pw.Font.ttf(await rootBundle.load('assets/fonts/Silkscreen-Regular.ttf'));
  return _cache = _Fonts(body, pixel);
}

const _subs = '₀₁₂₃₄₅₆₇₈₉';

/// Text where unicode subscript digits become a real lowered, smaller run.
pw.Widget subText(String s, {double size = 11, PdfColor? color}) {
  final spans = <pw.InlineSpan>[];
  final buf = StringBuffer();
  final sub = StringBuffer();
  void flushNormal() {
    if (buf.isNotEmpty) {
      spans.add(pw.TextSpan(text: buf.toString()));
      buf.clear();
    }
  }

  void flushSub() {
    if (sub.isNotEmpty) {
      spans.add(pw.TextSpan(
          text: sub.toString(),
          baseline: -size * .28,
          style: pw.TextStyle(fontSize: size * .62)));
      sub.clear();
    }
  }

  for (final ch in s.split('')) {
    final i = _subs.indexOf(ch);
    if (i >= 0) {
      flushNormal();
      sub.write(i);
    } else {
      flushSub();
      buf.write(ch);
    }
  }
  flushNormal();
  flushSub();
  return pw.RichText(
      text: pw.TextSpan(style: pw.TextStyle(fontSize: size, color: color), children: spans));
}

String _sub(int base) => base.toString().split('').map((d) => _subs[int.parse(d)]).join();

/// "1011₂ + 110₂" or "45₁₀" for the question of an exercise.
String questionWithBases(Exercise ex) {
  final q = ex.question;
  final parts = q.split(' ');
  if (parts.length == 3) {
    return '${parts[0]}${_sub(ex.questionBase)} ${parts[1]} ${parts[2]}${_sub(ex.questionBase)}';
  }
  return '$q${_sub(ex.questionBase)}';
}

bool _isOp(Exercise ex) => ex.question.contains(' ');

pw.Widget _header(_Fonts f, String title, String subtitle) => pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(children: [
          pw.Text('BASIL', style: pw.TextStyle(font: f.pixel, fontSize: 16, letterSpacing: 2)),
          pw.Spacer(),
          pw.Text(kSiteUrl.replaceFirst('https://', ''),
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
        ]),
        pw.SizedBox(height: 6),
        pw.Text(title, style: pw.TextStyle(font: f.pixel, fontSize: 13)),
        pw.SizedBox(height: 2),
        pw.Text(subtitle, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800)),
        pw.SizedBox(height: 8),
        pw.Divider(thickness: .8),
      ],
    );

pw.ThemeData _theme(_Fonts f) => pw.ThemeData.withFont(base: f.body, bold: f.body);

/// Worksheet with blank answers and the answer key on the last page.
Future<Uint8List> worksheetPdf(List<Exercise> items, String label) async {
  final f = await _fonts();
  final doc = pw.Document(title: 'Basil', author: 'Basil', creator: 'Basil');
  final title = tr('Scheda di esercizi', 'Exercise sheet');

  pw.Widget field(String l) => pw.Expanded(
        child: pw.Row(children: [
          pw.Text(l, style: const pw.TextStyle(fontSize: 9)),
          pw.SizedBox(width: 4),
          pw.Expanded(
              child: pw.Container(
                  height: 12,
                  decoration: const pw.BoxDecoration(
                      border: pw.Border(bottom: pw.BorderSide(width: .6))))),
        ]),
      );

  pw.Widget item(int i, Exercise ex) {
    final answerLine = pw.Container(
      width: 150,
      height: 16,
      decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(width: .6))),
    );
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 7),
      decoration: const pw.BoxDecoration(
          border: pw.Border(bottom: pw.BorderSide(width: .3, color: PdfColors.grey400))),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.SizedBox(
              width: 24,
              child: pw.Text('${i + 1}.', style: const pw.TextStyle(fontSize: 11))),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                subText(questionWithBases(ex), size: 13),
                pw.SizedBox(height: 2),
                pw.Text(
                    ex.caption ??
                        (_isOp(ex)
                            ? tr('risultato in base ${ex.answerBase}', 'result in base ${ex.answerBase}')
                            : tr('converti in base ${ex.answerBase}', 'convert to base ${ex.answerBase}')),
                    style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
              ],
            ),
          ),
          pw.Text('= ', style: const pw.TextStyle(fontSize: 13)),
          answerLine,
          subText(_sub(ex.answerBase), size: 13),
        ],
      ),
    );
  }

  doc.addPage(pw.MultiPage(
    theme: _theme(f),
    pageFormat: PdfPageFormat.a4,
    margin: const pw.EdgeInsets.fromLTRB(40, 36, 40, 36),
    header: (ctx) => ctx.pageNumber == 1
        ? pw.Column(children: [
            _header(f, title, label),
            pw.Row(children: [
              field(tr('Nome', 'Name')),
              pw.SizedBox(width: 14),
              field(tr('Classe', 'Class')),
              pw.SizedBox(width: 14),
              field(tr('Data', 'Date')),
            ]),
            pw.SizedBox(height: 8),
            pw.Row(children: [
              field(tr('Inizio', 'Start')),
              pw.SizedBox(width: 14),
              field(tr('Fine', 'End')),
              pw.SizedBox(width: 14),
              field(tr('Punteggio', 'Score')),
            ]),
            pw.SizedBox(height: 10),
          ])
        : pw.SizedBox(),
    footer: (ctx) => pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.Text('${ctx.pageNumber} / ${ctx.pagesCount}',
          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
    ),
    build: (ctx) => [for (var i = 0; i < items.length; i++) item(i, items[i])],
  ));

  // Answer key
  doc.addPage(pw.MultiPage(
    theme: _theme(f),
    pageFormat: PdfPageFormat.a4,
    margin: const pw.EdgeInsets.fromLTRB(40, 36, 40, 36),
    header: (ctx) => _header(f, tr('Soluzioni', 'Answer key'), label),
    build: (ctx) => [
      pw.Wrap(
        spacing: 10,
        runSpacing: 8,
        children: [
          for (var i = 0; i < items.length; i++)
            pw.Container(
              width: 160,
              child: pw.Row(children: [
                pw.SizedBox(
                    width: 24, child: pw.Text('${i + 1}.', style: const pw.TextStyle(fontSize: 10))),
                pw.Expanded(child: subText('${items[i].answer}${_sub(items[i].answerBase)}', size: 11)),
              ]),
            ),
        ],
      ),
      pw.SizedBox(height: 18),
      pw.Text(tr('Procedimenti', 'Workings'), style: pw.TextStyle(font: f.pixel, fontSize: 11)),
      pw.SizedBox(height: 6),
      for (var i = 0; i < items.length; i++)
        pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 8),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              subText('${i + 1}. ${questionWithBases(items[i])}', size: 10),
              for (final l in items[i].solution)
                pw.Padding(
                    padding: const pw.EdgeInsets.only(left: 14, top: 1),
                    child: subText(l, size: 8, color: PdfColors.grey800)),
            ],
          ),
        ),
    ],
  ));
  return doc.save();
}

class ResultRow {
  ResultRow(this.ex, this.given, this.ok, this.millis);
  final Exercise ex;
  final String given;
  final bool ok;
  final int millis;
}

String _fmt(int ms) {
  final m = ms ~/ 60000;
  final s = (ms % 60000) ~/ 1000;
  final d = (ms % 1000) ~/ 100;
  return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}.$d';
}

/// Results of a challenge with every question and the workings of mistakes.
Future<Uint8List> resultsPdf(
    List<ResultRow> rows, String label, int totalMs, DateTime when) async {
  final f = await _fonts();
  final doc = pw.Document(title: 'Basil', author: 'Basil', creator: 'Basil');
  final correct = rows.where((r) => r.ok).length;
  final pct = rows.isEmpty ? 0 : (correct * 100 / rows.length).round();
  final avg = rows.isEmpty ? 0 : totalMs ~/ rows.length;
  final date =
      '${when.day.toString().padLeft(2, '0')}/${when.month.toString().padLeft(2, '0')}/${when.year} ${when.hour.toString().padLeft(2, '0')}:${when.minute.toString().padLeft(2, '0')}';

  pw.Widget stat(String v, String l) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(v, style: const pw.TextStyle(fontSize: 18)),
          pw.Text(l.toUpperCase(), style: pw.TextStyle(font: f.pixel, fontSize: 7, color: PdfColors.grey700)),
        ],
      );

  pw.Widget cell(pw.Widget w) => pw.Padding(padding: const pw.EdgeInsets.all(4), child: w);

  doc.addPage(pw.MultiPage(
    theme: _theme(f),
    pageFormat: PdfPageFormat.a4,
    margin: const pw.EdgeInsets.fromLTRB(40, 36, 40, 36),
    header: (ctx) => _header(f, tr('Risultati della sfida', 'Challenge results'), '$label · $date'),
    build: (ctx) => [
      pw.Row(children: [
        stat(_fmt(totalMs), tr('tempo', 'time')),
        pw.SizedBox(width: 30),
        stat('$correct/${rows.length}', tr('giuste', 'correct')),
        pw.SizedBox(width: 30),
        stat('$pct%', tr('precisione', 'accuracy')),
        pw.SizedBox(width: 30),
        stat('${(avg / 1000).toStringAsFixed(1)}s', tr('media', 'avg')),
      ]),
      pw.SizedBox(height: 16),
      pw.Table(
        border: pw.TableBorder.all(width: .4, color: PdfColors.grey600),
        columnWidths: const {
          0: pw.FixedColumnWidth(22),
          1: pw.FlexColumnWidth(3),
          2: pw.FlexColumnWidth(2),
          3: pw.FlexColumnWidth(2),
          4: pw.FixedColumnWidth(26),
        },
        children: [
          pw.TableRow(
            decoration: const pw.BoxDecoration(color: PdfColors.grey200),
            children: [
              cell(pw.Text('#', style: const pw.TextStyle(fontSize: 8))),
              cell(pw.Text(tr('domanda', 'question'), style: const pw.TextStyle(fontSize: 8))),
              cell(pw.Text(tr('tua risposta', 'your answer'), style: const pw.TextStyle(fontSize: 8))),
              cell(pw.Text(tr('soluzione', 'solution'), style: const pw.TextStyle(fontSize: 8))),
              cell(pw.Text('', style: const pw.TextStyle(fontSize: 8))),
            ],
          ),
          for (var i = 0; i < rows.length; i++)
            pw.TableRow(children: [
              cell(pw.Text('${i + 1}', style: const pw.TextStyle(fontSize: 9))),
              cell(subText(
                  '${questionWithBases(rows[i].ex)} → ${rows[i].ex.caption ?? '${tr('base', 'base')} ${rows[i].ex.answerBase}'}',
                  size: 9)),
              cell(pw.Text(rows[i].given, style: const pw.TextStyle(fontSize: 9))),
              cell(subText('${rows[i].ex.answer}${_sub(rows[i].ex.answerBase)}', size: 9)),
              cell(pw.Text(rows[i].ok ? 'ok' : 'x',
                  style: pw.TextStyle(fontSize: 9, color: rows[i].ok ? PdfColors.black : PdfColors.grey700))),
            ]),
        ],
      ),
      if (rows.any((r) => !r.ok)) ...[
        pw.SizedBox(height: 18),
        pw.Text(tr('Da rivedere', 'To review'), style: pw.TextStyle(font: f.pixel, fontSize: 11)),
        pw.SizedBox(height: 6),
        for (final r in rows.where((r) => !r.ok))
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 8),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                subText(r.ex.prompt, size: 10),
                for (final l in r.ex.solution)
                  pw.Padding(
                      padding: const pw.EdgeInsets.only(left: 14, top: 1),
                      child: subText(l, size: 8, color: PdfColors.grey800)),
              ],
            ),
          ),
      ],
    ],
  ));
  return doc.save();
}
