import 'package:flutter/material.dart';
import '../../features/settings/data/settings_repository.dart';

class ThemeController extends ChangeNotifier {
  final SettingsRepository _settings;
  ThemeController(this._settings);

  ThemeMode _mode = ThemeMode.system;
  ThemeMode get mode => _mode;

  Future<void> load() async {
    final saved = await _settings.getThemeMode();
    _mode = switch (saved) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    notifyListeners();
  }

  Future<void> setMode(ThemeMode mode) async {
    _mode = mode;
    final str = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    await _settings.setThemeMode(str);
    notifyListeners();
  }
}
