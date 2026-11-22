/// Column arithmetic (+ − × ÷) in any base 2-36, with step data.
library;

import 'dart:math';

import '../app/i18n.dart';
import 'base_conv.dart';

enum Op {
  add('+'),
  sub('−'),
  mul('×'),
  div('÷');

  const Op(this.symbol);
  final String symbol;
}

/// One column of an addition or subtraction (position 0 = rightmost).
class OpColumn {
  const OpColumn({
    required this.position,
    required this.a,
    required this.b,
    required this.carryIn,
    required this.value,
    required this.digit,
    required this.carryOut,
  });
  final int position;
  final int a;
  final int b;
  final int carryIn; // carry (add) or borrow (sub) coming from the right
  final int value; // add: a+b+carry. sub: a−b−borrow (+base if borrowed)
  final int digit;
  final int carryOut;
}

class ColumnOpResult {
  const ColumnOpResult({
    required this.op,
    required this.base,
    required this.a,
    required this.b,
    required this.result,
    required this.columns,
    required this.negative,
  });
  final Op op;
  final int base;
  final String a; // padded operand on top
  final String b; // padded operand below
  final String result; // digits (no sign)
  final List<OpColumn> columns; // right to left
  /// Subtraction where the second number was bigger: we computed b − a.
  final bool negative;
}

String _d(int v) => digitChar(v);

/// Shows a digit with its decimal value when it is a letter: "B(11)".
String dv(int v) => v >= 10 ? '${_d(v)}($v)' : '$v';

ColumnOpResult addBase(String x, String y, int base) {
  final n = max(x.length, y.length);
  final a = x.padLeft(n, '0');
  final b = y.padLeft(n, '0');
  final cols = <OpColumn>[];
  final out = <String>[];
  var carry = 0;
  for (var i = n - 1; i >= 0; i--) {
    final da = digitValue(a[i]);
    final db = digitValue(b[i]);
    final s = da + db + carry;
    final digit = s % base;
    final co = s ~/ base;
    cols.add(OpColumn(
        position: n - 1 - i,
        a: da,
        b: db,
        carryIn: carry,
        value: s,
        digit: digit,
        carryOut: co));
    out.add(_d(digit));
    carry = co;
  }
  if (carry > 0) out.add(_d(carry));
  return ColumnOpResult(
      op: Op.add,
      base: base,
      a: a,
      b: b,
      result: out.reversed.join(),
      columns: cols,
      negative: false);
}

/// x − y. If y > x the operands are swapped and [negative] is set.
ColumnOpResult subBase(String x, String y, int base) {
  var neg = false;
  if (parseInBase(y, base) > parseInBase(x, base)) {
    final t = x;
    x = y;
    y = t;
    neg = true;
  }
  final n = max(x.length, y.length);
  final a = x.padLeft(n, '0');
  final b = y.padLeft(n, '0');
  final cols = <OpColumn>[];
  final out = <String>[];
  var borrow = 0;
  for (var i = n - 1; i >= 0; i--) {
    final da = digitValue(a[i]);
    final db = digitValue(b[i]);
    var d = da - db - borrow;
    var bo = 0;
    if (d < 0) {
      d += base;
      bo = 1;
    }
    cols.add(OpColumn(
        position: n - 1 - i,
        a: da,
        b: db,
        carryIn: borrow,
        value: d,
        digit: d,
        carryOut: bo));
    out.add(_d(d));
    borrow = bo;
  }
  return ColumnOpResult(
      op: Op.sub,
      base: base,
      a: a,
      b: b,
      result: stripLeadingZeros(out.reversed.join()),
      columns: cols,
      negative: neg);
}

