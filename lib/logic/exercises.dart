/// Random exercise generator with worked solutions (bilingual).
library;

import 'dart:math';

import '../app/i18n.dart';
import 'base_conv.dart';
import 'base_ops.dart';

enum Difficulty {
  easy,
  medium,
  hard;

  String get label => switch (this) {
        Difficulty.easy => tr('Facile', 'Easy'),
        Difficulty.medium => tr('Medio', 'Medium'),
        Difficulty.hard => tr('Difficile', 'Hard'),
      };
}

class Exercise {
  const Exercise({
    required this.category,
    required this.prompt,
    required this.hint,
    required this.answer,
    required this.answerBase,
    required this.solution,
    this.question = '',
    this.questionBase = 10,
  });

  final String category;
  final String prompt;
  final String hint;

  /// Bare operand / number shown big (e.g. "1011") and its base.
  final String question;
  final int questionBase;

  /// Canonical answer, written in [answerBase].
  final String answer;
  final int answerBase;
  final List<String> solution;

  bool check(String input) {
    final t = cleanInput(input).replaceFirst(RegExp(r'^\+'), '');
    if (t.isEmpty || t.length > 80) return false;
    if (!isValidInBase(t, answerBase)) return false;
    return parseInBase(t, answerBase) == parseInBase(answer, answerBase);
  }

  String get answerDisplay =>
      answerBase == 10 ? answer : withBase(answer, answerBase);
}

// ---------------------------------------------------------------------------
// Explanation helpers
// ---------------------------------------------------------------------------

List<String> expansionLines(List<PowerTerm> terms, BigInt value) {
  final prod = terms.map((t) => '${t.digitVal}×${t.weight}').join(' + ');
  final sum = terms.map((t) => t.product.toString()).join(' + ');
  return [
    tr('Cifra × peso (base^posizione): $prod',
        'Digit × weight (base^position): $prod'),
    tr('Somma: $sum = $value', 'Sum: $sum = $value'),
  ];
}

List<String> divisionLines(List<DivStep> steps, String result) {
  final lines = <String>[];
  for (final s in steps) {
    final letter = s.remainder >= 10 ? ' (= ${digitChar(s.remainder)})' : '';
    lines.add(tr(
        '${s.dividend} ÷ ${s.base} = ${s.quotient} resto ${s.remainder}$letter',
        '${s.dividend} ÷ ${s.base} = ${s.quotient} remainder ${s.remainder}$letter'));
  }
  lines.add(tr('Leggo i resti dal basso verso l’alto: $result',
      'Read the remainders from bottom to top: $result'));
  return lines;
}

List<String> groupingLines(String s, int from, int to) {
  if (from == 2 || to == 2) {
    final m = groupShortcut(s, from, to)!;
    final k = m.groupSize;
    final pairs = [
      for (var i = 0; i < m.digits.length; i++)
        m.toBinary
            ? '${m.digits[i]} = ${m.bitGroups[i]}'
            : '${m.bitGroups[i]} = ${m.digits[i]}'
    ].join(',  ');
    return [
      tr('$from e $to: ogni cifra in base ${from == 2 ? to : from} = $k bit (2^$k = ${from == 2 ? to : from})',
          '$from and $to: each base-${from == 2 ? to : from} digit = $k bits (2^$k = ${from == 2 ? to : from})'),
      m.toBinary
          ? tr('Ogni cifra → $k bit: $pairs', 'Each digit → $k bits: $pairs')
          : tr('Gruppi di $k bit da destra: $pairs',
              'Groups of $k bits from the right: $pairs'),
      tr('Risultato: ${m.toBinary ? stripLeadingZeros(m.bitGroups.join()) : m.digits.join()}',
          'Result: ${m.toBinary ? stripLeadingZeros(m.bitGroups.join()) : m.digits.join()}'),
    ];
  }
  // via binary
  final m1 = groupShortcut(s, from, 2)!;
  final bits = stripLeadingZeros(m1.bitGroups.join());
  final m2 = groupShortcut(bits, 2, to)!;
  return [
    tr('Passo 1: base $from → base 2 (${m1.groupSize} bit per cifra): ${m1.bitGroups.join(' ')}',
        'Step 1: base $from → base 2 (${m1.groupSize} bits per digit): ${m1.bitGroups.join(' ')}'),
    tr('Passo 2: raggruppo a ${m2.groupSize} bit da destra: ${m2.bitGroups.join(' ')}',
        'Step 2: regroup by ${m2.groupSize} bits from the right: ${m2.bitGroups.join(' ')}'),
    tr('Risultato: ${m2.digits.join()}', 'Result: ${m2.digits.join()}'),
  ];
}

