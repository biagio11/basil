import 'dart:convert';
import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'i18n.dart';
import 'look.dart';

export 'i18n.dart';
export 'look.dart';

/// App-wide preferences. Everything is stored only on this device
/// (SharedPreferences / browser localStorage); nothing leaves it.
class AppSettings extends ChangeNotifier {
  AppSettings._();
  static final AppSettings instance = AppSettings._();

  SharedPreferences? _p;

  ThemeMode themeMode = ThemeMode.dark;
  String lang = 'it';
  bool animations = true;
  Look look = const Look();
  bool haptics = true;
  bool explain = false;
  bool keypad = true;
  bool groupDigits = true;
  bool acceptedTerms = false;
  int fromBase = 10;
  int toBase = 2;

  Future<void> load() async {
    try {
      _p = await SharedPreferences.getInstance();
    } catch (_) {
      _p = null; // storage blocked (private mode): run with defaults
    }
    final p = _p;
    final sys = PlatformDispatcher.instance.locale.languageCode;
    lang = p?.getString('lang') ?? (sys == 'it' ? 'it' : 'en');
    if (lang != 'it' && lang != 'en') lang = 'en';
    appLang = lang;
    final tm = p?.getString('theme');
    themeMode = switch (tm) {
      'light' => ThemeMode.light,
      'system' => ThemeMode.system,
      _ => ThemeMode.dark,
    };
    animations = p?.getBool('animations') ?? true;
    look = const Look();
    final rawLook = p?.getString('look');
    if (rawLook != null) {
      try {
        look = Look.fromJson(jsonDecode(rawLook) as Map<String, dynamic>);
      } catch (_) {}
    } else if (p?.getBool('matrix') ?? false) {
      look = look.copyWith(background: 'rain'); // older versions had a switch
    }
    appLook = look;
    haptics = p?.getBool('haptics') ?? true;
    explain = p?.getBool('explain') ?? false;
    keypad = p?.getBool('keypad') ?? true;
    groupDigits = p?.getBool('groupDigits') ?? true;
    acceptedTerms = p?.getBool('acceptedTerms_v1') ?? false;
    fromBase = _base(p?.getInt('fromBase'), 10);
    toBase = _base(p?.getInt('toBase'), 2);
  }

  int _base(int? v, int def) => (v != null && v >= 2 && v <= 36) ? v : def;

  void _save(void Function(SharedPreferences p) f) {
    final p = _p;
    if (p == null) return;
    try {
      f(p);
    } catch (_) {}
  }

  void setTheme(ThemeMode m) {
    themeMode = m;
    _save((p) => p.setString('theme', m.name));
    notifyListeners();
  }

  void setLang(String l) {
    lang = l;
    appLang = l;
    _save((p) => p.setString('lang', l));
    notifyListeners();
  }

  void setAnimations(bool v) {
    animations = v;
    _save((p) => p.setBool('animations', v));
    notifyListeners();
  }

  void setLook(Look l) {
    if (l == look) return;
    look = l;
    appLook = l;
    _save((p) => p.setString('look', jsonEncode(l.toJson())));
    notifyListeners();
  }

  void setHaptics(bool v) {
    haptics = v;
    _save((p) => p.setBool('haptics', v));
    notifyListeners();
  }

  void setExplain(bool v) {
    explain = v;
    _save((p) => p.setBool('explain', v));
    notifyListeners();
  }

  void setKeypad(bool v) {
    keypad = v;
    _save((p) => p.setBool('keypad', v));
    notifyListeners();
  }

  void setGroupDigits(bool v) {
    groupDigits = v;
    _save((p) => p.setBool('groupDigits', v));
    notifyListeners();
  }

  void acceptTerms() {
    acceptedTerms = true;
    _save((p) => p.setBool('acceptedTerms_v1', true));
    notifyListeners();
  }

  void setBases(int from, int to) {
    fromBase = from;
    toBase = to;
    _save((p) {
      p.setInt('fromBase', from);
      p.setInt('toBase', to);
    });
  }

  // ---------------------------------------------------------------------------
  // Training records
  // ---------------------------------------------------------------------------

  List<TrainingRecord> get history {
    final raw = _p?.getString('history');
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .whereType<Map<String, dynamic>>()
          .map(TrainingRecord.fromJson)
          .whereType<TrainingRecord>()
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Saves [r]; returns true when it is the best result for its config.
  bool addRecord(TrainingRecord r) {
    final all = history;
    final same = all.where((x) => x.key == r.key).toList();
    final isBest = r.correct > 0 &&
        same.every((x) => r.betterThan(x));
    all.insert(0, r);
    final trimmed = all.take(200).toList();
    _save((p) => p.setString(
        'history', jsonEncode(trimmed.map((e) => e.toJson()).toList())));
    notifyListeners();
    return isBest;
  }

  /// Wipes everything Basil stored on this device and restores defaults.
  Future<void> clearAll() async {
    try {
      await _p?.clear();
    } catch (_) {}
    await load();
    notifyListeners();
  }

  void clearHistory() {
    _save((p) => p.remove('history'));
    notifyListeners();
  }
}

class TrainingRecord {
  TrainingRecord({
    required this.key,
    required this.label,
    required this.total,
    required this.correct,
    required this.millis,
    required this.when,
  });

  /// Identifies the configuration (mode, bases, difficulty, count).
  final String key;
  final String label;
  final int total;
  final int correct;
  final int millis;
  final DateTime when;

  double get accuracy => total == 0 ? 0 : correct / total;

  /// More correct answers wins; on a tie the faster run wins.
  bool betterThan(TrainingRecord o) =>
      correct > o.correct || (correct == o.correct && millis < o.millis);

  Map<String, dynamic> toJson() => {
        'k': key,
        'l': label,
        't': total,
        'c': correct,
        'm': millis,
        'w': when.millisecondsSinceEpoch,
      };

  static TrainingRecord? fromJson(Map<String, dynamic> j) {
    try {
      return TrainingRecord(
        key: j['k'] as String,
        label: j['l'] as String,
        total: j['t'] as int,
        correct: j['c'] as int,
        millis: j['m'] as int,
        when: DateTime.fromMillisecondsSinceEpoch(j['w'] as int),
      );
    } catch (_) {
      return null;
    }
  }
}

String formatMillis(int ms) {
  final m = ms ~/ 60000;
  final s = (ms % 60000) ~/ 1000;
  final d = (ms % 1000) ~/ 100;
  return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}.$d';
}
