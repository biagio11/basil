/// Tiny two-language helper (pure Dart, no Flutter imports).
library;

/// Current UI language: 'it' or 'en'.
String appLang = 'it';

/// Picks the Italian or English string for the current language.
String tr(String it, String en) => appLang == 'en' ? en : it;
