import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

/// A row of filled/unfilled circles showing how many PIN digits have been
/// entered so far.
class PinDots extends StatelessWidget {
  final int length;
  final int filled;

  const PinDots({super.key, required this.length, required this.filled});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(length, (i) {
        final isFilled = i < filled;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isFilled ? colors.accent : Colors.transparent,
            border: Border.all(color: colors.accent, width: 1.5),
          ),
        );
      }),
    );
  }
}

/// A 3x4 numeric keypad (1-9, an optional extra action, 0, backspace) shared
/// between the lock screen and the set-PIN screen.
class PinPad extends StatelessWidget {
  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;
  final Widget? extraAction;

  const PinPad({
    super.key,
    required this.onDigit,
    required this.onBackspace,
    this.extraAction,
  });

  Widget _key(
    BuildContext context, {
    String? label,
    IconData? icon,
    VoidCallback? onTap,
  }) {
    final colors = context.colors;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.all(8),
          height: 64,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: onTap == null ? Colors.transparent : colors.surfaceFlat,
          ),
          child: icon != null
              ? Icon(icon, color: colors.deep)
              : label != null
                  ? Text(
                      label,
                      style: GoogleFonts.nunito(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: colors.deep,
                      ),
                    )
                  : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(children: [
          _key(context, label: '1', onTap: () => onDigit('1')),
          _key(context, label: '2', onTap: () => onDigit('2')),
          _key(context, label: '3', onTap: () => onDigit('3')),
        ]),
        Row(children: [
          _key(context, label: '4', onTap: () => onDigit('4')),
          _key(context, label: '5', onTap: () => onDigit('5')),
          _key(context, label: '6', onTap: () => onDigit('6')),
        ]),
        Row(children: [
          _key(context, label: '7', onTap: () => onDigit('7')),
          _key(context, label: '8', onTap: () => onDigit('8')),
          _key(context, label: '9', onTap: () => onDigit('9')),
        ]),
        Row(children: [
          Expanded(child: extraAction ?? const SizedBox()),
          _key(context, label: '0', onTap: () => onDigit('0')),
          _key(context, icon: Icons.backspace_outlined, onTap: onBackspace),
        ]),
      ],
    );
  }
}