/// Worked solution for an integer conversion [s] (base [from]) → [to].
List<String> conversionLines(String s, int from, int to) {
  final v = parseInBase(s, from);
  final res = toBase(v, to);
  if (from == to) return [tr('Stessa base: nulla da fare.', 'Same base: nothing to do.')];
  if (isPow2(from) && isPow2(to)) return groupingLines(s, from, to);
  if (to == 10) return expansionLines(expansionTerms(s, from), v);
  if (from == 10) return divisionLines(divisionSteps(v, to), res);
  return [
    tr('Passo 1: da base $from a base 10', 'Step 1: base $from to base 10'),
    ...expansionLines(expansionTerms(s, from), v),
    tr('Passo 2: da base 10 a base $to', 'Step 2: base 10 to base $to'),
    ...divisionLines(divisionSteps(v, to), res),
  ];
}

bool isPow2(int b) => b >= 2 && b <= 32 && (b & (b - 1)) == 0;

String conversionHint(int from, int to) {
  if (isPow2(from) && isPow2(to)) {
    return tr('Scorciatoia: usa i gruppi di bit (passando dalla base 2).',
        'Shortcut: use groups of bits (through base 2).');
  }
  if (to == 10) {
    return tr('Moltiplica ogni cifra per $from^posizione (da 0, a destra) e somma.',
        'Multiply each digit by $from^position (from 0, on the right) and add up.');
  }
  if (from == 10) {
    return tr('Dividi per $to più volte e leggi i resti dal basso verso l’alto.',
        'Divide by $to repeatedly and read the remainders from bottom to top.');
  }
  return tr('Passa dalla base 10: prima cifra × $from^posizione, poi divisioni per $to.',
      'Go through base 10: first digit × $from^position, then divide by $to.');
}

// ---------------------------------------------------------------------------
// Generator
// ---------------------------------------------------------------------------

enum Topic {
  binDec,
  hex,
  octal,
  anyBase,
  binOps,
  anyOps;

  String get label => switch (this) {
        Topic.binDec => tr('Binario ↔ decimale', 'Binary ↔ decimal'),
        Topic.hex => tr('Esadecimale', 'Hexadecimal'),
        Topic.octal => tr('Ottale', 'Octal'),
        Topic.anyBase => tr('Base X → Y', 'Base X → Y'),
        Topic.binOps => tr('Operazioni binarie', 'Binary operations'),
        Topic.anyOps => tr('Operazioni in base X', 'Operations in base X'),
      };
}

class ExerciseGenerator {
  ExerciseGenerator([Random? rng]) : _r = rng ?? Random();
  final Random _r;

  int _between(int lo, int hi) => lo + _r.nextInt(hi - lo + 1);
  T _pick<T>(List<T> xs) => xs[_r.nextInt(xs.length)];

  /// Random digit string of exactly [len] digits, first digit non-zero.
  String _digits(int len, int base) {
    final sb = StringBuffer(digitChar(_between(1, base - 1)));
    for (var i = 1; i < len; i++) {
      sb.write(digitChar(_r.nextInt(base)));
    }
    return sb.toString();
  }

  Exercise topic(Topic t, Difficulty d) {
    switch (t) {
      case Topic.binDec:
        return _r.nextBool() ? conversion(2, 10, d) : conversion(10, 2, d);
      case Topic.hex:
        return _pick(const [
          [16, 10],
          [10, 16],
          [16, 2],
          [2, 16]
        ]).let((p) => conversion(p[0], p[1], d));
      case Topic.octal:
        return _pick(const [
          [8, 10],
          [10, 8],
          [8, 2],
          [2, 8],
          [8, 16],
          [16, 8]
        ]).let((p) => conversion(p[0], p[1], d));
      case Topic.anyBase:
        const bases = [3, 4, 5, 6, 7, 9, 11, 12];
        final a = _pick(bases);
        var b = _pick(bases);
        while (b == a) {
          b = _pick(bases);
        }
        return conversion(a, b, d);
      case Topic.binOps:
        return operation(_pick(Op.values), 2, d);
      case Topic.anyOps:
        return operation(_pick(Op.values), _pick(const [3, 4, 5, 8, 16]), d);
    }
  }

  /// Integer conversion exercise between any two bases.
  Exercise conversion(int from, int to, Difficulty d) {
    final small = from == 2 || to == 2;
    final (lo, hi) = switch (d) {
      Difficulty.easy => small ? (5, 31) : (10, 255),
      Difficulty.medium => small ? (32, 255) : (256, 4095),
      Difficulty.hard => small ? (256, 2047) : (4096, 65535),
    };
    var v = _between(lo, hi);
    // Make hex/high-base exercises contain at least one letter most of the time.
    if (from > 10) {
      for (var i = 0; i < 6 && !RegExp('[A-Z]').hasMatch(toBaseInt(v, from)); i++) {
        v = _between(lo, hi);
      }
    }
    final s = toBaseInt(v, from);
    final res = toBaseInt(v, to);
    final fromTxt = from == 10 ? s : withBase(s, from);
    return Exercise(
      category: tr('Da base $from a base $to', 'Base $from to base $to'),
      prompt: tr('Converti $fromTxt in base $to', 'Convert $fromTxt to base $to'),
      question: s,
      questionBase: from,
      hint: conversionHint(from, to),
      answer: res,
      answerBase: to,
      solution: conversionLines(s, from, to),
    );
  }

