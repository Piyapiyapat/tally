import 'package:flutter/material.dart';

/// The selectable color schemes. Each has its own light and dark
/// [AppColors] pair — see [AppColors.of].
enum AppPalette { forest, pink, blue, lavender, sunset }

extension AppPaletteX on AppPalette {
  String get label => switch (this) {
        AppPalette.forest => 'Forest',
        AppPalette.pink => 'Pink',
        AppPalette.blue => 'Blue',
        AppPalette.lavender => 'Lavender',
        AppPalette.sunset => 'Sunset',
      };

  /// Representative color shown on the picker swatch — always the light
  /// theme's accent, so swatches read consistently regardless of the
  /// current brightness mode.
  Color get swatch => switch (this) {
        AppPalette.forest => AppColors.light.accent,
        AppPalette.pink => AppColors.pinkLight.accent,
        AppPalette.blue => AppColors.blueLight.accent,
        AppPalette.lavender => AppColors.lavenderLight.accent,
        AppPalette.sunset => AppColors.sunsetLight.accent,
      };
}

/// Named brand colors for the whole app, registered on [ThemeData.extensions]
/// for both light and dark themes. Values for light mode are the app's
/// original palette (unchanged); dark values come from the approved
/// redesign preview.
class AppColors extends ThemeExtension<AppColors> {
  final Color background;
  final Color surface; // elevated card background (shadow-based cards)
  final Color surfaceFlat; // flat inset fill (text fields, calendar cells)
  final Color mint; // solid mint fill (pills, avatars, days-with-tally, done state)
  final Color mintSoft; // tinted icon-badge background
  final Color onMint; // text/icon drawn on top of mint/mintSoft fills
  final Color accent; // primary interactive color (buttons, active icons)
  final Color onAccent; // text/icon drawn on top of accent-filled surfaces
  final Color deep; // headings / strongest text
  final Color border;
  final Color textDim; // hints, placeholders, muted secondary text
  final Color error;
  final Color onError; // text/icon drawn on top of error-filled surfaces
  final Color errorBg;
  final Color errorBorder;
  final Color danger; // softer red used for delete actions
  final Color navBackground;
  final Color navInactiveIcon;
  final Brightness brightness;

  const AppColors({
    required this.background,
    required this.surface,
    required this.surfaceFlat,
    required this.mint,
    required this.mintSoft,
    required this.onMint,
    required this.accent,
    required this.onAccent,
    required this.deep,
    required this.border,
    required this.textDim,
    required this.error,
    required this.onError,
    required this.errorBg,
    required this.errorBorder,
    required this.danger,
    required this.navBackground,
    required this.navInactiveIcon,
    required this.brightness,
  });

  static const light = AppColors(
    background: Color(0xFFFAF7F0),
    surface: Color(0xFFFFFFFF),
    surfaceFlat: Color(0xFFE8F5EF),
    mint: Color(0xFF9FE1CB),
    mintSoft: Color(0x599FE1CB),
    onMint: Color(0xFF085041),
    accent: Color(0xFF0F6E56),
    onAccent: Color(0xFFFAF7F0),
    deep: Color(0xFF085041),
    border: Color(0xFFCEEADD),
    textDim: Color(0xFF9FE1CB),
    error: Color(0xFFB3574B),
    onError: Colors.white,
    errorBg: Color(0xFFFBEAEA),
    errorBorder: Color(0xFFF0D0CC),
    danger: Color(0xFFDBA8A8),
    navBackground: Color(0xFF0F6E56),
    navInactiveIcon: Color(0xFFFAF7F0),
    brightness: Brightness.light,
  );

  static const dark = AppColors(
    background: Color(0xFF0E1613),
    surface: Color(0xFF1A2420),
    surfaceFlat: Color(0xFF16201C),
    mint: Color(0xFF9FE1CB),
    mintSoft: Color(0x299FE1CB),
    onMint: Color(0xFF085041),
    accent: Color(0xFF3FBE93),
    onAccent: Color(0xFF0E1613),
    deep: Color(0xFFEAF6F1),
    border: Color(0xFF26362F),
    textDim: Color(0xFF8FB3A6),
    error: Color(0xFFE0897D),
    onError: Color(0xFF2A100D),
    errorBg: Color(0xFF3A2420),
    errorBorder: Color(0xFF4A322E),
    danger: Color(0xFFE3B0A8),
    navBackground: Color(0xFF16201C),
    navInactiveIcon: Color(0xFF8FB3A6),
    brightness: Brightness.dark,
  );

