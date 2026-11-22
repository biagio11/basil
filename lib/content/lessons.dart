import 'package:flutter/material.dart';

import '../app/settings.dart';
import '../logic/base_conv.dart';
import '../ui/common.dart';
import '../ui/interactives.dart';

class Slide {
  Slide(this.title, this.build);
  final String title;
  final Widget Function(BuildContext context, bool classMode) build;
}

class Lesson {
  Lesson({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.slides,
  });
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Slide> slides;
}

// ---------------------------------------------------------------------------
// Small builders
// ---------------------------------------------------------------------------

Widget _col(List<Widget> children) =>
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: children);

Widget _p(String text, {double size = 18}) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: RichLine(text, size: size),
    );

Slide _slide(
  String title, {
  List<String> before = const [],
  Widget Function()? widget,
  List<String> after = const [],
}) {
  return Slide(
    title,
    (context, classMode) => _col([
      for (final t in before) _p(t),
      if (widget != null)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: widget(),
        ),
      if (after.isNotEmpty) const SizedBox(height: 10),
      for (final t in after) _p(t),
    ]),
  );
}

Slide _quiz(String title, String question, List<String> options, int correct,
    String why) {
  return Slide(
    title,
    (context, classMode) => QuizCard(
      question: question,
      options: options,
      correct: correct,
      explanation: why,
      classMode: classMode,
    ),
  );
}

Widget _hexDigitsGrid() {
  return Builder(builder: (context) {
    final cs = context.cs;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (var i = 0; i < 16; i++)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: i < 10 ? context.bc.panelHi : cs.primaryContainer,
              borderRadius: BorderRadius.circular(5),
              border: Border.all(
                  color: i < 10 ? cs.outlineVariant : cs.primary.withAlpha(120)),
            ),
            child: Text('${digitChar(i)} = $i',
                style: monoStyle(size: 17, weight: FontWeight.bold)),
          ),
      ],
    );
  });
}

Widget _practiceButton(VoidCallback onTap) => Align(
      alignment: Alignment.centerLeft,
      child: FilledButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.bolt),
        label: Text(tr('Allenati ora', 'Train now')),
      ),
    );

// ---------------------------------------------------------------------------
// Lessons
// ---------------------------------------------------------------------------

List<Lesson> buildLessons({required VoidCallback onOpenPractice}) {
  return [
    _baseLesson(onOpenPractice),
    _opsLesson(onOpenPractice),
    _fracLesson(onOpenPractice),
  ];
}

