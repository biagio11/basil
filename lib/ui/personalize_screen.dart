import 'package:flutter/material.dart';

import '../app/settings.dart';
import '../app/theme.dart';
import 'common.dart';
import 'shell.dart' show Backdrop;
import 'widgets/fx.dart';
import 'widgets/pixel_leaf.dart';

/// Colours, background, fonts and shapes. Every change applies at once.
class PersonalizeScreen extends StatelessWidget {
  const PersonalizeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppSettings.instance;
    return ListenableBuilder(
      listenable: s,
      builder: (context, _) {
        final look = s.look;
        final cs = context.cs;
        void set(Look l) => s.setLook(l);
        Widget section(String t) => Padding(
              padding: const EdgeInsets.fromLTRB(4, 22, 4, 10),
              child: Text(t.toUpperCase(), style: pixelStyle(size: 11, color: cs.primary)),
            );
        Widget label(String t) => Padding(
              padding: const EdgeInsets.fromLTRB(4, 12, 4, 6),
              child: Text(t, style: const TextStyle(fontWeight: FontWeight.w700)),
            );
        final animated = look.background != 'none';
        return Scaffold(
          appBar: AppBar(
            title: Text(tr('Personalizza', 'Personalise')),
            actions: [
              TextButton.icon(
                onPressed: look == const Look() ? null : () => set(const Look()),
                icon: const Icon(Icons.restart_alt, size: 18),
                label: Text(tr('Ripristina', 'Reset')),
              ),
              const SizedBox(width: 6),
            ],
          ),
          body: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(14, 4, 14, 40),
                children: [
                  _Preview(look: look),
                  section(tr('Colori', 'Colours')),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final p in kPalettes)
                        _Swatch(
                          name: tr(p.it, p.en),
                          look: look.copyWith(palette: p.id),
                          selected: look.palette == p.id,
                          onTap: () => set(look.copyWith(palette: p.id)),
                        ),
                      _Swatch(
                        name: tr('Su misura', 'Custom'),
                        look: look.copyWith(palette: 'custom'),
                        selected: look.palette == 'custom',
                        rainbow: true,
                        onTap: () => set(look.copyWith(palette: 'custom')),
                      ),
                    ],
                  ),
                  if (look.palette == 'custom') ...[
                    label(tr('Tonalità', 'Hue')),
                    _HueSlider(
                      value: look.customHue,
                      onChanged: (v) => set(look.copyWith(customHue: v.roundToDouble())),
                    ),
                  ],
                  _switch(
                    tr('Nero assoluto', 'Pure black'),
                    tr('Sfondo nero pieno nel tema scuro, ottimo sugli schermi OLED',
                        'Solid black background in dark mode, great on OLED screens'),
                    look.pureBlack,
                    (v) => set(look.copyWith(pureBlack: v)),
                  ),
                  section(tr('Sfondo', 'Background')),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final (id, icon, it, en) in const [
                        ('none', Icons.block, 'Nessuno', 'None'),
                        ('rain', Icons.water_drop_outlined, 'Pioggia', 'Rain'),
                        ('bits', Icons.bubble_chart_outlined, 'Bit', 'Bits'),
                        ('grid', Icons.grid_on, 'Griglia', 'Grid'),
                        ('stars', Icons.auto_awesome_outlined, 'Stelle', 'Stars'),
                      ])
                        ChoiceChip(
                          avatar: Icon(icon, size: 18),
                          label: Text(tr(it, en)),
                          selected: look.background == id,
                          showCheckmark: false,
                          onSelected: (_) => set(look.copyWith(background: id)),
                        ),
                    ],
                  ),
                  if (animated) ...[
                    if (look.background == 'rain' || look.background == 'bits') ...[
                      label(tr('Simboli', 'Symbols')),
                      _seg<int>(
                        {2: '01', 8: '0‥7', 16: '0‥F', 36: '0‥Z'},
                        look.glyphs,
                        (v) => set(look.copyWith(glyphs: v)),
                      ),
                    ],
                    label(tr('Quantità', 'Amount')),
                    _seg<int>(
                      {0: tr('Poca', 'Low'), 1: tr('Media', 'Medium'), 2: tr('Tanta', 'High')},
                      look.density,
                      (v) => set(look.copyWith(density: v)),
                    ),
                    label(tr('Velocità', 'Speed')),
                    _seg<int>(
                      {0: tr('Lenta', 'Slow'), 1: tr('Normale', 'Normal'), 2: tr('Veloce', 'Fast')},
                      look.speed,
                      (v) => set(look.copyWith(speed: v)),
                    ),
                    label(tr('Intensità', 'Strength')),
                    Slider(
                      value: look.intensity,
                      min: .2,
                      max: 1,
                      divisions: 8,
                      label: '${(look.intensity * 100).round()}%',
                      onChanged: (v) => set(look.copyWith(intensity: v)),
                    ),
                    if (!AppSettings.instance.animations)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          tr('Le animazioni sono spente: lo sfondo resta fermo.',
                              'Animations are off, so the background stays still.'),
                          style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                        ),
                      ),
                  ],
                  section(tr('Effetti schermo', 'Screen effects')),
                  _switch(tr('Scanline', 'Scanlines'),
                      tr('Righe sottili come un vecchio monitor', 'Thin lines like an old monitor'),
                      look.scanlines, (v) => set(look.copyWith(scanlines: v))),
                  _switch(tr('Vignettatura', 'Vignette'),
                      tr('Angoli più scuri', 'Darker corners'),
                      look.vignette, (v) => set(look.copyWith(vignette: v))),
                  _switch(tr('Bagliore', 'Glow'),
                      tr('Alone luminoso su logo e risultati nel tema scuro', 'Soft light around logo and results in dark mode'),
                      look.glow, (v) => set(look.copyWith(glow: v))),
                  section(tr('Caratteri', 'Fonts')),
                  label(tr('Titoli', 'Headings')),
                  _fontSeg(look.titleFont, (v) => set(look.copyWith(titleFont: v)), 'Basil'),
                  label(tr('Numeri grandi', 'Big numbers')),
                  _fontSeg(look.digitFont, (v) => set(look.copyWith(digitFont: v)), '1F2A', digits: true),
                  label(tr('Dimensione testo', 'Text size')),
                  _seg<double>(
                    {.9: 'S', 1.0: 'M', 1.15: 'L', 1.3: 'XL'},
                    look.textScale,
                    (v) => set(look.copyWith(textScale: v)),
                  ),
                  section(tr('Forme', 'Shapes')),
                  label(tr('Angoli', 'Corners')),
                  _seg<int>(
                    {0: tr('Squadrati', 'Square'), 1: tr('Morbidi', 'Soft'), 2: tr('Tondi', 'Round')},
                    look.corners,
                    (v) => set(look.copyWith(corners: v)),
                  ),
                  label(tr('Cursore', 'Cursor')),
                  _seg<String>(
                    {'block': '█  ${tr('Blocco', 'Block')}', 'bar': '▏ ${tr('Barra', 'Bar')}', 'under': '_  ${tr('Sotto', 'Under')}'},
                    look.cursor,
                    (v) => set(look.copyWith(cursor: v)),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    tr('Le scelte restano solo su questo dispositivo.',
                        'Your choices stay on this device only.'),
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _switch(String title, String sub, bool v, ValueChanged<bool> f) => SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 4),
        title: Text(title),
        subtitle: Text(sub),
        value: v,
        onChanged: f,
      );

  Widget _seg<T>(Map<T, String> items, T value, ValueChanged<T> f) => SizedBox(
        width: double.infinity,
        child: SegmentedButton<T>(
          showSelectedIcon: false,
          segments: [
            for (final e in items.entries) ButtonSegment(value: e.key, label: Text(e.value, maxLines: 1)),
          ],
          selected: {value},
          onSelectionChanged: (v) => f(v.first),
        ),
      );

  Widget _fontSeg(String value, ValueChanged<String> f, String sample, {bool digits = false}) {
    TextStyle st(String id) => TextStyle(
          fontFamily: fontFor(id),
          fontSize: (digits ? 18 : 13) * (digits ? (id == 'term' ? 1.2 : .9) : titleScale(id)),
          fontWeight: id == 'mono' ? FontWeight.w800 : null,
        );
    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<String>(
        showSelectedIcon: false,
        segments: [
          for (final (id, it, en) in const [('pixel', 'Pixel', 'Pixel'), ('term', 'Terminale', 'Terminal'), ('mono', 'Mono', 'Mono')])
            ButtonSegment(
              value: id,
              label: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(sample, style: st(id), maxLines: 1),
                  Text(tr(it, en), style: const TextStyle(fontSize: 10)),
                ],
              ),
            ),
        ],
        selected: {value},
        onSelectionChanged: (v) => f(v.first),
      ),
    );
  }
}

