import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../services/app_lock_service.dart';
import '../services/db_service.dart';
import '../services/notification_service.dart';
import '../services/sync_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'manage_tags_screen.dart';
import 'set_pin_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late bool _reminderEnabled;
  late TimeOfDay _reminderTime;
  late bool _appLockEnabled;
  late bool _biometricEnabled;
  bool _biometricAvailable = false;

  @override
  void initState() {
    super.initState();
    _reminderEnabled = DbService.getReminderEnabled();
    _reminderTime = DbService.getReminderTime();
    _appLockEnabled = DbService.getAppLockEnabled();
    _biometricEnabled = DbService.getAppLockBiometricEnabled();
    AppLockService.biometricAvailable().then((available) {
      if (mounted) setState(() => _biometricAvailable = available);
    });
  }

  Future<void> _setAppLockEnabled(bool enabled) async {
    if (enabled && !await AppLockService.hasPin()) {
      if (!mounted) return;
      final created = await Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (_) => const SetPinScreen()),
      );
      if (created != true) return;
    }
    await DbService.setAppLockEnabled(enabled);
    if (!mounted) return;
    setState(() => _appLockEnabled = enabled);
  }

  Future<void> _changePin() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SetPinScreen()),
    );
  }

  Future<void> _setBiometricEnabled(bool enabled) async {
    await DbService.setAppLockBiometricEnabled(enabled);
    if (!mounted) return;
    setState(() => _biometricEnabled = enabled);
  }

  Future<void> _setReminderEnabled(bool enabled) async {
    if (enabled) {
      final granted = await NotificationService.requestPermission();
      if (!granted) {
        if (!mounted) return;
        final colors = context.colors;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Notifications are blocked — enable them for Tally in your '
              "phone's settings to use reminders.",
              style: GoogleFonts.nunito(
                fontWeight: FontWeight.w600,
                color: colors.onError,
              ),
            ),
            backgroundColor: colors.error,
          ),
        );
        return;
      }
      await NotificationService.scheduleDailyReminder(_reminderTime);
    } else {
      await NotificationService.cancelReminder();
    }
    await DbService.setReminderEnabled(enabled);
    unawaited(SyncService.pushSettings());
    if (!mounted) return;
    setState(() => _reminderEnabled = enabled);
  }

  Future<void> _pickReminderTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
      // Force 12-hour (AM/PM) mode: the 24-hour dial crams two rings of
      // numbers together, so the selection circle overlaps its neighbors.
      // A single 12-number ring has more natural spacing.
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
        child: child!,
      ),
    );
    if (picked == null) return;
    await DbService.setReminderTime(picked);
    unawaited(SyncService.pushSettings());
    if (_reminderEnabled) {
      await NotificationService.scheduleDailyReminder(picked);
    }
    if (!mounted) return;
    setState(() => _reminderTime = picked);
  }

  Future<void> _confirmDeleteAccount(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    final colors = context.colors;
    final passwordController = TextEditingController();
    String? localError;
    bool isSubmitting = false;

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => StatefulBuilder(
        builder: (sheetCtx, setSheetState) {
          return Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              20,
              20,
              MediaQuery.of(sheetCtx).viewInsets.bottom + 24,
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: colors.error),
                      const SizedBox(width: 8),
                      Text(
                        'Delete account',
                        style: GoogleFonts.nunito(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: colors.deep,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This permanently deletes your account and all backed-up '
                    'data in the cloud. Data on this device will also be cleared. '
                    'This cannot be undone.',
                    style: GoogleFonts.nunito(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: colors.accent,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (!auth.isGoogleUser) ...[
                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      style: GoogleFonts.nunito(
                        color: colors.deep,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Enter your password to confirm',
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
                    const SizedBox(height: 12),
                  ] else ...[
                    Text(
                      'You\'ll be asked to confirm with Google.',
                      style: GoogleFonts.nunito(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: colors.accent,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (localError != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: colors.errorBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        localError!,
                        style: GoogleFonts.nunito(
                          color: colors.error,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: isSubmitting
                              ? null
                              : () => Navigator.pop(sheetCtx, false),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: colors.accent,
                            side: BorderSide(color: colors.border),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.nunito(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: isSubmitting
                              ? null
                              : () async {
                                  setSheetState(() {
                                    isSubmitting = true;
                                    localError = null;
                                  });
                                  final error = await auth.deleteAccount(
                                    password: passwordController.text,
                                  );
                                  if (error != null) {
                                    setSheetState(() {
                                      isSubmitting = false;
                                      localError = error;
                                    });
                                  } else if (sheetCtx.mounted) {
                                    Navigator.pop(sheetCtx, true);
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colors.error,
                            foregroundColor: colors.onError,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: isSubmitting
                              ? SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: colors.onError,
                                  ),
                                )
                              : Text(
                                  'Delete',
                                  style: GoogleFonts.nunito(
                                    fontWeight: FontWeight.w700,
                                    color: colors.onError,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    if (confirmed == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Account deleted',
            style: GoogleFonts.nunito(
              fontWeight: FontWeight.w600,
              color: colors.onAccent,
            ),
          ),
          backgroundColor: colors.accent,
        ),
      );
      Navigator.pop(context); // กลับไป Profile
    }
  }

  Widget _themeModeButton(
    BuildContext context,
    AppColors colors,
    ThemeProvider themeProvider,
    ThemeMode mode,
    IconData icon,
    String label,
  ) {
    final isSelected = themeProvider.mode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => themeProvider.setThemeMode(mode),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? colors.accent : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: isSelected ? null : Border.all(color: colors.border),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? colors.onAccent : colors.accent,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.nunito(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? colors.onAccent : colors.accent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _paletteSwatch(
    BuildContext context,
    AppColors colors,
    ThemeProvider themeProvider,
    AppPalette palette,
  ) {
    final isSelected = themeProvider.palette == palette;
    return GestureDetector(
      onTap: () => themeProvider.setPalette(palette),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? colors.deep : Colors.transparent,
                width: 2,
              ),
            ),
            child: Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: palette.swatch,
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : null,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            palette.label,
            style: GoogleFonts.nunito(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isSelected ? colors.deep : colors.accent,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final colors = context.colors;
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: colors.deep, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Settings',
          style: GoogleFonts.nunito(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: colors.deep,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Appearance',
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
                children: [
                  Row(
                    children: [
                      _themeModeButton(
                        context,
                        colors,
                        themeProvider,
                        ThemeMode.light,
                        Icons.light_mode_outlined,
                        'Light',
                      ),
                      const SizedBox(width: 10),
                      _themeModeButton(
                        context,
                        colors,
                        themeProvider,
                        ThemeMode.dark,
                        Icons.dark_mode_outlined,
                        'Dark',
                      ),
                      const SizedBox(width: 10),
                      _themeModeButton(
                        context,
                        colors,
                        themeProvider,
                        ThemeMode.system,
                        Icons.settings_suggest_outlined,
                        'System',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Divider(color: colors.border),
                  const SizedBox(height: 12),
                  Wrap(
                    alignment: WrapAlignment.spaceEvenly,
                    spacing: 12,
                    runSpacing: 12,
                    children: AppPalette.values
                        .map(
                          (palette) => _paletteSwatch(
                            context,
                            colors,
                            themeProvider,
                            palette,
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Reminders',
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
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Daily reminder',
                              style: GoogleFonts.nunito(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: colors.deep,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Log your mood and check your habits',
                              style: GoogleFonts.nunito(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: colors.accent,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _reminderEnabled,
                        onChanged: _setReminderEnabled,
                        activeTrackColor: colors.accent,
                        thumbColor: WidgetStateProperty.resolveWith(
                          (states) => states.contains(WidgetState.selected)
                              ? colors.onAccent
                              : colors.textDim,
                        ),
                      ),
                    ],
                  ),
                  if (_reminderEnabled) ...[
                    const SizedBox(height: 12),
                    Divider(color: colors.border),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: _pickReminderTime,
                      child: Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 18,
                            color: colors.accent,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Reminder time',
                            style: GoogleFonts.nunito(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: colors.deep,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            _reminderTime.format(context),
                            style: GoogleFonts.nunito(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: colors.accent,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.chevron_right,
                            size: 18,
                            color: colors.accent,
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Privacy',
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
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'App lock',
                              style: GoogleFonts.nunito(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: colors.deep,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Require a PIN to open Tally',
                              style: GoogleFonts.nunito(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: colors.accent,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _appLockEnabled,
                        onChanged: _setAppLockEnabled,
                        activeTrackColor: colors.accent,
                        thumbColor: WidgetStateProperty.resolveWith(
                          (states) => states.contains(WidgetState.selected)
                              ? colors.onAccent
                              : colors.textDim,
                        ),
                      ),
                    ],
                  ),
                  if (_appLockEnabled) ...[
                    const SizedBox(height: 12),
                    Divider(color: colors.border),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: _changePin,
                      child: Row(
                        children: [
                          Icon(Icons.password, size: 18, color: colors.accent),
                          const SizedBox(width: 8),
                          Text(
                            'Change PIN',
                            style: GoogleFonts.nunito(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: colors.deep,
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            Icons.chevron_right,
                            size: 18,
                            color: colors.accent,
                          ),
                        ],
                      ),
                    ),
                    if (_biometricAvailable) ...[
                      const SizedBox(height: 12),
                      Divider(color: colors.border),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Use biometric unlock',
                              style: GoogleFonts.nunito(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: colors.deep,
                              ),
                            ),
                          ),
                          Switch(
                            value: _biometricEnabled,
                            onChanged: _setBiometricEnabled,
                            activeTrackColor: colors.accent,
                            thumbColor: WidgetStateProperty.resolveWith(
                              (states) => states.contains(WidgetState.selected)
                                  ? colors.onAccent
                                  : colors.textDim,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Journal',
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
              child: GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ManageTagsScreen()),
                ),
                child: Row(
                  children: [
                    Icon(Icons.sell_outlined, size: 18, color: colors.accent),
                    const SizedBox(width: 8),
                    Text(
                      'Manage tags',
                      style: GoogleFonts.nunito(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: colors.deep,
                      ),
                    ),
                    const Spacer(),
                    Icon(Icons.chevron_right, size: 18, color: colors.accent),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (auth.isLoggedIn) ...[
              Text(
                'Account',
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
                    Text(
                      auth.user?.email ?? '',
                      style: GoogleFonts.nunito(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: colors.deep,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => _confirmDeleteAccount(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: colors.error,
                          side: BorderSide(color: colors.errorBorder),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Delete account',
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
            ] else
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 60),
                  child: Text(
                    'Log in from your Profile to manage account settings',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colors.textDim,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
