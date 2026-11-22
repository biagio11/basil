/// Privacy Policy and Terms of Use (Italian + English), pure Dart so the
/// same text feeds the app and the static web pages (tool/gen_legal.dart).
library;

import '../app/config.dart';
import '../app/i18n.dart';

class LegalSection {
  const LegalSection(this.heading, this.paragraphs);
  final String heading;
  final List<String> paragraphs;
}

class LegalDoc {
  const LegalDoc(this.title, this.intro, this.sections);
  final String title;
  final String intro;
  final List<LegalSection> sections;
}

String get _author => tr('l’autore di Basil', 'the author of Basil');

String get _contact => tr(
    'aprendo una segnalazione (issue) su GitHub, $kIssuesUrl. Le segnalazioni sono pubbliche: '
        'non scriverci dati personali.',
    'by opening an issue on GitHub, $kIssuesUrl. Issues are public, so please do not include '
        'personal data.');

LegalDoc privacyDoc() => LegalDoc(
      tr('Informativa sulla privacy', 'Privacy Policy'),
      tr('Ultimo aggiornamento: $kLegalUpdated. In breve: Basil non raccoglie dati personali. '
          'Non ci sono account, pubblicità, statistiche, cookie di profilazione o tracciamento. '
          'Tutto quello che scrivi resta sul tuo dispositivo.',
          'Last updated: $kLegalUpdated. In short: Basil does not collect personal data. '
          'There are no accounts, ads, analytics, profiling cookies or trackers. '
          'Everything you type stays on your device.'),
      [
        LegalSection(tr('1. Chi siamo', '1. Who we are'), [
          tr('Basil (sito web e app) è uno strumento didattico gratuito realizzato e pubblicato da $_author '
              '(«noi»). Per qualsiasi domanda sulla privacy puoi contattarci $_contact',
              'Basil (website and app) is a free educational tool made and published by $_author '
              '("we", "us"). For any privacy question you can contact us $_contact'),
        ]),
        LegalSection(tr('2. Quali dati raccogliamo', '2. What data we collect'), [
          tr('Nessuno. Basil funziona interamente nel tuo browser o sul tuo telefono: i numeri che scrivi, '
              'le conversioni, i calcoli e gli esercizi sono elaborati localmente e non vengono mai inviati '
              'a noi né a terzi.',
              'None. Basil runs entirely in your browser or on your phone: the numbers you type, conversions, '
              'calculations and exercises are processed locally and are never sent to us or to third parties.'),
          tr('Non usiamo strumenti di analisi (analytics), pubblicità, social plugin, font o librerie caricati '
              'da server esterni. Tutti i caratteri tipografici sono inclusi nell’app.',
              'We use no analytics, advertising, social plugins, or fonts or libraries loaded from external '
              'servers. All typefaces are bundled with the app.'),
        ]),
        LegalSection(tr('3. Dati salvati sul tuo dispositivo', '3. Data stored on your device'), [
          tr('Per ricordare le tue scelte Basil salva sul dispositivo (localStorage del browser o memoria '
              'dell’app): tema, lingua, impostazioni, ultime basi usate e i risultati delle sfide a tempo.',
              'To remember your choices Basil stores on your device (browser localStorage or app storage): '
              'theme, language, settings, last bases used and your timed-challenge results.'),
          tr('Questi dati servono solo a far funzionare le funzioni che usi, non ci vengono mai trasmessi e non '
              'li possiamo vedere. Non sono cookie di profilazione e non richiedono consenso (art. 122 Codice '
              'Privacy, direttiva ePrivacy). Puoi cancellarli in qualsiasi momento da Impostazioni → «Cancella '
              'tutti i dati», cancellando i dati del sito nel browser o disinstallando l’app.',
              'This data is only used to make the features you use work, is never transmitted to us and we '
              'cannot see it. It is not profiling cookies and needs no consent (ePrivacy Directive art. 5(3)). '
              'You can delete it at any time from Settings → "Delete all data", by clearing the site data in '
              'your browser, or by uninstalling the app.'),
        ]),
        LegalSection(tr('4. Hosting del sito', '4. Website hosting'), [
          tr('Il sito è ospitato da Netlify, Inc. Come per qualsiasi sito web, quando apri le pagine i server '
              'del fornitore trattano necessariamente dati tecnici (indirizzo IP, tipo di browser, pagina '
              'richiesta, data e ora) per consegnare i contenuti e proteggere il servizio da abusi. Noi non '
              'usiamo questi dati per identificarti e non li incrociamo con altre informazioni.',
              'The website is hosted by Netlify, Inc. As with any website, when you open the pages the '
              'provider’s servers necessarily process technical data (IP address, browser type, requested page, '
              'date and time) to deliver the content and protect the service from abuse. We do not use this '
              'data to identify you and do not combine it with other information.'),
          tr('Base giuridica: legittimo interesse a fornire un sito funzionante e sicuro (art. 6.1.f GDPR). '
              'Il fornitore può trattare i dati anche fuori dall’UE, con le garanzie previste dalla legge e '
              'descritte nella sua informativa (netlify.com/privacy).',
              'Legal basis: legitimate interest in providing a working and secure website (GDPR art. 6(1)(f)). '
              'The provider may process data outside the EU, with the safeguards required by law and described '
              'in its own privacy policy (netlify.com/privacy).'),
          tr('Se apri una segnalazione su GitHub, quello che scrivi e il tuo nome utente sono pubblici e '
              'trattati da GitHub secondo la propria informativa. Usiamo queste informazioni solo per '
              'rispondere e migliorare Basil.',
              'If you open an issue on GitHub, what you write and your username are public and processed by '
              'GitHub under its own privacy policy. We only use them to reply and to improve Basil.'),
        ]),
        LegalSection(tr('5. App per telefono', '5. Phone app'), [
          tr('L’app Android non richiede l’accesso a Internet, alla posizione, alla fotocamera, ai contatti '
              'o ad altri dati personali. Se la scarichi da uno store, lo store può trattare dati secondo la '
              'propria informativa.',
              'The Android app does not request access to the Internet, location, camera, contacts or other '
              'personal data. If you download it from a store, the store may process data under its own policy.'),
        ]),
        LegalSection(tr('6. Minori e scuole', '6. Children and schools'), [
          tr('Basil è pensato anche per studenti e uso in classe. Poiché non raccoglie dati personali, può essere '
              'usato da minori senza registrazione né consenso dei genitori.',
              'Basil is designed for students and classroom use too. Since it collects no personal data, it '
              'can be used by minors without registration or parental consent.'),
        ]),
        LegalSection(tr('7. I tuoi diritti', '7. Your rights'), [
          tr('Hai i diritti previsti dagli artt. 15-22 GDPR (accesso, rettifica, cancellazione, limitazione, '
              'opposizione) e il diritto di presentare reclamo al Garante per la protezione dei dati personali '
              '(garanteprivacy.it) o all’autorità del tuo Paese. Dato che non conserviamo dati che ti riguardano, '
              'le richieste riguarderanno di solito i log tecnici del fornitore di hosting.',
              'You have the rights set out in GDPR arts. 15-22 (access, rectification, erasure, restriction, '
              'objection) and the right to lodge a complaint with the Italian Data Protection Authority '
              '(garanteprivacy.it) or the authority in your country. Since we keep no data about you, requests '
              'will usually concern the hosting provider’s technical logs.'),
        ]),
        LegalSection(tr('8. Modifiche', '8. Changes'), [
          tr('Se cambiamo questa informativa aggiorneremo la data in alto. Le modifiche importanti saranno '
              'segnalate nell’app.',
              'If we change this policy we will update the date at the top. Important changes will be '
              'announced in the app.'),
        ]),
      ],
    );

