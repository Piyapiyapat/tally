import 'dart:async';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/journal_provider.dart';
import '../services/db_service.dart';
import '../services/sync_service.dart';
import '../utils/mood_style.dart';
import '../widgets/stat_card.dart';
import 'export_preview_screen.dart';
import 'settings_screen.dart';
import '../providers/auth_provider.dart';
import 'auth_screen.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/avatar_display.dart';
import 'profile_picture_screen.dart';
import 'mood_calendar_screen.dart';

class ProfileScreen extends StatefulWidget {
  final void Function(int index)? onNavigate;
  const ProfileScreen({super.key, this.onNavigate});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late String _displayName;
  String? _profilePicture;

  @override
  void initState() {
    super.initState();
    _displayName = DbService.getDisplayName();
    _profilePicture = DbService.getProfilePicture();
  }

  Future<void> _openProfilePicture() async {
    final initial = _displayName.trim().isNotEmpty
        ? _displayName.trim()[0].toUpperCase()
        : '?';
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProfilePictureScreen(initials: initial),
      ),
    );
    if (!mounted) return;
    setState(() => _profilePicture = DbService.getProfilePicture());
  }

  Future<void> _confirmSignOut(AuthProvider auth) async {
    final colors = context.colors;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Sign out?',
          style: GoogleFonts.nunito(
            fontWeight: FontWeight.w700,
            color: colors.deep,
          ),
        ),
        content: Text(
          "You'll need to log in again to access your account.",
          style: GoogleFonts.nunito(color: colors.accent),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.nunito(
                color: colors.accent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Sign out',
              style: GoogleFonts.nunito(
                color: colors.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await auth.signOut();
    }
  }

  void _editName() {
    final controller = TextEditingController(text: _displayName);
    final colors = context.colors;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          MediaQuery.of(sheetCtx).viewInsets.bottom +
              MediaQuery.of(sheetCtx).padding.bottom +
              24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your name',
              style: GoogleFonts.nunito(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: colors.deep,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              style: GoogleFonts.nunito(
                color: colors.deep,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                hintText: 'Enter your name',
                hintStyle: GoogleFonts.nunito(
                  color: colors.textDim,
                  fontWeight: FontWeight.w500,
                ),
                filled: true,
                fillColor: colors.surfaceFlat,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final name = controller.text.trim();
                  if (name.isEmpty) return;
                  final navigator = Navigator.of(sheetCtx); // ดึงก่อน await
                  await DbService.setDisplayName(name);
                  unawaited(SyncService.pushProfile());
                  if (!mounted) return;
                  setState(() => _displayName = name);
                  navigator.pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.accent,
                  foregroundColor: colors.onAccent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Save',
                  style: GoogleFonts.nunito(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: colors.onAccent,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startExport() async {
    final options = await _pickExportOptions();
    if (options == null || !mounted) return;

    DateTimeRange range;
    if (options.allTime) {
      range = DateTimeRange(start: DateTime(2000), end: DateTime.now());
    } else {
      final colors = context.colors;
      final now = DateTime.now();
      final picked = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2000),
        lastDate: now,
        initialDateRange: DateTimeRange(
          start: now.subtract(const Duration(days: 30)),
          end: now,
        ),
        builder: (ctx, child) => Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: Theme.of(ctx).colorScheme.copyWith(
              primary: colors.accent,
              onPrimary: colors.onAccent,
              surface: colors.surface,
              onSurface: colors.deep,
            ),
          ),
          child: child!,
        ),
      );
      if (picked == null || !mounted) return;
      range = picked;
    }

    final inclusiveEnd = DateTime(
      range.end.year,
      range.end.month,
      range.end.day,
      23,
      59,
      59,
      999,
    );
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ExportPreviewScreen(
          from: range.start,
          to: inclusiveEnd,
          includeMoods: options.moods,
          includeHabits: options.habits,
          includeJournals: options.journals,
        ),
      ),
    );
  }

  Future<({bool moods, bool habits, bool journals, bool allTime})?>
  _pickExportOptions() async {
    final colors = context.colors;
    var moods = true;
    var habits = true;
    var journals = true;
    var allTime = true;

    final continued = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => StatefulBuilder(
        builder: (sheetCtx, setSheetState) {
          final noneSelected = !moods && !habits && !journals;
          return Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              20,
              20,
              MediaQuery.of(sheetCtx).viewInsets.bottom +
                  MediaQuery.of(sheetCtx).padding.bottom +
                  24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'What to include',
                  style: GoogleFonts.nunito(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: colors.deep,
                  ),
                ),
                const SizedBox(height: 8),
                CheckboxListTile(
                  value: moods,
                  onChanged: (v) => setSheetState(() => moods = v ?? false),
                  title: Text(
                    'Mood logs',
                    style: GoogleFonts.nunito(
                      fontWeight: FontWeight.w600,
                      color: colors.deep,
                    ),
                  ),
                  activeColor: colors.accent,
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
                CheckboxListTile(
                  value: habits,
                  onChanged: (v) => setSheetState(() => habits = v ?? false),
                  title: Text(
                    'Habits',
                    style: GoogleFonts.nunito(
                      fontWeight: FontWeight.w600,
                      color: colors.deep,
                    ),
                  ),
                  activeColor: colors.accent,
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
                CheckboxListTile(
                  value: journals,
                  onChanged: (v) => setSheetState(() => journals = v ?? false),
                  title: Text(
                    'Journal entries',
                    style: GoogleFonts.nunito(
                      fontWeight: FontWeight.w600,
                      color: colors.deep,
                    ),
                  ),
                  activeColor: colors.accent,
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 8),
                Divider(color: colors.border),
                const SizedBox(height: 8),
                Text(
                  'Time period',
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: colors.deep,
                  ),
                ),
                RadioGroup<bool>(
                  groupValue: allTime,
                  onChanged: (v) => setSheetState(() => allTime = v ?? true),
                  child: Column(
                    children: [
                      RadioListTile<bool>(
                        value: true,
                        title: Text(
                          'All time',
                          style: GoogleFonts.nunito(
                            fontWeight: FontWeight.w600,
                            color: colors.deep,
                          ),
                        ),
                        activeColor: colors.accent,
                        contentPadding: EdgeInsets.zero,
                      ),
                      RadioListTile<bool>(
                        value: false,
                        title: Text(
                          'Choose a date range',
                          style: GoogleFonts.nunito(
                            fontWeight: FontWeight.w600,
                            color: colors.deep,
                          ),
                        ),
                        activeColor: colors.accent,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: noneSelected
                        ? null
                        : () => Navigator.pop(sheetCtx, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.accent,
                      disabledBackgroundColor: colors.border,
                      foregroundColor: colors.onAccent,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Continue',
                      style: GoogleFonts.nunito(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: colors.onAccent,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    if (continued != true) return null;
    return (moods: moods, habits: habits, journals: journals, allTime: allTime);
  }

  String _moodLabel(int mood) {
    switch (mood) {
      case 1:
        return 'Terrible';
      case 2:
        return 'Bad';
      case 3:
        return 'Neutral';
      case 4:
        return 'Good';
      case 5:
        return 'Great';
      default:
        return '';
    }
  }

  void _showDetailSheet(
    BuildContext context, {
    IconData? icon,
    FaIconData? faIcon,
    required String title,
    required List<Widget> body,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    final colors = context.colors;
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  icon != null
                      ? Icon(icon, color: colors.accent, size: 22)
                      : FaIcon(faIcon, color: colors.accent, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    title,
                    style: GoogleFonts.nunito(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: colors.deep,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...body,
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(sheetCtx);
                    onAction();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.accent,
                    foregroundColor: colors.onAccent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    actionLabel,
                    style: GoogleFonts.nunito(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: colors.onAccent,
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

  Widget _detailRow(String label, String value) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.nunito(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colors.accent,
              ),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.nunito(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: colors.deep,
            ),
          ),
        ],
      ),
    );
  }

  void _showMoodLogsDetail(BuildContext context, int total) {
    final counts = {for (var m = 1; m <= 5; m++) m: 0};
    for (final entry in DbService.moodBox.values) {
      counts[entry.mood] = (counts[entry.mood] ?? 0) + 1;
    }
    _showDetailSheet(
      context,
      faIcon: moodIconFor(5),
      title: 'Mood logs',
      body: [
        _detailRow('Total logged', '$total'),
        const SizedBox(height: 8),
        for (var m = 5; m >= 1; m--) _detailRow(_moodLabel(m), '${counts[m]}'),
      ],
      actionLabel: 'View mood calendar',
      onAction: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const MoodCalendarScreen()),
      ),
    );
  }

  void _showJournalDetail(BuildContext context, int total) {
    _showDetailSheet(
      context,
      icon: Icons.menu_book_outlined,
      title: 'Journal',
      body: [_detailRow('Entries written', '$total')],
      actionLabel: 'Go to journal',
      onAction: () => widget.onNavigate?.call(0),
    );
  }

  void _showHabitsDetail(BuildContext context, int total) {
    final totalCompletions = DbService.habitLogBox.length;
    _showDetailSheet(
      context,
      icon: Icons.repeat_outlined,
      title: 'Habits',
      body: [
        _detailRow('Active habits', '$total'),
        _detailRow('Total completions', '$totalCompletions'),
      ],
      actionLabel: 'View habit calendar',
      onAction: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const MoodCalendarScreen(startOnHabits: true),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final journalProvider = context.watch<JournalProvider>();
    final colors = context.colors;

    final totalMoodLogs = DbService.moodBox.length;
    final totalJournalEntries = journalProvider.entries.length;
    final totalHabits = DbService.habitBox.length;

    final initial = _displayName.trim().isNotEmpty
        ? _displayName.trim()[0].toUpperCase()
        : '?';

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Profile',
          style: GoogleFonts.nunito(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: colors.deep,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.settings_outlined, color: colors.accent),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // â”€â”€ Avatar + name â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
              Row(
                children: [
                  GestureDetector(
                    onTap: _openProfilePicture,
                    child: Stack(
                      children: [
                        AvatarImage(
                          pictureValue: _profilePicture,
                          initials: initial,
                          size: 64,
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: colors.accent,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: colors.background,
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              Icons.camera_alt,
                              size: 12,
                              color: colors.onAccent,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: GestureDetector(
                      onTap: _editName,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _displayName,
                            style: GoogleFonts.nunito(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: colors.deep,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(
                                Icons.edit_outlined,
                                size: 14,
                                color: colors.accent,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Tap to edit name',
                                style: GoogleFonts.nunito(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: colors.accent,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // â”€â”€ Stats grid â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
              Text(
                'Your stats',
                style: GoogleFonts.nunito(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: colors.deep,
                ),
              ),
              const SizedBox(height: 12),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: StatCard.fa(
                        faIcon: moodIconFor(5),
                        value: '$totalMoodLogs',
                        label: 'Mood logs',
                        onTap: () =>
                            _showMoodLogsDetail(context, totalMoodLogs),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StatCard(
                        icon: Icons.menu_book_outlined,
                        value: '$totalJournalEntries',
                        label: 'Journal',
                        onTap: () =>
                            _showJournalDetail(context, totalJournalEntries),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StatCard(
                        icon: Icons.repeat_outlined,
                        value: '$totalHabits',
                        label: 'Habits',
                        onTap: () => _showHabitsDetail(context, totalHabits),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // â”€â”€ Backup section â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
              Consumer<AuthProvider>(
                builder: (context, auth, _) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Backup',
                        style: GoogleFonts.nunito(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: colors.deep,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colors.surface,
                          borderRadius: BorderRadius.circular(kCardRadius),
                          boxShadow: colors.cardShadow,
                        ),
                        child: auth.isLoggedIn
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.cloud_done_outlined,
                                        color: colors.accent,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          auth.user?.email ?? '',
                                          style: GoogleFonts.nunito(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: colors.deep,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (auth.isSyncing) ...[
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        SizedBox(
                                          width: 12,
                                          height: 12,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: colors.accent,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Syncing your data...',
                                          style: GoogleFonts.nunito(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: colors.accent,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                  if (!auth.isEmailVerified) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      'Email not verified yet â€” check your inbox',
                                      style: GoogleFonts.nunito(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: colors.error,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton(
                                      onPressed: () => _confirmSignOut(auth),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: colors.error,
                                        side: BorderSide(color: colors.border),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        'Sign out',
                                        style: GoogleFonts.nunito(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.cloud_outlined,
                                        color: colors.accent,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          'Link an email to back up your data',
                                          style: GoogleFonts.nunito(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: colors.deep,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton(
                                      onPressed: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => const AuthScreen(),
                                        ),
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: colors.accent,
                                        side: BorderSide(color: colors.border),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        'Link email',
                                        style: GoogleFonts.nunito(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),

              // â”€â”€ Data export â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
              Text(
                'Your data',
                style: GoogleFonts.nunito(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: colors.deep,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(kCardRadius),
                  boxShadow: colors.cardShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.picture_as_pdf_outlined,
                          color: colors.accent,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Preview and export your mood, habit, and journal history as a PDF report',
                            style: GoogleFonts.nunito(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: colors.deep,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _startExport,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: colors.accent,
                          side: BorderSide(color: colors.border),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Preview report',
                          style: GoogleFonts.nunito(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // â”€â”€ About â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
              Text(
                'About',
                style: GoogleFonts.nunito(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: colors.deep,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(kCardRadius),
                  boxShadow: colors.cardShadow,
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: colors.accent),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tally',
                            style: GoogleFonts.nunito(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: colors.deep,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Version 1.0.0',
                            style: GoogleFonts.nunito(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: colors.accent,
                            ),
                          ),
                        ],
                      ),
                    ),
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
