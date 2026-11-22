/// Pure-Dart logic for positional number systems (no Flutter imports).
library;

import '../app/i18n.dart';

const String kDigits = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ';

int digitValue(String ch) => kDigits.indexOf(ch.toUpperCase());

String digitChar(int v) => kDigits[v];

String cleanInput(String s) => s.replaceAll(RegExp(r'\s+'), '').toUpperCase();

String stripLeadingZeros(String s) {
  final t = s.replaceFirst(RegExp(r'^0+'), '');
  return t.isEmpty ? '0' : t;
}

/// First character of [s] that is not a valid digit in [base], or null.
String? firstInvalidDigit(String s, int base) {
  for (final ch in cleanInput(s).split('')) {
    final v = digitValue(ch);
    if (v < 0 || v >= base) return ch;
  }
  return null;
}

bool isValidInBase(String s, int base) {
  final t = cleanInput(s);
  return t.isNotEmpty && firstInvalidDigit(t, base) == null;
}

/// Human label for the valid digits of a base, e.g. "0-1" or "0-9 e A-F".
String validDigitsLabel(int base) {
  if (base <= 10) return '0-${base - 1}';
  return tr('0-9 e A-${kDigits[base - 1]}', '0-9 and A-${kDigits[base - 1]}');
}

BigInt parseInBase(String s, int base) {
  final b = BigInt.from(base);
  var r = BigInt.zero;
  for (final ch in cleanInput(s).split('')) {
    r = r * b + BigInt.from(digitValue(ch));
  }
  return r;
}

String toBase(BigInt n, int base) {
  if (n == BigInt.zero) return '0';
  final b = BigInt.from(base);
  final out = <String>[];
  var x = n;
  while (x > BigInt.zero) {
    out.add(kDigits[(x % b).toInt()]);
    x = x ~/ b;
  }
  return out.reversed.join();
}

String toBaseInt(int n, int base) => toBase(BigInt.from(n), base);

String subscript(int n) {
  const subs = '₀₁₂₃₄₅₆₇₈₉';
  return n.toString().split('').map((c) => subs[int.parse(c)]).join();
}

/// "101101" in base 2 -> "101101₂".
String withBase(String digits, int base) => '$digits${subscript(base)}';

// ---------------------------------------------------------------------------
// Base b -> base 10: digit × b^position
// ---------------------------------------------------------------------------

class PowerTerm {
  const PowerTerm({
    required this.digit,
    required this.digitVal,
    required this.position,
    required this.weight,
    required this.product,
  });
  final String digit;
  final int digitVal;
  final int position;
  final BigInt weight;
  final BigInt product;
}

List<PowerTerm> expansionTerms(String s, int base) {
  final t = cleanInput(s);
  final n = t.length;
  final b = BigInt.from(base);
  final terms = <PowerTerm>[];
  for (var i = 0; i < n; i++) {
    final pos = n - 1 - i;
    final w = b.pow(pos);
    final v = digitValue(t[i]);
    terms.add(PowerTerm(
      digit: t[i],
      digitVal: v,
      position: pos,
      weight: w,
      product: w * BigInt.from(v),
    ));
  }
  return terms;
}

// ---------------------------------------------------------------------------
// Base 10 -> base b: repeated division
// ---------------------------------------------------------------------------

class DivStep {
  const DivStep({
    required this.dividend,
    required this.base,
    required this.quotient,
    required this.remainder,
  });
  final BigInt dividend;
  final int base;
  final BigInt quotient;
  final int remainder;
}

List<DivStep> divisionSteps(BigInt n, int base) {
  final b = BigInt.from(base);
  if (n == BigInt.zero) {
    return [
      DivStep(
          dividend: BigInt.zero,
          base: base,
          quotient: BigInt.zero,
          remainder: 0)
    ];
  }
  final steps = <DivStep>[];
  var x = n;
  while (x > BigInt.zero) {
    final q = x ~/ b;
    final r = (x % b).toInt();
    steps.add(DivStep(dividend: x, base: base, quotient: q, remainder: r));
    x = q;
  }
  return steps;
}

// ---------------------------------------------------------------------------
// Grouping shortcut: base 2 <-> base 4 / 8 / 16 / 32
// ---------------------------------------------------------------------------

List<String> chunkFromRight(String s, int size) {
  final padded = s.padLeft(((s.length + size - 1) ~/ size) * size, '0');
  final out = <String>[];
  for (var i = 0; i < padded.length; i += size) {
    out.add(padded.substring(i, i + size));
  }
  return out;
}

class GroupMapping {
  const GroupMapping({
    required this.bitGroups,
    required this.digits,
    required this.groupSize,
    required this.toBinary,
  });
  final List<String> bitGroups;
  final List<String> digits;
  final int groupSize;

  /// true when converting from the big base down to binary.
  final bool toBinary;
}

bool _isPow2Base(int b) => b >= 4 && b <= 32 && (b & (b - 1)) == 0;

int _log2(int b) {
  var k = 0;
  var x = b;
  while (x > 1) {
    x >>= 1;
    k++;
  }
  return k;
}

/// Returns the grouping that converts [s] between base 2 and base 2^k, or
/// null when the pair of bases does not allow the shortcut.
GroupMapping? groupShortcut(String s, int from, int to) {
  final t = cleanInput(s);
  if (t.isEmpty) return null;
  if (from == 2 && _isPow2Base(to)) {
    final k = _log2(to);
    final groups = chunkFromRight(t, k);
    final digits =
        groups.map((g) => digitChar(int.parse(g, radix: 2))).toList();
    return GroupMapping(
        bitGroups: groups, digits: digits, groupSize: k, toBinary: false);
  }
  if (to == 2 && _isPow2Base(from)) {
    final k = _log2(from);
    final digits = t.split('');
    final groups =
        digits.map((d) => digitValue(d).toRadixString(2).padLeft(k, '0')).toList();
    return GroupMapping(
        bitGroups: groups, digits: digits, groupSize: k, toBinary: true);
  }
  return null;
}

String rgbToHex(int r, int g, int b) {
  String h(int v) => toBaseInt(v, 16).padLeft(2, '0');
  return '#${h(r)}${h(g)}${h(b)}';
}
