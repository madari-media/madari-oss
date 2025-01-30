import 'dart:math';

import 'package:flutter/material.dart';

class StremioCardSize {
  final double width;
  final double height;
  final int columns;

  const StremioCardSize({
    required this.width,
    required this.height,
    required this.columns,
  });

  static StremioCardSize getSize(BuildContext context, {bool isGrid = false}) {
    final screenWidth = MediaQuery.of(context).size.width;
    double cardWidth;
    int columns;

    if (screenWidth < 600) {
      cardWidth = isGrid ? screenWidth * 0.35 : screenWidth * 0.32;
      columns = 3;
    } else if (screenWidth < 900) {
      cardWidth = min(screenWidth * 0.19, 180);
      columns = 4;
    } else if (screenWidth < 1200) {
      cardWidth = min(screenWidth * 0.15, 200);
      columns = 6;
    } else if (screenWidth < 1600) {
      cardWidth = min(screenWidth * 0.12, 220);
      columns = 8;
    } else if (screenWidth < 2560) {
      cardWidth = min(screenWidth * 0.1, 220);
      columns = 10;
    } else if (screenWidth < 3840) {
      cardWidth = min(screenWidth * 0.08, 220);
      columns = 12;
    } else {
      cardWidth = min(screenWidth * 0.06, 220);
      columns = 16;
    }

    const aspectRatio = 1.5;

    return StremioCardSize(
      width: cardWidth,
      height: cardWidth * aspectRatio,
      columns: columns,
    );
  }
}
