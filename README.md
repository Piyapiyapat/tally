# Tally

A personal wellness tracker for mood, habits, and journaling — built with Flutter.

Tally lets you log how you feel, keep habits on track, and write down your
days, then pulls it all together into insights that connect the dots between
your mood, your habits, and what you wrote about them.

## Features

- **Mood tracking** — log how you're feeling each day with a quick note, browse
  past entries on a calendar view, and spot each mood at a glance with its own
  color (red through green).
- **Habits** — create habits, check them off day by day, and build streaks.
- **Journal** — write dated entries, organize them with custom tags (up to
  20), and find your way back to them by month.
- **Insights** — charts and stats that surface patterns across mood, habits,
  and journaling over time.
- **Cloud sync** — sign in with email/password or Google; your habits, moods,
  journal entries, tags, profile, and app settings (theme and reminders) sync
  to Firestore so nothing is lost on reinstall or when switching devices.
  Signing out clears the device and returns you to the welcome screen; your
  data is safe in the cloud until you sign back in.
- **Themes** — five color palettes (forest, pink, blue, lavender, sunset),
  each with a light and dark variant.
- **Privacy** — optional PIN or biometric app lock (device-only; it doesn't
  sync between devices).
- **Export** — generate a PDF summary of your data to share or keep.
- **Onboarding** — a short animated walkthrough for first-time users.

## Tech stack

- **Flutter** / Dart
- **Hive** (`hive_ce`) for local, offline-first storage
- **Firebase Auth** + **Cloud Firestore** for account sign-in and cross-device
  sync
- **Provider** for state management
- **fl_chart** for the insights charts

## Getting started

1. Install the [Flutter SDK](https://docs.flutter.dev/get-started/install).
2. Clone this repo and fetch packages:
   ```
   git clone https://github.com/<your-username>/tally.git
   cd tally
   flutter pub get
   ```
3. This project uses Firebase (Auth + Firestore). To run it from source
   you'll need your own Firebase project, with `android/app/google-services.json`
   and `lib/firebase_options.dart` generated via the
   [FlutterFire CLI](https://firebase.google.com/docs/flutter/setup) —
   these files aren't committed to this repo.
4. Run it:
   ```
   flutter run
   ```

Prefer to just try the app without building it? Grab the APK from the
[Releases](../../releases) page and install it on an Android device.

## Project structure

- `lib/screens/` — app screens (home, habits, journal, mood calendar,
  statistics, settings, profile, onboarding, auth, etc.)
- `lib/services/` — Hive/DB access, Firebase sync, notifications
- `lib/theme/` — color palettes and app theming
- `lib/widgets/` — shared UI components
