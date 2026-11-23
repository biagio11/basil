part of 'lessons.dart';

Lesson _signalsLesson(VoidCallback onOpenPractice) {
  Widget summary() => Builder(builder: (context) {
        final cs = context.cs;
        Widget c(String s, {bool head = false}) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              child: Text(s,
                  style: head ? pixelStyle(size: 9, color: cs.primary) : const TextStyle(fontSize: 14, height: 1.35)),
            );
        final rows = [
          (tr('Analogico', 'Analog'), tr('varia in modo continuo', 'changes continuously')),
          (tr('Digitale', 'Digital'), tr('è fatto di numeri, va a passi', 'is made of numbers, moves in steps')),
          (tr('Campionare', 'Sampling'), tr('misurare a intervalli regolari', 'measuring at regular intervals')),
          (tr('Quantizzare', 'Quantising'), tr('arrotondare al livello più vicino', 'rounding to the nearest level')),
          (tr('Frequenza', 'Sample rate'), tr('quanti campioni al secondo', 'how many samples per second')),
          (tr('Profondità', 'Bit depth'), tr('quanti bit per campione o per pixel', 'how many bits per sample or pixel')),
          ('Pixel', tr('un puntino di colore dell’immagine', 'one coloured dot of an image')),
          ('#RRGGBB', tr('rosso, verde e blu in base 16, da 00 a FF', 'red, green and blue in base 16, 00 to FF')),
        ];
        return Table(
          columnWidths: const {0: IntrinsicColumnWidth(), 1: FlexColumnWidth()},
          border: TableBorder.all(color: cs.outlineVariant),
          children: [
            TableRow(children: [c(tr('PAROLA', 'WORD'), head: true), c(tr('IN DUE PAROLE', 'IN A FEW WORDS'), head: true)]),
            for (final (a, b) in rows) TableRow(children: [c(a), c(b)]),
          ],
        );
      });

  return Lesson(
    id: 'signals',
    title: tr('Dai segnali ai bit', 'From signals to bits'),
    subtitle: tr('Analogico e digitale, campionamento, suoni e immagini',
        'Analog and digital, sampling, sounds and images'),
    icon: Icons.graphic_eq,
    slides: [
      _slide(
        tr('Analogico e digitale', 'Analog and digital'),
        before: [
          tr('Una grandezza **analogica** varia in modo continuo: la lancetta di un orologio passa per tutti i punti. '
                  'Una grandezza **digitale** è fatta di numeri, quindi va **a passi**.',
              'An **analog** quantity changes continuously: a clock hand passes through every point. A **digital** '
                  'quantity is made of numbers, so it moves **in steps**.'),
          tr('Muovi il cursore e guarda la differenza.', 'Move the slider and watch the difference.'),
        ],
        widget: () => const AnalogDigital(),
      ),
      _slide(
        tr('Intorno a noi', 'All around us'),
        before: [
          tr('• orologio a lancette e orologio con le cifre;', '• a clock with hands and a clock with digits;'),
          tr('• termometro a mercurio e termometro digitale;', '• a mercury thermometer and a digital one;'),
          tr('• disco in vinile e file MP3;', '• a vinyl record and an MP3 file;'),
          tr('• pellicola fotografica e foto sul telefono.', '• photographic film and a photo on your phone.'),
          tr('Il mondo è quasi tutto analogico, ma il computer capisce solo numeri, anzi solo **0 e 1**. '
                  'Per questo bisogna **trasformare** i segnali in numeri.',
              'The world is mostly analog, but a computer only understands numbers, in fact only **0 and 1**. '
                  'That is why signals have to be **turned** into numbers.'),
        ],
      ),
      _quiz(
        tr('Quiz: analogico o digitale?', 'Quiz: analog or digital?'),
        tr('Quale di questi è **analogico**?', 'Which of these is **analog**?'),
        [
          tr('Una foto sul telefono', 'A photo on a phone'),
          tr('La lancetta del tachimetro', 'The needle of a speedometer'),
          tr('Un file MP3', 'An MP3 file'),
          tr('Il display di una calcolatrice', 'A calculator display'),
        ],
        1,
        tr('La lancetta si muove in modo continuo e passa per tutti i valori. Gli altri sono fatti di numeri.',
            'The needle moves continuously through every value. The others are made of numbers.'),
      ),
      _slide(
        tr('Dal segnale ai numeri', 'From signal to numbers'),
        before: [
          tr('Ecco come si porta un suono nel computer. Segui i **5 passi** con le frecce.',
              'This is how a sound gets into a computer. Follow the **5 steps** with the arrows.'),
        ],
        widget: () => const SignalLab(showResolution: false),
      ),
      _quiz(
        tr('Quiz: quantizzazione', 'Quiz: quantisation'),
        tr('Un campione vale **4,5**. A quale livello va?', 'A sample is **4.5**. Which level does it go to?'),
        ['4', '5', '4,5', tr('si scarta', 'it is dropped')],
        1,
        tr('A metà o sopra si sale alla riga di sopra, quindi 5. Nel digitale non esistono valori a metà.',
            'Halfway or above goes up to the next line, so 5. Digital has no values in between.'),
      ),
      _slide(
        tr('La risoluzione', 'Resolution'),
        before: [
          tr('Con il quadretto **u/2** prendiamo il **doppio dei campioni** e abbiamo il **doppio dei livelli**: '
                  'lo scalino segue meglio la curva, ma ogni numero richiede **un bit in più**.',
              'With the **u/2** square we take **twice the samples** and get **twice the levels**: the steps follow '
                  'the curve better, but each number needs **one more bit**.'),
          tr('**Frequenza di campionamento**: quanti campioni al secondo. **Profondità di bit**: quanti bit per '
                  'campione. Più sono alte, migliore è la qualità, ma il file pesa di più.',
              '**Sample rate**: how many samples per second. **Bit depth**: how many bits per sample. The higher '
                  'they are, the better the quality, but the bigger the file.'),
        ],
        widget: () => const SignalLab(initialStep: 4),
      ),
      _quiz(
        tr('Quiz: quanti bit?', 'Quiz: how many bits?'),
        tr('I livelli vanno da **0 a 15**. Quanti bit servono per ogni campione?',
            'Levels go from **0 to 15**. How many bits does each sample need?'),
        ['3', '4', '8', '15'],
        1,
        tr('16 livelli = 2^4, quindi 4 bit. Con 3 bit si arriva solo a 7.',
            '16 levels = 2^4, so 4 bits. With 3 bits you only reach 7.'),
      ),
      _slide(
        tr('Il suono', 'Sound'),
        before: [
          tr('Un CD audio prende **44 100 campioni al secondo**, ognuno da **16 bit**, per **2 canali** (destra e '
                  'sinistra).',
              'An audio CD takes **44,100 samples per second**, each of **16 bits**, on **2 channels** (left and '
                  'right).'),
          '`44 100 × 16 × 2 = 1 411 200 bit` ${tr('al secondo', 'per second')}',
          tr('Cioè circa **176 KB al secondo** e **10 MB al minuto**. Per questo esistono formati compressi come '
                  'l’MP3, che tolgono quello che l’orecchio sente meno.',
              'That is about **176 KB per second** and **10 MB per minute**. This is why compressed formats such as '
                  'MP3 exist: they remove what the ear hears less.'),
        ],
      ),
      _quiz(
        tr('Quiz: una telefonata', 'Quiz: a phone call'),
        tr('Una vecchia telefonata usa **8000 campioni al secondo** da **8 bit**. Quanti bit in **un secondo**?',
            'An old phone call uses **8000 samples per second** of **8 bits**. How many bits in **one second**?'),
        ['8 000', '16 000', '64 000', '1 000'],
        2,
        tr('8000 × 8 = 64 000 bit al secondo.', '8000 × 8 = 64,000 bits per second.'),
      ),
      _slide(
        tr('Le immagini', 'Images'),
        before: [
          tr('Un’immagine digitale è una griglia di **pixel**. Ogni pixel ha un colore, scritto con un certo numero '
                  'di bit: la **profondità di colore**.',
              'A digital image is a grid of **pixels**. Each pixel has a colour, written with a certain number of '
                  'bits: the **colour depth**.'),
          tr('Peso = **pixel × bit per pixel**. Prova a togliere pixel o colori alla foglia.',
              'Size = **pixels × bits per pixel**. Try removing pixels or colours from the leaf.'),
        ],
        widget: () => const PixelLab(),
      ),
      _slide(
        tr('I colori in base 16', 'Colours in base 16'),
        before: [
          tr('Nei siti e nei programmi di grafica un colore si scrive con **#** e sei cifre esadecimali: la prima '
                  'coppia è il **rosso**, la seconda il **verde**, la terza il **blu**. Ogni coppia va da `00` a '
                  '`FF`, cioè da 0 a 255.',
              'In websites and graphics programs a colour is written as **#** and six hex digits: the first pair is '
                  '**red**, the second **green**, the third **blue**. Each pair goes from `00` to `FF`, i.e. 0 to 255.'),
        ],
        widget: () => const ColorMixer(),
        after: [
          tr('3 coppie da 8 bit = **24 bit** per pixel, più di 16 milioni di colori.',
              '3 pairs of 8 bits = **24 bits** per pixel, more than 16 million colours.'),
        ],
      ),
      _quiz(
        tr('Quiz: che colore è?', 'Quiz: which colour?'),
        tr('Che colore è **#00FF00**?', 'Which colour is **#00FF00**?'),
        [tr('rosso', 'red'), tr('verde', 'green'), tr('blu', 'blue'), tr('bianco', 'white')],
        1,
        tr('Rosso 00, verde FF (il massimo), blu 00: è il verde pieno.',
            'Red 00, green FF (the maximum), blue 00: it is full green.'),
      ),
      _quiz(
        tr('Quiz: quanto pesa?', 'Quiz: how big?'),
        tr('Un’icona di **10 × 10 pixel** in bianco e nero, con **1 bit** per pixel. Quanti bit pesa?',
            'A **10 × 10 pixel** black and white icon, with **1 bit** per pixel. How many bits is it?'),
        ['10', '20', '100', '800'],
        2,
        tr('10 × 10 = 100 pixel, per 1 bit ciascuno = 100 bit.', '10 × 10 = 100 pixels, 1 bit each = 100 bits.'),
      ),
      Slide(
        tr('Riepilogo', 'Summary'),
        (context, classMode) => _col([
          summary(),
          const SizedBox(height: 16),
          _p(tr('Adesso che sai da dove vengono i bit, la prossima lezione spiega come contarli.',
              'Now that you know where bits come from, the next lesson explains how to count with them.')),
        ]),
      ),
    ],
  );
}
