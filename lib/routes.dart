import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:madari_client/engine/engine.dart';
import 'package:madari_client/pages/library_view.page.dart';
import 'package:madari_client/pages/stremio_item.page.dart';

import 'features/connections/types/stremio/stremio_base.types.dart';
import 'pages/download.page.dart';
import 'pages/getting_started.page.dart';
import 'pages/home.page.dart';
import 'pages/home_tab.page.dart';
import 'pages/more_tab.page.dart';
import 'pages/search_tab.page.dart';
import 'pages/sign_in.page.dart';
import 'pages/sign_up.page.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

GoRouter createRouter() {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/',
    refreshListenable: ValueNotifier(AppEngine.engine.pb.authStore.onChange),
    redirect: (context, state) => _routeGuard(context, state),
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return HomePage(
            navigationShell: navigationShell,
          );
        },
        branches: [
          StatefulShellBranch(
            navigatorKey: GlobalKey<NavigatorState>(debugLabel: 'Home'),
            routes: [
              GoRoute(
                path: HomeTabPage.routeName,
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: HomeTabPage(
                    hideAppBar: false,
                  ),
                ),
              ),
              GoRoute(
                path: "/library/:libraryId",
                builder: (context, state) => const LibraryViewPage(),
              )
            ],
          ),
          StatefulShellBranch(
            navigatorKey: GlobalKey<NavigatorState>(debugLabel: 'Search'),
            routes: [
              GoRoute(
                path: SearchPage.routeName,
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: SearchPage(),
                ),
              ),
            ],
          ),
          if (!kIsWeb)
            StatefulShellBranch(
              navigatorKey: GlobalKey<NavigatorState>(
                debugLabel: 'Downloads',
              ),
              routes: [
                GoRoute(
                  path: DownloadPage.routeName,
                  pageBuilder: (context, state) => const NoTransitionPage(
                    child: DownloadPage(),
                  ),
                ),
              ],
            ),
          StatefulShellBranch(
            navigatorKey: GlobalKey<NavigatorState>(debugLabel: 'Settings'),
            routes: [
              GoRoute(
                path: '/settings',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: MoreContainer(),
                ),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: "/info/stremio/:connection/:library/:type/:id",
        builder: (context, state) {
          final params = state.pathParameters;
          final meta = state.extra as Meta?;

          return StremioItemPage(
            hero: state.uri.queryParameters["hero"],
            type: params["type"]!,
            id: params["id"]!,
            connection: params["connection"]!,
            meta: meta,
            library: params["library"]!,
          );
        },
      ),
      GoRoute(
        path: "/info/stremio/:connection/:type/:id/stream",
        builder: (ctx, state) {
          return Container();
        },
      ),
      ShellRoute(
        parentNavigatorKey: rootNavigatorKey,
        routes: [
          GoRoute(
            path: GettingStartedPage.routeName,
            builder: (context, state) => const GettingStartedPage(),
          ),
        ],
      ),
      GoRoute(
        path: SignInPage.routeName,
        builder: (context, state) => const SignInPage(),
      ),
      GoRoute(
        path: SignUpPage.routeName,
        builder: (context, state) => const SignUpPage(),
      ),
    ],
  );
}

String? _routeGuard(
  BuildContext context,
  GoRouterState state,
) {
  final isLoggedIn = AppEngine.engine.pb.authStore.isValid;

  final bool isLoggingIn = state.uri.toString() == SignInPage.routeName ||
      state.uri.toString() == GettingStartedPage.routeName ||
      state.uri.toString() == SignUpPage.routeName;

  if (!isLoggedIn && !isLoggingIn) {
    return AppEngine.engine.pb.authStore.record?.getStringValue("setup") == ""
        ? GettingStartedPage.routeName
        : SignInPage.routeName;
  }

  if (isLoggedIn && isLoggingIn) {
    return '/';
  }

  return null;
}