Lesson _baseLesson(VoidCallback onOpenPractice) {
  const bin45 = '101101'; // 45 in base 2
  final div37 = divisionSteps(BigInt.from(37), 2);
  final n37 = div37.length;

  final powerTexts = [
    tr('Vogliamo sapere quanto vale `101101` in base 10.',
        'We want to know what `101101` is worth in base 10.'),
    tr('Numeriamo le posizioni **da destra**, partendo da 0.',
        'Number the positions **from the right**, starting at 0.'),
    tr('Ogni posizione ha un peso: **2 elevato alla posizione**.',
        'Each position has a weight: **2 to the power of the position**.'),
    tr('Moltiplichiamo ogni cifra per il suo peso. Con le cifre 0 e 1 il '
            'prodotto è 0 oppure il peso stesso.',
        'Multiply each digit by its weight. With digits 0 and 1 the product '
            'is either 0 or the weight itself.'),
    tr('Sommiamo tutto: **101101₂ = 45**.', 'Add everything up: **101101₂ = 45**.'),
  ];
  final powerTitles = [
    tr('Da base 2 a base 10: il numero', 'Base 2 to base 10: the number'),
    tr('Da base 2 a base 10: le posizioni', 'Base 2 to base 10: positions'),
    tr('Da base 2 a base 10: i pesi', 'Base 2 to base 10: weights'),
    tr('Da base 2 a base 10: cifra × peso', 'Base 2 to base 10: digit × weight'),
    tr('Da base 2 a base 10: la somma', 'Base 2 to base 10: the sum'),
  ];

  return Lesson(
    id: 'bases',
    title: tr('Cambi di base', 'Changing bases'),
    subtitle: tr('Posizioni, base 2, base 10, base 16 e oltre',
        'Positions, base 2, base 10, base 16 and beyond'),
    icon: Icons.swap_horiz,
    slides: [
      _slide(
        tr('Contare con le posizioni', 'Counting with positions'),
        before: [
          tr('Con **n bit** si scrivono **2^n** combinazioni diverse.',
              'With **n bits** you can write **2^n** different combinations.'),
          tr('Ogni posizione vale il doppio di quella alla sua destra: '
                  '1, 2, 4, 8, 16… Prova: tocca i bit per accenderli e spegnerli.',
              'Each position is worth twice the one on its right: '
                  '1, 2, 4, 8, 16… Try it: tap the bits to switch them on and off.'),
        ],
        widget: () => const BitToggler(),
      ),
      _quiz(
        tr('Quiz: le combinazioni', 'Quiz: combinations'),
        tr('Quante combinazioni diverse si possono scrivere con **3 bit**?',
            'How many different combinations can you write with **3 bits**?'),
        ['6', '8', '9', '3'],
        1,
        tr('2 × 2 × 2 = 2^3 = 8: da `000` a `111`.', '2 × 2 × 2 = 2^3 = 8: from `000` to `111`.'),
      ),
      _slide(
        tr('Ogni posizione ha un peso', 'Every position has a weight'),
        before: [
          tr('In base 10 le posizioni valgono 1, 10, 100, 1000…: '
                  '`347 = 3×100 + 4×10 + 7×1`.',
              'In base 10 the positions are worth 1, 10, 100, 1000…: '
                  '`347 = 3×100 + 4×10 + 7×1`.'),
          tr('In base 2 valgono 1, 2, 4, 8, 16…: ogni posizione vale '
                  '**il doppio** della precedente.',
              'In base 2 they are worth 1, 2, 4, 8, 16…: each position is worth '
                  '**double** the previous one.'),
          tr('Cambia solo la base: da 10 a 2.', 'Only the base changes: from 10 to 2.'),
        ],
      ),
      for (var k = 0; k < 5; k++)
        _slide(
          powerTitles[k],
          before: [powerTexts[k]],
          widget: () => PowerTable(digits: bin45, base: 2, stage: k),
        ),
      _quiz(
        tr('Quiz: da base 2 a base 10', 'Quiz: base 2 to base 10'),
        tr('Quanto vale `1001` (base 2) in base 10?', 'What is `1001` (base 2) in base 10?'),
        ['1001', '5', '9', '11'],
        2,
        '8 + 0 + 0 + 1 = 9.',
      ),
      _slide(
        tr('Da base 10 a base 2: l’idea', 'Base 10 to base 2: the idea'),
        before: [
          tr('Per scrivere **37** in base 2 dividiamo per 2, ancora e ancora, '
                  'finché il quoziente non è 0.',
              'To write **37** in base 2 we divide by 2, again and again, '
                  'until the quotient is 0.'),
          tr('Di ogni divisione ci interessa il **resto**: sarà sempre 0 oppure 1.',
              'From each division we keep the **remainder**: it is always 0 or 1.'),
          tr('Una divisione per slide!', 'One division per slide!'),
        ],
      ),
      for (var i = 0; i < n37; i++)
        _slide(
          tr('37 ÷ 2: passo ${i + 1} di $n37', '37 ÷ 2: step ${i + 1} of $n37'),
          before: [
            tr('`${div37[i].dividend} ÷ 2 = ${div37[i].quotient}` '
                    'con resto **${div37[i].remainder}**'
                    '${div37[i].quotient == BigInt.zero ? ', il quoziente è 0 e ci fermiamo.' : ''}',
                '`${div37[i].dividend} ÷ 2 = ${div37[i].quotient}` '
                    'remainder **${div37[i].remainder}**'
                    '${div37[i].quotient == BigInt.zero ? ', the quotient is 0 so we stop.' : ''}'),
          ],
          widget: () => DivisionTable(number: BigInt.from(37), base: 2, upTo: i),
        ),
      _slide(
        tr('Leggi i resti dal basso verso l’alto', 'Read the remainders bottom-up'),
        before: [
          tr('L’ultimo resto è la cifra di **peso maggiore**: si legge per primo.',
              'The last remainder is the **most significant** digit: read it first.'),
        ],
        widget: () =>
            DivisionTable(number: BigInt.from(37), base: 2, showResult: true),
      ),
      _quiz(
        tr('Quiz: l’errore più comune', 'Quiz: the most common mistake'),
        tr('Dalle divisioni di 37 hai ottenuto i resti **1, 0, 1, 0, 0, 1** '
                '(nell’ordine in cui sono usciti). Qual è 37 in binario?',
            'Dividing 37 you got the remainders **1, 0, 1, 0, 0, 1** '
                '(in the order they came out). What is 37 in binary?'),
        ['101001', '111111', '100101', '010010'],
        2,
        tr('I resti si leggono dal basso verso l’alto. L’errore tipico è '
                'leggerli nell’ordine in cui escono: `101001` vale 41, non 37.',
            'Remainders are read from bottom to top. The typical mistake is '
                'reading them in the order they come out: `101001` is 41, not 37.'),
      ),
      _slide(
        tr('Una regola per tutte le basi', 'One rule for every base'),
        before: [
          tr('I due metodi non dipendono dal 2. In **base b**:',
              'The two methods do not depend on 2. In **base b**:'),
          tr('• ogni posizione vale `b^posizione`;', '• each position is worth `b^position`;'),
          tr('• per passare da base 10 a base b si **divide per b** e si '
                  'leggono i resti dal basso.',
              '• to go from base 10 to base b you **divide by b** and read '
                  'the remainders from the bottom.'),
          tr('Cambia solo l’alfabeto: la base b usa le cifre da 0 a b−1.',
              'Only the alphabet changes: base b uses the digits 0 to b−1.'),
        ],
      ),
      _slide(
        tr('Esempio: 45 in base 5', 'Example: 45 in base 5'),
        before: [tr('Dividiamo per **5** invece che per 2:', 'We divide by **5** instead of 2:')],
        widget: () =>
            DivisionTable(number: BigInt.from(45), base: 5, showResult: true),
        after: [tr('Verifica: `1×25 + 4×5 + 0×1 = 45`', 'Check: `1×25 + 4×5 + 0×1 = 45`')],
      ),
      _slide(
        tr('E se avessimo 16 dita?', 'What if we had 16 fingers?'),
        before: [
          tr('In **base 16** servono 16 cifre: dopo il 9 si usano le lettere.',
              'In **base 16** we need 16 digits: after 9 we use letters.'),
        ],
        widget: _hexDigitsGrid,
        after: [tr('Si chiama **esadecimale**.', 'It is called **hexadecimal**.')],
      ),
      _slide(
        tr('2F in base 10', '2F in base 10'),
        before: [tr('Stesso metodo: cifra × peso. **F** vale 15.',
            'Same method: digit × weight. **F** is 15.')],
        widget: () => const PowerTable(digits: '2F', base: 16, stage: 4),
        after: ['`2F = 2×16 + 15×1 = 47`'],
      ),
      _slide(
        tr('200 in base 16', '200 in base 16'),
        before: [tr('Stesso metodo: dividiamo per 16.', 'Same method: divide by 16.')],
        widget: () =>
            DivisionTable(number: BigInt.from(200), base: 16, showResult: true),
        after: [
          tr('Il resto 12 si scrive **C**. Leggendo dal basso: **C8**.',
              'The remainder 12 is written **C**. Reading bottom-up: **C8**.'),
        ],
      ),
      _quiz(
        tr('Quiz: esadecimale', 'Quiz: hexadecimal'),
        tr('Come si scrive **255** in base 16?', 'How do you write **255** in base 16?'),
        ['100', 'F0', 'EE', 'FF'],
        3,
        tr('255 ÷ 16 = 15 resto 15 → F e F. Oppure: 15×16 + 15 = 255.',
            '255 ÷ 16 = 15 remainder 15 → F and F. Or: 15×16 + 15 = 255.'),
      ),
      _slide(
        tr('Esadecimale ↔ binario: gruppi di 4', 'Hexadecimal ↔ binary: groups of 4'),
        before: [
          tr('16 = 2^4: ogni cifra esadecimale corrisponde esattamente a '
                  '**4 bit**. Non servono divisioni: si raggruppa.',
              '16 = 2^4: each hex digit matches exactly **4 bits**. '
                  'No divisions needed: just group.'),
          tr('Vale lo stesso per l’**ottale**: 8 = 2^3, quindi gruppi di **3 bit**.',
              'Same for **octal**: 8 = 2^3, so groups of **3 bits**.'),
        ],
        widget: () => const HexBinGroups(),
      ),
      _quiz(
        tr('Quiz: gruppi di 4 bit', 'Quiz: groups of 4 bits'),
        tr('Come si scrive `10111110` (base 2) in base 16?',
            'How do you write `10111110` (base 2) in base 16?'),
        ['EB', 'AE', 'BE', 'B6'],
        2,
        tr('`1011 = B` e `1110 = E`: quindi **BE**.', '`1011 = B` and `1110 = E`: so **BE**.'),
      ),
      _slide(
        tr('I colori RGB', 'RGB colours'),
        before: [
          tr('Ogni colore sullo schermo è una terna **R, G, B**: tre byte, cioè '
                  'tre numeri da 0 a 255, scritti di solito con **2 cifre '
                  'esadecimali** ciascuno.',
              'Every colour on screen is a triple **R, G, B**: three bytes, i.e. '
                  'three numbers from 0 to 255, usually written with **2 hex '
                  'digits** each.'),
          tr('`#FF8000` = rosso FF (255), verde 80 (128), blu 00 (0): arancione. '
                  'Muovi gli slider!',
              '`#FF8000` = red FF (255), green 80 (128), blue 00 (0): orange. '
                  'Move the sliders!'),
        ],
        widget: () => const RgbMixer(),
      ),
      _quiz(
        tr('Quiz: colori', 'Quiz: colours'),
        tr('Che colore è `#0000FF`?', 'What colour is `#0000FF`?'),
        [tr('Verde', 'Green'), tr('Blu', 'Blue'), tr('Rosso', 'Red'), tr('Bianco', 'White')],
        1,
        tr('Rosso 00, verde 00, blu FF (= 255, il massimo): è acceso solo il blu.',
            'Red 00, green 00, blue FF (= 255, the maximum): only blue is on.'),
      ),
      _slide(
        tr('Base X → base Y: si passa da 10', 'Base X → base Y: go through 10'),
        before: [
          tr('Se né la base di partenza né quella di arrivo è 10 (e non vale '
                  'la scorciatoia dei gruppi di bit), usa la **base 10 come tappa**:',
              'If neither base is 10 (and the bit-group shortcut does not apply), '
                  'use **base 10 as a stopover**:'),
          tr('1. base X → base 10 (cifra × peso)', '1. base X → base 10 (digit × weight)'),
          tr('2. base 10 → base Y (divisioni)', '2. base 10 → base Y (divisions)'),
          tr('Esempio: **231 in base 4** → base 5.', 'Example: **231 in base 4** → base 5.'),
        ],
      ),
      _slide(
        tr('Passo 1: 231 (base 4) → base 10', 'Step 1: 231 (base 4) → base 10'),
        widget: () => const PowerTable(digits: '231', base: 4, stage: 4),
        after: ['`2×16 + 3×4 + 1×1 = 45`'],
      ),
      _slide(
        tr('Passo 2: 45 → base 5', 'Step 2: 45 → base 5'),
        widget: () =>
            DivisionTable(number: BigInt.from(45), base: 5, showResult: true),
        after: [
          '**231₄ = 45 = 140₅**',
          '${tr('Lo stesso numero in basi diverse: ', 'The same number in different bases: ')}'
              '`45 = 101101₂ = 231₄ = 140₅ = 2D₁₆`.',
        ],
      ),
      _quiz(
        tr('Quiz bonus: base X → base Y', 'Bonus quiz: base X → base Y'),
        tr('Primo passo di una conversione: quanto vale `123` (base 4) in base 10?',
            'First step of a conversion: what is `123` (base 4) in base 10?'),
        ['123', '27', '24', '11'],
        1,
        '1×16 + 2×4 + 3×1 = 16 + 8 + 3 = 27.',
      ),
      Slide(
        tr('Riepilogo', 'Summary'),
        (context, classMode) => _col([
          _p(tr('**Base b → 10**: cifra × b^posizione, poi somma.',
              '**Base b → 10**: digit × b^position, then add.')),
          _p(tr('**10 → base b**: dividi per b, leggi i resti dal basso.',
              '**10 → base b**: divide by b, read the remainders bottom-up.')),
          _p(tr('**2 ↔ 8 / 16**: gruppi di 3 / 4 bit.', '**2 ↔ 8 / 16**: groups of 3 / 4 bits.')),
          _p(tr('**X → Y**: passa dalla base 10.', '**X → Y**: go through base 10.')),
          const SizedBox(height: 8),
          _practiceButton(onOpenPractice),
        ]),
      ),
    ],
  );
}

