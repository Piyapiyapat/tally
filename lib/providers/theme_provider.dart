import 'dart:async';
import 'package:flutter/material.dart';
import '../services/db_service.dart';
import '../services/sync_service.dart';
import '../theme/app_colors.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _mode = DbService.getThemeMode();
  AppPalette _palette = DbService.getAppPalette();

  ThemeMode get mode => _mode;
  AppPalette get palette => _palette;

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_mode == mode) return;
    _mode = mode;
    notifyListeners();
    await DbService.setThemeMode(mode);
    unawaited(SyncService.pushSettings());
  }

  Future<void> setPalette(AppPalette palette) async {
    if (_palette == palette) return;
    _palette = palette;
    notifyListeners();
    await DbService.setAppPalette(palette);
    unawaited(SyncService.pushSettings());
  }

  /// Re-reads from Hive after a cloud merge may have filled in a theme/
  /// palette this device never had set locally.
  void reload() {
    _mode = DbService.getThemeMode();
    _palette = DbService.getAppPalette();
    notifyListeners();
  }
}
