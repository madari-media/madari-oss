import 'dart:math' as math;

import 'package:flutter/material.dart';

class ColorUtils {
  static final ColorUtils _instance = ColorUtils._internal();

  factory ColorUtils() {
    return _instance;
  }

  ColorUtils._internal();

  MaterialColor createMaterialColor(Color color) {
    HSLColor hslColor = HSLColor.fromColor(color);

    Map<int, Color> shades = {
      50: _createShade(hslColor, 0.9),
      100: _createShade(hslColor, 0.8),
      200: _createShade(hslColor, 0.7),
      300: _createShade(hslColor, 0.6),
      400: _createShade(hslColor, 0.5),
      500: color,
      600: _createShade(hslColor, 0.4),
      700: _createShade(hslColor, 0.3),
      800: _createShade(hslColor, 0.2),
      900: _createShade(hslColor, 0.1),
    };

    return MaterialColor(_colorToInt(color), shades);
  }

  Color _createShade(HSLColor hslColor, double factor) {
    double lightness =
        math.min(1.0, math.max(0.0, hslColor.lightness * factor));
    return hslColor.withLightness(lightness).toColor();
  }

  int _colorToInt(Color color) {
    return (0xFF << 24) |
        (color.r.toInt() << 16) |
        (color.g.toInt() << 8) |
        color.b.toInt();
  }

  Color colorFromRGB(int r, int g, int b) {
    return Color.fromARGB(255, r, g, b);
  }

  List<int> colorToRGB(Color color) {
    return [color.r.toInt(), color.g.toInt(), color.b.toInt()];
  }
}