Lesson _opsLesson(VoidCallback onOpenPractice) {
  return Lesson(
    id: 'ops',
    title: tr('Operazioni binarie', 'Binary operations'),
    subtitle: tr('Somma, differenza, prodotto, divisione e overflow',
        'Addition, subtraction, multiplication, division and overflow'),
    icon: Icons.calculate_outlined,
    slides: [
      _slide(
        tr('Perché il computer lavora in binario', 'Why computers work in binary'),
        before: [
          tr('Dentro un computer ci sono miliardi di **interruttori '
                  'microscopici** (transistor): ognuno è acceso o spento.',
              'Inside a computer there are billions of **microscopic switches** '
                  '(transistors): each one is either on or off.'),
          tr('Due soli stati (1 e 0) sono facili da distinguere anche quando il '
                  'segnale è un po’ disturbato: il sistema è **affidabile ed '
                  'economico**.',
              'Just two states (1 and 0) are easy to tell apart even when the '
                  'signal is a bit noisy: the system is **reliable and cheap**.'),
          tr('Numeri, testi, immagini e suoni diventano **sequenze di 0 e 1**: '
                  'per questo le operazioni si fanno in binario.',
              'Numbers, text, images and sounds become **sequences of 0s and 1s**: '
                  'that is why arithmetic is done in binary.'),
        ],
      ),
      _slide(
        tr('Addizione: le regole', 'Addition: the rules'),
        before: [
          '`0 + 0 = 0`',
          tr('`0 + 1 = 1`   e   `1 + 0 = 1`', '`0 + 1 = 1`   and   `1 + 0 = 1`'),
          tr('`1 + 1 = 10`  → scrivo **0** e **riporto** 1',
              '`1 + 1 = 10`  → write **0** and **carry** 1'),
          tr('`1 + 1 + 1 = 11`  (con un riporto in arrivo) → scrivo 1, riporto 1',
              '`1 + 1 + 1 = 11`  (with an incoming carry) → write 1, carry 1'),
        ],
      ),
      _slide(
        tr('Addizione passo dopo passo', 'Addition step by step'),
        before: [
          tr('Si parte dalla colonna **più a destra**. Cambia pure i numeri!',
              'Start from the **rightmost** column. Feel free to change the numbers!'),
        ],
        widget: () =>
            const ColumnWalk(op: WalkOp.add, initialA: '1011', initialB: '110'),
      ),
      _slide(
        tr('Controlla in base 10', 'Check in base 10'),
        before: [
          '`1011 = 11`,  `110 = 6`,  `11 + 6 = 17`.',
          tr('E 17 in binario? `17 = 16 + 1 = 10001`',
              'And 17 in binary? `17 = 16 + 1 = 10001`'),
          tr('**Controlla sempre il risultato in base 10.**',
              '**Always check the result in base 10.**'),
        ],
      ),
      _quiz(
        tr('Quiz: addizione', 'Quiz: addition'),
        tr('Quanto fa `1101 + 11`?', 'What is `1101 + 11`?'),
        ['1000', '10000', '10001', '1111'],
        1,
        tr('13 + 3 = 16 = `10000`: il riporto attraversa tutte le colonne.',
            '13 + 3 = 16 = `10000`: the carry ripples through every column.'),
      ),
      _slide(
        tr('Sottrazione: il prestito', 'Subtraction: borrowing'),
        before: [
          '`0 − 0 = 0`,  `1 − 0 = 1`,  `1 − 1 = 0`',
          tr('`0 − 1` non si può: si prende **1 in prestito** dalla colonna a '
                  'sinistra, che in questa colonna **vale 2**: `2 − 1 = 1`.',
              '`0 − 1` is not possible: **borrow 1** from the left column, which '
                  'in this column **is worth 2**: `2 − 1 = 1`.'),
        ],
      ),
      _slide(
        tr('Sottrazione passo dopo passo', 'Subtraction step by step'),
        widget: () =>
            const ColumnWalk(op: WalkOp.sub, initialA: '1101', initialB: '110'),
      ),
      _slide(
        tr('Controlla in base 10', 'Check in base 10'),
        before: [
          '`1101 = 13`,  `110 = 6`,  `13 − 6 = 7`.',
          tr('E 7 in binario? `7 = 4 + 2 + 1 = 111`', 'And 7 in binary? `7 = 4 + 2 + 1 = 111`'),
        ],
      ),
      _quiz(
        tr('Quiz: sottrazione', 'Quiz: subtraction'),
        tr('Quanto fa `1000 − 1`?', 'What is `1000 − 1`?'),
        ['1001', '111', '1111', '100'],
        1,
        tr('Il prestito attraversa tutti gli zeri: `1000 − 1 = 0111`, cioè '
                '`111` (8 − 1 = 7).',
            'The borrow ripples through all the zeros: `1000 − 1 = 0111`, i.e. '
                '`111` (8 − 1 = 7).'),
      ),
      _slide(
        tr('Moltiplicazione', 'Multiplication'),
        before: [
          tr('Per ogni cifra del secondo numero scrivi il primo numero (se la '
                  'cifra è 1) oppure zeri (se è 0), **spostando ogni riga di una '
                  'posizione a sinistra**. Poi **somma** le righe.',
              'For each digit of the second number write the first number (if '
                  'the digit is 1) or zeros (if it is 0), **shifting each row one '
                  'place to the left**. Then **add** the rows.'),
        ],
        widget: () => const MulView(a: '101', b: '11'),
        after: [tr('Verifica: `5 × 3 = 15 = 1111`', 'Check: `5 × 3 = 15 = 1111`')],
      ),
      _slide(
        tr('× 10 in binario = × 2', '× 10 in binary = × 2'),
        before: [
          tr('In base 10, ×10 aggiunge uno 0 a destra. In base 2 il numero '
                  '`10` vale 2: **×10 aggiunge uno 0 e raddoppia**.',
              'In base 10, ×10 appends a 0 on the right. In base 2 the number '
                  '`10` is 2: **×10 appends a 0 and doubles**.'),
        ],
        widget: () => const ShiftDemo(showDiv: false),
      ),
      _slide(
        tr('Divisione per 2', 'Dividing by 2'),
        before: [
          tr('Dividere per `10` (cioè per 2) significa **cancellare l’ultima '
                  'cifra**. La cifra cancellata è il resto.',
              'Dividing by `10` (i.e. by 2) means **dropping the last digit**. '
                  'The dropped digit is the remainder.'),
        ],
        widget: () => const ShiftDemo(showMul: false),
        after: [
          tr('`1101 ÷ 10 = 110` resto `1`  (13 ÷ 2 = 6 resto 1)',
              '`1101 ÷ 10 = 110` remainder `1`  (13 ÷ 2 = 6 remainder 1)')
        ],
      ),
      _slide(
        tr('Divisione in colonna', 'Long division'),
        before: [
          tr('Come la divisione in colonna che conosci: abbassi un bit alla '
                  'volta e controlli se il divisore ci sta (scrivi 1) oppure no '
                  '(scrivi 0).',
              'Just like the long division you know: bring down one bit at a '
                  'time and check whether the divisor fits (write 1) or not '
                  '(write 0).'),
        ],
        widget: () => const DivBinView(dividend: '1101', divisor: '11'),
      ),
      _quiz(
        tr('Quiz: divisione', 'Quiz: division'),
        tr('Quanto fa `1100 ÷ 10`?', 'What is `1100 ÷ 10`?'),
        ['110', '11', '1000', '101'],
        0,
        tr('Si cancella l’ultima cifra: `1100 ÷ 10 = 110` (12 ÷ 2 = 6).',
            'Drop the last digit: `1100 ÷ 10 = 110` (12 ÷ 2 = 6).'),
      ),
      _slide(
        'Overflow',
        before: [
          tr('Un numero occupa un **numero fisso di bit**. Con 8 bit il massimo '
                  'è `11111111` = 255: aggiungi 1 e il riporto esce dai bit '
                  'disponibili, resta `00000000`. Questo è l’**overflow**.',
              'A number takes a **fixed number of bits**. With 8 bits the maximum '
                  'is `11111111` = 255: add 1 and the carry falls off the end, '
                  'leaving `00000000`. That is **overflow**.'),
          tr('Esempio famoso: nel 2014 un contatore di visualizzazioni di un '
                  'video online superò 2 147 483 647, cioè 2^31 − 1, il massimo '
                  'di un intero a 32 bit con segno: la piattaforma passò a un '
                  'contatore a 64 bit.',
              'A famous example: in 2014 the view counter of an online video went '
                  'past 2,147,483,647, i.e. 2^31 − 1, the maximum of a signed 32-bit '
                  'integer: the platform switched to a 64-bit counter.'),
          tr('Prova tu: premi **+ 1** finché scatta l’overflow.',
              'Try it: press **+ 1** until overflow kicks in.'),
        ],
        widget: () => const OverflowCounter(),
      ),
      _quiz(
        tr('Quiz: overflow', 'Quiz: overflow'),
        tr('In un registro a **4 bit** c’è `1111`. Aggiungi 1: cosa ottieni?',
            'A **4-bit** register holds `1111`. Add 1: what do you get?'),
        ['0001', '10000', '1110', '0000'],
        3,
        tr('15 + 1 = 16 richiede 5 bit. Con 4 bit il bit in più va perso e '
                'resta `0000`.',
            '15 + 1 = 16 needs 5 bits. With 4 bits the extra bit is lost and '
                '`0000` is left.'),
      ),
      _slide(
        tr('In ogni base funziona allo stesso modo', 'It works the same in every base'),
        before: [
          tr('In **base b** il riporto scatta quando la somma arriva a **b**, '
                  'e un prestito vale **b**. Esempio in base 8: `7 + 5 = 12` '
                  '(cioè 1×8 + 4) → scrivo 4, riporto 1.',
              'In **base b** a carry happens when the sum reaches **b**, and a '
                  'borrow is worth **b**. Example in base 8: `7 + 5 = 12` '
                  '(i.e. 1×8 + 4) → write 4, carry 1.'),
          tr('Prova la scheda **Calcola**: fa somme, differenze, prodotti e '
                  'divisioni in qualsiasi base, con tutti i passaggi.',
              'Try the **Calc** tab: it does additions, subtractions, products and '
                  'divisions in any base, with every step.'),
        ],
      ),
      _slide(
        tr('Le quattro operazioni (da copiare)', 'The four operations (cheat sheet)'),
        widget: () => Builder(builder: (context) {
          Widget card(String t) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: InfoCard(child: RichLine(t, size: 16)),
              );
          return _col([
            card(tr('**Somma**: da destra; `1+1 = 10` → scrivo 0, riporto 1.',
                '**Addition**: from the right; `1+1 = 10` → write 0, carry 1.')),
            card(tr('**Sottrazione**: `0−1` → prestito di 1 dalla colonna a '
                    'sinistra (vale 2).',
                '**Subtraction**: `0−1` → borrow 1 from the left column (worth 2).')),
            card(tr('**Prodotto**: una riga per ogni cifra del 2° numero '
                    '(1 → copia, 0 → zeri), spostata a sinistra; poi somma. '
                    '×10 = aggiungi uno 0.',
                '**Product**: one row per digit of the 2nd number '
                    '(1 → copy, 0 → zeros), shifted left; then add. '
                    '×10 = append a 0.')),
            card(tr('**Divisione**: ÷10 = cancella l’ultima cifra (è il resto); '
                    'altrimenti in colonna.',
                '**Division**: ÷10 = drop the last digit (it is the remainder); '
                    'otherwise long division.')),
            card(tr('**Sempre**: verifica in base 10. Con N bit il massimo è '
                    '2^N − 1: oltre c’è overflow.',
                '**Always**: check in base 10. With N bits the maximum is '
                    '2^N − 1: beyond that, overflow.')),
          ]);
        }),
      ),
      Slide(
        tr('Esercizi misti', 'Mixed exercises'),
        (context, classMode) => _col([
          _p(tr('Mettiti alla prova: nella scheda **Allenati** trovi '
                  'esercizi sempre diversi con il procedimento svolto e le '
                  'sfide a tempo.',
              'Put yourself to the test: the **Train** tab has endless exercises '
                  'with worked solutions, plus timed challenges.')),
          const SizedBox(height: 8),
          _practiceButton(onOpenPractice),
        ]),
      ),
    ],
  );
}

