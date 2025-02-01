import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../provider/theme_provider.dart';
import '../utils/color_utils.dart';

class AppTheme {
  static final AppTheme _instance = AppTheme._internal();
  static const String _primaryColorKey = 'primary_color';
  static const String _isDarkModeKey = 'is_dark_mode';
  final _logger = Logger('AppTheme');

  factory AppTheme() {
    return _instance;
  }

  AppTheme._internal();

  final ThemeProvider _themeProvider = ThemeProvider();
  final ColorUtils _colorUtils = ColorUtils();

  ThemeProvider get themeProvider => _themeProvider;
  ColorUtils get colorUtils => _colorUtils;

  Future<void> ensureInitialized() async {
    final prefs = await SharedPreferences.getInstance();

    final isDarkMode = prefs.getBool(_isDarkModeKey) ?? false;
    if (isDarkMode) _themeProvider.toggleTheme();

    final primaryColorValue = prefs.getInt(_primaryColorKey);
    if (primaryColorValue != null) {
      _themeProvider.setPrimaryColor(Color(primaryColorValue));
    }
  }

  Future<void> toggleTheme() async {
    _themeProvider.toggleTheme();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isDarkModeKey, _themeProvider.isDarkMode);
    _logger.info("isDarkMode ${_themeProvider.isDarkMode}");
  }

  Future<void> setPrimaryColor(Color color) async {
    _themeProvider.setPrimaryColor(color);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_primaryColorKey, color.value);
  }

  Future<void> setPrimaryColorFromRGB(int r, int g, int b) async {
    Color color = _colorUtils.colorFromRGB(r, g, b);
    await setPrimaryColor(color);
  }

  ThemeData getCurrentTheme() => _themeProvider.getTheme();
}
