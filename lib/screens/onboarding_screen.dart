import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import 'welcome_screen.dart';

class _OnboardingSlide {
  final IconData icon;
  final String title;
  final String description;
  const _OnboardingSlide({
    required this.icon,
    required this.title,
    required this.description,
  });
}

const _slides = [
  _OnboardingSlide(
    icon: Icons.mood_outlined,
    title: 'Track your mood',
    description:
        'Log how you\'re feeling each day, add a quick note, and start '
        'noticing the patterns behind your good and bad days.',
  ),
  _OnboardingSlide(
    icon: Icons.repeat_outlined,
    title: 'Build better habits',
    description:
        'Create the habits you want to stick with, and check them off '
        'as you go — see your streaks build day by day.',
  ),
  _OnboardingSlide(
    icon: Icons.menu_book_outlined,
    title: 'Write it down',
    description:
        'Keep a journal of your thoughts and days, tagged and organized '
        'by month so you can always find your way back to them.',
  ),
  _OnboardingSlide(
    icon: Icons.insights_outlined,
    title: 'See your patterns',
    description:
        'Insights connect the dots between your mood, habits, and '
        'journaling — so you can see what actually helps.',
  ),
];

/// Shown once, right before [WelcomeScreen], to give a first-time user a
/// quick tour of the app's four core features before asking them to choose
/// an account path.
class OnboardingScreen extends StatefulWidget {
  final VoidCallback onContinue;
  const OnboardingScreen({super.key, required this.onContinue});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _page = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _next() {
    if (_page == _slides.length - 1) {
      _goToWelcome();
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _goToWelcome() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WelcomeScreen(onContinue: widget.onContinue),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isLast = _page == _slides.length - 1;

    return Scaffold(
      backgroundColor: colors.background,
      body: DecoratedBox(
        // A whisper of a gradient, not a splash of color — just enough to
        // keep a plain flat background from feeling bare.
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colors.background,
              Color.lerp(colors.background, colors.mintSoft, 0.6)!,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 8, top: 4),
                  child: TextButton(
                    onPressed: _goToWelcome,
                    child: Text(
                      'Skip',
                      style: GoogleFonts.nunito(
                        fontWeight: FontWeight.w600,
                        color: colors.accent,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _slides.length,
                  onPageChanged: (i) => setState(() => _page = i),
                  itemBuilder: (context, i) {
                    return AnimatedBuilder(
                      animation: _pageController,
                      builder: (context, child) {
                        var offset = (_page - i).toDouble();
                        if (_pageController.hasClients &&
                            _pageController.position.haveDimensions) {
                          offset = (_pageController.page ?? _page.toDouble()) - i;
                        }
                        final distance = offset.abs().clamp(0.0, 1.0);
                        return Opacity(
                          opacity: 1 - distance * 0.6,
                          child: Transform.scale(
                            scale: 1 - distance * 0.12,
                            child: child,
                          ),
                        );
                      },
                      child: _SlideView(slide: _slides[i]),
                    );
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_slides.length, (i) {
                  final selected = i == _page;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOutCubic,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: selected ? 22 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: selected ? colors.accent : colors.border,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: DecoratedBox(
                    // Reuses the app's existing hero-panel gradient tokens
                    // rather than inventing a new color combo.
                    decoration: BoxDecoration(
                      gradient: colors.heroGradient,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: colors.heroShadow,
                    ),
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: _next,
                        child: Center(
                          child: Text(
                            isLast ? 'Get started' : 'Next',
                            style: GoogleFonts.nunito(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: colors.onAccent,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SlideView extends StatefulWidget {
  final _OnboardingSlide slide;
  const _SlideView({required this.slide});

  @override
  State<_SlideView> createState() => _SlideViewState();
}

class _SlideViewState extends State<_SlideView>
    with TickerProviderStateMixin {
  late final _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..forward();
  late final _float = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat(reverse: true);

  late final _iconScale = CurvedAnimation(
    parent: _entrance,
    curve: const Interval(0.0, 0.75, curve: Curves.easeOutBack),
  );
  late final _textFade = CurvedAnimation(
    parent: _entrance,
    curve: const Interval(0.35, 1.0, curve: Curves.easeOut),
  );
  late final _floatOffset = Tween(begin: -7.0, end: 7.0).animate(
    CurvedAnimation(parent: _float, curve: Curves.easeInOut),
  );

  @override
  void dispose() {
    _entrance.dispose();
    _float.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: Listenable.merge([_entrance, _float]),
            builder: (context, child) => Transform.translate(
              offset: Offset(0, _floatOffset.value),
              child: Transform.scale(
                scale: _iconScale.value,
                child: Opacity(
                  opacity: _entrance.value.clamp(0.0, 1.0),
                  child: child,
                ),
              ),
            ),
            child: _GlowIcon(icon: widget.slide.icon, colors: colors),
          ),
          const SizedBox(height: 36),
          FadeTransition(
            opacity: _textFade,
            child: SlideTransition(
              position: _textFade.drive(
                Tween(begin: const Offset(0, 0.12), end: Offset.zero),
              ),
              child: Column(
                children: [
                  Text(
                    widget.slide.title,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.nunito(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: colors.deep,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.slide.description,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: colors.accent,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A soft radial glow behind a gently gradient-filled circular badge —
/// built from the same tokens the rest of the app already uses (mint,
/// surface, cardShadow), just composed for a bit more depth than a flat
/// icon badge.
class _GlowIcon extends StatelessWidget {
  final IconData icon;
  final AppColors colors;
  const _GlowIcon({required this.icon, required this.colors});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  colors.mint.withValues(alpha: 0.32),
                  colors.mint.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
          Container(
            width: 132,
            height: 132,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [colors.surface, colors.mintSoft],
              ),
              boxShadow: colors.cardShadow,
            ),
            child: Icon(icon, size: 60, color: colors.accent),
          ),
        ],
      ),
    );
  }
}
