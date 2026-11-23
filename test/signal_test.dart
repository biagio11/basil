import 'package:basil/ui/signal_widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the class signal gives the same samples as the summary', () {
    final s = sampleSignal();
    expect(s.level, [3, 4, 3, 1, 2, 4, 5, 6, 5, 4, 5, 6]);
    expect(s.bits, 3);
  });

  test('half grid doubles samples and fits in 4 bits', () {
    final s = sampleSignal(fine: true);
    expect(s.level.length, 24);
    expect(s.level.every((l) => l >= 0 && l <= 15), isTrue);
    expect(s.bits, 4);
  });
}