  Exercise operation(Op op, int base, Difficulty d) {
    switch (op) {
      case Op.add:
      case Op.sub:
        final len = switch (d) {
          Difficulty.easy => _between(2, 3),
          Difficulty.medium => _between(4, 5),
          Difficulty.hard => _between(6, 8),
        };
        var x = _digits(len, base);
        var y = _digits(_between(max(1, len - 2), len), base);
        if (op == Op.sub && parseInBase(y, base) > parseInBase(x, base)) {
          final t = x;
          x = y;
          y = t;
        }
        final r = op == Op.add ? addBase(x, y, base) : subBase(x, y, base);
        final dx = parseInBase(x, base);
        final dy = parseInBase(y, base);
        final dres = op == Op.add ? dx + dy : dx - dy;
        return _opExercise(op, base, x, y, r.result, [
          for (final c in r.columns)
            tr('Colonna ${c.position}: ', 'Column ${c.position}: ') + columnText(r, c),
          _check(dx, op, dy, dres, r.result, base),
        ], op == Op.add
            ? tr('Colonna per colonna da destra: se la somma arriva a $base, scrivi la differenza e riporta 1.',
                'Column by column from the right: when the sum reaches $base, write the excess and carry 1.')
            : tr('Se la cifra sopra è più piccola, prendi in prestito 1 dalla colonna a sinistra: vale $base.',
                'If the top digit is smaller, borrow 1 from the left column: it is worth $base.'));
      case Op.mul:
        final (la, lb) = switch (d) {
          Difficulty.easy => (2, 1),
          Difficulty.medium => (3, 2),
          Difficulty.hard => (4, 3),
        };
        final x = _digits(la, base);
        final y = _digits(lb, base);
        final r = mulBase(x, y, base);
        final dx = parseInBase(x, base);
        final dy = parseInBase(y, base);
        return _opExercise(op, base, x, y, r.result, [
          for (var i = 0; i < r.rows.length; i++)
            tr('Riga ${i + 1}: $x × ${digitChar(r.rows[i].digit)} = ${r.rows[i].value}',
                'Row ${i + 1}: $x × ${digitChar(r.rows[i].digit)} = ${r.rows[i].value}'),
          tr('Somma delle righe: ${r.result}', 'Sum of the rows: ${r.result}'),
          _check(dx, op, dy, dx * dy, r.result, base),
        ], tr('Una riga per ogni cifra del secondo numero, spostata a sinistra; poi somma le righe.',
            'One row per digit of the second number, shifted left; then add the rows.'));
      case Op.div:
        final (qlo, qhi, dlo, dhi) = switch (d) {
          Difficulty.easy => (2, base * 2, 2, min(base - 1, 5)),
          Difficulty.medium => (base, base * base, 2, base + 3),
          Difficulty.hard => (base * 2, base * base * 4, 3, base * 2),
        };
        final q = _between(qlo, max(qlo, qhi));
        final dvs = _between(dlo, max(dlo, dhi));
        final dividend = toBaseInt(q * dvs, base);
        final divisor = toBaseInt(dvs, base);
        final r = divBase(dividend, divisor, base);
        return _opExercise(op, base, dividend, divisor, r.quotient, [
          for (final s in r.steps) divStepTextBase(s, r),
          tr('Quoziente: ${r.quotient}', 'Quotient: ${r.quotient}'),
          _check(BigInt.from(q * dvs), op, BigInt.from(dvs), BigInt.from(q),
              r.quotient, base),
        ], tr('Divisione in colonna: abbassa una cifra alla volta e chiediti quante volte ci sta il divisore.',
            'Long division: bring down one digit at a time and ask how many times the divisor fits.'));
    }
  }

  String _check(BigInt a, Op op, BigInt b, BigInt res, String digits, int base) {
    return tr('Verifica in base 10: $a ${op.symbol} $b = $res = ${withBase(digits, base)}',
        'Check in base 10: $a ${op.symbol} $b = $res = ${withBase(digits, base)}');
  }

  Exercise _opExercise(Op op, int base, String x, String y, String res,
      List<String> solution, String hint) {
    final name = switch (op) {
      Op.add => tr('Addizione', 'Addition'),
      Op.sub => tr('Sottrazione', 'Subtraction'),
      Op.mul => tr('Moltiplicazione', 'Multiplication'),
      Op.div => tr('Divisione', 'Division'),
    };
    return Exercise(
      category: tr('$name in base $base', '$name in base $base'),
      prompt: tr('Calcola in base $base:  $x ${op.symbol} $y',
          'Compute in base $base:  $x ${op.symbol} $y'),
      question: '$x ${op.symbol} $y',
      questionBase: base,
      hint: hint,
      answer: res,
      answerBase: base,
      solution: solution,
    );
  }
}

extension _Let<T> on T {
  R let<R>(R Function(T) f) => f(this);
}
