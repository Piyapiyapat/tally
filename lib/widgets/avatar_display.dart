import 'dart:io';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Renders the user's chosen profile picture, or a mint initials circle as
/// a fallback. [pictureValue] is the raw string stored via
/// `DbService.getProfilePicture()` — `file:<path>` for a photo taken or
/// picked from the device, `asset:<path>` for a bundled default avatar.
class AvatarImage extends StatelessWidget {
  final String? pictureValue;
  final String initials;
  final double size;

  const AvatarImage({
    super.key,
    required this.pictureValue,
    required this.initials,
    this.size = 64,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final value = pictureValue;

    Widget child;
    if (value != null && value.startsWith('file:')) {
      child = ClipOval(
        child: Image.file(
          File(value.substring(5)),
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _initialsCircle(colors),
        ),
      );
    } else if (value != null && value.startsWith('asset:')) {
      child = ClipOval(
        child: Image.asset(
          value.substring(6),
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _initialsCircle(colors),
        ),
      );
    } else {
      child = _initialsCircle(colors);
    }

    return SizedBox(width: size, height: size, child: child);
  }

  Widget _initialsCircle(AppColors colors) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: colors.mint, shape: BoxShape.circle),
      child: Text(
        initials,
        style: TextStyle(
          fontSize: size * 0.4,
          fontWeight: FontWeight.w800,
          color: colors.onMint,
        ),
      ),
    );
  }
}