  // A warm rose, not a cool fuchsia/magenta — the earlier magenta-leaning
  // pink (hue ~335°) read harshly regardless of brightness; this whole
  // family sits closer to hue ~350° (nearer red than purple).
  static const pinkLight = AppColors(
    background: Color(0xFFFDF2F0),
    surface: Color(0xFFFFFFFF),
    surfaceFlat: Color(0xFFFAE2DE),
    mint: Color(0xFFE8B0B9),
    mintSoft: Color(0x59E8B0B9),
    onMint: Color(0xFF6B1F2A),
    accent: Color(0xFFB23449),
    onAccent: Color(0xFFFDF2F0),
    deep: Color(0xFF6B1F2A),
    border: Color(0xFFF0C9C3),
    textDim: Color(0xFFE8B0B9),
    error: Color(0xFFB3574B),
    onError: Colors.white,
    errorBg: Color(0xFFFBEAEA),
    errorBorder: Color(0xFFF0D0CC),
    danger: Color(0xFFDBA8A8),
    navBackground: Color(0xFFB23449),
    navInactiveIcon: Color(0xFFFDF2F0),
    brightness: Brightness.light,
  );

  static const pinkDark = AppColors(
    background: Color(0xFF1D1210),
    surface: Color(0xFF2A1B17),
    surfaceFlat: Color(0xFF241713),
    mint: Color(0xFFE8B0B9),
    mintSoft: Color(0x29E8B0B9),
    onMint: Color(0xFF6B1F2A),
    accent: Color(0xFFD3697B),
    onAccent: Color(0xFF1D1210),
    deep: Color(0xFFFBEAE6),
    border: Color(0xFF3A2620),
    textDim: Color(0xFFC79A94),
    error: Color(0xFFE0897D),
    onError: Color(0xFF2A100D),
    errorBg: Color(0xFF3A2420),
    errorBorder: Color(0xFF4A322E),
    danger: Color(0xFFE3B0A8),
    navBackground: Color(0xFF241713),
    navInactiveIcon: Color(0xFFC79A94),
    brightness: Brightness.dark,
  );

  static const blueLight = AppColors(
    background: Color(0xFFF2F7FC),
    surface: Color(0xFFFFFFFF),
    surfaceFlat: Color(0xFFE3EEF9),
    mint: Color(0xFFA9CDEE),
    mintSoft: Color(0x59A9CDEE),
    onMint: Color(0xFF0D3D66),
    accent: Color(0xFF1971C2),
    onAccent: Color(0xFFF2F7FC),
    deep: Color(0xFF0D3D66),
    border: Color(0xFFC7DEF3),
    textDim: Color(0xFFA9CDEE),
    error: Color(0xFFB3574B),
    onError: Colors.white,
    errorBg: Color(0xFFFBEAEA),
    errorBorder: Color(0xFFF0D0CC),
    danger: Color(0xFFDBA8A8),
    navBackground: Color(0xFF1971C2),
    navInactiveIcon: Color(0xFFF2F7FC),
    brightness: Brightness.light,
  );

  static const blueDark = AppColors(
    background: Color(0xFF0B141F),
    surface: Color(0xFF16232F),
    surfaceFlat: Color(0xFF121D28),
    mint: Color(0xFFA9CDEE),
    mintSoft: Color(0x29A9CDEE),
    onMint: Color(0xFF0D3D66),
    accent: Color(0xFF4A8FD1),
    onAccent: Color(0xFF0B141F),
    deep: Color(0xFFE7F1FB),
    border: Color(0xFF233244),
    textDim: Color(0xFF87A9C4),
    error: Color(0xFFE0897D),
    onError: Color(0xFF2A100D),
    errorBg: Color(0xFF3A2420),
    errorBorder: Color(0xFF4A322E),
    danger: Color(0xFFE3B0A8),
    navBackground: Color(0xFF121D28),
    navInactiveIcon: Color(0xFF87A9C4),
    brightness: Brightness.dark,
  );

