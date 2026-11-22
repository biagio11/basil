// Writes web/privacy.html and web/terms.html (Italian + English) from the
// same text the app shows. Run:  dart run tool/gen_legal.dart
import 'dart:io';

import 'package:basil/app/config.dart';
import 'package:basil/app/i18n.dart';
import 'package:basil/content/legal.dart';

String esc(String s) => s
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;');

String block(LegalDoc d, String lang) {
  final b = StringBuffer('<section lang="$lang" id="$lang">\n');
  b.writeln('<h1>${esc(d.title)}</h1>');
  b.writeln('<p class="intro">${esc(d.intro)}</p>');
  for (final s in d.sections) {
    b.writeln('<h2>${esc(s.heading)}</h2>');
    for (final p in s.paragraphs) {
      b.writeln('<p>${esc(p)}</p>');
    }
  }
  b.writeln('</section>');
  return b.toString();
}

void write(String file, LegalDoc Function() doc, String titleIt, String titleEn) {
  appLang = 'it';
  final it = block(doc(), 'it');
  appLang = 'en';
  final en = block(doc(), 'en');
  final html = '''<!DOCTYPE html>
<html lang="it">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Basil · $titleIt / $titleEn</title>
<meta name="referrer" content="no-referrer">
<meta name="color-scheme" content="dark light">
<link rel="icon" type="image/png" href="favicon.png">
<link rel="stylesheet" href="legal.css">
</head>
<body>
<header><a class="brand" href="./"><img src="favicon.png" width="24" height="24" alt=""> BASIL</a>
<nav><a href="#it">Italiano</a> · <a href="#en">English</a></nav></header>
<main>
$it
<hr>
$en
</main>
<footer>Basil v$kAppVersion · <a href="privacy.html">Privacy</a> · <a href="terms.html">Termini / Terms</a> · <a href="./">App</a></footer>
</body>
</html>
''';
  File('web/$file').writeAsStringSync(html);
  stdout.writeln('wrote web/$file');
}

void main() {
  write('privacy.html', privacyDoc, 'Informativa sulla privacy', 'Privacy Policy');
  write('terms.html', termsDoc, 'Termini di utilizzo', 'Terms of Use');
}
