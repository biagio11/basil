import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app/config.dart';
import '../app/settings.dart';
import '../content/legal.dart';
import 'common.dart';
import 'widgets/fx.dart';
import 'widgets/pixel_leaf.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppSettings.instance;
    return ListenableBuilder(
      listenable: s,
      builder: (context, _) {
        final cs = context.cs;
        Widget section(String t) => Padding(
              padding: const EdgeInsets.fromLTRB(4, 18, 4, 8),
              child: Text(t.toUpperCase(), style: pixelStyle(size: 11, color: cs.primary)),
            );
        return Scaffold(
          appBar: AppBar(title: Text(tr('Impostazioni', 'Settings'))),
          body: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 32),
                children: [
                  section(tr('Aspetto', 'Appearance')),
                  SegmentedButton<ThemeMode>(
                    showSelectedIcon: false,
                    segments: [
                      ButtonSegment(value: ThemeMode.dark, icon: const Icon(Icons.dark_mode_outlined, size: 18), label: Text(tr('Scuro', 'Dark'))),
                      ButtonSegment(value: ThemeMode.light, icon: const Icon(Icons.light_mode_outlined, size: 18), label: Text(tr('Chiaro', 'Light'))),
                      ButtonSegment(value: ThemeMode.system, icon: const Icon(Icons.brightness_auto_outlined, size: 18), label: Text(tr('Auto', 'Auto'))),
                    ],
                    selected: {s.themeMode},
                    onSelectionChanged: (v) => s.setTheme(v.first),
                  ),
                  const SizedBox(height: 10),
                  SegmentedButton<String>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(value: 'it', label: Text('Italiano')),
                      ButtonSegment(value: 'en', label: Text('English')),
                    ],
                    selected: {s.lang},
                    onSelectionChanged: (v) => s.setLang(v.first),
                  ),
                  const SizedBox(height: 6),
                  SwitchListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                    title: Text(tr('Effetto matrix', 'Matrix effect')),
                    subtitle: Text(tr('Cifre che scendono sullo sfondo', 'Falling digits in the background')),
                    value: s.matrix,
                    onChanged: s.setMatrix,
                  ),
                  SwitchListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                    title: Text(tr('Animazioni', 'Animations')),
                    subtitle: Text(tr('Transizioni ed effetti', 'Transitions and effects')),
                    value: s.animations,
                    onChanged: s.setAnimations,
                  ),
                  SwitchListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                    title: Text(tr('Vibrazione', 'Haptics')),
                    subtitle: Text(tr('Piccolo feedback sulle ruote e sui tasti (telefono)', 'Tiny feedback on wheels and keys (phone)')),
                    value: s.haptics,
                    onChanged: s.setHaptics,
                  ),
                  section(tr('Convertitore', 'Converter')),
                  SwitchListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                    title: Text(tr('Spiegazione attiva di default', 'Explanation on by default')),
                    value: s.explain,
                    onChanged: s.setExplain,
                  ),
                  SwitchListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                    title: Text(tr('Tastierino Basil sul telefono', 'Basil keypad on phones')),
                    subtitle: Text(tr('Mostra solo le cifre valide per la base', 'Shows only the digits valid in the base')),
                    value: s.keypad,
                    onChanged: s.setKeypad,
                  ),
                  SwitchListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                    title: Text(tr('Raggruppa le cifre', 'Group digits')),
                    subtitle: Text('1011 0110 · 1 234 567'),
                    value: s.groupDigits,
                    onChanged: s.setGroupDigits,
                  ),
                  section(tr('Privacy e informazioni', 'Privacy & info')),
                  _tile(context, Icons.shield_outlined, tr('Informativa sulla privacy', 'Privacy Policy'),
                      () => openLegal(context, privacyDoc)),
                  _tile(context, Icons.gavel_outlined, tr('Termini di utilizzo', 'Terms of Use'),
                      () => openLegal(context, termsDoc)),
                  _tile(context, Icons.code, tr('Codice sorgente su GitHub', 'Source code on GitHub'),
                      () => _open(kRepoUrl)),
                  _tile(context, Icons.bug_report_outlined, tr('Segnala un problema', 'Report a problem'),
                      () => _open(kIssuesUrl)),
                  _tile(context, Icons.description_outlined, tr('Licenze', 'Licences'), () {
                    showLicensePage(
                      context: context,
                      applicationName: 'Basil',
                      applicationVersion: kAppVersion,
                      applicationIcon: const Padding(
                          padding: EdgeInsets.all(12), child: PixelLeaf(size: 48)),
                    );
                  }),
                  _tile(context, Icons.delete_forever_outlined, tr('Cancella tutti i dati', 'Delete all data'), () async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text(tr('Cancellare tutti i dati?', 'Delete all data?')),
                        content: Text(tr(
                            'Impostazioni e record salvati su questo dispositivo verranno eliminati. Non si può annullare.',
                            'Settings and records saved on this device will be removed. This cannot be undone.')),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(tr('Annulla', 'Cancel'))),
                          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(tr('Cancella', 'Delete'))),
                        ],
                      ),
                    );
                    if (ok == true) {
                      await s.clearAll();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(tr('Dati cancellati', 'Data deleted'))));
                      }
                    }
                  }, danger: true),
                  const SizedBox(height: 26),
                  Center(child: Column(children: [
                    const BasilLogo(size: 30),
                    const SizedBox(height: 8),
                    Text('v$kAppVersion · ${tr('nessun tracciamento, nessun dato raccolto', 'no tracking, no data collected')}',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall),
                  ])),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _open(String url) async {
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  Widget _tile(BuildContext context, IconData icon, String title, VoidCallback onTap, {bool danger = false}) {
    final c = danger ? context.bc.bad : context.cs.onSurface;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      leading: Icon(icon, color: c),
      title: Text(title, style: TextStyle(color: c, fontWeight: FontWeight.w600)),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

void openLegal(BuildContext context, LegalDoc Function() doc) {
  Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => LegalScreen(doc: doc)));
}

class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key, required this.doc});
  final LegalDoc Function() doc;

  @override
  Widget build(BuildContext context) {
    final d = doc();
    final cs = context.cs;
    return Scaffold(
      appBar: AppBar(title: Text(d.title)),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: SelectionArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 4, 18, 40),
              children: [
                Appear(child: InfoCard(child: Text(d.intro, style: const TextStyle(height: 1.5)))),
                for (final s in d.sections) ...[
                  const SizedBox(height: 18),
                  Text(s.heading, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: cs.primary)),
                  const SizedBox(height: 8),
                  for (final p in s.paragraphs)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(p, style: const TextStyle(height: 1.55, fontSize: 14)),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
