import 'package:flutter/material.dart';

import '../provider/theme_provider.dart';
import '../utils/color_utils.dart';

class AppTheme {
  static final AppTheme _instance = AppTheme._internal();

  factory AppTheme() {
    return _instance;
  }

  AppTheme._internal();

  final ThemeProvider _themeProvider = ThemeProvider();
  final ColorUtils _colorUtils = ColorUtils();

  ThemeProvider get themeProvider => _themeProvider;
  ColorUtils get colorUtils => _colorUtils;

  void toggleTheme() => _themeProvider.toggleTheme();

  void setPrimaryColor(Color color) => _themeProvider.setPrimaryColor(color);

  void setPrimaryColorFromRGB(int r, int g, int b) {
    Color color = _colorUtils.colorFromRGB(r, g, b);
    _themeProvider.setPrimaryColor(color);
  }

  ThemeData getCurrentTheme() => _themeProvider.getTheme();
}
