import 'dart:async';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../utils/mood_style.dart';
import '../widgets/icon_badge.dart';
import '../widgets/mood_face_widget.dart';
import 'welcome_screen.dart';

class _OnboardingSlide {
  final Widget preview;
  final String title;
  final String description;
  const _OnboardingSlide({
    required this.preview,
    required this.title,
    required this.description,
  });
}

final _slides = [
  _OnboardingSlide(
    preview: const _MoodPreview(),
    title: 'Track your mood',
    description:
        'Log how you\'re feeling each day, add a quick note, and start '
        'noticing the patterns behind your good and bad days.',
  ),
  _OnboardingSlide(
    preview: const _HabitsPreview(),
    title: 'Build better habits',
    description:
        'Create the habits you want to stick with, and check them off '
        'as you go — see them build up day by day.',
  ),
  _OnboardingSlide(
    preview: const _JournalPreview(),
    title: 'Write it down',
    description:
        'Keep a journal of your thoughts and days, tagged and organized '
        'by month so you can always find your way back to them.',
  ),
  _OnboardingSlide(
    preview: const _InsightsPreview(),
    title: 'See your patterns',
    description:
        'Insights connect the dots between your mood, habits, and '
        'journaling — so you can see what actually helps.',
  ),
];

/// Shown once, right before [WelcomeScreen], to give a first-time user a
/// quick tour of the app's four core features before asking them to choose
/// an account path. Each slide previews the real feature (a mood pick, a
/// habit list, a journal entry, a trend chart) with the app's actual
/// colors/icons/components, rather than a generic icon badge.
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
                          offset =
                              (_pageController.page ?? _page.toDouble()) - i;
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

class _SlideViewState extends State<_SlideView> with TickerProviderStateMixin {
  late final _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..forward();
  late final _float = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat(reverse: true);

  late final _previewScale = CurvedAnimation(
    parent: _entrance,
    curve: const Interval(0.0, 0.75, curve: Curves.easeOutBack),
  );
  late final _textFade = CurvedAnimation(
    parent: _entrance,
    curve: const Interval(0.35, 1.0, curve: Curves.easeOut),
  );
  late final _floatOffset = Tween(
    begin: -5.0,
    end: 5.0,
  ).animate(CurvedAnimation(parent: _float, curve: Curves.easeInOut));

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
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: Listenable.merge([_entrance, _float]),
            builder: (context, child) => Transform.translate(
              offset: Offset(0, _floatOffset.value),
              child: Transform.scale(
                scale: _previewScale.value,
                child: Opacity(
                  opacity: _entrance.value.clamp(0.0, 1.0),
                  child: child,
                ),
              ),
            ),
            child: widget.slide.preview,
          ),
          const SizedBox(height: 32),
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

/// Slide 1 preview: the real 5-face mood picker (see [MoodFaceWidget]),
/// cycling which face is picked — plus a matching note — so the slide shows
/// the actual tap-to-select motion instead of a frozen choice.
class _MoodPreview extends StatefulWidget {
  const _MoodPreview();

  @override
  State<_MoodPreview> createState() => _MoodPreviewState();
}

class _MoodPreviewState extends State<_MoodPreview> {
  static const _sequence = [3, 4, 5, 4];
  static const _notes = {
    3: 'Feeling pretty okay today',
    4: "Feeling good about today's progress",
    5: 'Had a really great day!',
  };

