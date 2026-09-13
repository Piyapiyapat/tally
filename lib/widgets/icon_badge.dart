import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../theme/app_colors.dart';

/// A circular, softly-tinted backdrop for a leading icon — used instead of
/// a bare icon on cards, per the approved redesign. Use the default
/// constructor for a normal Material [IconData], or [IconBadge.fa] for a
/// Font Awesome icon (e.g. one of the mood face icons from `mood_style.dart`).
class IconBadge extends StatelessWidget {
  final IconData? icon;
  final FaIconData? faIcon;
  final double size;
  final double iconSize;

  const IconBadge({
    super.key,
    required IconData this.icon,
    this.size = 36,
    this.iconSize = 19,
  }) : faIcon = null;

  const IconBadge.fa({
    super.key,
    required FaIconData this.faIcon,
    this.size = 36,
    this.iconSize = 19,
  }) : icon = null;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.mintSoft,
        borderRadius: BorderRadius.circular(size * 0.32),
      ),
      child: icon != null
          ? Icon(icon, size: iconSize, color: colors.accent)
          : FaIcon(faIcon, size: iconSize, color: colors.accent),
    );
  }
}
