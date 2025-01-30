import 'package:flutter/material.dart';

import '../models/navigation.model.dart';

class DesktopNavigation extends StatelessWidget {
  final List<NavigationItem> items;
  final int currentIndex;
  final ValueChanged<int> onNavigate;

  const DesktopNavigation({
    super.key,
    required this.items,
    required this.onNavigate,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppBar(
      backgroundColor: theme.colorScheme.surface.withValues(alpha: 0.8),
      elevation: 0,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: items.map((item) {
          final index = items.indexOf(item);
          final isSelected = index == currentIndex;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: TextButton.icon(
              onPressed: () => onNavigate(index),
              icon: Icon(
                isSelected ? item.selectedIcon ?? item.icon : item.icon,
                color: isSelected ? theme.colorScheme.primary : null,
              ),
              label: Text(
                item.label,
                style: TextStyle(
                  color: isSelected ? theme.colorScheme.primary : null,
                ),
              ),
              style: TextButton.styleFrom(
                backgroundColor: isSelected
                    ? theme.colorScheme.primaryContainer.withValues(
                        alpha: 0.2,
                      )
                    : null,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