String columnText(ColumnOpResult r, OpColumn c) {
  final b = r.base;
  if (r.op == Op.add) {
    final carry = c.carryIn > 0 ? tr(' + riporto ${c.carryIn}', ' + carry ${c.carryIn}') : '';
    if (c.carryOut == 0) {
      return tr('${dv(c.a)} + ${dv(c.b)}$carry = ${c.value} → scrivo ${_d(c.digit)}',
          '${dv(c.a)} + ${dv(c.b)}$carry = ${c.value} → write ${_d(c.digit)}');
    }
    return tr(
        '${dv(c.a)} + ${dv(c.b)}$carry = ${c.value} = ${c.carryOut}×$b + ${c.digit} → scrivo ${_d(c.digit)}, riporto ${c.carryOut}',
        '${dv(c.a)} + ${dv(c.b)}$carry = ${c.value} = ${c.carryOut}×$b + ${c.digit} → write ${_d(c.digit)}, carry ${c.carryOut}');
  }
  final lent = c.carryIn > 0 ? tr(' − prestito 1', ' − borrow 1') : '';
  if (c.carryOut == 1) {
    final big = c.a + b;
    return tr(
        '${dv(c.a)} − ${dv(c.b)}$lent non si può: prendo 1 dalla colonna a sinistra (vale $b) → $big − ${c.b}${c.carryIn > 0 ? ' − 1' : ''} = ${dv(c.digit)}',
        '${dv(c.a)} − ${dv(c.b)}$lent is negative: borrow 1 from the left column (worth $b) → $big − ${c.b}${c.carryIn > 0 ? ' − 1' : ''} = ${dv(c.digit)}');
  }
  return '${dv(c.a)} − ${dv(c.b)}$lent = ${dv(c.digit)}';
}

// ---------------------------------------------------------------------------
// Multiplication: one partial product per digit of the second factor
// ---------------------------------------------------------------------------

class MulRow {
  const MulRow(this.digit, this.shift, this.value);
  final int digit; // digit of the second factor
  final int shift; // positions shifted left
  final String value; // partial product (with shift zeros), in base
}

class MulBaseResult {
  const MulBaseResult(this.a, this.b, this.base, this.rows, this.result);
  final String a;
  final String b;
  final int base;
  final List<MulRow> rows;
  final String result;
}

MulBaseResult mulBase(String x, String y, int base) {
  final bx = parseInBase(x, base);
  final rows = <MulRow>[];
  var total = BigInt.zero;
  for (var i = y.length - 1; i >= 0; i--) {
    final shift = y.length - 1 - i;
    final d = digitValue(y[i]);
    final p = bx * BigInt.from(d);
    final s = d == 0 ? '0' * x.length : toBase(p, base);
    rows.add(MulRow(d, shift, s + '0' * shift));
    total += p * BigInt.from(base).pow(shift);
  }
  return MulBaseResult(x, y, base, rows, toBase(total, base));
}

// ---------------------------------------------------------------------------
// Long division in base b
// ---------------------------------------------------------------------------

class DivBaseStep {
  const DivBaseStep(this.broughtDown, this.current, this.qDigit, this.remainder);
  final String broughtDown;
  final BigInt current;
  final int qDigit;
  final BigInt remainder;
}

class DivBaseResult {
  const DivBaseResult(this.dividend, this.divisor, this.base, this.steps,
      this.quotient, this.remainder);
  final String dividend;
  final String divisor;
  final int base;
  final List<DivBaseStep> steps;
  final String quotient;
  final String remainder;
}

/// [divisor] must be non-zero.
DivBaseResult divBase(String dividend, String divisor, int base) {
  final d = parseInBase(divisor, base);
  final b = BigInt.from(base);
  var rem = BigInt.zero;
  final q = StringBuffer();
  final steps = <DivBaseStep>[];
  for (var i = 0; i < dividend.length; i++) {
    rem = rem * b + BigInt.from(digitValue(dividend[i]));
    final cur = rem;
    final qd = (rem ~/ d).toInt();
    rem = rem - d * BigInt.from(qd);
    steps.add(DivBaseStep(dividend[i], cur, qd, rem));
    q.write(digitChar(qd));
  }
  return DivBaseResult(dividend, divisor, base, steps,
      stripLeadingZeros(q.toString()), toBase(rem, base));
}

String divStepTextBase(DivBaseStep s, DivBaseResult r) {
  final cur = toBase(s.current, r.base);
  if (s.qDigit == 0) {
    return tr('Abbasso ${s.broughtDown}: ho $cur → ${r.divisor} non ci sta → 0',
        'Bring down ${s.broughtDown}: $cur → ${r.divisor} does not fit → 0');
  }
  return tr(
      'Abbasso ${s.broughtDown}: ho $cur → ${r.divisor} ci sta ${dv(s.qDigit)} volte, resto ${toBase(s.remainder, r.base)}',
      'Bring down ${s.broughtDown}: $cur → ${r.divisor} fits ${dv(s.qDigit)} times, remainder ${toBase(s.remainder, r.base)}');
}
