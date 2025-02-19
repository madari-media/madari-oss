import 'dart:async';

import 'package:cached_query/cached_query.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';
import 'package:madari_client/features/streamio_addons/extension/query_extension.dart';
import 'package:madari_client/features/widgetter/plugin_base.dart';
import 'package:madari_client/features/widgetter/plugins/stremio/widgets/catalog_featured_shimmer.dart';
import 'package:madari_client/features/widgetter/service/home_layout_service.dart';
import 'package:madari_client/features/widgetter/state/widget_state_provider.dart';
import 'package:madari_client/features/widgetter/types/home_layout_model.dart';
import 'package:provider/provider.dart';

import '../home/pages/home_page.dart';
import '../pocketbase/service/pocketbase.service.dart';

class LayoutManager extends StatefulWidget {
  final bool hasSearch;

  const LayoutManager({
    super.key,
    this.hasSearch = false,
  });

  @override
  State<LayoutManager> createState() => LayoutManagerState();
}

class LayoutManagerState extends State<LayoutManager> {
  final _logger = Logger('LayoutManager');
  final ScrollController _scrollController = ScrollController();
  List<HomeLayoutModel> _layouts = [];
  List<HomeLayoutModel> _filteredLayouts = [];
  bool _isLoading = true;
  final profileService = AppPocketBaseService.instance.engine.profileService;

  late StreamSubscription<bool> _listener;

  @override
  void initState() {
    super.initState();
    _loadLayouts();

    _listener = profileService.onProfileUpdate.listen((_) {
      refresh();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _listener.cancel();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  Future<void> refresh() async {
    final result = await _loadLayouts(
      refresh: true,
    );

    HomeLayoutService.instance.refreshWidgets.add(true);

    return result;
  }

  Future<void> _loadLayouts({
    bool refresh = false,
  }) async {
    try {
      _logger.info('Loading layouts');
      print((await profileService.getCurrentProfile())!.id);
      final query = Query(
        key:
            "home_layout_${(await profileService.getCurrentProfile())!.id}${widget.hasSearch}",
        config: QueryConfig(
          ignoreCacheDuration: refresh,
          cacheDuration: const Duration(hours: 8),
          refetchDuration: const Duration(minutes: 5),
        ),
        queryFn: () async {
          return await AppPocketBaseService.instance.pb
              .collection('home_layout')
              .getFullList(
                sort: 'order',
                filter:
                    "profiles = '${(await profileService.getCurrentProfile())!.id}'",
              );
        },
      );

      if (refresh) {
        await query.refetch();
      }

      final records = await query.queryFn();

      setState(() {
        _layouts = records
            .map((record) => HomeLayoutModel.fromJson(record.toJson()))
            .toList();
        _filteredLayouts = _layouts;
        _isLoading = false;
      });
    } catch (e) {
      _logger.severe('Error loading layouts', e);
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final search = context.watch<StateProvider>().search;

    return RefreshIndicator(
      onRefresh: () {
        return refresh();
      },
      child: ListenableBuilder(
        listenable: PluginRegistry.instance,
        builder: (context, _) {
          if (_isLoading) {
            return const CatalogFeaturedShimmer();
          }

          if (_layouts.isEmpty) {
            return Center(
              child: Container(
                padding: const EdgeInsets.all(24.0),
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.design_services,
                      size: 64,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      "Configure Home Layout",
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "You need to define your home before start",
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 32),
                    FilledButton.icon(
                      onPressed: () {
                        context.push("/layout");
                      },
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text(
                        "Configure Layout",
                        style: TextStyle(
                          fontSize: 15,
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return Column(
            children: [
              if (widget.hasSearch)
                const SearchBox(
                  hintText: 'Search...',
                ),
              if (!widget.hasSearch || search.trim() != "")
                Expanded(
                  child: CustomScrollView(
                    controller: _scrollController,
                    slivers: [
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final layout = _filteredLayouts[index];

                            if (widget.hasSearch) {
                              if (!(layout.pluginId == "stremio_catalog" &&
                                  layout.type == "catalog_grid")) {
                                return const SizedBox.shrink();
                              }
                            }

                            return PluginWidget(
                              key: ValueKey(
                                '${layout.id}_${layout.pluginId}_${layout.type}_${search.trim()}',
                              ),
                              layout: layout,
                              pluginContext: PluginContext(
                                index: index,
                                hasSearch: widget.hasSearch,
                              ),
                            );
                          },
                          childCount: _filteredLayouts.length,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
