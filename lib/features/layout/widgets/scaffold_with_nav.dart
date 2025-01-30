import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:universal_platform/universal_platform.dart';

import '../../widgetter/state/widget_state_provider.dart';
import '../data/navigation_items.dart';
import '../models/device_type.dart';
import 'desktop_navigation.dart';
import 'mobile_navigation.dart';

class ScaffoldWithNav extends StatefulWidget {
  final StatefulNavigationShell child;

  const ScaffoldWithNav({
    super.key,
    required this.child,
  });

  @override
  State<ScaffoldWithNav> createState() => _ScaffoldWithNavState();
}

class _ScaffoldWithNavState extends State<ScaffoldWithNav> {
  DateTime? currentBackPressTime;
  bool canPopNow = false;
  static const int requiredSeconds = 2;

  DeviceType _getDeviceType() {
    if (UniversalPlatform.isIOS || UniversalPlatform.isAndroid) {
      return DeviceType.mobile;
    }

    return DeviceType.desktop;
  }

  @override
  void initState() {
    super.initState();
  }

  String previousSearch = "";

  onNavigate(int index) {
    widget.child.goBranch(index);

    final contextData = context.read<StateProvider>();

    if (index == 0) {
      previousSearch = contextData.search;
      contextData.setSearch("");
    } else if (index == 1) {
      contextData.setSearch(previousSearch);
    }
  }

  void onPopInvoked(bool didPop) {
    DateTime now = DateTime.now();
    if (currentBackPressTime == null ||
        now.difference(currentBackPressTime!) >
            const Duration(seconds: requiredSeconds)) {
      currentBackPressTime = now;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Tap back again to leave"),
          duration: Duration(seconds: 2),
        ),
      );
      Future.delayed(
        const Duration(seconds: requiredSeconds),
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
  Widget build(BuildContext context) {
    return PopScope(
      canPop: canPopNow,
      onPopInvokedWithResult: (c, cc) => onPopInvoked(c),
      child: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    final deviceType = _getDeviceType();

    switch (deviceType) {
      case DeviceType.mobile:
        return Scaffold(
          body: Padding(
            padding: const EdgeInsets.only(bottom: 64.0),
            child: widget.child,
          ),
          extendBody: true,
          bottomNavigationBar: MobileNavigation(
            items: navigationItems,
            currentIndex: widget.child.currentIndex,
            onNavigate: onNavigate,
          ),
        );

      case DeviceType.desktop:
        return Scaffold(
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(kToolbarHeight),
            child: DesktopNavigation(
              items: navigationItems,
              currentIndex: widget.child.currentIndex,
              onNavigate: onNavigate,
            ),
          ),
          body: widget.child,
        );
    }
  }
}
