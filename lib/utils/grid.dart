import 'package:flutter/material.dart';

double getGridResponsivePadding(BuildContext context) {
  final width = MediaQuery.of(context).size.width;
  if (width < 600) return 8.0;
  if (width < 1200) return 16.0;
  return 24.0;
}

int getGridResponsiveColumnCount(BuildContext context) {
  final width = MediaQuery.of(context).size.width;
  if (width < 600) return 3;
  if (width < 900) return 5;
  if (width < 1200) return 5;
  if (width < 1800) return 6;
  if (width < 2000) return 6;
  return 10;
}

double getGridResponsiveSpacing(BuildContext context) {
  final width = MediaQuery.of(context).size.width;
  if (width < 600) return 8.0;
  if (width < 1200) return 16.0;
  return 24.0;
}

double getGridResponsiveAspectRatio(BuildContext context) {
  final width = MediaQuery.of(context).size.width;
  if (width < 600) return 1.2;
  return 1.5;
}
