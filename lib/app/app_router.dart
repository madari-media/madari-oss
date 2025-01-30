import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:madari_client/features/downloads/pages/downloads_page.dart';
import 'package:madari_client/features/offline_ratings/pages/offline_ratings.dart';
import 'package:madari_client/features/settings/pages/profile_page.dart';

import '../features/accounts/pages/external_account.dart';
import '../features/auth/pages/forget_password_page.dart';
import '../features/auth/pages/signin_page.dart';
import '../features/auth/pages/signup_page.dart';
import '../features/explore/pages/explore.page.dart';
import '../features/home/pages/home_page.dart';
import '../features/layout/widgets/scaffold_with_nav.dart';
import '../features/library/container/create_list_widget.dart';
import '../features/library/pages/library.page.dart';
import '../features/library/pages/list_detail_page.dart';
import '../features/library/types/library_types.dart';
import '../features/pocketbase/service/pocketbase.service.dart';
import '../features/settings/pages/appearance_page.dart';
import '../features/settings/pages/change_password_page.dart';
import '../features/settings/pages/debug/logs_page.dart';
import '../features/settings/pages/full_profile_selector.dart';
import '../features/settings/pages/layout_page.dart';
import '../features/settings/pages/playback_settings_page.dart';
import '../features/settings/pages/settings_page.dart';
import '../features/settings/pages/subprofiles_page.dart';
import '../features/streamio_addons/pages/stremio_addons_page.dart';
import '../features/video_player/container/video_player.dart';
import '../features/widgetter/plugins/stremio/pages/streamio_item_viewer.dart';
import '../features/zeku/pages/integration_page.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<StatefulNavigationShellState> _shellNavigatorKey =
    GlobalKey<StatefulNavigationShellState>();

final GlobalKey<NavigatorState> _homeNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _searchNavigatorKey =
    GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _downloadsNavigatorKey =
    GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _settingsNavigatorKey =
    GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _exploreNavigatorKey =
    GlobalKey<NavigatorState>();

GoRouter createRouterDesktop() {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    refreshListenable: ValueNotifier(
      AppPocketBaseService.instance.pb.authStore.onChange,
    ),
    redirect: (context, state) {
      final isLoggedIn = AppPocketBaseService.instance.pb.authStore.isValid;
      final isAuthRoute = state.uri.path == '/signin' ||
          state.uri.path == '/signup' ||
          state.uri.path == '/forgot-password';

      if (!isLoggedIn && !isAuthRoute) {
        return '/signin';
      }

      if (isLoggedIn && isAuthRoute) {
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/signin',
        builder: (context, state) => const SignInPage(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordPage(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignUpPage(),
      ),
      GoRoute(
        path: "/downloads",
        builder: (context, state) => const DownloadsPage(),
      ),
      GoRoute(
        path: "/settings/integration",
        builder: (context, state) => const IntegrationPage(),
      ),
      StatefulShellRoute.indexedStack(
        key: _shellNavigatorKey,
        builder: (context, state, navigationShell) {
          return ScaffoldWithNav(
            child: navigationShell,
          );
        },
        branches: [
          StatefulShellBranch(
            navigatorKey: _homeNavigatorKey,
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => const HomePage(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _searchNavigatorKey,
            routes: [
              GoRoute(
                path: '/search',
                builder: (context, state) => const HomePage(
                  hasSearch: true,
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _exploreNavigatorKey,
            routes: [
              GoRoute(
                path: '/explore',
                builder: (context, state) => const ExplorePage(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _downloadsNavigatorKey,
            routes: [
              GoRoute(
                path: '/library',
                builder: (context, state) => const LibraryPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _settingsNavigatorKey,
            routes: settingsRoutes,
          )
        ],
      ),
      GoRoute(
        path: "/layout",
        builder: (context, state) => const LayoutPage(),
      ),
      GoRoute(
        path: '/library/create',
        builder: (context, state) => const CreateListPage(),
      ),
      GoRoute(
        path: '/library/:id',
        builder: (context, state) {
          final list = state.extra as ListModel;
          return ListDetailsPage(list: list);
        },
      ),
      GoRoute(
        path: "/profile",
        builder: (context, state) {
          return const FullProfileSelectorPage();
        },
      ),
      GoRoute(
        path: "/profile/manage",
        builder: (context, state) => const SubprofilesPage(),
      ),
      GoRoute(
        path: '/meta/:type/:id',
        builder: (context, state) {
          return StreamioItemViewer(
            id: state.pathParameters['id']!,
            type: state.pathParameters['type']!,
            image: state.uri.queryParameters["image"],
            name: state.uri.queryParameters['name'],
            prefix: state.uri.queryParameters['prefix'],
            meta: state.extra is Map ? (state.extra as Map)["meta"] : null,
          );
        },
      ),
      GoRoute(
        path: '/player/:type/:id/:stream',
        builder: (context, state) => VideoPlayer(
          id: state.pathParameters['id']!,
          type: state.pathParameters['type']!,
          stream: state.pathParameters["stream"]!,
          selectedIndex: state.uri.queryParameters["index"],
          meta: state.extra is Map ? (state.extra as Map)["meta"] : null,
        ),
      ),
      GoRoute(
        path: "/settings/offline-ratings",
        builder: (context, state) => const OfflineRatings(),
      ),
      GoRoute(
        path: '/settings/addons',
        builder: (context, state) => const StremioAddonsPage(),
      ),
    ],
  );
}

final List<RouteBase> settingsRoutes = [
  GoRoute(
    path: '/settings',
    builder: (context, state) => const SettingsPage(),
  ),
  GoRoute(
    path: '/settings/profile',
    builder: (context, state) => const ProfilePage(),
  ),
  GoRoute(
    path: '/settings/appearance',
    builder: (context, state) => const AppearancePage(),
  ),
  GoRoute(
    path: '/settings/stremio',
    builder: (context, state) => const StremioAddonsPage(),
  ),
  GoRoute(
    path: '/settings/playback',
    builder: (context, state) => const PlaybackSettingsPage(),
  ),
  GoRoute(
    path: '/settings/external-account',
    builder: (context, state) => const ExternalAccount(),
  ),
  GoRoute(
    path: '/settings/debug',
    builder: (context, state) => const LogsPage(),
  ),
  GoRoute(
    path: "/settings/security",
    builder: (context, state) => const ChangePasswordPage(),
  ),
  GoRoute(
    path: "/settings/subprofiles",
    builder: (context, state) => const SubprofilesPage(),
  ),
];