/// A small live sample of the app with the current look.
class _Preview extends StatelessWidget {
  const _Preview({required this.look});
  final Look look;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final bc = context.bc;
    final dark = context.isDark;
    return ClipRRect(
      borderRadius: look.br(8),
      child: Container(
        height: 190,
        decoration: BoxDecoration(
          border: Border.all(color: cs.outline),
          borderRadius: look.br(8),
          gradient: RadialGradient(
            center: const Alignment(0.8, -1.1),
            radius: 1.6,
            colors: [
              dark ? (look.pureBlack ? Colors.black : look.tone(const Color(0xFF0B2414))) : look.tone(const Color(0xFFDDF2DF)),
              cs.surface,
            ],
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(child: Backdrop(look: look)),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const PixelLeaf(size: 30),
                      const SizedBox(width: 10),
                      Text('BASIL', style: pixelStyle(size: 18, color: cs.primary)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: bc.accent.withAlpha(40),
                          borderRadius: look.br(4),
                        ),
                        child: Text(tr('riporto', 'carry'), style: monoStyle(size: 12, color: bc.accent, weight: FontWeight.w700)),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('101101', style: termStyle(size: 44, color: cs.primary)),
                      Padding(
                        padding: const EdgeInsets.only(left: 3, bottom: 4),
                        child: Text('2', style: monoStyle(size: 15, weight: FontWeight.w700, color: cs.onSurfaceVariant)),
                      ),
                      const SizedBox(width: 4),
                      const Padding(
                        padding: EdgeInsets.only(bottom: 10),
                        child: BlinkCursor(height: 24, width: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      MathText('45 = 2^5 + 2^3 + 2^2 + 2^0', style: monoStyle(size: 13, color: cs.onSurfaceVariant)),
                      const Spacer(),
                      Icon(Icons.check_circle, size: 18, color: bc.ok),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.name,
    required this.look,
    required this.selected,
    required this.onTap,
    this.rainbow = false,
  });
  final String name;
  final Look look;
  final bool selected;
  final VoidCallback onTap;
  final bool rainbow;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final t = buildTheme(Theme.of(context).brightness, look);
    final main = t.colorScheme.primary;
    return Semantics(
      selected: selected,
      button: true,
      label: name,
      child: InkWell(
        onTap: onTap,
        borderRadius: appLook.br(6),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 92,
          padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
          decoration: BoxDecoration(
            color: t.extension<BasilColors>()!.panel,
            borderRadius: appLook.br(6),
            border: Border.all(color: selected ? cs.primary : cs.outlineVariant, width: selected ? 2 : 1),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (rainbow)
                    Container(
                      width: 46,
                      height: 22,
                      decoration: BoxDecoration(
                        borderRadius: appLook.br(4),
                        gradient: LinearGradient(colors: [
                          for (var h = 0; h <= 360; h += 60) HSLColor.fromAHSL(1, h.toDouble(), .9, .55).toColor(),
                        ]),
                      ),
                    )
                  else ...[
                    _dot(main),
                    _dot(t.colorScheme.secondary),
                    _dot(t.extension<BasilColors>()!.accent),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              Text(name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: t.colorScheme.onSurface)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dot(Color c) => Container(
        width: 14,
        height: 22,
        margin: const EdgeInsets.symmetric(horizontal: 1.5),
        decoration: BoxDecoration(color: c, borderRadius: appLook.br(3)),
      );
}

class _HueSlider extends StatelessWidget {
  const _HueSlider({required this.value, required this.onChanged});
  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Positioned(
          left: 24,
          right: 24,
          child: Container(
            height: 10,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5),
              gradient: LinearGradient(colors: [
                for (var h = 0; h <= 360; h += 30) HSLColor.fromAHSL(1, h.toDouble(), .85, .55).toColor(),
              ]),
            ),
          ),
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: Colors.transparent,
            inactiveTrackColor: Colors.transparent,
            thumbColor: HSLColor.fromAHSL(1, value, .85, .55).toColor(),
          ),
          child: Slider(value: value, min: 0, max: 359, onChanged: onChanged),
        ),
      ],
    );
  }
}
