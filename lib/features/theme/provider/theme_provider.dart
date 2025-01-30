import 'package:flutter/material.dart';

import '../service/theme_preferences.service.dart';
import '../utils/color_utils.dart';

class ThemeProvider with ChangeNotifier {
  static final ThemeProvider _instance = ThemeProvider._internal();

  factory ThemeProvider() {
    return _instance;
  }

  ThemeProvider._internal() {
    loadPreferences();
  }

  final ThemePreferences _themePreferences = ThemePreferences();
  final ColorUtils _colorUtils = ColorUtils();

  bool _isDarkMode = false;
  Color _primaryColor = Colors.red;

  bool get isDarkMode => _isDarkMode;
  Color get primaryColor => _primaryColor;

  loadPreferences() async {
    _isDarkMode = await _themePreferences.getThemeMode();
    _primaryColor = await _themePreferences.getPrimaryColor();
    notifyListeners();
  }

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    _themePreferences.setThemeMode(_isDarkMode);
    notifyListeners();
  }

  void setPrimaryColor(Color color) {
    _primaryColor = color;
    _themePreferences.setPrimaryColor(color);
    notifyListeners();
  }

  MaterialColor get primarySwatch =>
      _colorUtils.createMaterialColor(_primaryColor);

  ThemeData getTheme() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _primaryColor,
      brightness: _isDarkMode ? Brightness.dark : Brightness.light,
    );

    return ThemeData(
      colorScheme: colorScheme,
      primarySwatch: primarySwatch,
      useMaterial3: true,
    );
  }
}
