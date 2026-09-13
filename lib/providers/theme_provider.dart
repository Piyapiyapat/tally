import 'package:flutter/material.dart';
import '../services/db_service.dart';
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
  }

  Future<void> setPalette(AppPalette palette) async {
    if (_palette == palette) return;
    _palette = palette;
    notifyListeners();
    await DbService.setAppPalette(palette);
  }
}
