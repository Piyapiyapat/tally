import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/db_service.dart';
import '../theme/app_colors.dart';
import 'auth_screen.dart';

/// Shown once, before the user's very first visit to [AppShell] — lets them
/// choose between continuing without an account (the app already works
/// fully offline) or signing up/logging in right away. The choice is
/// persisted via [DbService.setOnboardingComplete] so this never shows
/// again after either path completes.
class WelcomeScreen extends StatelessWidget {
  final VoidCallback onContinue;

  const WelcomeScreen({super.key, required this.onContinue});

  // [onContinue] only swaps what the app's root route renders (from
  // OnboardingScreen/WelcomeScreen to the signed-in app) — it doesn't touch
  // the Navigator stack. WelcomeScreen (and, when this came via sign-in,
  // AuthScreen) were both *pushed* on top of that root, so without
  // explicitly popping back down to it here, they'd stay stacked on top,
  // hiding the very screen [onContinue] just switched to underneath.
  Future<void> _finishOnboarding(BuildContext context) async {
    await DbService.setOnboardingComplete(true);
    onContinue();
    if (context.mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  Future<void> _signUpOrLogIn(BuildContext context) async {
    final success = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AuthScreen()),
    );
    if (success == true) {
      if (!context.mounted) return;
      await _finishOnboarding(context);
    }
    // Otherwise the user backed out of AuthScreen — it just pops away,
    // leaving them back here on the choice screen.
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const Spacer(flex: 3),
              SvgPicture.asset(
                'assets/images/tally_logo.svg',
                width: 96,
                height: 96,
              ),
              const SizedBox(height: 24),
              Text(
                'Tally',
                style: GoogleFonts.nunito(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: colors.deep,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Track your mood, habits, and thoughts — all in one place.',
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: colors.accent,
                ),
              ),
              const Spacer(flex: 4),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _signUpOrLogIn(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.accent,
                    foregroundColor: colors.onAccent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Sign up / Log in',
                    style: GoogleFonts.nunito(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: colors.onAccent,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _finishOnboarding(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colors.accent,
                    side: BorderSide(color: colors.border),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Continue as Guest',
                    style: GoogleFonts.nunito(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'You can always sign in later from your Profile.',
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: colors.textDim,
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
