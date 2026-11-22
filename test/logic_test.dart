import 'dart:math';

import 'package:basil/app/i18n.dart';
import 'package:basil/logic/base_conv.dart';
import 'package:basil/logic/base_ops.dart';
import 'package:basil/logic/binary_ops.dart';
import 'package:basil/logic/exercises.dart';
import 'package:basil/logic/numbers.dart';
import 'package:basil/logic/signed.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('base conversion', () {
    test('10 -> 2 and back', () {
      expect(toBaseInt(37, 2), '100101');
      expect(parseInBase('100101', 2), BigInt.from(37));
    });

    test('hex', () {
      expect(parseInBase('2F', 16), BigInt.from(47));
      expect(toBaseInt(200, 16), 'C8');
      expect(toBaseInt(255, 16), 'FF');
    });

    test('same value in several bases (45)', () {
      expect(parseInBase('231', 4), BigInt.from(45));
      expect(toBaseInt(45, 2), '101101');
      expect(toBaseInt(45, 5), '140');
      expect(toBaseInt(45, 16), '2D');
    });

    test('division steps for 37', () {
      final steps = divisionSteps(BigInt.from(37), 2);
      expect(steps.map((s) => s.remainder).toList(), [1, 0, 1, 0, 0, 1]);
      expect(steps.map((s) => s.quotient.toInt()).toList(), [
        18,
        9,
        4,
        2,
        1,
        0,
      ]);
    });

    test('zero', () {
      expect(toBaseInt(0, 2), '0');
      expect(divisionSteps(BigInt.zero, 2).length, 1);
    });

    test('validation', () {
      expect(isValidInBase('1012', 2), isFalse);
      expect(isValidInBase('2f', 16), isTrue);
      expect(isValidInBase('', 2), isFalse);
    });

    test('grouping shortcut', () {
      final m = groupShortcut('2D', 16, 2)!;
      expect(m.bitGroups, ['0010', '1101']);
      final n = groupShortcut('101101', 2, 16)!;
      expect(n.digits, ['2', 'D']);
      expect(groupShortcut('101', 10, 2), isNull);
    });

    test('rgb', () {
      expect(rgbToHex(255, 128, 0), '#FF8000');
    });
  });

  group('binary operations', () {
    test('add', () {
      expect(addBinary('1011', '110').result, '10001');
      expect(addBinary('1101', '11').result, '10000');
    });

    test('sub', () {
      expect(stripLeadingZeros(subBinary('1101', '110').result), '111');
      expect(subBinary('1000', '1').result, '0111');
    });

    test('mul', () {
      final r = mulBinary('101', '11');
      expect(r.rows, ['101', '1010']);
      expect(r.result, '1111');
    });

    test('div', () {
      final r = divBinary('1101', '11');
      expect(r.quotient, '100');
      expect(r.remainder, '1');
      expect(divBinary('1101', '10').quotient, '110');
    });

    test('overflow', () {
      expect(wrapAdd(255, 1, 8), 0);
      expect(wrapAdd(15, 1, 4), 0);
      expect(wrapAdd(10, 3, 4), 13);
    });
  });

  group('exercise generator', () {
    test('every topic exercise accepts its own answer', () {
      final gen = ExerciseGenerator(Random(42));
      for (final lang in ['it', 'en']) {
        appLang = lang;
        for (final t in Topic.values) {
          for (final d in Difficulty.values) {
            for (var i = 0; i < 120; i++) {
              final ex = gen.topic(t, d);
              expect(ex.check(ex.answer), isTrue, reason: '${ex.prompt} -> ${ex.answer}');
              expect(ex.check(ex.answer.toLowerCase()), isTrue);
              if (!ex.answer.startsWith('-')) expect(ex.check('00${ex.answer}'), isTrue);
              expect(ex.solution, isNotEmpty);
            }
          }
        }
      }
      appLang = 'it';
    });

    test('conversion exercises between every pair of bases are correct', () {
      final gen = ExerciseGenerator(Random(3));
      for (var a = 2; a <= 36; a += 3) {
        for (var b = 2; b <= 36; b += 5) {
          if (a == b) continue;
          final ex = gen.conversion(a, b, Difficulty.medium);
          final v = parseInBase(ex.question, a);
          expect(toBase(v, b), ex.answer);
        }
      }
    });

    test('operation exercises in many bases are correct', () {
      final gen = ExerciseGenerator(Random(9));
      for (final base in [2, 3, 5, 8, 10, 16, 36]) {
        for (final op in Op.values) {
          for (final d in Difficulty.values) {
            final ex = gen.operation(op, base, d);
            final parts = ex.question.split(' ${op.symbol} ');
            final x = parseInBase(parts[0], base);
            final y = parseInBase(parts[1], base);
            final expected = switch (op) {
              Op.add => x + y,
              Op.sub => x - y,
              Op.mul => x * y,
              Op.div => x ~/ y,
            };
            expect(parseInBase(ex.answer, base), expected, reason: ex.prompt);
            if (op == Op.div) expect(x % y, BigInt.zero);
          }
        }
      }
    });

    test('wrong answers are rejected', () {
      final gen = ExerciseGenerator(Random(1));
      final ex = gen.conversion(2, 10, Difficulty.medium);
      final wrong = (BigInt.parse(ex.answer) + BigInt.one).toString();
      expect(ex.check(wrong), isFalse);
      expect(ex.check(''), isFalse);
      expect(ex.check('zz!'), isFalse);
    });
  });

  group('numbers with sign and fraction', () {
    test('parse accepts separators, comma, sign, lowercase', () {
      final p = parseNumber(' -1_0 1,10 ', 2);
      expect(p.ok, isTrue);
      expect(p.value!.negative, isTrue);
      expect(p.value!.intDigits, '101');
      expect(p.value!.fracDigits, '1');
      expect(parseNumber('ff', 16).value!.intValue, BigInt.from(255));
    });

    test('parse rejects bad input', () {
      expect(parseNumber('', 10).error, ParseError.empty);
      expect(parseNumber('12', 2).error, ParseError.invalidChar);
      expect(parseNumber('12', 2).badChar, '2');
      expect(parseNumber('1.2.3', 10).error, ParseError.badFormat);
      expect(parseNumber('1' * 200, 10).error, ParseError.tooLong);
      expect(parseNumber('<script>', 36).error, ParseError.invalidChar);
    });

    test('fractions convert exactly, with periods', () {
      ConvResult c(String s, int from, int to) => convertNumber(parseNumber(s, from).value!, to);
      expect(c('5.75', 10, 2).display, '101.11');
      expect(c('101.11', 2, 10).display, '5.75');
      expect(c('0.1', 10, 2).display, '0.0(0011)');
      expect(c('0.1', 3, 10).display, '0.(3)');
      expect(c('-45', 10, 16).display, '-2D');
      expect(c('-0', 10, 2).display, '0');
      expect(c('0.5', 10, 16).display, '0.8');
    });

    test('grouping helper', () {
      expect(groupDigits('10110110', 4), '1011 0110');
      expect(groupDigits('-1234567', 3), '-1 234 567');
      expect(groupDigits('101.11', 4), '101.11');
    });

    test('method choice', () {
      expect(methodFor(2, 16), ConvMethod.grouping);
      expect(methodFor(8, 16), ConvMethod.viaBinary);
      expect(methodFor(8, 16, hasFraction: true), ConvMethod.viaDecimal);
      expect(methodFor(7, 10), ConvMethod.toDecimal);
      expect(methodFor(10, 7), ConvMethod.fromDecimal);
      expect(methodFor(5, 7), ConvMethod.viaDecimal);
    });
  });

  group('operations in any base', () {
    test('add/sub/mul/div agree with BigInt', () {
      final r = Random(5);
      for (var i = 0; i < 300; i++) {
        final base = 2 + r.nextInt(35);
        final x = BigInt.from(r.nextInt(1 << 20));
        final y = BigInt.from(1 + r.nextInt(1 << 12));
        final sx = toBase(x, base);
        final sy = toBase(y, base);
        expect(parseInBase(addBase(sx, sy, base).result, base), x + y);
        final sub = subBase(sx, sy, base);
        expect(parseInBase(sub.result, base) * (sub.negative ? -BigInt.one : BigInt.one), x - y);
        expect(parseInBase(mulBase(sx, sy, base).result, base), x * y);
        final d = divBase(sx, sy, base);
        expect(parseInBase(d.quotient, base), x ~/ y);
        expect(parseInBase(d.remainder, base), x % y);
      }
    });

    test('subtraction swaps when the result is negative', () {
      final r = subBase('11', '101', 2);
      expect(r.negative, isTrue);
      expect(r.result, '10');
    });
  });

  group('signed numbers', () {
    test('representations of -5 on 8 bits', () {
      expect(toSignMagnitude(-5, 8), '10000101');
      expect(toOnes(-5, 8), '11111010');
      expect(toTwos(-5, 8), '11111011');
      expect(twosValue(0xFB, 8), -5);
      expect(signMagnitudeValue(0x80, 8), '-0');
      expect(onesValue(0xFF, 8), '-0');
      expect(twosRange(4), (-8, 7));
    });

    test('two complement round trips', () {
      for (var n = -128; n < 128; n++) {
        expect(twosValue(int.parse(toTwos(n, 8), radix: 2), 8), n);
      }
    });

    test('two complement exercises accept their answers', () {
      final gen = ExerciseGenerator(Random(11));
      for (final d in Difficulty.values) {
        for (var i = 0; i < 200; i++) {
          final ex = gen.twos(d);
          expect(ex.check(ex.answer), isTrue, reason: ex.prompt);
          expect(ex.solution, isNotEmpty);
          if (ex.answerBase == 10) {
            final n = int.parse(ex.answer);
            expect(ex.check('${n + 1}'), isFalse);
            if (n < 0) expect(ex.check('${-n}'), isFalse);
          }
        }
      }
    });
  });
}
