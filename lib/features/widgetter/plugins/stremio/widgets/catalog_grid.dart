import 'dart:async';
import 'dart:math';

import 'package:cached_query_flutter/cached_query_flutter.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';
import 'package:madari_client/features/streamio_addons/extension/query_extension.dart';
import 'package:madari_client/features/widgetter/plugin_base.dart';
import 'package:madari_client/features/widgetter/plugins/stremio/widgets/catalog_featured.dart';
import 'package:madari_client/features/widgetter/plugins/stremio/widgets/stremio_card.dart';
import 'package:madari_client/utils/array-extension.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../streamio_addons/models/stremio_base_types.dart';
import '../../../../streamio_addons/service/stremio_addon_service.dart';
import '../../../interface/widgets.dart';
import '../../../service/home_layout_service.dart';
import '../../../state/widget_state_provider.dart';
import '../utils/size.dart';
import 'catalog_featured_shimmer.dart';
import 'catalog_grid_full.dart';
import 'error_card.dart';

final _logger = Logger('CatalogGrid');

class CatalogGrid extends StatefulWidget {
  final Map<String, dynamic> config;
  final bool isWide;
  final PluginContext pluginContext;

  const CatalogGrid({
    super.key,
    required this.config,
    this.isWide = false,
    required this.pluginContext,
  });

  @override
  State<CatalogGrid> createState() => _CatalogGridState();
}

class _CatalogGridState extends State<CatalogGrid> implements Refreshable {
  late InfiniteQuery<List<Meta>, int> _query;
  final ScrollController _scrollController = ScrollController();
  final service = StremioAddonService.instance;
  static const int pageSize = 20;
  int _focusedIndex = 0;
  bool _isFocused = false;

  late bool isWide = widget.config['wide'] == true;

  late final id =
      'catalog-${widget.config["type"]}-${widget.config["addon"]}-${widget.config["id"]}';

  late StreamSubscription<void> _refresh;

