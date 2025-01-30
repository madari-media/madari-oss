import 'package:flutter/material.dart';

import '../models/navigation.model.dart';

final navigationItems = [
  const NavigationItem(
    label: 'Home',
    path: '/',
    icon: Icons.home_outlined,
    selectedIcon: Icons.home,
  ),
  const NavigationItem(
    label: 'Search',
    path: '/search',
    icon: Icons.search_outlined,
    selectedIcon: Icons.search,
  ),
  const NavigationItem(
    label: 'Explore',
    path: '/explore',
    icon: Icons.explore_outlined,
    selectedIcon: Icons.explore,
  ),
  const NavigationItem(
    label: 'Library',
    path: '/library',
    icon: Icons.video_library_outlined,
    selectedIcon: Icons.video_library,
  ),
  const NavigationItem(
    label: 'Settings',
    path: '/settings',
    icon: Icons.settings_outlined,
    selectedIcon: Icons.settings,
  ),
];