Lesson _fracLesson(VoidCallback onOpenPractice) {
  return Lesson(
    id: 'frac',
    title: tr('Numeri con la virgola', 'Fractional numbers'),
    subtitle: tr('Pesi negativi, moltiplicazioni e cifre periodiche',
        'Negative weights, multiplications and repeating digits'),
    icon: Icons.more_horiz,
    slides: [
      _slide(
        tr('Dopo la virgola', 'After the point'),
        before: [
          tr('A destra della virgola le posizioni continuano con esponenti '
                  '**negativi**: in base 10 valgono 1/10, 1/100…',
              'To the right of the point positions continue with **negative** '
                  'exponents: in base 10 they are worth 1/10, 1/100…'),
          tr('In base 2 valgono **1/2, 1/4, 1/8, 1/16**…, cioè 0.5, 0.25, 0.125…',
              'In base 2 they are worth **1/2, 1/4, 1/8, 1/16**…, i.e. 0.5, 0.25, 0.125…'),
          tr('Esempio: `101.11₂ = 4 + 1 + 0.5 + 0.25 = 5.75`',
              'Example: `101.11₂ = 4 + 1 + 0.5 + 0.25 = 5.75`'),
        ],
      ),
      _slide(
        tr('Da base 10 a base 2: moltiplica', 'Base 10 to base 2: multiply'),
        before: [
          tr('Per la parte dopo la virgola si **moltiplica per 2** e si prende '
                  'la parte intera (0 o 1). Le cifre si leggono **dall’alto in basso**.',
              'For the part after the point **multiply by 2** and take the integer '
                  'part (0 or 1). Digits are read **from top to bottom**.'),
          '`0.375 × 2 = 0.75 → 0`',
          '`0.75 × 2 = 1.5 → 1`',
          '`0.5 × 2 = 1.0 → 1`',
          tr('Quindi `0.375 = 0.011₂`.', 'So `0.375 = 0.011₂`.'),
        ],
      ),
      _slide(
        tr('Cifre che non finiscono mai', 'Digits that never end'),
        before: [
          tr('`0.1` in base 10 diventa `0.0001100110011…₂`: il blocco `0011` si '
                  'ripete all’infinito, come 1/3 = 0.333… in base 10.',
              '`0.1` in base 10 becomes `0.0001100110011…₂`: the block `0011` '
                  'repeats forever, just like 1/3 = 0.333… in base 10.'),
          tr('Basil lo scrive così: `0.0(0011)`, le cifre tra parentesi si ripetono.',
              'Basil writes it like this: `0.0(0011)`, digits in brackets repeat.'),
          tr('È anche il motivo per cui nei computer `0.1 + 0.2` non fa esattamente `0.3`!',
              'It is also why in computers `0.1 + 0.2` is not exactly `0.3`!'),
        ],
      ),
      _quiz(
        tr('Quiz: virgola binaria', 'Quiz: binary point'),
        tr('Quanto vale `0.1₂` in base 10?', 'What is `0.1₂` in base 10?'),
        ['0.1', '0.5', '0.25', '1'],
        1,
        tr('La prima posizione dopo la virgola vale 2^−1 = 1/2 = 0.5.',
            'The first position after the point is worth 2^−1 = 1/2 = 0.5.'),
      ),
      _slide(
        tr('Numeri negativi', 'Negative numbers'),
        before: [
          tr('Il convertitore tratta il segno a parte: `-45 = -101101₂`.',
              'The converter handles the sign separately: `-45 = -101101₂`.'),
          tr('Nei computer però si usa spesso il **complemento a 2**: con 8 bit '
                  '`-1 = 11111111`. È un altro argomento, ma ora hai le basi!',
              'Computers often use **two’s complement** instead: with 8 bits '
                  '`-1 = 11111111`. That is another topic, but now you have the basics!'),
        ],
      ),
      Slide(
        tr('Prova nel convertitore', 'Try it in the converter'),
        (context, classMode) => _col([
          _p(tr('Scrivi `0.1` nel **Convertitore** da base 10 a base 2 e attiva '
                  '**Spiega**: vedrai ogni moltiplicazione.',
              'Type `0.1` in the **Converter** from base 10 to base 2 and turn on '
                  '**Explain**: you will see every multiplication.')),
          const SizedBox(height: 8),
          _practiceButton(onOpenPractice),
        ]),
      ),
    ],
  );
}
