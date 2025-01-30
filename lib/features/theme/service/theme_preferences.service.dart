import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemePreferences {
  static final ThemePreferences _instance = ThemePreferences._internal();

  factory ThemePreferences() {
    return _instance;
  }

  ThemePreferences._internal();

  static const themeMode = 'theme_mode';
  static const String primaryColorR = 'primary_color_r';
  static const String primaryColorG = 'primary_color_g';
  static const String primaryColorB = 'primary_color_b';

  setThemeMode(bool isDarkMode) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool(themeMode, isDarkMode);
  }

  setPrimaryColor(Color color) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setInt(primaryColorR, color.r.toInt());
    prefs.setInt(primaryColorG, color.g.toInt());
    prefs.setInt(primaryColorB, color.b.toInt());
  }

  Future<bool> getThemeMode() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(themeMode) ?? true;
  }

  Future<Color> getPrimaryColor() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int r = prefs.getInt(primaryColorR) ?? 255;
    int g = prefs.getInt(primaryColorG) ?? 0;
    int b = prefs.getInt(primaryColorB) ?? 0;

    return Color.fromARGB(255, r, g, b);
  }
}
