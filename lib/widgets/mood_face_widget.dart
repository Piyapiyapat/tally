import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../theme/app_colors.dart';
import '../utils/mood_style.dart';
import 'bouncy_mood_icon.dart';

/// One face in the 5-mood picker: a circular badge around a sentiment icon,
/// filled/accent-colored when selected, outlined/muted otherwise. Bounces
/// in whenever its selected state flips.
class MoodFaceWidget extends StatelessWidget {
  final int value;
  final bool isSelected;
  final double size;

  const MoodFaceWidget({
    super.key,
    required this.value,
    required this.isSelected,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isSelected ? colors.mint : colors.surfaceFlat,
        border: Border.all(
          color: isSelected ? colors.mint : colors.border,
          width: 1.5,
        ),
      ),
      child: BouncyMoodIcon(
        moodKey: '$value-$isSelected',
        child: FaIcon(
          moodIconFor(value),
          size: size * 0.5,
          color: isSelected ? colors.onMint : colors.textDim,
        ),
      ),
    );
  }
}
