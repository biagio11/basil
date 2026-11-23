import 'package:flutter/material.dart';

import '../app/settings.dart';
import '../content/legal.dart';
import 'calc_screen.dart';
import 'common.dart';
import 'converter_screen.dart';
import 'lessons_screen.dart';
import 'settings_screen.dart';
import 'widgets/backdrops.dart';
import 'train_screen.dart';
import 'widgets/fx.dart';
import 'widgets/matrix_rain.dart';
import 'widgets/pixel_leaf.dart';
import 'widgets/theme_reveal.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  static int _tab = 0;
  final s = AppSettings.instance;

  void _select(int i) {
    if (i == _tab) return;
    hapticTick();
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _tab = i);
  }

  void _openPractice() {
    Navigator.of(context).popUntil((r) => r.isFirst);
    setState(() => _tab = 3);
  }

  List<(IconData, IconData, String)> get _dest => [
        (Icons.swap_horiz, Icons.swap_horizontal_circle, tr('Converti', 'Convert')),
        (Icons.calculate_outlined, Icons.calculate, tr('Calcola', 'Calc')),
        (Icons.school_outlined, Icons.school, tr('Impara', 'Learn')),
        (Icons.bolt_outlined, Icons.bolt, tr('Allenati', 'Train')),
      ];

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final wide = MediaQuery.sizeOf(context).width >= 900;
    final anim = animationsOn(context);
    final pages = <Widget>[
      const ConverterScreen(),
      const CalcScreen(),
      LessonsScreen(onOpenPractice: _openPractice),
      const TrainScreen(),
    ];

    final body = Stack(
      children: [
        for (var i = 0; i < pages.length; i++)
          IgnorePointer(
            ignoring: i != _tab,
            child: ExcludeFocus(
              excluding: i != _tab,
              child: AnimatedOpacity(
                opacity: i == _tab ? 1 : 0,
                duration: Duration(milliseconds: anim ? 200 : 0),
                child: AnimatedSlide(
                  offset: i == _tab ? Offset.zero : const Offset(0, 0.015),
                  duration: Duration(milliseconds: anim ? 240 : 0),
                  curve: Curves.easeOutCubic,
                  // Hidden tabs keep their state but stop animating.
                  child: TickerMode(enabled: i == _tab, child: pages[i]),
                ),
              ),
            ),
          ),
      ],
    );

    final appBar = AppBar(
      toolbarHeight: 60,
      titleSpacing: 16,
      title: const BasilLogo(size: 30),
      actions: [
        TextButton(
          onPressed: () => s.setLang(s.lang == 'it' ? 'en' : 'it'),
          child: Text(s.lang == 'it' ? 'IT' : 'EN',
              style: pixelStyle(size: 12, color: cs.primary)),
        ),
        Builder(builder: (btn) => IconButton(
          tooltip: tr('Tema chiaro/scuro', 'Light/dark theme'),
          onPressed: () => switchTheme(btn, context.isDark ? ThemeMode.light : ThemeMode.dark,
              from: centerOf(btn)),
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (c, a) => RotationTransition(
                turns: Tween(begin: .75, end: 1.0).animate(a),
                child: FadeTransition(opacity: a, child: c)),
            child: Icon(context.isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                key: ValueKey(context.isDark)),
          ),
        )),
        IconButton(
          tooltip: tr('Impostazioni', 'Settings'),
          onPressed: () => Navigator.of(context)
              .push(MaterialPageRoute<void>(builder: (_) => const SettingsScreen())),
          icon: const Icon(Icons.tune),
        ),
        const SizedBox(width: 6),
      ],
    );

    final content = Column(
      children: [
        Expanded(child: body),
        if (!s.acceptedTerms) _TermsBar(onOk: () => setState(s.acceptTerms)),
      ],
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: appBar,
      extendBodyBehindAppBar: false,
      body: SafeArea(
        top: false,
        bottom: wide,
        child: wide
            ? Row(
                children: [
                  NavigationRail(
                    selectedIndex: _tab,
                    onDestinationSelected: _select,
                    labelType: NavigationRailLabelType.all,
                    groupAlignment: -0.9,
                    destinations: [
                      for (final d in _dest)
                        NavigationRailDestination(
                          icon: Icon(d.$1),
                          selectedIcon: Icon(d.$2, color: cs.primary),
                          label: Text(d.$3),
                        ),
                    ],
                  ),
                  VerticalDivider(width: 1, color: cs.outlineVariant),
                  Expanded(child: content),
                ],
              )
            : content,
      ),
      bottomNavigationBar: wide
          ? null
          : NavigationBar(
              selectedIndex: _tab,
              onDestinationSelected: _select,
              destinations: [
                for (final d in _dest)
                  NavigationDestination(
                    icon: Icon(d.$1),
                    selectedIcon: Icon(d.$2, color: cs.primary),
                    label: d.$3,
                  ),
              ],
            ),
    );
  }
}