  static const lavenderLight = AppColors(
    background: Color(0xFFF6F2FA),
    surface: Color(0xFFFFFFFF),
    surfaceFlat: Color(0xFFEDE4F7),
    mint: Color(0xFFC9B6E8),
    mintSoft: Color(0x59C9B6E8),
    onMint: Color(0xFF3D2A5C),
    accent: Color(0xFF7C4DBC),
    onAccent: Color(0xFFF6F2FA),
    deep: Color(0xFF3D2A5C),
    border: Color(0xFFDCCBEF),
    textDim: Color(0xFFC9B6E8),
    error: Color(0xFFB3574B),
    onError: Colors.white,
    errorBg: Color(0xFFFBEAEA),
    errorBorder: Color(0xFFF0D0CC),
    danger: Color(0xFFDBA8A8),
    navBackground: Color(0xFF7C4DBC),
    navInactiveIcon: Color(0xFFF6F2FA),
    brightness: Brightness.light,
  );

  static const lavenderDark = AppColors(
    background: Color(0xFF17131E),
    surface: Color(0xFF241D2E),
    surfaceFlat: Color(0xFF1E1826),
    mint: Color(0xFFC9B6E8),
    mintSoft: Color(0x29C9B6E8),
    onMint: Color(0xFF3D2A5C),
    accent: Color(0xFFA87FE0),
    onAccent: Color(0xFF17131E),
    deep: Color(0xFFF0E9F8),
    border: Color(0xFF332A40),
    textDim: Color(0xFFA996C2),
    error: Color(0xFFE0897D),
    onError: Color(0xFF2A100D),
    errorBg: Color(0xFF3A2420),
    errorBorder: Color(0xFF4A322E),
    danger: Color(0xFFE3B0A8),
    navBackground: Color(0xFF1E1826),
    navInactiveIcon: Color(0xFFA996C2),
    brightness: Brightness.dark,
  );

  static const sunsetLight = AppColors(
    background: Color(0xFFFDF6F0),
    surface: Color(0xFFFFFFFF),
    surfaceFlat: Color(0xFFFBE9DC),
    mint: Color(0xFFF5BE93),
    mintSoft: Color(0x59F5BE93),
    onMint: Color(0xFF7A3B12),
    accent: Color(0xFFC2621F),
    onAccent: Color(0xFFFDF6F0),
    deep: Color(0xFF7A3B12),
    border: Color(0xFFF3D5B8),
    textDim: Color(0xFFF5BE93),
    error: Color(0xFFB3574B),
    onError: Colors.white,
    errorBg: Color(0xFFFBEAEA),
    errorBorder: Color(0xFFF0D0CC),
    danger: Color(0xFFDBA8A8),
    navBackground: Color(0xFFC2621F),
    navInactiveIcon: Color(0xFFFDF6F0),
    brightness: Brightness.light,
  );

  static const sunsetDark = AppColors(
    background: Color(0xFF1C1410),
    surface: Color(0xFF2B211A),
    surfaceFlat: Color(0xFF241B15),
    mint: Color(0xFFF5BE93),
    mintSoft: Color(0x29F5BE93),
    onMint: Color(0xFF7A3B12),
    accent: Color(0xFFF0A15C),
    onAccent: Color(0xFF1C1410),
    deep: Color(0xFFFBEADB),
    border: Color(0xFF3D2F24),
    textDim: Color(0xFFC9A788),
    error: Color(0xFFE0897D),
    onError: Color(0xFF2A100D),
    errorBg: Color(0xFF3A2420),
    errorBorder: Color(0xFF4A322E),
    danger: Color(0xFFE3B0A8),
    navBackground: Color(0xFF241B15),
    navInactiveIcon: Color(0xFFC9A788),
    brightness: Brightness.dark,
  );

  /// Looks up the [AppColors] pair for a given [palette] + [brightness].
  static AppColors of(AppPalette palette, Brightness brightness) {
    final isLight = brightness == Brightness.light;
    switch (palette) {
      case AppPalette.forest:
        return isLight ? light : dark;
      case AppPalette.pink:
        return isLight ? pinkLight : pinkDark;
      case AppPalette.blue:
        return isLight ? blueLight : blueDark;
      case AppPalette.lavender:
        return isLight ? lavenderLight : lavenderDark;
      case AppPalette.sunset:
        return isLight ? sunsetLight : sunsetDark;
    }
  }