  int _step = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 1700), (_) {
      setState(() => _step = (_step + 1) % _sequence.length);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final selected = _sequence[_step];
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            for (var m = 1; m <= 5; m++)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: MoodFaceWidget(
                  value: m,
                  isSelected: m == selected,
                  size: m == selected ? 50 : 32,
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 280),
          child: Container(
            key: ValueKey(selected),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(14),
              boxShadow: colors.cardShadow,
            ),
            child: Text(
              _notes[selected] ?? '',
              style: GoogleFonts.nunito(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colors.deep,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Slide 2 preview: habit rows styled like the real Home habit list — mint
/// fill once done, flat otherwise — with the last one actually toggling on
/// a loop so the slide shows a habit being checked off, not just a list.
class _HabitsPreview extends StatefulWidget {
  const _HabitsPreview();

  @override
  State<_HabitsPreview> createState() => _HabitsPreviewState();
}

class _HabitsPreviewState extends State<_HabitsPreview> {
  bool _readingDone = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 2100), (_) {
      setState(() => _readingDone = !_readingDone);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Widget _row(
    AppColors colors, {
    required IconData icon,
    required String name,
    required bool done,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      width: 220,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: done ? colors.mint : colors.surfaceFlat,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: done ? colors.onMint : colors.accent),
          const SizedBox(width: 10),
          Expanded(
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 320),
              style: GoogleFonts.nunito(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: done ? colors.onMint : colors.deep,
              ),
              child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ),
          AnimatedScale(
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeOutBack,
            scale: done ? 1 : 0,
            child: Icon(Icons.check_circle, size: 16, color: colors.onMint),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _row(colors, icon: Icons.local_drink, name: 'Drink water', done: true),
        _row(
          colors,
          icon: Icons.directions_run,
          name: 'Morning run',
          done: true,
        ),
        _row(
          colors,
          icon: Icons.menu_book,
          name: 'Read 20 pages',
          done: _readingDone,
        ),
      ],
    );
  }
}

/// Slide 3 preview: a journal entry card laid out like the real Journal
/// list item — icon badge, title/time, mood icon, tag chip, excerpt — with
/// the tag cycling to hint that entries get tagged and organized.
class _JournalPreview extends StatefulWidget {
  const _JournalPreview();

  @override
  State<_JournalPreview> createState() => _JournalPreviewState();
}

class _JournalPreviewState extends State<_JournalPreview> {
  static const _tags = ['Work', 'Reflection', 'Wins'];
  int _tagIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 1900), (_) {
      setState(() => _tagIndex = (_tagIndex + 1) % _tags.length);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: 240,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: colors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const IconBadge(icon: Icons.menu_book_outlined),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'A good day',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.nunito(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: colors.deep,
                      ),
                    ),
                    Text(
                      'Today, 9:40 PM',
                      style: GoogleFonts.nunito(
                        fontSize: 11,
                        color: colors.accent,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 1),
                child: FaIcon(moodIconFor(4), size: 15, color: moodColorFor(4)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SizeTransition(
                sizeFactor: animation,
                axis: Axis.horizontal,
                child: child,
              ),
            ),
            child: Container(
              key: ValueKey(_tagIndex),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: colors.surfaceFlat,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _tags[_tagIndex],
                style: GoogleFonts.nunito(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: colors.accent,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "Finally wrapped up the project I've been stuck on for weeks.",
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.nunito(
              fontSize: 12.5,
              color: colors.accent,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

/// Slide 4 preview: a weekly mood-trend bar chart matching the real one on
/// the Statistics screen — bars colored by [moodColorFor], best day ringed —
/// with today's bar (the last one) still moving, as if today's mood just
/// got logged and the trend updated live.
class _InsightsPreview extends StatefulWidget {
  const _InsightsPreview();

  @override
  State<_InsightsPreview> createState() => _InsightsPreviewState();
}

class _InsightsPreviewState extends State<_InsightsPreview> {
  static const _leadingMoods = [3, 4, 2, 4, 5, 4];
  static const _todayValues = [3, 5];
  static const _dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  int _todayStep = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 1900), (_) {
      setState(() => _todayStep = (_todayStep + 1) % _todayValues.length);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Widget _bar(AppColors colors, int mood, {required bool isBest}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
      width: 18,
      height: 16.0 + (mood - 1) * 11.0,
      decoration: BoxDecoration(
        color: moodColorFor(mood),
        borderRadius: BorderRadius.circular(8),
        border: isBest ? Border.all(color: colors.deep, width: 2) : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final weekMoods = [..._leadingMoods, _todayValues[_todayStep]];
    final bestValue = weekMoods.reduce((a, b) => a > b ? a : b);
    return Container(
      width: 250,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: colors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mood trend · this week',
            style: GoogleFonts.nunito(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: colors.accent,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final m in weekMoods)
                _bar(colors, m, isBest: m == bestValue),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final d in _dayLabels)
                SizedBox(
                  width: 18,
                  child: Text(
                    d,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.nunito(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: colors.accent,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
