import 'package:flutter/material.dart';

/// A colour palette. [hue] is where the main colour sits on the wheel;
/// every themed colour is rotated from the original basil green to it.
class Palette {
  const Palette(this.id, this.it, this.en, this.hue, {this.mono = false});
  final String id;
  final String it;
  final String en;
  final double hue;
  final bool mono;
}

const double kBasilHue = 139;

const kPalettes = <Palette>[
  Palette('basil', 'Basilico', 'Basil', kBasilHue),
  Palette('mint', 'Menta', 'Mint', 162),
  Palette('cyan', 'Ciano', 'Cyan', 186),
  Palette('ocean', 'Oceano', 'Ocean', 212),
  Palette('violet', 'Viola', 'Violet', 266),
  Palette('magenta', 'Magenta', 'Magenta', 300),
  Palette('amber', 'Ambra', 'Amber', 38),
  Palette('lime', 'Lime', 'Lime', 82),
  Palette('mono', 'Fosforo', 'Phosphor', kBasilHue, mono: true),
];

/// Everything the user can personalise about how Basil looks.
@immutable
class Look {
  const Look({
    this.palette = 'basil',
    this.customHue = 200,
    this.pureBlack = false,
    this.corners = 1,
    this.titleFont = 'pixel',
    this.digitFont = 'term',
    this.cursor = 'block',
    this.textScale = 1.0,
    this.background = 'none',
    this.glyphs = 16,
    this.density = 1,
    this.speed = 1,
    this.intensity = .7,
    this.scanlines = true,
    this.vignette = false,
    this.glow = true,
  });

  final String palette; // a Palette id or 'custom'
  final double customHue;
  final bool pureBlack;
  final int corners; // 0 square, 1 soft, 2 round
  final String titleFont; // pixel | term | mono
  final String digitFont; // term | mono | pixel
  final String cursor; // block | bar | under
  final double textScale;
  final String background; // none | rain | grid | bits | stars
  final int glyphs; // rain alphabet: 2, 8, 16 or 36 symbols
  final int density; // 0 low, 1 normal, 2 high
  final int speed; // 0 slow, 1 normal, 2 fast
  final double intensity; // background strength 0.2 to 1
  final bool scanlines;
  final bool vignette;
  final bool glow;

  Palette? get preset {
    for (final p in kPalettes) {
      if (p.id == palette) return p;
    }
    return null;
  }

  double get hue => palette == 'custom' ? customHue : (preset ?? kPalettes.first).hue;
  bool get mono => preset?.mono ?? false;

  /// Moves a colour designed for basil green to the chosen palette.
  Color tone(Color c) {
    if (palette == 'basil') return c;
    final h = HSLColor.fromColor(c);
    if (mono) return h.withSaturation(h.saturation * .08).toColor();
    return h.withHue((h.hue + hue - kBasilHue) % 360).toColor();
  }

  double radius(double r) => switch (corners) {
        0 => 0,
        2 => r * 2.2,
        _ => r,
      };

  BorderRadius br(double r) => BorderRadius.circular(radius(r));

  Look copyWith({
    String? palette,
    double? customHue,
    bool? pureBlack,
    int? corners,
    String? titleFont,
    String? digitFont,
    String? cursor,
    double? textScale,
    String? background,
    int? glyphs,
    int? density,
    int? speed,
    double? intensity,
    bool? scanlines,
    bool? vignette,
    bool? glow,
  }) =>
      Look(
        palette: palette ?? this.palette,
        customHue: customHue ?? this.customHue,
        pureBlack: pureBlack ?? this.pureBlack,
        corners: corners ?? this.corners,
        titleFont: titleFont ?? this.titleFont,
        digitFont: digitFont ?? this.digitFont,
        cursor: cursor ?? this.cursor,
        textScale: textScale ?? this.textScale,
        background: background ?? this.background,
        glyphs: glyphs ?? this.glyphs,
        density: density ?? this.density,
        speed: speed ?? this.speed,
        intensity: intensity ?? this.intensity,
        scanlines: scanlines ?? this.scanlines,
        vignette: vignette ?? this.vignette,
        glow: glow ?? this.glow,
      );

  Map<String, Object> toJson() => {
        'p': palette,
        'h': customHue,
        'k': pureBlack,
        'c': corners,
        'tf': titleFont,
        'df': digitFont,
        'cu': cursor,
        'ts': textScale,
        'bg': background,
        'g': glyphs,
        'd': density,
        's': speed,
        'i': intensity,
        'sl': scanlines,
        'v': vignette,
        'gl': glow,
      };

  /// Reads saved values, falling back to defaults for anything odd.
  static Look fromJson(Map<String, dynamic> j) {
    const d = Look();
    T pick<T>(String k, T def, bool Function(T v) ok) {
      final v = j[k];
      return (v is T && ok(v)) ? v : def;
    }

    double rd(String k, double def, double lo, double hi) {
      final v = j[k];
      return (v is num && v >= lo && v <= hi) ? v.toDouble() : def;
    }

    final ids = {for (final p in kPalettes) p.id, 'custom'};
    return Look(
      palette: pick<String>('p', d.palette, ids.contains),
      customHue: rd('h', d.customHue, 0, 360),
      pureBlack: pick<bool>('k', d.pureBlack, (_) => true),
      corners: pick<int>('c', d.corners, (v) => v >= 0 && v <= 2),
      titleFont: pick<String>('tf', d.titleFont, const {'pixel', 'term', 'mono'}.contains),
      digitFont: pick<String>('df', d.digitFont, const {'pixel', 'term', 'mono'}.contains),
      cursor: pick<String>('cu', d.cursor, const {'block', 'bar', 'under'}.contains),
      textScale: rd('ts', d.textScale, .85, 1.35),
      background: pick<String>('bg', d.background, const {'none', 'rain', 'grid', 'bits', 'stars'}.contains),
      glyphs: pick<int>('g', d.glyphs, const {2, 8, 16, 36}.contains),
      density: pick<int>('d', d.density, (v) => v >= 0 && v <= 2),
      speed: pick<int>('s', d.speed, (v) => v >= 0 && v <= 2),
      intensity: rd('i', d.intensity, .2, 1),
      scanlines: pick<bool>('sl', d.scanlines, (_) => true),
      vignette: pick<bool>('v', d.vignette, (_) => true),
      glow: pick<bool>('gl', d.glow, (_) => true),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Look && _mapEq(toJson(), other.toJson());

  @override
  int get hashCode => Object.hashAll(toJson().values);
}

bool _mapEq(Map<String, Object> a, Map<String, Object> b) {
  if (a.length != b.length) return false;
  for (final e in a.entries) {
    if (b[e.key] != e.value) return false;
  }
  return true;
}

/// The look in use. Kept as a global like the language so plain helpers
/// such as [termStyle] can read it without a BuildContext.
Look appLook = const Look();
