import 'package:cached_query/cached_query.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:madari_client/features/settings/service/selected_profile.dart';
import 'package:madari_client/features/streamio_addons/extension/query_extension.dart';
import 'package:madari_client/features/widgetter/plugin_base.dart';
import 'package:madari_client/features/widgetter/plugins/stremio/widgets/catalog_featured_shimmer.dart';
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

  @override
  void initState() {
    super.initState();
    _loadLayouts();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  Future<void> refresh() {
    return _loadLayouts(
      refresh: true,
    );
  }

  Future<void> _loadLayouts({
    bool refresh = false,
  }) async {
    try {
      _logger.info('Loading layouts');
      final query = Query(
        key: "home_layout_${SelectedProfileService.instance.selectedProfileId}",
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
                    "profiles = '${SelectedProfileService.instance.selectedProfileId}'",
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

          return Column(
            children: [
              if (widget.hasSearch)
                const SearchBox(
                  hintText: 'Search...',
                ),
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