  InfiniteQuery<List<Meta>, int> getQuery({
    String? id,
  }) {
    final state = context.read<StateProvider>();

    return InfiniteQuery(
      key: (id ?? this.id) + state.search.trim(),
      getNextArg: (state) {
        final lastPage = state.lastPage;
        if (lastPage == null) return 1;
        if (lastPage.length < pageSize) return null;
        return state.length + 1;
      },
      queryFn: (page) async {
        _logger.info('Fetching catalog for page: $page');
        try {
          final addonManifest = await service
              .validateManifest(
                widget.config["addon"],
              )
              .queryFn();

          List<ConnectionFilterItem> items = [];

          if (state.search.trim() != "" && widget.pluginContext.hasSearch) {
            items.add(
              ConnectionFilterItem(
                title: "search",
                value: state.search,
              ),
            );
          }

          if (state.state.containsKey("genre") &&
              (state.state["genre"] as String?)?.trim() != "") {
            items.add(
              ConnectionFilterItem(
                title: "genre",
                value: state.state["genre"],
              ),
            );
          }

          final result = await service.getCatalog(
            addonManifest,
            widget.config["type"],
            widget.config["id"],
            page - 1,
            items,
          );

          return result.sublist(0, min(pageSize, result.length));
        } catch (e, stack) {
          _logger.severe('Error fetching catalog: $e', e, stack);
          throw Exception('Failed to fetch catalog');
        }
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _query = getQuery();

    _refresh = HomeLayoutService.instance.refreshWidgets.listen((value) {
      _query.refetch();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _refresh.cancel();
    super.dispose();
  }

  Widget _buildShimmerCard(BuildContext context, StremioCardSize cardSize) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(right: 12),
      child: Shimmer.fromColors(
        baseColor: theme.brightness == Brightness.light
            ? Colors.grey[300]!
            : Colors.grey[800]!,
        highlightColor: theme.brightness == Brightness.light
            ? Colors.grey[100]!
            : Colors.grey[700]!,
        child: Container(
          width: cardSize.width,
          height: cardSize.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.red,
            boxShadow: [
              BoxShadow(
                color: theme.shadowColor.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool hasNoContent(StateProvider state) {
    final hasSearchContent = context.read<StateProvider>();

    if (widget.pluginContext.hasSearch) {
      if ((!(widget.config["extra_supported"] as List).contains("search")) ||
          hasSearchContent.search.trim() == "") {
        return true;
      }
    }

    final required = (widget.config["extra_required"] ?? []).every((item) {
      final result = [widget.pluginContext.hasSearch ? "search" : ""]
          .firstWhereOrNull((allItem) {
        return allItem == item;
      });

      return result != null;
    });

    if (required == false) {
      return true;
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    final cardSize = StremioCardSize.getSize(context);

    final widgetState = context.watch<StateProvider>();

    return InfiniteQueryBuilder(
      query: _query,
      builder: (context, state, query) {
        if (state.error != null) {
          _logger.severe('Error in query state: ${state.error}');
          return ErrorCard(error: state.error.toString());
        }

        final type = widget.config["type"].toString();
        final title = "${type.capitalize} ${widget.config["name"]}";

        if (((widget.config["extra_supported"] ?? []) as List)
            .contains("featured")) {
          if (widget.pluginContext.hasSearch) {
            return const SizedBox.shrink();
          }

          if (state.data?.firstOrNull == null) {
            return const CatalogFeaturedShimmer();
          }

          if ((state.data?.first ?? []).isEmpty) {
            return const SizedBox.shrink();
          }

          return CatalogFeatured(
            meta: state.data?.first ?? [],
            onTap: () {},
          );
        }

        if (hasNoContent(widgetState)) {
          return const SizedBox.shrink();
        }

        final allItems = state.data?.expand((page) => page).toList() ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(
              height: 6,
            ),
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                const Spacer(),
                if (!widget.pluginContext.hasSearch)
                  SizedBox(
                    height: 34,
                    child: TextButton(
                      onPressed: () {
                        final query = getQuery();

                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => CatalogFullView(
                              title: title,
                              initialItems: allItems,
                              queryBuilder: () {
                                return query;
                              },
                              prefix:
                                  widget.pluginContext.hasSearch.toString() +
                                      widget.pluginContext.index.toString() +
                                      widget.config["description"] +
                                      widget.config["id"] +
                                      widget.config["type"],
                            ),
                          ),
                        );
                      },
                      child: const Text("Show more"),
                    ),
                  ),
              ],
            ),
            SizedBox(
              height: cardSize.height,
              child: state.status == QueryStatus.loading && allItems.isEmpty
                  ? ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: 20,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      itemBuilder: (context, index) => SizedBox(
                        height: cardSize.height,
                        width: cardSize.width,
                        child: _buildShimmerCard(
                          context,
                          cardSize,
                        ),
                      ),
                    )
                  : _buildContentList(
                      context,
                      state: state,
                      cardSize,
                      title: title,
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildContentList(
    BuildContext context,
    StremioCardSize cardSize, {
    required InfiniteQueryState<List<Meta>> state,
    required String title,
  }) {
    final allItems = state.data?.expand((page) => page).toList() ?? [];
    final itemCount = allItems.take(15).length +
        (!(allItems.isNotEmpty && widget.pluginContext.hasSearch) ? 1 : 0);

    if (allItems.isEmpty) {
      return const SizedBox(
        width: double.infinity,
        child: ErrorCard(
          title: "No results",
          error: "No result found",
          hideIcon: true,
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      itemCount: itemCount,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      itemBuilder: (context, index) {
        if (index == allItems.take(15).length) {
          return _buildShowMoreCard(
            context,
            cardSize,
            allItems,
            title: title,
          );
        }

        return _buildItemCard(
          context,
          allItems[index],
          cardSize,
          index == _focusedIndex && _isFocused,
        );
      },
    );
  }

  Widget _buildShowMoreCard(
    BuildContext context,
    StremioCardSize cardSize,
    List<Meta> allItems, {
    required String title,
  }) {
    final isFocused = _focusedIndex == allItems.take(15).length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Container(
        width: cardSize.width,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: isFocused
              ? Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 3.0,
                )
              : Border.all(
                  color: Colors.transparent,
                  width: 3.0,
                ),
          boxShadow: isFocused
              ? [
                  BoxShadow(
                    color:
                        Theme.of(context).colorScheme.primary.withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 2,
                  )
                ]
              : null,
        ),
        child: Card(
          elevation: 4,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            focusNode: FocusNode(),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => CatalogFullView(
                    title: title,
                    queryBuilder: () {
                      return getQuery();
                    },
                    initialItems: [],
                    prefix: widget.pluginContext.hasSearch.toString() +
                        widget.pluginContext.index.toString() +
                        widget.config["description"] +
                        widget.config["id"] +
                        widget.config["type"],
                  ),
                ),
              );
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.grid_view_rounded,
                  size: 32,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 8),
                Text(
                  'Show More',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildItemCard(
    BuildContext context,
    Meta item,
    StremioCardSize cardSize,
    bool isFocused,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Container(
        width: cardSize.width * (isWide ? 2.6 : 1),
        height: cardSize.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: isFocused
              ? Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 3.0,
                )
              : Border.all(
                  color: Colors.transparent,
                  width: 3.0,
                ),
          boxShadow: isFocused
              ? [
                  BoxShadow(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.3),
                    blurRadius: 8,
                    spreadRadius: 2,
                  )
                ]
              : null,
        ),
        child: StremioCard(
          isWide: isWide,
          item: item,
          prefix: widget.pluginContext.hasSearch.toString() +
              widget.pluginContext.index.toString() +
              widget.config["description"] +
              widget.config["id"] +
              widget.config["type"],
          onTap: (image) {
            final prefix = widget.pluginContext.hasSearch.toString() +
                widget.pluginContext.index.toString() +
                widget.config["description"] +
                widget.config["id"] +
                widget.config["type"] +
                "${item.type}${item.id}";

            context.push(
              "/meta/${item.type}/${item.id}?image=${Uri.encodeQueryComponent(item.poster ?? "")}&name=${item.name == null ? "" : Uri.encodeQueryComponent(item.name!)}&prefix=${Uri.encodeQueryComponent(prefix)}",
              extra: {
                "meta": item,
              },
            );
          },
          focusNode: FocusNode(),
        ),
      ),
    );
  }

  @override
  Future refresh() async {
    return _query.refetch();
  }
}