LegalDoc termsDoc() => LegalDoc(
      tr('Termini di utilizzo', 'Terms of Use'),
      tr('Ultimo aggiornamento: $kLegalUpdated. Usando Basil accetti questi termini. Se non li accetti, '
          'non usare il sito o l’app.',
          'Last updated: $kLegalUpdated. By using Basil you accept these terms. If you do not accept them, '
          'do not use the website or the app.'),
      [
        LegalSection(tr('1. Il servizio', '1. The service'), [
          tr('Basil è uno strumento didattico gratuito per convertire numeri tra basi (2-36), fare operazioni '
              'in qualsiasi base, studiare lezioni ed esercitarsi. È fornito da $_author «così com’è» e «come '
              'disponibile», senza alcun costo e senza obbligo di assistenza.',
              'Basil is a free educational tool to convert numbers between bases (2-36), do arithmetic in any '
              'base, study lessons and practise. It is provided by $_author "as is" and "as available", free '
              'of charge and with no obligation to provide support.'),
        ]),
        LegalSection(tr('2. Nessuna garanzia', '2. No warranty'), [
          tr('Facciamo il possibile perché risultati e spiegazioni siano corretti, ma non garantiamo che siano '
              'privi di errori, completi o adatti a uno scopo particolare. Basil non deve essere usato come unica '
              'fonte per attività professionali, finanziarie, mediche, di sicurezza o in cui un errore può causare '
              'danni. Verifica sempre in modo indipendente i risultati importanti (per esempio in un compito o '
              'in un esame).',
              'We do our best to make results and explanations correct, but we do not warrant that they are '
              'error-free, complete or fit for a particular purpose. Basil must not be used as the sole source '
              'for professional, financial, medical or safety-critical work, or wherever an error could cause '
              'harm. Always check important results independently (for example in homework or an exam).'),
          tr('Le lezioni sono semplificazioni a scopo didattico e non sostituiscono libri di testo o insegnanti.',
              'Lessons are simplifications for teaching purposes and do not replace textbooks or teachers.'),
        ]),
        LegalSection(tr('3. Limitazione di responsabilità', '3. Limitation of liability'), [
          tr('Nella misura massima consentita dalla legge, $_author non è responsabile di danni diretti o '
              'indiretti derivanti dall’uso o dall’impossibilità di usare Basil, inclusi errori nei risultati, '
              'voti, perdita di dati salvati sul dispositivo (come i record) o interruzioni del servizio.',
              'To the maximum extent permitted by law, $_author is not liable for any direct or indirect damage '
              'arising from the use of, or inability to use, Basil, including errors in results, grades, loss '
              'of data stored on your device (such as records) or service interruptions.'),
          tr('Nulla in questi termini esclude o limita la responsabilità che per legge non può essere esclusa '
              'o limitata (per esempio per dolo o colpa grave, art. 1229 c.c.), né i diritti inderogabili dei '
              'consumatori.',
              'Nothing in these terms excludes or limits liability that cannot be excluded or limited by law '
              '(for example for wilful misconduct or gross negligence), nor any mandatory consumer rights.'),
        ]),
        LegalSection(tr('4. Uso consentito', '4. Acceptable use'), [
          tr('Puoi usare Basil liberamente per studio personale e in classe. Sul sito pubblicato non è '
              'consentito tentare di comprometterne, sovraccaricarne o aggirarne la sicurezza, né usarlo per '
              'attività illecite.',
              'You may use Basil freely for personal study and in class. On the published website you may not '
              'try to compromise, overload or bypass its security, or use it for unlawful purposes.'),
        ]),
        LegalSection(tr('5. Codice aperto e licenze', '5. Open source and licences'), [
          tr('Basil è open source. Il codice è pubblicato su $kRepoUrl con licenza MIT: puoi studiarlo, '
              'modificarlo e ridistribuirlo rispettando quella licenza, che include a sua volta l’esclusione di '
              'garanzia. Se pubblichi una versione modificata, non presentarla come la versione ufficiale di Basil.',
              'Basil is open source. The code is published at $kRepoUrl under the MIT licence: you may study, '
              'modify and redistribute it under that licence, which also includes a warranty disclaimer. If you '
              'publish a modified version, do not present it as the official Basil.'),
          tr('I caratteri JetBrains Mono, VT323 e Silkscreen sono distribuiti dai rispettivi autori con licenza '
              'SIL Open Font License 1.1 (vedi Impostazioni, Licenze). Gli altri marchi citati appartengono ai '
              'rispettivi titolari.',
              'The JetBrains Mono, VT323 and Silkscreen typefaces are distributed by their authors under the '
              'SIL Open Font License 1.1 (see Settings, Licences). Other trademarks mentioned belong to their '
              'respective owners.'),
        ]),
        LegalSection(tr('6. Disponibilità e modifiche', '6. Availability and changes'), [
          tr('Possiamo modificare, sospendere o chiudere Basil, in tutto o in parte, in qualsiasi momento e senza '
              'preavviso. Possiamo aggiornare questi termini: la versione in vigore è sempre quella pubblicata '
              'nell’app, con la data in alto.',
              'We may change, suspend or discontinue Basil, in whole or in part, at any time and without notice. '
              'We may update these terms: the version in force is always the one published in the app, with the '
              'date at the top.'),
        ]),
        LegalSection(tr('7. Legge applicabile', '7. Governing law'), [
          tr('Questi termini sono regolati dalla legge italiana. Se sei un consumatore, restano salve le tutele '
              'inderogabili della legge del tuo Paese di residenza e la competenza del foro del consumatore.',
              'These terms are governed by Italian law. If you are a consumer, you keep the mandatory protections '
              'of the law of your country of residence and the right to bring proceedings in your local courts.'),
        ]),
        LegalSection(tr('8. Contatti', '8. Contact'), [
          tr('Per segnalazioni, errori o domande puoi contattarci $_contact',
              'For reports, bugs or questions you can contact us $_contact'),
        ]),
      ],
    );
