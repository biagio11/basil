import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app/settings.dart';
import 'app/theme.dart';
import 'ui/shell.dart';
import 'ui/widgets/theme_reveal.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _registerFontLicences();
  await AppSettings.instance.load();
  runApp(const BasilApp());
}

void _registerFontLicences() {
  LicenseRegistry.addLicense(() async* {
    for (final (name, file) in const [
      ('JetBrains Mono', 'OFL-JetBrainsMono.txt'),
      ('VT323', 'OFL-VT323.txt'),
      ('Silkscreen', 'OFL-Silkscreen.txt'),
    ]) {
      final text = await rootBundle.loadString('assets/fonts/$file');
      yield LicenseEntryWithLineBreaks([name], text);
    }
  });
}

class BasilApp extends StatelessWidget {
  const BasilApp({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppSettings.instance;
    return ListenableBuilder(
      listenable: s,
      builder: (context, _) {
        return MaterialApp(
          title: 'Basil · base converter',
          debugShowCheckedModeBanner: false,
          theme: buildTheme(Brightness.light),
          darkTheme: buildTheme(Brightness.dark),
          themeMode: s.themeMode,
          themeAnimationDuration: Duration.zero,
          locale: Locale(s.lang),
          supportedLocales: const [Locale('it'), Locale('en')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          builder: (context, child) {
            final dark = Theme.of(context).brightness == Brightness.dark;
            SystemChrome.setSystemUIOverlayStyle(dark
                ? SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent)
                : SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent));
            // Cap text scaling so layouts never break, while still honouring
            // the user's accessibility setting.
            final mq = MediaQuery.of(context);
            return MediaQuery(
              data: mq.copyWith(
                  textScaler: mq.textScaler.clamp(minScaleFactor: 0.9, maxScaleFactor: 1.35)),
              child: ThemeReveal(child: BasilBackground(child: child ?? const SizedBox())),
            );
          },
          home: KeyedSubtree(key: ValueKey(s.lang), child: const HomeShell()),
        );
      },
    );
  }
}
