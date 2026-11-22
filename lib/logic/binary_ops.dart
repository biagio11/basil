/// Binary arithmetic with step-by-step data for explanations.
library;

import 'dart:math';

import '../app/i18n.dart';
import 'base_conv.dart';

// ---------------------------------------------------------------------------
// Addition
// ---------------------------------------------------------------------------

class AddColumn {
  const AddColumn({
    required this.position,
    required this.a,
    required this.b,
    required this.carryIn,
    required this.sum,
    required this.bit,
    required this.carryOut,
  });
  final int position; // 0 = rightmost
  final int a;
  final int b;
  final int carryIn;
  final int sum;
  final int bit;
  final int carryOut;
}

class AddResult {
  const AddResult({
    required this.a,
    required this.b,
    required this.result,
    required this.columns,
  });
  final String a; // padded
  final String b; // padded
  final String result; // may be one digit longer than a/b
  final List<AddColumn> columns; // right to left
}

AddResult addBinary(String x, String y) {
  final n = max(x.length, y.length);
  final a = x.padLeft(n, '0');
  final b = y.padLeft(n, '0');
  final cols = <AddColumn>[];
  final bits = <String>[];
  var carry = 0;
  for (var i = n - 1; i >= 0; i--) {
    final da = a.codeUnitAt(i) - 48;
    final db = b.codeUnitAt(i) - 48;
    final s = da + db + carry;
    final bit = s % 2;
    final co = s ~/ 2;
    cols.add(AddColumn(
      position: n - 1 - i,
      a: da,
      b: db,
      carryIn: carry,
      sum: s,
      bit: bit,
      carryOut: co,
    ));
    bits.add('$bit');
    carry = co;
  }
  if (carry == 1) bits.add('1');
  return AddResult(a: a, b: b, result: bits.reversed.join(), columns: cols);
}

String addColumnText(AddColumn c) {
  final carryPart = c.carryIn == 1 ? tr(' + riporto 1', ' + carry 1') : '';
  final total = c.sum.toRadixString(2);
  final carryOut = c.carryOut == 1 ? tr(', riporto 1', ', carry 1') : '';
  return tr('${c.a} + ${c.b}$carryPart = $total → scrivo ${c.bit}$carryOut',
      '${c.a} + ${c.b}$carryPart = $total → write ${c.bit}$carryOut');
}

// ---------------------------------------------------------------------------
// Subtraction (requires x >= y)
// ---------------------------------------------------------------------------

class SubColumn {
  const SubColumn({
    required this.position,
    required this.a,
    required this.b,
    required this.borrowIn,
    required this.borrowOut,
    required this.bit,
  });
  final int position;
  final int a;
  final int b;
  final int borrowIn;
  final int borrowOut;
  final int bit;
}

class SubResult {
  const SubResult({
    required this.a,
    required this.b,
    required this.result,
    required this.columns,
  });
  final String a; // padded
  final String b; // padded
  final String result; // same width as a
  final List<SubColumn> columns;
}

SubResult subBinary(String x, String y) {
  final n = max(x.length, y.length);
  final a = x.padLeft(n, '0');
  final b = y.padLeft(n, '0');
  final cols = <SubColumn>[];
  final bits = <String>[];
  var borrow = 0;
  for (var i = n - 1; i >= 0; i--) {
    final da = a.codeUnitAt(i) - 48;
    final db = b.codeUnitAt(i) - 48;
    var d = da - db - borrow;
    var bo = 0;
    if (d < 0) {
      d += 2;
      bo = 1;
    }
    cols.add(SubColumn(
      position: n - 1 - i,
      a: da,
      b: db,
      borrowIn: borrow,
      borrowOut: bo,
      bit: d,
    ));
    bits.add('$d');
    borrow = bo;
  }
  return SubResult(a: a, b: b, result: bits.reversed.join(), columns: cols);
}

String subColumnText(SubColumn c) {
  final lent = c.borrowIn == 1 ? tr(' − prestito 1', ' − borrow 1') : '';
  if (c.borrowOut == 1) {
    return tr(
        '${c.a} − ${c.b}$lent non si può: prendo 1 in prestito dalla '
            'colonna a sinistra (vale 2) → ${c.a + 2} − ${c.b}$lent = ${c.bit}',
        '${c.a} − ${c.b}$lent is negative: borrow 1 from the left column '
            '(worth 2) → ${c.a + 2} − ${c.b}$lent = ${c.bit}');
  }
  return '${c.a} − ${c.b}$lent = ${c.bit}';
}

// ---------------------------------------------------------------------------
// Multiplication
// ---------------------------------------------------------------------------

class MulResult {
  const MulResult({required this.a, required this.b, required this.rows, required this.result});
  final String a;
  final String b;
  final List<String> rows; // shifted partial products, bottom bit first
  final String result;
}

MulResult mulBinary(String x, String y) {
  final rows = <String>[];
  var total = BigInt.zero;
  for (var i = y.length - 1; i >= 0; i--) {
    final shift = y.length - 1 - i;
    final base = y[i] == '1' ? x : '0' * x.length;
    final row = base + '0' * shift;
    rows.add(row);
    total += parseInBase(row, 2);
  }
  return MulResult(a: x, b: y, rows: rows, result: toBase(total, 2));
}

// ---------------------------------------------------------------------------
// Division (long division in binary)
// ---------------------------------------------------------------------------

class DivBinStep {
  const DivBinStep({
    required this.broughtDown,
    required this.current,
    required this.qBit,
    required this.remainder,
  });
  final String broughtDown;
  final BigInt current; // partial remainder after bringing the bit down
  final int qBit;
  final BigInt remainder;
}

class DivBinResult {
  const DivBinResult({
    required this.quotient,
    required this.remainder,
    required this.steps,
  });
  final String quotient;
  final String remainder;
  final List<DivBinStep> steps;
}

/// [divisor] must be non-zero.
DivBinResult divBinary(String dividend, String divisor) {
  final d = parseInBase(divisor, 2);
  final two = BigInt.from(2);
  var rem = BigInt.zero;
  final q = StringBuffer();
  final steps = <DivBinStep>[];
  for (var i = 0; i < dividend.length; i++) {
    final bit = dividend[i];
    rem = rem * two + BigInt.from(bit == '1' ? 1 : 0);
    final current = rem;
    var qb = 0;
    if (rem >= d) {
      rem -= d;
      qb = 1;
    }
    steps.add(DivBinStep(
        broughtDown: bit, current: current, qBit: qb, remainder: rem));
    q.write(qb);
  }
  return DivBinResult(
    quotient: stripLeadingZeros(q.toString()),
    remainder: toBase(rem, 2),
    steps: steps,
  );
}

String divStepText(DivBinStep s, String divisor) {
  final cur = toBase(s.current, 2);
  if (s.qBit == 1) {
    return tr(
        'Abbasso ${s.broughtDown}: ho $cur → $divisor sta (1), '
            'resto ${toBase(s.remainder, 2)}',
        'Bring down ${s.broughtDown}: $cur → $divisor fits (1), '
            'remainder ${toBase(s.remainder, 2)}');
  }
  return tr('Abbasso ${s.broughtDown}: ho $cur → $divisor non sta (0)',
      'Bring down ${s.broughtDown}: $cur → $divisor does not fit (0)');
}

// ---------------------------------------------------------------------------
// Overflow
// ---------------------------------------------------------------------------

int wrapAdd(int value, int add, int bits) => (value + add) & ((1 << bits) - 1);