class _TermsBar extends StatelessWidget {
  const _TermsBar({required this.onOk});
  final VoidCallback onOk;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    return Appear(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
        decoration: BoxDecoration(
          color: context.bc.panel,
          border: Border(top: BorderSide(color: cs.primary.withAlpha(120))),
        ),
        child: Row(
          children: [
            Icon(Icons.shield_outlined, size: 20, color: cs.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(tr('Basil non raccoglie dati. Usandolo accetti i ', 'Basil collects no data. By using it you accept the '),
                      style: const TextStyle(fontSize: 12)),
                  InkWell(
                    onTap: () => openLegal(context, termsDoc),
                    child: Text(tr('Termini', 'Terms'),
                        style: TextStyle(fontSize: 12, color: cs.primary, decoration: TextDecoration.underline)),
                  ),
                  Text(tr(' e la ', ' and the '), style: const TextStyle(fontSize: 12)),
                  InkWell(
                    onTap: () => openLegal(context, privacyDoc),
                    child: Text(tr('Privacy', 'Privacy Policy'),
                        style: TextStyle(fontSize: 12, color: cs.primary, decoration: TextDecoration.underline)),
                  ),
                  const Text('.', style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10)),
              onPressed: onOk,
              child: const Text('OK'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Background: soft gradient, the chosen effect, scanlines and vignette.
class BasilBackground extends StatelessWidget {
  const BasilBackground({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final dark = context.isDark;
    final cs = context.cs;
    final look = AppSettings.instance.look;
    final top = dark
        ? (look.pureBlack ? Colors.black : look.tone(const Color(0xFF0B2414)))
        : look.tone(const Color(0xFFDDF2DF));
    return Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0.8, -1.1),
                radius: 1.6,
                colors: [top, cs.surface],
              ),
            ),
          ),
        ),
        Positioned.fill(child: Backdrop(look: look)),
        if (look.scanlines)
          Positioned.fill(child: IgnorePointer(child: CustomPaint(painter: _Scanlines(dark)))),
        if (look.vignette) const Positioned.fill(child: Vignette()),
        Positioned.fill(child: child),
      ],
    );
  }
}

/// The animated effect chosen in personalisation, or nothing.
class Backdrop extends StatelessWidget {
  const Backdrop({super.key, required this.look, this.enabled});
  final Look look;
  final bool? enabled;

  @override
  Widget build(BuildContext context) {
    final on = enabled ?? animationsOn(context);
    final o = look.intensity;
    return switch (look.background) {
      'rain' => MatrixRain(
          key: const ValueKey('rain'),
          enabled: on,
          opacity: o * 1.25,
          glyphs: look.glyphs,
          density: look.density,
          speed: look.speed,
        ),
      'grid' => GridBackdrop(
          key: const ValueKey('grid'), enabled: on, opacity: o * 1.25, density: look.density, speed: look.speed),
      'bits' => BitsBackdrop(
          key: const ValueKey('bits'),
          enabled: on,
          opacity: o * 1.25,
          density: look.density,
          speed: look.speed,
          glyphs: look.glyphs),
      'stars' => StarsBackdrop(
          key: const ValueKey('stars'), enabled: on, opacity: o * 1.25, density: look.density, speed: look.speed),
      _ => const SizedBox.shrink(),
    };
  }
}

class _Scanlines extends CustomPainter {
  const _Scanlines(this.dark);
  final bool dark;
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = dark ? const Color(0x0A000000) : const Color(0x07000000);
    for (double y = 0; y < size.height; y += 3) {
      canvas.drawRect(Rect.fromLTWH(0, y, size.width, 1), p);
    }
  }

  @override
  bool shouldRepaint(_Scanlines old) => old.dark != dark;
}
