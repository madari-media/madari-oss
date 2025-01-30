import 'package:flutter/material.dart';

import '../models/navigation.model.dart';

class TVNavigation extends StatefulWidget {
  final List<NavigationItem> items;
  final String currentLocation;
  final ValueChanged<int> onNavigate;
  final bool isTV;

  const TVNavigation({
    super.key,
    required this.items,
    required this.currentLocation,
    required this.onNavigate,
    this.isTV = false,
  });

  @override
  State<TVNavigation> createState() => _TVNavigationState();
}

class _TVNavigationState extends State<TVNavigation> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: _isExpanded ? 240.0 : 72.0,
      child: Drawer(
        elevation: 0,
        child: Column(
          crossAxisAlignment: _isExpanded
              ? CrossAxisAlignment.start
              : CrossAxisAlignment.center,
          children: [
            if (!widget.isTV)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: IconButton(
                  icon: Icon(
                      _isExpanded ? Icons.chevron_left : Icons.chevron_right),
                  onPressed: () => setState(() => _isExpanded = !_isExpanded),
                ),
              ),
            Expanded(
              child: ListView(
                children: widget.items.map((item) {
                  final isSelected =
                      widget.currentLocation.startsWith(item.path);
                  return ListTile(
                    selected: isSelected,
                    leading: Icon(
                      isSelected ? item.selectedIcon ?? item.icon : item.icon,
                      color: isSelected ? theme.colorScheme.primary : null,
                    ),
                    title: _isExpanded ? Text(item.label) : null,
                    onTap: () => widget.onNavigate(0),
                    autofocus: widget.isTV && isSelected,
                    selectedTileColor:
                        theme.colorScheme.primaryContainer.withValues(
                      alpha: 0.2,
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
