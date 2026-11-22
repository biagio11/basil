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

const _owner = 'github.com/biagio11';

String get _author => tr('l’autore di Basil', 'the author of Basil');

String get _contact => tr(
    'aprendo una segnalazione (issue) su $kIssuesUrl. Le segnalazioni sono pubbliche, quindi non '
        'scriverci dati personali. Se la tua richiesta richiede riservatezza, apri una segnalazione '
        'chiedendo un canale privato, senza indicare altri dettagli.',
    'by opening an issue at $kIssuesUrl. Issues are public, so do not include personal data. If your '
        'request needs privacy, open an issue asking for a private channel without giving other details.');

LegalDoc privacyDoc() => LegalDoc(
      tr('Informativa sulla privacy', 'Privacy Policy'),
      tr('Versione $kAppVersion, aggiornata il $kLegalUpdated. In breve, Basil non raccoglie dati personali. '
          'Non ci sono account, pubblicità, statistiche, cookie o strumenti di tracciamento. Quello che '
          'scrivi nell’app resta sul tuo dispositivo.',
          'Version $kAppVersion, updated on $kLegalUpdated. In short, Basil does not collect personal data. '
          'There are no accounts, ads, analytics, cookies or tracking tools. What you type in the app stays '
          'on your device.'),
      [
        LegalSection(tr('1. Titolare del trattamento', '1. Data controller'), [
          tr('Basil (sito web e app) è uno strumento didattico gratuito e open source pubblicato da $_author, '
              'titolare dell’account GitHub $_owner («noi»). Puoi contattarci $_contact',
              'Basil (website and app) is a free, open source educational tool published by $_author, owner '
              'of the GitHub account $_owner ("we", "us"). You can contact us $_contact'),
        ]),
        LegalSection(tr('2. Dati che raccogliamo', '2. Data we collect'), [
          tr('Nessuno. Numeri, conversioni, calcoli, esercizi e risultati sono elaborati solo sul tuo dispositivo e '
              'non vengono mai inviati a noi né a terzi. Non abbiamo un server che riceva dati dall’app.',
              'None. Numbers, conversions, calculations, exercises and results are processed only on your '
              'device and are never sent to us or to third parties. We have no server that receives data from '
              'the app.'),
          tr('Non usiamo cookie, analytics, pubblicità, pixel, social plugin, font o librerie caricati da server '
              'esterni. Non facciamo profilazione né decisioni automatizzate.',
              'We use no cookies, analytics, ads, pixels, social plugins, or fonts or libraries loaded from '
              'external servers. We do no profiling and no automated decision making.'),
        ]),
        LegalSection(tr('3. Dati salvati sul tuo dispositivo', '3. Data stored on your device'), [
          tr('Per ricordare le tue scelte, Basil salva solo sul dispositivo (localStorage del browser o memoria '
              'dell’app) tema, lingua, impostazioni, ultime basi usate e risultati delle sfide a tempo.',
              'To remember your choices, Basil stores only on your device (browser localStorage or app storage) '
              'theme, language, settings, last bases used and timed challenge results.'),
          tr('Questi dati servono solo a far funzionare le funzioni che usi, non ci vengono trasmessi e non possiamo '
              'vederli. Si tratta di memorizzazione strettamente necessaria a un servizio richiesto da te, che non '
              'richiede consenso (art. 122 del Codice Privacy, art. 5.3 della direttiva ePrivacy). Restano finché '
              'non li cancelli da Impostazioni, «Cancella tutti i dati», cancellando i dati del sito nel browser o '
              'disinstallando l’app.',
              'This data is only used to make the features you use work, is not transmitted to us and we cannot '
              'see it. It is storage strictly necessary for a service you requested, which needs no consent '
              '(ePrivacy Directive art. 5(3)). It stays until you delete it from Settings, "Delete all data", by '
              'clearing the site data in your browser or by uninstalling the app.'),
        ]),
        LegalSection(tr('4. Hosting del sito', '4. Website hosting'), [
          tr('Il sito è ospitato da Netlify, Inc., che agisce come fornitore del servizio di hosting. Come per '
              'qualsiasi sito web, i suoi server trattano necessariamente dati tecnici (indirizzo IP, tipo di '
              'browser, pagina richiesta, data e ora) per consegnare le pagine e proteggerle da abusi e attacchi.',
              'The website is hosted by Netlify, Inc., acting as hosting provider. As with any website, its '
              'servers necessarily process technical data (IP address, browser type, requested page, date and '
              'time) to deliver the pages and protect them from abuse and attacks.'),
          tr('Base giuridica: legittimo interesse a fornire un sito funzionante e sicuro (art. 6.1.f GDPR). Non '
              'usiamo questi dati per identificarti, non li incrociamo con altre informazioni e non li vendiamo. '
              'Sono conservati per il tempo stabilito dal fornitore per finalità tecniche e di sicurezza. Il '
              'fornitore può trattarli anche fuori dall’Unione europea con le garanzie previste dagli artt. 44 e '
              'seguenti del GDPR, descritte nella sua informativa (netlify.com/privacy).',
              'Legal basis: legitimate interest in providing a working and secure website (GDPR art. 6(1)(f)). We '
              'do not use this data to identify you, do not combine it with other information and do not sell '
              'it. It is kept for the time set by the provider for technical and security purposes. The provider '
              'may process it outside the European Union with the safeguards required by GDPR art. 44 and '
              'following, described in its own policy (netlify.com/privacy).'),
        ]),
        LegalSection(tr('5. GitHub e link esterni', '5. GitHub and external links'), [
          tr('I link al codice sorgente e alle segnalazioni portano su GitHub, un servizio esterno. Se apri una '
              'segnalazione, quello che scrivi e il tuo nome utente sono pubblici e trattati da GitHub come titolare '
              'autonomo secondo la propria informativa. Usiamo queste informazioni solo per rispondere e migliorare '
              'Basil.',
              'Links to the source code and to issues lead to GitHub, an external service. If you open an issue, '
              'what you write and your username are public and processed by GitHub as an independent controller '
              'under its own policy. We only use this information to reply and to improve Basil.'),
        ]),
        LegalSection(tr('6. Condivisione, immagini e PDF', '6. Sharing, images and PDFs'), [
          tr('Le immagini dei risultati e i PDF sono creati sul tuo dispositivo. Vengono inviati altrove solo se '
              'scegli tu di condividerli, tramite l’app che selezioni (per esempio Instagram o TikTok), che li '
              'tratta secondo le proprie regole.',
              'Result images and PDFs are created on your device. They go elsewhere only if you choose to share '
              'them, through the app you select (for example Instagram or TikTok), which handles them under its '
              'own rules.'),
        ]),
        LegalSection(tr('7. App per telefono', '7. Phone app'), [
          tr('L’app Android non richiede permessi: niente accesso a Internet, posizione, fotocamera, microfono, '
              'contatti o archivio. Se la scarichi da uno store, lo store può trattare dati secondo la propria '
              'informativa.',
              'The Android app requests no permissions: no access to the Internet, location, camera, microphone, '
              'contacts or storage. If you download it from a store, the store may process data under its own '
              'policy.'),
        ]),
        LegalSection(tr('8. Minori e scuole', '8. Children and schools'), [
          tr('Basil è pensato anche per studenti e per l’uso in classe. Poiché non raccoglie dati personali, può '
              'essere usato da minori senza registrazione. Chiediamo ai minori di non aprire segnalazioni su GitHub '
              'senza il permesso di un genitore o di un insegnante.',
              'Basil is designed for students and classroom use too. Since it collects no personal data, minors '
              'can use it without registering. We ask minors not to open GitHub issues without permission from '
              'a parent or teacher.'),
        ]),
        LegalSection(tr('9. Sicurezza', '9. Security'), [
          tr('Il sito usa solo HTTPS, non carica script di terze parti e applica regole di sicurezza restrittive '
              '(Content Security Policy, blocco dell’inserimento in altri siti, nessun referrer, permessi del '
              'browser disattivati). Nessun sistema è sicuro al cento per cento, ma non avendo dati da custodire '
              'il rischio per i tuoi dati è minimo.',
              'The site uses HTTPS only, loads no third party scripts and applies strict security rules (Content '
              'Security Policy, no embedding in other sites, no referrer, browser permissions disabled). No system '
              'is one hundred percent secure, but since we hold no data the risk to your data is minimal.'),
        ]),
        LegalSection(tr('10. I tuoi diritti', '10. Your rights'), [
          tr('Hai i diritti previsti dagli artt. 15-22 GDPR (accesso, rettifica, cancellazione, limitazione, '
              'portabilità, opposizione) e il diritto di presentare reclamo al Garante per la protezione dei dati '
              'personali (garanteprivacy.it) o all’autorità del tuo Paese. Dato che non conserviamo dati che ti '
              'riguardano, le richieste riguarderanno di solito i log tecnici del fornitore di hosting, per i quali '
              'ti aiuteremo a contattarlo.',
              'You have the rights set out in GDPR arts. 15-22 (access, rectification, erasure, restriction, '
              'portability, objection) and the right to lodge a complaint with the Italian Data Protection '
              'Authority (garanteprivacy.it) or the authority in your country. Since we keep no data about you, '
              'requests will usually concern the hosting provider’s technical logs, and we will help you reach it.'),
        ]),
        LegalSection(tr('11. Modifiche', '11. Changes'), [
          tr('Se cambiamo questa informativa aggiorneremo versione e data in alto. Le modifiche importanti saranno '
              'segnalate nell’app. In caso di differenze tra la versione italiana e quella inglese prevale quella '
              'italiana.',
              'If we change this policy we will update the version and date at the top. Important changes will be '
              'announced in the app. If the Italian and English versions differ, the Italian one prevails.'),
        ]),
      ],
    );

