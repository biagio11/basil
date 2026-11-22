/// Full numbers: sign, integer part, fractional part, repeating digits.
library;

import '../app/i18n.dart';
import 'base_conv.dart';

/// Hard limits that keep every computation instant and every explanation
/// readable, whatever the user types or pastes.
const int kMaxIntDigits = 64;
const int kMaxFracDigits = 24;
const int kMaxInputLength = 96;

class ParsedNumber {
  const ParsedNumber({
    required this.negative,
    required this.intDigits,
    required this.fracDigits,
    required this.base,
  });
  final bool negative;

  /// Integer digits without leading zeros ("0" for zero).
  final String intDigits;

  /// Fractional digits without trailing zeros ("" when integer).
  final String fracDigits;
  final int base;

  bool get hasFraction => fracDigits.isNotEmpty;
  BigInt get intValue => parseInBase(intDigits, base);
  BigInt get fracNum =>
      fracDigits.isEmpty ? BigInt.zero : parseInBase(fracDigits, base);
  BigInt get fracDen => BigInt.from(base).pow(fracDigits.length);
  bool get isZero => intValue == BigInt.zero && fracNum == BigInt.zero;

  String get display {
    final s = hasFraction ? '$intDigits.$fracDigits' : intDigits;
    return (negative && !isZero) ? '-$s' : s;
  }
}

enum ParseError { empty, invalidChar, tooLong, badFormat }

class NumberParse {
  const NumberParse.ok(ParsedNumber this.value)
      : error = null,
        badChar = null;
  const NumberParse.fail(ParseError this.error, [this.badChar]) : value = null;
  final ParsedNumber? value;
  final ParseError? error;
  final String? badChar;
  bool get ok => value != null;
}

/// Accepts spaces/underscores as separators, ',' or '.' as the radix point,
/// a leading '+', '-' or '−', and lowercase letters.
NumberParse parseNumber(String raw, int base, {bool allowFraction = true}) {
  var s = raw.trim().replaceAll(RegExp(r'[\s_  ]'), '');
  if (s.length > kMaxInputLength) {
    return const NumberParse.fail(ParseError.tooLong);
  }
  var neg = false;
  if (s.startsWith('-') || s.startsWith('−')) {
    neg = true;
    s = s.substring(1);
  } else if (s.startsWith('+')) {
    s = s.substring(1);
  }
  s = s.replaceAll(',', '.').toUpperCase();
  if (s.isEmpty || s == '.') return const NumberParse.fail(ParseError.empty);
  final parts = s.split('.');
  if (parts.length > 2 || (!allowFraction && parts.length > 1)) {
    return const NumberParse.fail(ParseError.badFormat);
  }
  for (final ch in s.split('')) {
    if (ch == '.') continue;
    final v = digitValue(ch);
    if (v < 0 || v >= base) return NumberParse.fail(ParseError.invalidChar, ch);
  }
  final ip = stripLeadingZeros(parts[0].isEmpty ? '0' : parts[0]);
  var fp = parts.length == 2 ? parts[1] : '';
  fp = fp.replaceFirst(RegExp(r'0+$'), '');
  if (ip.length > kMaxIntDigits || fp.length > kMaxFracDigits) {
    return const NumberParse.fail(ParseError.tooLong);
  }
  return NumberParse.ok(ParsedNumber(
      negative: neg, intDigits: ip, fracDigits: fp, base: base));
}

String parseErrorText(NumberParse p, int base) {
  switch (p.error) {
    case ParseError.empty:
      return tr('Scrivi un numero', 'Type a number');
    case ParseError.invalidChar:
      return tr(
          '«${p.badChar}» non è una cifra in base $base (cifre: ${validDigitsLabel(base)})',
          '"${p.badChar}" is not a digit in base $base (digits: ${validDigitsLabel(base)})');
    case ParseError.tooLong:
      return tr(
          'Numero troppo lungo (max $kMaxIntDigits cifre intere e $kMaxFracDigits dopo la virgola)',
          'Number too long (max $kMaxIntDigits integer and $kMaxFracDigits fractional digits)');
    case ParseError.badFormat:
      return tr('Formato non valido: usa al massimo una virgola',
          'Invalid format: use at most one radix point');
    case null:
      return '';
  }
}

/// Result of a conversion; the fractional part may repeat forever.
class ConvResult {
  const ConvResult({
    required this.negative,
    required this.intDigits,
    required this.fracDigits,
    required this.repeat,
    required this.truncated,
  });
  final bool negative;
  final String intDigits;
  final String fracDigits; // digits before the repeating block
  final String repeat; // repeating block ('' if none)
  final bool truncated; // cut at kMaxFracDigits, no period found

  bool get hasFraction => fracDigits.isNotEmpty || repeat.isNotEmpty;

  /// e.g. "-101.0(011)": digits in brackets repeat forever.
  String get display {
    final sign = negative ? '-' : '';
    if (!hasFraction) return '$sign$intDigits';
    final rep = repeat.isEmpty ? '' : '($repeat)';
    final dots = truncated ? '…' : '';
    return '$sign$intDigits.$fracDigits$rep$dots';
  }

  /// Copy-friendly: no brackets.
  String get plain {
    final sign = negative ? '-' : '';
    if (!hasFraction) return '$sign$intDigits';
    return '$sign$intDigits.$fracDigits$repeat';
  }
}

