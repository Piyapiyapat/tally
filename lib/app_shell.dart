import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/home_screen.dart';
import 'screens/journal_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/statistics_screen.dart';
import 'theme/app_colors.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 1;

  // Built once and kept alive via IndexedStack below, rather than
  // reconstructed on every tab switch — otherwise each tab's screen (and
  // any one-shot animation or transient UI state in it, e.g. the mood
  // picker's bounce-in) gets torn down and rebuilt from scratch every time
  // you navigate back to it.
  late final List<Widget> _screens = [
    const JournalScreen(),
    HomeScreen(onNavigate: (index) => setState(() => _currentIndex = index)),
    const StatisticsScreen(),
    ProfileScreen(
        onNavigate: (index) => setState(() => _currentIndex = index)),
  ];

  static const List<_NavItem> _items = [
    _NavItem(
      label: 'Journal',
      expandedWidth: 120,
      kind: _NavIconKind.journal,
    ),
    _NavItem(label: 'Home', expandedWidth: 100, kind: _NavIconKind.home),
    _NavItem(
      label: 'Insights',
      expandedWidth: 116,
      kind: _NavIconKind.insights,
    ),
    _NavItem(
      label: 'Profile',
      expandedWidth: 110,
      kind: _NavIconKind.profile,
    ),
  ];

  // Collapsed (icon-only) pill width, shared by every tab.
  static const double _collapsedWidth = 44;

  Widget _navIcon(_NavIconKind kind, bool isSelected, AppColors colors) {
    final color = isSelected ? colors.onMint : colors.navInactiveIcon;
    switch (kind) {
      case _NavIconKind.journal:
        return Icon(isSelected ? Icons.book : Icons.book_outlined,
            color: color, size: 22);
      case _NavIconKind.home:
        return _SmileFaceIcon(color: color, size: 22);
      case _NavIconKind.insights:
        return Icon(isSelected ? Icons.pie_chart : Icons.pie_chart_outline,
            color: color, size: 22);
      case _NavIconKind.profile:
        return Icon(isSelected ? Icons.person : Icons.person_outline,
            color: color, size: 22);
    }
  }

  Widget _buildTab(_NavItem item, int index, AppColors colors) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
        width: isSelected ? item.expandedWidth : _collapsedWidth,
        height: 44,
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          color: isSelected ? colors.mint : Colors.transparent,
          borderRadius: BorderRadius.circular(32),
        ),
        child: Stack(
          alignment: Alignment.centerLeft,
          children: [
            // Icon: fixed position, always visible.
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOutCubic,
              left: 11,
              top: 0,
              bottom: 0,
              child: Center(child: _navIcon(item.kind, isSelected, colors)),
            ),
            // Label: fades in to the right of the icon, only when expanded.
            if (item.label != null)
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOutCubic,
                left: 40,
                top: 0,
                bottom: 0,
                child: AnimatedOpacity(
                  opacity: isSelected ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Center(
                    child: Text(
                      item.label!,
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.clip,
                      style: GoogleFonts.nunito(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: colors.onMint,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.only(bottom: 16, left: 32, right: 32),
        child: SafeArea(
          top: false,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                decoration: BoxDecoration(
                  color: colors.navBackground,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: colors.cardShadow,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    for (int i = 0; i < _items.length; i++) ...[
                      if (i > 0) const SizedBox(width: 8),
                      _buildTab(_items[i], i, colors),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _NavIconKind { journal, home, insights, profile }

class _NavItem {
  final _NavIconKind kind;
  final String? label;
  final double expandedWidth;
  const _NavItem({
    required this.kind,
    this.label,
    required this.expandedWidth,
  });
}

/// A simple smiley face (circle outline + two dot eyes + a smile curve)
/// used for the Home tab instead of a stock Material icon.
class _SmileFaceIcon extends StatelessWidget {
  final Color color;
  final double size;

  const _SmileFaceIcon({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _SmileFacePainter(color),
    );
  }
}

class _SmileFacePainter extends CustomPainter {
  final Color color;

  const _SmileFacePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.08
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - strokePaint.strokeWidth / 2;

    // face outline
    canvas.drawCircle(center, radius, strokePaint);

    // eyes
    final eyePaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final eyeRadius = size.width * 0.06;
    final eyeY = center.dy - radius * 0.25;
    canvas.drawCircle(
        Offset(center.dx - radius * 0.4, eyeY), eyeRadius, eyePaint);
    canvas.drawCircle(
        Offset(center.dx + radius * 0.4, eyeY), eyeRadius, eyePaint);

    // smile
    final smileRect = Rect.fromCenter(
      center: Offset(center.dx, center.dy - radius * 0.05),
      width: radius * 1.1,
      height: radius * 1.1,
    );
    canvas.drawArc(
      smileRect,
      math.pi * 0.15,
      math.pi * 0.7,
      false,
      strokePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _SmileFacePainter oldDelegate) =>
      oldDelegate.color != color;
}
