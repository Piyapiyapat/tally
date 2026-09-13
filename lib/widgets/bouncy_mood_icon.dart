import 'package:flutter/material.dart';

/// Wraps a mood icon with a playful bounce-in whenever [moodKey] changes
/// (e.g. a different mood value gets selected, or a fresh entry is saved) —
/// a little life on an otherwise static glyph. Deliberately a one-shot
/// entrance, not a continuous loop: used only on the picker and the saved
/// mood display, not on lists/grids (calendar cells, mood-count rows, the
/// weekly capsule chart) where many icons animating — or re-animating on
/// every scroll rebuild — would be noise rather than delight.
class BouncyMoodIcon extends StatelessWidget {
  final Object moodKey;
  final Widget child;

  const BouncyMoodIcon({
    super.key,
    required this.moodKey,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: ValueKey(moodKey),
      tween: Tween(begin: 0.3, end: 1.0),
      duration: const Duration(milliseconds: 500),
      curve: Curves.elasticOut,
      builder: (context, scale, child) => Transform.scale(
        scale: scale,
        child: child,
      ),
      child: child,
    );
  }
}
