import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pocketbase/pocketbase.dart';

import '../engine/engine.dart';

class HomePage extends StatefulWidget {
  static String get routeName => "/";
  final StatefulNavigationShell navigationShell;

  const HomePage({
    super.key,
    required this.navigationShell,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  DateTime? currentBackPressTime;
  bool canPopNow = false;
  int requiredSeconds = 2;

  RecordModel? _authUser;

  late List<NavigationItem> _items;

  void onPopInvoked(bool didPop) {
    DateTime now = DateTime.now();
    if (currentBackPressTime == null ||
        now.difference(currentBackPressTime!) >
            Duration(seconds: requiredSeconds)) {
      currentBackPressTime = now;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Tap back again to leave"),
          duration: Duration(seconds: 2),
        ),
      );
      Future.delayed(
        Duration(seconds: requiredSeconds),
        () {
          setState(() {
            canPopNow = false;
          });
        },
      );
      setState(() {
        canPopNow = true;
      });
    }
  }

  @override
  void initState() {
    super.initState();

    _authUser = AppEngine.engine.pb.authStore.record;

    _items = NavigationItems.items(_authUser!);
  }

  PreferredSizeWidget appBarRef() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(94),
      child: Column(
        children: [
          Container(
            constraints: const BoxConstraints(
              maxWidth: 600,
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.only(
                  top: 16.0,
                  bottom: 16.0,
                ),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(32),
                  ),
                  child: NavigationBar(
                    selectedIndex: widget.navigationShell.currentIndex,
                    onDestinationSelected: _onDestinationSelected,
                    backgroundColor: Colors.transparent,
                    labelBehavior:
                        NavigationDestinationLabelBehavior.onlyShowSelected,
                    height: 60,
                    destinations: _items
                        .map((item) => NavigationDestination(
                              icon: Icon(item.icon, color: Colors.white),
                              label: item.label,
                            ))
                        .toList(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onDestinationSelected(int index) {
    widget.navigationShell.goBranch(index);
  }

  String? get mediaType {
    return _authUser?.getStringValue("mode") == "study" ? "study" : "media";
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 800;
    final isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    return PopScope(
      canPop: canPopNow,
      onPopInvokedWithResult: (c, cc) => onPopInvoked(c),
      child: Scaffold(
        appBar: isDesktop ? appBarRef() : null,
        body: Stack(
          children: [
            AnimatedPadding(
              padding: isKeyboardVisible
                  ? EdgeInsets.zero
                  : const EdgeInsets.only(bottom: 52.0),
              duration: const Duration(milliseconds: 200),
              child: widget.navigationShell,
            ),
            if (!isDesktop)
              AnimatedPositioned(
                duration: const Duration(milliseconds: 200),
                left: 0,
                right: 0,
                bottom: isKeyboardVisible ? -100 : 8,
                child: SafeArea(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(32),
                    ),
                    child: NavigationBar(
                      selectedIndex: widget.navigationShell.currentIndex,
                      onDestinationSelected: _onDestinationSelected,
                      backgroundColor: Colors.transparent,
                      labelBehavior:
                          NavigationDestinationLabelBehavior.alwaysHide,
                      height: 48,
                      destinations: _items
                          .map((item) => Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 2.0,
                                ),
                                child: NavigationDestination(
                                  icon: Icon(item.icon, color: Colors.white),
                                  label: item.label,
                                ),
                              ))
                          .toList(),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class NavigationItem {
  final String route;
  final String label;
  final IconData icon;

  const NavigationItem({
    required this.route,
    required this.label,
    required this.icon,
  });
}

class NavigationItems {
  static const home = NavigationItem(
    route: 'home',
    label: 'Home',
    icon: Icons.home,
  );

  static const downloads = NavigationItem(
    route: "downloads",
    label: "Downloads",
    icon: Icons.download,
  );

  static const search = NavigationItem(
    route: 'search',
    label: 'Search',
    icon: Icons.search,
  );

  static const more = NavigationItem(
    route: 'settings',
    label: 'Settings',
    icon: Icons.person_outline,
  );

  static List<NavigationItem> items(RecordModel auth) {
    return [
      home,
      search,
      if (!kIsWeb) downloads,
      more,
    ];
  }
}
