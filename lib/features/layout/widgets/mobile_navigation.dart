import 'package:flutter/material.dart';

import '../models/navigation.model.dart';

class MobileNavigation extends StatelessWidget {
  final List<NavigationItem> items;
  final int currentIndex;
  final ValueChanged<int> onNavigate;

  const MobileNavigation({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(20),
        topRight: Radius.circular(20),
      ),
      child: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          onNavigate(index);
        },
        height: 58,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
        destinations: items
            .map((item) => NavigationDestination(
                  icon: Icon(item.icon),
                  selectedIcon: item.selectedIcon != null
                      ? Icon(item.selectedIcon)
                      : null,
                  label: item.label,
                ))
            .toList(),
      ),
    );
  }
}
