import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Optional quick-tap "what's affecting this" tags shown under the mood
/// picker — same idea as journal tags, but framed as mood triggers rather
/// than journal subjects.
const kMoodTags = [
  'Work',
  'Sleep',
  'Health',
  'Family',
  'Social',
  'Finance',
  'Exercise',
  'Weather',
  'Stress',
];

/// Icon + label for each mood level (1-5), shared across every screen that
/// displays a logged mood. Uses Font Awesome's "face" set (a proper
/// graduated 1-5 expression scale) instead of Material's flatter sentiment
/// icons or the old AI-generated SVG illustrations.
///
/// Render with [FaIcon], not the plain [Icon] widget — Font Awesome icons
/// are wrapped in [FaIconData] specifically to prevent misrendering in
/// [Icon] (it assumes square glyphs; several FA icons aren't).
FaIconData moodIconFor(int mood) {
  switch (mood) {
    case 1:
      return FontAwesomeIcons.faceSadCry;
    case 2:
      return FontAwesomeIcons.faceFrown;
    case 3:
      return FontAwesomeIcons.faceMeh;
    case 4:
      return FontAwesomeIcons.faceSmile;
    case 5:
      return FontAwesomeIcons.faceLaughBeam;
    default:
      return FontAwesomeIcons.faceMeh;
  }
}

/// A fixed red-to-green sentiment scale, one color per mood level —
/// deliberately independent of the selected [AppPalette] so "terrible"
/// always reads as red and "great" always reads as green, no matter which
/// accent color the user has picked in Settings.
Color moodColorFor(int mood) {
  switch (mood) {
    case 1:
      return const Color(0xFFD65C4F);
    case 2:
      return const Color(0xFFE0894A);
    case 3:
      return const Color(0xFFCDA23A);
    case 4:
      return const Color(0xFF8FB96B);
    case 5:
      return const Color(0xFF3F9463);
    default:
      return const Color(0xFFCDA23A);
  }
}

/// Tinted background version of [moodColorFor], for badges/pills that hold
/// a mood icon — same idea as [AppColors.mintSoft] but per-mood.
Color moodColorSoftFor(int mood, Brightness brightness) {
  return moodColorFor(
    mood,
  ).withValues(alpha: brightness == Brightness.dark ? 0.22 : 0.30);
}

String moodLabelFor(int mood) {
  switch (mood) {
    case 1:
      return 'Terrible';
    case 2:
      return 'Bad';
    case 3:
      return 'Neutral';
    case 4:
      return 'Good';
    case 5:
      return 'Great';
    default:
      return '';
  }
}
