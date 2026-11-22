/// Signed integer representations on a fixed number of bits.
library;

/// Value of [x] (0 ≤ x < 2^bits) read as two's complement.
int twosValue(int x, int bits) {
  final sign = 1 << (bits - 1);
  return (x & sign) == 0 ? x : x - (1 << bits);
}

/// Value read as sign and magnitude ("-0" exists).
String signMagnitudeValue(int x, int bits) {
  final sign = 1 << (bits - 1);
  final mag = x & (sign - 1);
  if ((x & sign) == 0) return '$mag';
  return mag == 0 ? '-0' : '-$mag';
}

/// Value read as one's complement ("-0" exists).
String onesValue(int x, int bits) {
  final sign = 1 << (bits - 1);
  if ((x & sign) == 0) return '$x';
  final mag = (~x) & ((1 << bits) - 1);
  return mag == 0 ? '-0' : '-$mag';
}

/// Bit pattern of [n] in two's complement on [bits] bits.
String toTwos(int n, int bits) => (n & ((1 << bits) - 1)).toRadixString(2).padLeft(bits, '0');

String toSignMagnitude(int n, int bits) =>
    (n < 0 ? '1' : '0') + n.abs().toRadixString(2).padLeft(bits - 1, '0');

String toOnes(int n, int bits) {
  final p = n.abs().toRadixString(2).padLeft(bits, '0');
  if (n >= 0) return p;
  return p.split('').map((c) => c == '0' ? '1' : '0').join();
}

class TwosSteps {
  const TwosSteps(this.magnitude, this.inverted, this.result);
  final String magnitude;
  final String inverted;
  final String result;
}

TwosSteps twosSteps(int n, int bits) {
  final mag = n.abs().toRadixString(2).padLeft(bits, '0');
  final inv = mag.split('').map((c) => c == '0' ? '1' : '0').join();
  return TwosSteps(mag, inv, toTwos(n, bits));
}

/// Range of two's complement on [bits] bits.
(int, int) twosRange(int bits) => (-(1 << (bits - 1)), (1 << (bits - 1)) - 1);