ConvResult convertNumber(ParsedNumber n, int to) {
  final ip = toBase(n.intValue, to);
  final (frac, rep, cut) = fractionDigits(n.fracNum, n.fracDen, to);
  return ConvResult(
    negative: n.negative && !n.isZero,
    intDigits: ip,
    fracDigits: frac,
    repeat: rep,
    truncated: cut,
  );
}

/// Digits of num/den (0 ≤ num < den) in base [to]: (prefix, period, truncated).
(String, String, bool) fractionDigits(BigInt num, BigInt den, int to,
    {int maxDigits = kMaxFracDigits}) {
  if (num == BigInt.zero) return ('', '', false);
  final t = BigInt.from(to);
  final seen = <BigInt, int>{};
  final out = StringBuffer();
  var r = num;
  var i = 0;
  while (r != BigInt.zero && i < maxDigits) {
    final at = seen[r];
    if (at != null) {
      final s = out.toString();
      return (s.substring(0, at), s.substring(at), false);
    }
    seen[r] = i;
    r *= t;
    out.write(kDigits[(r ~/ den).toInt()]);
    r = r % den;
    i++;
  }
  final at = seen[r];
  if (r != BigInt.zero && at != null) {
    final s = out.toString();
    return (s.substring(0, at), s.substring(at), false);
  }
  return (out.toString(), '', r != BigInt.zero);
}

/// Decimal text of num/den: exact when it terminates, otherwise "0.333333…".
String ratToDecimal(BigInt num, BigInt den, {int maxDigits = 8}) {
  final ip = num ~/ den;
  final r = num % den;
  if (r == BigInt.zero) return '$ip';
  final (f, rep, cut) = fractionDigits(r, den, 10, maxDigits: maxDigits);
  if (rep.isEmpty && !cut) return '$ip.$f';
  var all = f;
  while (all.length < maxDigits) {
    all += rep.isEmpty ? '' : rep;
    if (rep.isEmpty) break;
  }
  if (all.length > maxDigits) all = all.substring(0, maxDigits);
  return '$ip.$all…';
}

// ---------------------------------------------------------------------------
// Fraction explanations
// ---------------------------------------------------------------------------

/// digit × base^(−k), k = 1, 2, …
class FracTerm {
  const FracTerm(this.digit, this.digitVal, this.k, this.den);
  final String digit;
  final int digitVal;
  final int k;
  final BigInt den; // base^k
}

List<FracTerm> fracTerms(String fracDigits, int base) => [
      for (var i = 0; i < fracDigits.length; i++)
        FracTerm(fracDigits[i], digitValue(fracDigits[i]), i + 1,
            BigInt.from(base).pow(i + 1)),
    ];

/// One step of "multiply the fractional part by the base".
class MulFracStep {
  const MulFracStep(this.num, this.den, this.base, this.digit);
  final BigInt num; // fractional part before the step = num/den
  final BigInt den;
  final int base;
  final int digit; // integer part of num*base/den
  BigInt get product => num * BigInt.from(base);
  BigInt get nextNum => product % den;
}

List<MulFracStep> mulFracSteps(BigInt num, BigInt den, int to, {int max = 12}) {
  final steps = <MulFracStep>[];
  final seen = <BigInt>{};
  var r = num;
  while (r != BigInt.zero && steps.length < max && seen.add(r)) {
    final d = ((r * BigInt.from(to)) ~/ den).toInt();
    final s = MulFracStep(r, den, to, d);
    steps.add(s);
    r = s.nextNum;
  }
  return steps;
}

bool isPow2Base(int b) => b >= 2 && b <= 32 && (b & (b - 1)) == 0;

/// How the explanation should proceed for a pair of bases.
enum ConvMethod { same, grouping, viaBinary, toDecimal, fromDecimal, viaDecimal }

ConvMethod methodFor(int from, int to, {bool hasFraction = false}) {
  if (from == to) return ConvMethod.same;
  if (!hasFraction && isPow2Base(from) && isPow2Base(to)) {
    if (from == 2 || to == 2) return ConvMethod.grouping;
    return ConvMethod.viaBinary;
  }
  if (to == 10) return ConvMethod.toDecimal;
  if (from == 10) return ConvMethod.fromDecimal;
  return ConvMethod.viaDecimal;
}

/// Inserts a space every [size] digits from the right of the integer part
/// (and from the left of the fractional part) for readability.
String groupDigits(String s, int size) {
  if (size <= 0) return s;
  var sign = '';
  var body = s;
  if (body.startsWith('-')) {
    sign = '-';
    body = body.substring(1);
  }
  final dot = body.indexOf('.');
  final ip = dot < 0 ? body : body.substring(0, dot);
  final rest = dot < 0 ? '' : body.substring(dot);
  final b = StringBuffer();
  for (var i = 0; i < ip.length; i++) {
    if (i > 0 && (ip.length - i) % size == 0) b.write(' ');
    b.write(ip[i]);
  }
  return '$sign$b$rest';
}

int groupSizeFor(int base) => switch (base) {
      2 => 4,
      4 => 4,
      8 => 3,
      10 => 3,
      16 => 4,
      _ => 0,
    };