  /// Soft, tinted layered shadow used on every elevated card. Palette-tinted
  /// in light mode; plain black in dark mode since a tinted shadow wouldn't
  /// read against a dark surface.
  List<BoxShadow> get cardShadow {
    final tint = brightness == Brightness.light ? deep : Colors.black;
    final o1 = brightness == Brightness.light ? 0.08 : 0.35;
    final o2 = brightness == Brightness.light ? 0.22 : 0.55;
    return [
      BoxShadow(
        color: tint.withValues(alpha: o1),
        blurRadius: 5,
        offset: const Offset(0, 2),
      ),
      BoxShadow(
        color: tint.withValues(alpha: o2),
        blurRadius: 32,
        spreadRadius: -10,
        offset: const Offset(0, 16),
      ),
    ];
  }

  /// Bold gradient built from colors every palette already defines — no
  /// palette-specific hero colors to hand-tune. In light mode this reads as
  /// a deep, saturated panel; in dark mode `deep`/`accent` are themselves
  /// light/bright (they're defined as "strongest text" / "interactive
  /// color" against a dark background), so the same formula naturally
  /// becomes a bright glowing panel instead — pair it with [onAccent] text
  /// either way.
  LinearGradient get heroGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [deep, accent],
      );

  /// Stronger shadow for hero-level elements (the greeting panel, primary
  /// CTAs) — deeper than [cardShadow] in light mode, and a soft accent-tinted
  /// glow in dark mode rather than a black shadow that wouldn't show up
  /// against an already-dark background.
  List<BoxShadow> get heroShadow {
    if (brightness == Brightness.light) {
      return [
        BoxShadow(
          color: deep.withValues(alpha: 0.35),
          blurRadius: 24,
          offset: const Offset(0, 10),
        ),
      ];
    }
    return [
      BoxShadow(
        color: accent.withValues(alpha: 0.35),
        blurRadius: 28,
        offset: const Offset(0, 8),
      ),
    ];
  }

  @override
  AppColors copyWith({
    Color? background,
    Color? surface,
    Color? surfaceFlat,
    Color? mint,
    Color? mintSoft,
    Color? onMint,
    Color? accent,
    Color? onAccent,
    Color? deep,
    Color? border,
    Color? textDim,
    Color? error,
    Color? onError,
    Color? errorBg,
    Color? errorBorder,
    Color? danger,
    Color? navBackground,
    Color? navInactiveIcon,
    Brightness? brightness,
  }) {
    return AppColors(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceFlat: surfaceFlat ?? this.surfaceFlat,
      mint: mint ?? this.mint,
      mintSoft: mintSoft ?? this.mintSoft,
      onMint: onMint ?? this.onMint,
      accent: accent ?? this.accent,
      onAccent: onAccent ?? this.onAccent,
      deep: deep ?? this.deep,
      border: border ?? this.border,
      textDim: textDim ?? this.textDim,
      error: error ?? this.error,
      onError: onError ?? this.onError,
      errorBg: errorBg ?? this.errorBg,
      errorBorder: errorBorder ?? this.errorBorder,
      danger: danger ?? this.danger,
      navBackground: navBackground ?? this.navBackground,
      navInactiveIcon: navInactiveIcon ?? this.navInactiveIcon,
      brightness: brightness ?? this.brightness,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceFlat: Color.lerp(surfaceFlat, other.surfaceFlat, t)!,
      mint: Color.lerp(mint, other.mint, t)!,
      mintSoft: Color.lerp(mintSoft, other.mintSoft, t)!,
      onMint: Color.lerp(onMint, other.onMint, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
      deep: Color.lerp(deep, other.deep, t)!,
      border: Color.lerp(border, other.border, t)!,
      textDim: Color.lerp(textDim, other.textDim, t)!,
      error: Color.lerp(error, other.error, t)!,
      onError: Color.lerp(onError, other.onError, t)!,
      errorBg: Color.lerp(errorBg, other.errorBg, t)!,
      errorBorder: Color.lerp(errorBorder, other.errorBorder, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      navBackground: Color.lerp(navBackground, other.navBackground, t)!,
      navInactiveIcon: Color.lerp(navInactiveIcon, other.navInactiveIcon, t)!,
      brightness: t < 0.5 ? brightness : other.brightness,
    );
  }
}

extension AppColorsX on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
}
