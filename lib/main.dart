import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/db_service.dart';
import 'services/notification_service.dart';
import 'providers/habit_provider.dart';
import 'providers/mood_provider.dart';
import 'providers/journal_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'theme/app_colors.dart';
import 'theme/app_theme.dart';
import 'app_shell.dart';
import 'screens/lock_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/sync_loading_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await DbService.init();
  await NotificationService.init();
  if (DbService.getReminderEnabled()) {
    await NotificationService.scheduleDailyReminder(
      DbService.getReminderTime(),
    );
  }
  await _rescheduleHabitReminders();
  runApp(const MyApp());
}

/// Re-registers every habit's own reminder — called at startup and again
/// after a cloud merge, since a reminder time pulled in from another device
/// won't otherwise get scheduled on this one.
Future<void> _rescheduleHabitReminders() async {
  for (final h in DbService.getAllHabits()) {
    if (h.reminderHour != null && h.reminderMinute != null) {
      await NotificationService.scheduleHabitReminder(
        h.id,
        h.name,
        TimeOfDay(hour: h.reminderHour!, minute: h.reminderMinute!),
      );
    }
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => HabitProvider()..loadHabits()),
        ChangeNotifierProvider(create: (_) => MoodProvider()..loadMood()),
        ChangeNotifierProvider(
          create: (_) => JournalProvider()..loadJournals(),
        ),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'Tally',
            debugShowCheckedModeBanner: false,
            themeMode: themeProvider.mode,
            theme: buildAppTheme(
              AppColors.of(themeProvider.palette, Brightness.light),
            ),
            darkTheme: buildAppTheme(
              AppColors.of(themeProvider.palette, Brightness.dark),
            ),
            home: _AppLockGate(
              child: _SyncBootstrapper(child: const AppShell()),
            ),
          );
        },
      ),
    );
  }
}

class _SyncBootstrapper extends StatefulWidget {
  final Widget child;
  const _SyncBootstrapper({required this.child});

  @override
  State<_SyncBootstrapper> createState() => _SyncBootstrapperState();
}

class _SyncBootstrapperState extends State<_SyncBootstrapper> {
  late bool _needsOnboarding = !DbService.getOnboardingComplete();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      auth.onDataSynced = () async {
        if (!mounted) return;
        context.read<HabitProvider>().loadHabits();
        context.read<MoodProvider>().loadMood();
        context.read<JournalProvider>().loadJournals();
        await _rescheduleHabitReminders();
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_needsOnboarding) {
      return OnboardingScreen(
        onContinue: () => setState(() => _needsOnboarding = false),
      );
    }
    // Block on the initial cloud sync rather than showing the app with
    // stale/default local data that then visibly flips to the real thing
    // a moment later.
    if (context.watch<AuthProvider>().isSyncing) {
      return const SyncLoadingScreen();
    }
    return widget.child;
  }
}

/// Shows [LockScreen] instead of [child] when app lock is on — at startup,
/// and again once the app has sat backgrounded for a while (a quick trip to
/// a share sheet or system picker doesn't count, so it doesn't re-lock on
/// every interruption).
class _AppLockGate extends StatefulWidget {
  final Widget child;
  const _AppLockGate({required this.child});

  @override
  State<_AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends State<_AppLockGate>
    with WidgetsBindingObserver {
  static const _reLockAfter = Duration(seconds: 30);

  late bool _locked = DbService.getAppLockEnabled();
  DateTime? _pausedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!DbService.getAppLockEnabled()) return;
    if (state == AppLifecycleState.paused) {
      _pausedAt = DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      final pausedAt = _pausedAt;
      _pausedAt = null;
      if (pausedAt != null &&
          DateTime.now().difference(pausedAt) >= _reLockAfter) {
        setState(() => _locked = true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_locked) {
      return LockScreen(onUnlocked: () => setState(() => _locked = false));
    }
    return widget.child;
  }
}
