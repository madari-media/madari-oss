import 'dart:io';

import 'package:cached_query_flutter/cached_query_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:madari_client/engine/library.dart';
import 'package:madari_client/features/connections/service/base_connection_service.dart';
import 'package:madari_client/features/trakt/containers/up_next.container.dart';
import 'package:madari_client/features/trakt/service/trakt.service.dart';
import 'package:pocketbase/pocketbase.dart';

import '../features/connections/widget/base/render_library_list.dart';
import '../features/getting_started/container/getting_started.dart';
import '../utils/auth_refresh.dart';

class HomeTabPage extends StatefulWidget {
  final String? search;
  final bool hideAppBar;
  final LibraryRecordResponse? defaultLibraries;

  static String get routeName => "/";

  const HomeTabPage({
    super.key,
    this.search,
    this.hideAppBar = kIsWeb,
    this.defaultLibraries,
  });

  @override
  State<HomeTabPage> createState() => _HomeTabPageState();
}

class _HomeTabPageState extends State<HomeTabPage> {
  late final query = Query(
    queryFn: () async {
      try {
        if (TraktService.isEnabled() == true) {
          await TraktService.ensureInitialized();
        }
      } catch (e, stack) {
        print(e);
        print(stack);
      }

      if (widget.defaultLibraries != null) {
        return Future.value(
          widget.defaultLibraries,
        );
      }

      return await BaseConnectionService.getLibraries();
    },
    key: [
      "home${widget.defaultLibraries?.data.length ?? 0}${widget.search ?? ""}",
    ],
  );

  final Map<int, GlobalKey<TraktContainerState>> _keyMap = {};

  GlobalKey<TraktContainerState> _getKey(int id) {
    return _keyMap.putIfAbsent(
      id,
      () => GlobalKey<TraktContainerState>(),
    );
  }

  Future<void> _onRefresh() async {
    TraktService.instance?.clearCache();
    final List<Future> promises = [];
    for (final item in traktLibraries) {
      final state = _getKey(traktLibraries.indexOf(item)).currentState;

      if (state == null) continue;

      promises.add(() async {
        try {
          state.refresh();
        } catch (e) {}
      }());
    }

    await Future.wait(promises);
  }

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      query.refetch();
    });

    super.initState();

    traktLibraries = getTraktLibraries();
  }

  List<String> traktLibraries = [];

  final traktService = TraktService();

  List<String> getTraktLibraries() {
    if (widget.defaultLibraries?.data.isNotEmpty == true) {
      return [];
    }

    return traktService.getHomePageContent();
  }

  reloadPage() async {
    await refreshAuth();
    await query.refetch();
    setState(() {
      traktLibraries = getTraktLibraries();
    });
    await _onRefresh();
    return;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDesktop = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      appBar: (widget.hideAppBar || isDesktop) || widget.search?.trim() == ""
          ? null
          : AppBar(
              title: Text(
                "Madari",
                style: GoogleFonts.montserrat(),
              ),
              actions: [
                if (isWeb || (!Platform.isIOS && !Platform.isAndroid))
                  IconButton(
                    onPressed: () {
                      reloadPage();
                    },
                    icon: const Icon(
                      Icons.refresh,
                    ),
                  ),
              ],
            ),
      body: RefreshIndicator(
        onRefresh: () async {
          return reloadPage();
        },
        child: QueryBuilder(
          query: query,
          builder: (context, state) {
            if (QueryStatus.error == state.status) {
              return _buildError(state.error);
            }

            final data = state.data;

            if (data == null) {
              return const Text("Loading");
            }

            if (data.data.isEmpty && widget.defaultLibraries != null) {
              return Padding(
                padding: const EdgeInsets.only(
                  bottom: 24,
                  left: 12,
                  right: 12,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: GettingStartedScreen(
                    onCallback: () async {
                      await refreshAuth();

                      query.refetch();
                      setState(() {
                        traktLibraries = getTraktLibraries();
                      });

                      await _onRefresh();
                    },
                  ),
                ),
              );
            }

            return Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 8.0,
                horizontal: 16.0,
              ),
              child: ListView.builder(
                itemBuilder: (item, index) {
                  if (traktLibraries.length > index) {
                    final category = traktLibraries[index];

                    return TraktContainer(
                      key: _getKey(index),
                      loadId: category,
                    );
                  }

                  final item = data.data[index - traktLibraries.length];

                  return Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              item.title,
                              style: theme.textTheme.bodyLarge,
                            ),
                            const Spacer(),
                            SizedBox(
                              height: 30,
                              child: TextButton(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) {
                                        return ShowMorePage(
                                          item: item,
                                          search: widget.search,
                                        );
                                      },
                                    ),
                                  );
                                },
                                child: Text(
                                  "Show more",
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: Colors.white70,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(
                          height: 8,
                        ),
                        RenderLibraryList(
                          item: item,
                          filters: [
                            if ((widget.search ?? "").trim() != "")
                              ConnectionFilterItem(
                                title: "search",
                                value: widget.search,
                              ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
                itemCount: data.data.length + traktLibraries.length,
              ),
            );
          },
        ),
      ),
    );
  }

  _buildError(Error? error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 60,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Oops! Something went wrong',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error?.toString() ?? 'Failed to load libraries',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => query.refetch(),
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}

class ShowMorePage extends StatelessWidget {
  final LibraryRecord item;
  final String? search;

  const ShowMorePage({
    super.key,
    required this.item,
    required this.search,
  });

  @override
  Widget build(BuildContext context) {
    return RenderLibraryList(
      item: item,
      isGrid: true,
      filters: [
        if ((search ?? "").trim() != "")
          ConnectionFilterItem(
            title: "search",
            value: search,
          ),
      ],
    );
  }
}
