import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Corner radius for elevated (shadow-based) cards, per the approved
/// redesign — larger than the old flat-bordered card radius (16).
const double kCardRadius = 22.0;

ThemeData buildAppTheme(AppColors colors) {
  final navLabelStyle = WidgetStateProperty.resolveWith((states) {
    if (states.contains(WidgetState.selected)) {
      return GoogleFonts.nunito(
        color: colors.deep,
        fontWeight: FontWeight.w700,
        fontSize: 12,
      );
    }
    return GoogleFonts.nunito(
      color: colors.accent,
      fontWeight: FontWeight.w500,
      fontSize: 12,
    );
  });

  return ThemeData(
    brightness: colors.brightness,
    scaffoldBackgroundColor: colors.background,
    colorScheme: ColorScheme.fromSeed(
      seedColor: colors.accent,
      brightness: colors.brightness,
      surface: colors.background,
    ),
    textTheme: GoogleFonts.nunitoTextTheme(
      colors.brightness == Brightness.dark
          ? ThemeData(brightness: Brightness.dark).textTheme
          : ThemeData(brightness: Brightness.light).textTheme,
    ),
    navigationBarTheme: NavigationBarThemeData(labelTextStyle: navLabelStyle),
    useMaterial3: true,
    extensions: [colors],
  );
}
