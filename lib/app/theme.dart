import 'package:flutter/material.dart';

const kBody = 'JetBrainsMono';
const kPixel = 'Silkscreen';
const kTerm = 'VT323';
const kFallback = [kBody];

/// Extra semantic colours not covered by [ColorScheme].
@immutable
class BasilColors extends ThemeExtension<BasilColors> {
  const BasilColors({
    required this.ok,
    required this.bad,
    required this.accent,
    required this.glow,
    required this.panel,
    required this.panelHi,
    required this.grid,
  });
  final Color ok;
  final Color bad;
  final Color accent; // carries, remainders, highlights (amber)
  final Color glow;
  final Color panel;
  final Color panelHi;
  final Color grid;

  @override
  BasilColors copyWith() => this;

  @override
  BasilColors lerp(ThemeExtension<BasilColors>? other, double t) {
    if (other is! BasilColors) return this;
    return BasilColors(
      ok: Color.lerp(ok, other.ok, t)!,
      bad: Color.lerp(bad, other.bad, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      glow: Color.lerp(glow, other.glow, t)!,
      panel: Color.lerp(panel, other.panel, t)!,
      panelHi: Color.lerp(panelHi, other.panelHi, t)!,
      grid: Color.lerp(grid, other.grid, t)!,
    );
  }
}

extension BasilThemeX on BuildContext {
  BasilColors get bc => Theme.of(this).extension<BasilColors>()!;
  ColorScheme get cs => Theme.of(this).colorScheme;
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}

const _darkBasil = BasilColors(
  ok: Color(0xFF3DFF7A),
  bad: Color(0xFFFF4D6D),
  accent: Color(0xFFFFB000),
  glow: Color(0xFF3DFF7A),
  panel: Color(0xFF0B150E),
  panelHi: Color(0xFF112016),
  grid: Color(0xFF1B3322),
);

const _lightBasil = BasilColors(
  ok: Color(0xFF0E8A3E),
  bad: Color(0xFFC81E45),
  accent: Color(0xFFB86E00),
  glow: Color(0xFF17A34A),
  panel: Color(0xFFFFFFFF),
  panelHi: Color(0xFFEAF5E8),
  grid: Color(0xFFC9DECB),
);

ThemeData buildTheme(Brightness b) {
  final dark = b == Brightness.dark;
  final cs = dark
      ? const ColorScheme(
          brightness: Brightness.dark,
          primary: Color(0xFF3DFF7A),
          onPrimary: Color(0xFF02180A),
          primaryContainer: Color(0xFF0F3D1E),
          onPrimaryContainer: Color(0xFFB8FFCB),
          secondary: Color(0xFFA6FF00),
          onSecondary: Color(0xFF142000),
          secondaryContainer: Color(0xFF213300),
          onSecondaryContainer: Color(0xFFDBFF9E),
          tertiary: Color(0xFFFFB000),
          onTertiary: Color(0xFF2A1A00),
          error: Color(0xFFFF4D6D),
          onError: Color(0xFF2B0010),
          surface: Color(0xFF060B07),
          onSurface: Color(0xFFD3F8DA),
          onSurfaceVariant: Color(0xFF8FB89A),
          surfaceContainerLowest: Color(0xFF040805),
          surfaceContainerLow: Color(0xFF09120B),
          surfaceContainer: Color(0xFF0C170F),
          surfaceContainerHigh: Color(0xFF102014),
          surfaceContainerHighest: Color(0xFF142919),
          outline: Color(0xFF2A5236),
          outlineVariant: Color(0xFF1B3322),
          inverseSurface: Color(0xFFD3F8DA),
          onInverseSurface: Color(0xFF060B07),
          shadow: Colors.black,
        )
      : const ColorScheme(
          brightness: Brightness.light,
          primary: Color(0xFF0B7A36),
          onPrimary: Color(0xFFFFFFFF),
          primaryContainer: Color(0xFFC6F0CF),
          onPrimaryContainer: Color(0xFF00290F),
          secondary: Color(0xFF4A7F00),
          onSecondary: Color(0xFFFFFFFF),
          secondaryContainer: Color(0xFFDDF3B8),
          onSecondaryContainer: Color(0xFF142000),
          tertiary: Color(0xFFB86E00),
          onTertiary: Color(0xFFFFFFFF),
          error: Color(0xFFC81E45),
          onError: Color(0xFFFFFFFF),
          surface: Color(0xFFF2F8F0),
          onSurface: Color(0xFF0B1F12),
          onSurfaceVariant: Color(0xFF41594A),
          surfaceContainerLowest: Color(0xFFFFFFFF),
          surfaceContainerLow: Color(0xFFF7FBF6),
          surfaceContainer: Color(0xFFEDF5EB),
          surfaceContainerHigh: Color(0xFFE5F0E3),
          surfaceContainerHighest: Color(0xFFDCEADA),
          outline: Color(0xFF9DBDA3),
          outlineVariant: Color(0xFFC9DECB),
          inverseSurface: Color(0xFF0B1F12),
          onInverseSurface: Color(0xFFF2F8F0),
          shadow: Color(0x33000000),
        );

  final base = ThemeData(
    useMaterial3: true,
    colorScheme: cs,
    brightness: b,
    fontFamily: kBody,
    scaffoldBackgroundColor: cs.surface,
  );
  final t = base.textTheme;
  TextStyle? px(TextStyle? s, double size) => s?.copyWith(
      fontFamily: kPixel,
      fontFamilyFallback: kFallback,
      fontSize: size,
      letterSpacing: 0.5,
      height: 1.25);

  const radius = BorderRadius.all(Radius.circular(6));
  final border = OutlineInputBorder(
    borderRadius: radius,
    borderSide: BorderSide(color: cs.outline),
  );

  return base.copyWith(
    extensions: [dark ? _darkBasil : _lightBasil],
    textTheme: t.copyWith(
      displaySmall: px(t.displaySmall, 30),
      headlineMedium: px(t.headlineMedium, 24),
      headlineSmall: px(t.headlineSmall, 20),
      titleLarge: px(t.titleLarge, 17),
      titleMedium: t.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      bodyLarge: t.bodyLarge?.copyWith(height: 1.5),
      bodyMedium: t.bodyMedium?.copyWith(height: 1.45),
      labelLarge: t.labelLarge?.copyWith(
          fontWeight: FontWeight.w700, letterSpacing: 0.6),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: px(t.titleLarge, 18)?.copyWith(color: cs.onSurface),
      foregroundColor: cs.onSurface,
    ),
    cardTheme: CardThemeData(
      color: dark ? _darkBasil.panel : _lightBasil.panel,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: cs.outlineVariant),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: border,
      enabledBorder: border,
      focusedBorder: border.copyWith(
          borderSide: BorderSide(color: cs.primary, width: 2)),
      errorBorder:
          border.copyWith(borderSide: BorderSide(color: cs.error, width: 1.5)),
      filled: true,
      fillColor: dark ? const Color(0xFF07100A) : Colors.white,
      isDense: true,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: const RoundedRectangleBorder(borderRadius: radius),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        textStyle: const TextStyle(
            fontFamily: kBody, fontWeight: FontWeight.w800, letterSpacing: 0.8),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: const RoundedRectangleBorder(borderRadius: radius),
        side: BorderSide(color: cs.outline),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        textStyle: const TextStyle(
            fontFamily: kBody, fontWeight: FontWeight.w700, letterSpacing: 0.6),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        shape: const RoundedRectangleBorder(borderRadius: radius),
        textStyle:
            const TextStyle(fontFamily: kBody, fontWeight: FontWeight.w700),
      ),
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(
          borderRadius: radius, side: BorderSide(color: cs.outline)),
      side: BorderSide(color: cs.outline),
      labelStyle: TextStyle(
          fontFamily: kBody, fontWeight: FontWeight.w700, color: cs.onSurface),
      selectedColor: cs.primaryContainer,
      checkmarkColor: cs.primary,
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        shape: const RoundedRectangleBorder(borderRadius: radius),
        side: BorderSide(color: cs.outline),
        selectedBackgroundColor: cs.primaryContainer,
        selectedForegroundColor: cs.onPrimaryContainer,
        textStyle: const TextStyle(
            fontFamily: kBody, fontWeight: FontWeight.w800, fontSize: 13),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: dark ? const Color(0xF0050906) : const Color(0xF2FFFFFF),
      surfaceTintColor: Colors.transparent,
      indicatorColor: cs.primaryContainer,
      indicatorShape: const RoundedRectangleBorder(borderRadius: radius),
      height: 68,
      labelTextStyle: WidgetStateProperty.resolveWith((s) => TextStyle(
            fontFamily: kPixel,
            fontFamilyFallback: kFallback,
            fontSize: 11,
            color: s.contains(WidgetState.selected)
                ? cs.primary
                : cs.onSurfaceVariant,
          )),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: dark ? const Color(0xF0050906) : const Color(0xF2FFFFFF),
      indicatorColor: cs.primaryContainer,
      indicatorShape: const RoundedRectangleBorder(borderRadius: radius),
      selectedLabelTextStyle: TextStyle(
          fontFamily: kPixel,
          fontFamilyFallback: kFallback,
          fontSize: 12,
          color: cs.primary),
      unselectedLabelTextStyle: TextStyle(
          fontFamily: kPixel,
          fontFamilyFallback: kFallback,
          fontSize: 12,
          color: cs.onSurfaceVariant),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.selected) ? cs.onPrimary : cs.outline),
      trackColor: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.selected) ? cs.primary : cs.surfaceContainerHighest),
      trackOutlineColor: WidgetStateProperty.all(cs.outline),
    ),
    dividerTheme: DividerThemeData(color: cs.outlineVariant, space: 1),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: cs.inverseSurface,
      contentTextStyle: TextStyle(
          fontFamily: kBody, color: cs.onInverseSurface, fontWeight: FontWeight.w700),
      shape: const RoundedRectangleBorder(borderRadius: radius),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: dark ? _darkBasil.panel : _lightBasil.panel,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
          borderRadius: radius, side: BorderSide(color: cs.outline)),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: dark ? _darkBasil.panel : _lightBasil.panel,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
          side: BorderSide(color: cs.outline)),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: cs.primary,
      linearTrackColor: cs.surfaceContainerHighest,
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
          color: cs.inverseSurface, borderRadius: radius),
      textStyle: TextStyle(fontFamily: kBody, color: cs.onInverseSurface, fontSize: 12),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(builders: {
      TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
      TargetPlatform.iOS: FadeForwardsPageTransitionsBuilder(),
      TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
      TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
      TargetPlatform.macOS: FadeForwardsPageTransitionsBuilder(),
    }),
  );
}

/// Monospace style for digits (JetBrains Mono, tabular figures).
TextStyle monoStyle({double size = 18, Color? color, FontWeight? weight}) {
  return TextStyle(
    fontFamily: kBody,
    fontSize: size,
    color: color,
    fontWeight: weight,
    fontFeatures: const [FontFeature.tabularFigures()],
  );
}

/// Big terminal-style digits (VT323).
TextStyle termStyle({double size = 32, Color? color, double? height}) {
  return TextStyle(
    fontFamily: kTerm,
    fontFamilyFallback: kFallback,
    fontSize: size,
    color: color,
    height: height ?? 1.0,
  );
}

/// Pixel headline style (Silkscreen).
TextStyle pixelStyle({double size = 14, Color? color, FontWeight? weight}) {
  return TextStyle(
    fontFamily: kPixel,
    fontFamilyFallback: kFallback,
    fontSize: size,
    color: color,
    fontWeight: weight,
    letterSpacing: 0.6,
  );
}
