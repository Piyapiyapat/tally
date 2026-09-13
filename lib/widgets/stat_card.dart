import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'icon_badge.dart';

class StatCard extends StatelessWidget {
  final IconData? icon;
  final FaIconData? faIcon;
  final String value;
  final String label;
  final VoidCallback? onTap;

  const StatCard({
    super.key,
    required IconData this.icon,
    required this.value,
    required this.label,
    this.onTap,
  }) : faIcon = null;

  const StatCard.fa({
    super.key,
    required FaIconData this.faIcon,
    required this.value,
    required this.label,
    this.onTap,
  }) : icon = null;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(kCardRadius),
          boxShadow: colors.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            icon != null
                ? IconBadge(icon: icon!, size: 40, iconSize: 22)
                : IconBadge.fa(faIcon: faIcon!, size: 40, iconSize: 22),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.nunito(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: colors.deep,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.nunito(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colors.accent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
