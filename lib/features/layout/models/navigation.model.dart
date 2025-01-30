import 'package:flutter/material.dart';

class NavigationItem {
  final String label;
  final String path;
  final IconData icon;
  final IconData? selectedIcon;

  const NavigationItem({
    required this.label,
    required this.path,
    required this.icon,
    this.selectedIcon,
  });
}
