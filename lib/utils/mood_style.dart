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