LegalDoc termsDoc() => LegalDoc(
      tr('Termini di utilizzo', 'Terms of Use'),
      tr('Versione $kAppVersion, aggiornata il $kLegalUpdated. Usando il sito o l’app accetti questi termini. '
          'Se non li accetti, non usare Basil.',
          'Version $kAppVersion, updated on $kLegalUpdated. By using the website or the app you accept these '
          'terms. If you do not accept them, do not use Basil.'),
      [
        LegalSection(tr('1. Il servizio', '1. The service'), [
          tr('Basil è uno strumento didattico gratuito per convertire numeri tra basi da 2 a 36, fare operazioni '
              'in qualsiasi base, studiare lezioni ed esercitarsi. È fornito da $_author senza costi, senza account '
              'e senza alcun obbligo di assistenza, aggiornamento o disponibilità.',
              'Basil is a free educational tool to convert numbers between bases 2 to 36, do arithmetic in any '
              'base, study lessons and practise. It is provided by $_author free of charge, without accounts and '
              'without any obligation of support, updates or availability.'),
          tr('I minori possono usarlo sotto la responsabilità di un genitore o di un insegnante, quando richiesto '
              'dalla legge del loro Paese.',
              'Minors may use it under the responsibility of a parent or teacher where the law of their country '
              'requires it.'),
        ]),
        LegalSection(tr('2. Uso didattico, nessuna garanzia', '2. Educational use, no warranty'), [
          tr('Basil è fornito «così com’è» e «come disponibile». Facciamo il possibile perché risultati e '
              'spiegazioni siano corretti, ma, nei limiti consentiti dalla legge, non garantiamo che siano privi di '
              'errori, completi, aggiornati o adatti a uno scopo particolare, né che il servizio sia sempre '
              'disponibile o privo di difetti.',
              'Basil is provided "as is" and "as available". We do our best to make results and explanations '
              'correct but, to the extent permitted by law, we do not warrant that they are error free, complete, '
              'up to date or fit for a particular purpose, nor that the service is always available or free of '
              'defects.'),
          tr('Basil non è uno strumento professionale e non fornisce consulenza. Non usarlo come unica fonte per '
              'attività professionali, finanziarie, mediche, di sicurezza o dove un errore può causare danni. '
              'Verifica sempre in modo indipendente i risultati importanti, per esempio in un compito o in un esame. '
              'Le lezioni sono semplificazioni e non sostituiscono libri di testo o insegnanti.',
              'Basil is not a professional tool and gives no advice. Do not use it as the sole source for '
              'professional, financial, medical or safety critical work, or wherever an error could cause harm. '
              'Always check important results independently, for example in homework or an exam. Lessons are '
              'simplifications and do not replace textbooks or teachers.'),
        ]),
        LegalSection(tr('3. Limitazione di responsabilità', '3. Limitation of liability'), [
          tr('Nella misura massima consentita dalla legge, $_author non risponde di danni diretti, indiretti, '
              'incidentali o consequenziali derivanti dall’uso o dall’impossibilità di usare Basil, inclusi errori '
              'nei risultati, voti o valutazioni, perdita dei dati salvati sul dispositivo (come i record), '
              'interruzioni del servizio o contenuti di siti esterni.',
              'To the maximum extent permitted by law, $_author is not liable for any direct, indirect, incidental '
              'or consequential damage arising from the use of, or inability to use, Basil, including errors in '
              'results, grades or assessments, loss of data stored on your device (such as records), service '
              'interruptions or content of external sites.'),
          tr('Nulla in questi termini esclude o limita la responsabilità che per legge non può essere esclusa o '
              'limitata, come quella per dolo o colpa grave (art. 1229 c.c.), né i diritti inderogabili dei '
              'consumatori previsti dal Codice del consumo o dalla legge del tuo Paese.',
              'Nothing in these terms excludes or limits liability that cannot be excluded or limited by law, such '
              'as liability for wilful misconduct or gross negligence, nor the mandatory rights of consumers under '
              'the law of your country.'),
        ]),
        LegalSection(tr('4. Uso consentito', '4. Acceptable use'), [
          tr('Puoi usare Basil liberamente per studio personale e in classe. Sul sito pubblicato non è consentito '
              'tentare di comprometterne, sovraccaricarne o aggirarne la sicurezza, inviare richieste automatizzate '
              'in modo massivo, usarlo per attività illecite o far credere che una versione modificata sia quella '
              'ufficiale. Possiamo limitare l’accesso in caso di abusi.',
              'You may use Basil freely for personal study and in class. On the published website you may not try '
              'to compromise, overload or bypass its security, send automated requests in bulk, use it for unlawful '
              'purposes or pass off a modified version as the official one. We may restrict access in case of abuse.'),
        ]),
        LegalSection(tr('5. Contenuti che condividi', '5. Content you share'), [
          tr('Sei responsabile delle immagini, dei PDF e dei risultati che scegli di condividere e di dove li '
              'pubblichi. Puoi usare il nome e il logo di Basil solo per indicare che il contenuto proviene da Basil.',
              'You are responsible for the images, PDFs and results you choose to share and for where you post '
              'them. You may use the Basil name and logo only to show that the content comes from Basil.'),
        ]),
        LegalSection(tr('6. Codice aperto e licenze', '6. Open source and licences'), [
          tr('Il codice di Basil è pubblicato su $kRepoUrl con licenza MIT. Per l’uso del codice valgono i termini '
              'di quella licenza, che prevalgono su questi in caso di conflitto e includono a loro volta '
              'l’esclusione di garanzia. Questi termini regolano l’uso del sito e dell’app pubblicati.',
              'Basil’s code is published at $kRepoUrl under the MIT licence. Use of the code is governed by that '
              'licence, which prevails over these terms in case of conflict and also includes a warranty '
              'disclaimer. These terms govern the use of the published website and app.'),
          tr('I caratteri JetBrains Mono, VT323 e Silkscreen sono distribuiti dai rispettivi autori con licenza SIL '
              'Open Font License 1.1 (vedi Impostazioni, Licenze). Gli altri marchi citati appartengono ai rispettivi '
              'titolari e sono usati solo a scopo descrittivo.',
              'The JetBrains Mono, VT323 and Silkscreen typefaces are distributed by their authors under the SIL '
              'Open Font License 1.1 (see Settings, Licences). Other trademarks mentioned belong to their owners and '
              'are used for descriptive purposes only.'),
        ]),
        LegalSection(tr('7. Link esterni', '7. External links'), [
          tr('Basil contiene link a servizi di terzi come GitHub. Non controlliamo questi servizi e non siamo '
              'responsabili dei loro contenuti, della loro disponibilità o del loro trattamento dei dati.',
              'Basil contains links to third party services such as GitHub. We do not control these services and '
              'are not responsible for their content, availability or handling of data.'),
        ]),
        LegalSection(tr('8. Disponibilità e modifiche', '8. Availability and changes'), [
          tr('Possiamo modificare, sospendere o chiudere Basil, in tutto o in parte, in qualsiasi momento e senza '
              'preavviso. Possiamo aggiornare questi termini. La versione in vigore è sempre quella pubblicata '
              'nell’app, con versione e data in alto, e continuare a usare Basil dopo una modifica significa '
              'accettarla.',
              'We may change, suspend or discontinue Basil, in whole or in part, at any time and without notice. We '
              'may update these terms. The version in force is always the one published in the app, with version '
              'and date at the top, and continuing to use Basil after a change means accepting it.'),
        ]),
        LegalSection(tr('9. Clausole finali', '9. Final clauses'), [
          tr('Se una clausola risulta invalida o inapplicabile, le altre restano valide. Il mancato esercizio di '
              'un diritto non vale come rinuncia. Questi termini, insieme all’informativa sulla privacy, sono '
              'l’intero accordo tra te e noi su Basil. In caso di differenze tra la versione italiana e quella '
              'inglese prevale quella italiana.',
              'If any clause is found invalid or unenforceable, the others remain in force. Not exercising a right '
              'is not a waiver of it. These terms, together with the privacy policy, are the entire agreement '
              'between you and us about Basil. If the Italian and English versions differ, the Italian one '
              'prevails.'),
        ]),
        LegalSection(tr('10. Legge applicabile', '10. Governing law'), [
          tr('Questi termini sono regolati dalla legge italiana. Se sei un consumatore restano salve le tutele '
              'inderogabili della legge del tuo Paese di residenza e la competenza del giudice del luogo in cui '
              'risiedi.',
              'These terms are governed by Italian law. If you are a consumer you keep the mandatory protections '
              'of the law of your country of residence and the right to bring proceedings in your local courts.'),
        ]),
        LegalSection(tr('11. Contatti', '11. Contact'), [
          tr('Per segnalazioni, errori o domande puoi contattarci $_contact',
              'For reports, bugs or questions you can contact us $_contact'),
        ]),
      ],
    );
