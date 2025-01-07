import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class TVHomePage extends StatefulWidget {
  static String get routeName => "/tv";
  final StatefulNavigationShell navigationShell;

  const TVHomePage({
    super.key,
    required this.navigationShell,
  });

  @override
  State<TVHomePage> createState() => _TVHomePageState();
}

class _TVHomePageState extends State<TVHomePage> {
  int _selectedIndex = 0;
  final FocusNode _contentFocusNode = FocusNode();
  final FocusNode _navigationFocusNode = FocusNode();

  // Handle keyboard navigation
  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {}
  }

  @override
  void dispose() {
    _contentFocusNode.dispose();
    _navigationFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Focus(
        focusNode: _navigationFocusNode,
        onKeyEvent: (node, event) {
          _handleKeyEvent(event);
          return KeyEventResult.handled;
        },
        child: Row(
          children: [
            NavigationRail(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) {
                setState(() {
                  _selectedIndex = index;
                  widget.navigationShell
                      .goBranch(index); // Navigate to the selected branch
                  _contentFocusNode.unfocus(); // Unfocus the content area
                });
              },
              labelType: NavigationRailLabelType.selected,
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.home),
                  label: Text('Home'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.search),
                  label: Text('Search'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.download),
                  label: Text('Downloads'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.settings),
                  label: Text('Settings'),
                ),
              ],
            ),
            Expanded(
              child: Focus(
                focusNode: _contentFocusNode,
                onKeyEvent: (node, event) {
                  _handleKeyEvent(event);
                  return KeyEventResult.handled;
                },
                child: widget.navigationShell,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
