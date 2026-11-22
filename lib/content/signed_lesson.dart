part of 'lessons.dart';

Lesson _signedLesson(VoidCallback onOpenPractice) {
  Widget table() => Builder(builder: (context) {
        final cs = context.cs;
        final h = pixelStyle(size: 9, color: cs.primary);
        Widget c(String s, {TextStyle? st}) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Text(s, style: st ?? monoStyle(size: 14)),
            );
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Table(
            defaultColumnWidth: const IntrinsicColumnWidth(),
            border: TableBorder.all(color: cs.outlineVariant),
            children: [
              TableRow(children: [
                c('', st: h),
                c(tr('MODULO E SEGNO', 'SIGN MAGNITUDE'), st: h),
                c(tr('COMPL. A 1', 'ONES COMPL.'), st: h),
                c(tr('COMPL. A 2', 'TWOS COMPL.'), st: h),
              ]),
              TableRow(children: [
                c(tr('negativo', 'negative')),
                c(tr('bit di segno a 1', 'sign bit to 1')),
                c(tr('inverti i bit', 'invert bits')),
                c(tr('inverti e +1', 'invert and +1')),
              ]),
              TableRow(children: [c('-5'), c('10000101'), c('11111010'), c('11111011')]),
              TableRow(children: [c(tr('zeri', 'zeros')), c('2'), c('2'), c('1')]),
              TableRow(children: [c('8 bit'), c('-127..127'), c('-127..127'), c('-128..127')]),
              TableRow(children: [
                c(tr('somme', 'sums')),
                c(tr('no', 'no')),
                c(tr('quasi', 'almost')),
                c(tr('sì', 'yes')),
              ]),
            ],
          ),
        );
      });

  return Lesson(
    id: 'signed',
    title: tr('Numeri con segno', 'Signed numbers'),
    subtitle: tr('Modulo e segno, complemento a 1 e complemento a 2',
        'Sign and magnitude, one’s and two’s complement'),
    icon: Icons.exposure,
    slides: [
      _slide(
        tr('Il problema del segno', 'The sign problem'),
        before: [
          tr('Un computer ha solo 0 e 1: non esiste un tasto **meno**. Per scrivere i numeri negativi serve una '
                  '**convenzione**.',
              'A computer only has 0 and 1: there is no **minus** key. To write negative numbers we need a '
                  '**convention**.'),
          tr('Si lavora sempre con un **numero fisso di bit**, per esempio 8. Vediamo tre modi di usarli.',
              'We always work with a **fixed number of bits**, for example 8. Let us see three ways to use them.'),
        ],
      ),
      _slide(
        tr('Modulo e segno', 'Sign and magnitude'),
        before: [
          tr('Il primo bit a sinistra è il **segno**: 0 vuol dire positivo, 1 negativo. Gli altri bit sono il '
                  'valore (modulo).',
              'The leftmost bit is the **sign**: 0 means positive, 1 negative. The other bits are the value '
                  '(magnitude).'),
          '`+5 = 00000101`     `-5 = 10000101`',
          tr('Semplice, ma ha due difetti: esistono **due zeri** (`00000000` e `10000000`) e le somme non '
                  'funzionano direttamente, perché `5 + (-5)` darebbe `10001010`, cioè -10.',
              'Simple, but with two flaws: there are **two zeros** (`00000000` and `10000000`) and sums do not '
                  'work directly, because `5 + (-5)` would give `10001010`, i.e. -10.'),
          tr('Con 8 bit va da **-127 a +127**.', 'With 8 bits it goes from **-127 to +127**.'),
        ],
      ),
      _quiz(
        tr('Quiz: modulo e segno', 'Quiz: sign and magnitude'),
        tr('Come si scrive **-3** in modulo e segno su **4 bit**?',
            'How do you write **-3** in sign and magnitude on **4 bits**?'),
        ['0011', '1011', '1101', '1100'],
        1,
        tr('Segno 1, poi 3 su 3 bit = `011`, quindi `1011`.', 'Sign 1, then 3 on 3 bits = `011`, so `1011`.'),
      ),
      _slide(
        tr('Complemento a 1', 'One’s complement'),
        before: [
          tr('Per fare un negativo si **invertono tutti i bit** del positivo: gli 0 diventano 1 e viceversa.',
              'To make a negative you **invert all the bits** of the positive: 0s become 1s and vice versa.'),
          '`+5 = 00000101`     `-5 = 11111010`',
          tr('Il primo bit indica ancora il segno, ma restano **due zeri** (`00000000` e `11111111`). Con 8 bit '
                  'va da -127 a +127.',
              'The first bit still shows the sign, but there are still **two zeros** (`00000000` and '
                  '`11111111`). With 8 bits it goes from -127 to +127.'),
        ],
      ),
      _slide(
        tr('Complemento a 2', 'Two’s complement'),
        before: [
          tr('È il metodo usato da tutti i computer. Per fare un negativo **inverti i bit e aggiungi 1**.',
              'It is the method every computer uses. To make a negative **invert the bits and add 1**.'),
          '`+5 = 00000101` → `11111010` → `-5 = 11111011`',
          tr('C’è **un solo zero** e con 8 bit va da **-128 a +127**. Prova a cambiare il numero.',
              'There is **only one zero** and with 8 bits it goes from **-128 to +127**. Try changing the number.'),
        ],
        widget: () => const TwosSteps(),
      ),
      _slide(
        tr('Il trucco veloce', 'The quick trick'),
        before: [
          tr('Partendo da destra **copia i bit fino al primo 1 compreso**, poi **inverti tutti gli altri**.',
              'Starting from the right **copy the bits up to and including the first 1**, then **invert all the '
                  'others**.'),
          tr('Esempio con 12 = `00001100`. Copio `100`, inverto `00001` in `11110`, quindi **-12 = `11110100`**.',
              'Example with 12 = `00001100`. Copy `100`, invert `00001` into `11110`, so **-12 = `11110100`**.'),
        ],
      ),
      _slide(
        tr('Leggere un numero in complemento a 2', 'Reading a two’s complement number'),
        before: [
          tr('Il primo bit ha **peso negativo**: su 8 bit vale **-128**, gli altri valgono come sempre.',
              'The first bit has a **negative weight**: on 8 bits it is worth **-128**, the others are worth '
                  'the usual.'),
          '`11111011 = -128 + 64 + 32 + 16 + 8 + 2 + 1 = -5`',
          tr('In alternativa, se il primo bit è 1, rifai il complemento a 2 e metti il meno davanti.',
              'Alternatively, if the first bit is 1, take the two’s complement again and put a minus in front.'),
          tr('Tocca i bit e confronta le rappresentazioni.', 'Tap the bits and compare the representations.'),
        ],
        widget: () => const SignedBits(),
      ),
      _quiz(
        tr('Quiz: complemento a 2', 'Quiz: two’s complement'),
        tr('Quanto vale `11111111` in complemento a 2 su 8 bit?',
            'What is `11111111` in two’s complement on 8 bits?'),
        ['255', '-127', '-1', '-0'],
        2,
        tr('-128 + 127 = -1. In complemento a 2 non esiste -0.', '-128 + 127 = -1. Two’s complement has no -0.'),
      ),
      _quiz(
        tr('Quiz: da decimale a complemento a 2', 'Quiz: decimal to two’s complement'),
        tr('Come si scrive **-8** in complemento a 2 su **8 bit**?',
            'How do you write **-8** in two’s complement on **8 bits**?'),
        ['10001000', '11110111', '11111000', '00001000'],
        2,
        tr('8 = `00001000`, invertito `11110111`, più 1 fa `11111000`.',
            '8 = `00001000`, inverted `11110111`, plus 1 gives `11111000`.'),
      ),
      _slide(
        tr('Perché proprio il complemento a 2', 'Why two’s complement'),
        before: [
          tr('Perché la **sottrazione diventa un’addizione**: `7 - 5 = 7 + (-5)`.',
              'Because **subtraction becomes addition**: `7 - 5 = 7 + (-5)`.'),
          '`00000111 + 11111011 = 1 00000010`',
          tr('Il riporto che esce dall’ottavo bit **si scarta** e resta `00000010` = 2. Al processore basta un '
                  'solo circuito, il sommatore.',
              'The carry out of the eighth bit **is discarded** and `00000010` = 2 is left. The processor only '
                  'needs one circuit, the adder.'),
        ],
      ),
      _slide(
        tr('Overflow con segno', 'Signed overflow'),
        before: [
          tr('Se il risultato esce dall’intervallo il segno si rompe: `100 + 50 = 150`, ma su 8 bit si ottiene '
                  '`10010110` = **-106**.',
              'If the result leaves the range the sign breaks: `100 + 50 = 150`, but on 8 bits you get '
                  '`10010110` = **-106**.'),
          tr('Regola: c’è overflow quando **due positivi danno un negativo** o **due negativi danno un positivo**. '
                  'Sommando un positivo e un negativo non succede mai.',
              'Rule: there is overflow when **two positives give a negative** or **two negatives give a '
                  'positive**. Adding a positive and a negative never overflows.'),
        ],
      ),
      _quiz(
        tr('Quiz: intervallo', 'Quiz: range'),
        tr('Qual è l’intervallo del complemento a 2 su **4 bit**?',
            'What is the two’s complement range on **4 bits**?'),
        ['-7 .. 7', '-8 .. 7', '0 .. 15', '-8 .. 8'],
        1,
        tr('Da -2^3 a 2^3 - 1, cioè da -8 a 7.', 'From -2^3 to 2^3 - 1, i.e. from -8 to 7.'),
      ),
      _slide(
        tr('Eccesso K (cenni)', 'Excess K (a glimpse)'),
        before: [
          tr('Un quarto metodo: si aggiunge una costante K e si scrive il risultato senza segno. Con 8 bit e '
                  'K = 128, `-5 + 128 = 123 = 01111011`.',
              'A fourth method: add a constant K and write the result unsigned. With 8 bits and K = 128, '
                  '`-5 + 128 = 123 = 01111011`.'),
          tr('Si usa per gli esponenti dei numeri in virgola mobile.',
              'It is used for the exponents of floating point numbers.'),
        ],
      ),
      Slide(
        tr('Riepilogo', 'Summary'),
        (context, classMode) => _col([
          table(),
          const SizedBox(height: 16),
          _practiceButton(onOpenPractice),
        ]),
      ),
    ],
  );
}
