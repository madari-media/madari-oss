import 'package:cached_query_flutter/cached_query_flutter.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';
import 'package:madari_client/features/widgetter/plugins/stremio/widgets/stremio_card.dart';
import 'package:madari_engine/madari_engine.dart';
import 'package:shimmer/shimmer.dart';

import '../utils/size.dart';

typedef GetQuery = InfiniteQuery<List<Meta>, int> Function();

class CatalogFullView extends StatefulWidget {
  final List<Meta> initialItems;
  final String prefix;
  final String? title;
  final GetQuery queryBuilder;
  final bool supportsLoadMore;

  const CatalogFullView({
    super.key,
    required this.initialItems,
    required this.prefix,
    required this.queryBuilder,
    this.title,
    this.supportsLoadMore = false,
  });

  @override
  State<CatalogFullView> createState() => _CatalogFullViewState();
}

class _CatalogFullViewState extends State<CatalogFullView> {
  final ScrollController _scrollController = ScrollController();
  final _logger = Logger("CatalogFullView");

  late final InfiniteQuery<List<Meta>, int> _query;

  @override
  void initState() {
    super.initState();

    _query = widget.queryBuilder();
  }

  Future<void> _loadMoreData() async {
    final currentState = _query.state;

    if (currentState.lastPage != null && currentState.lastPage!.isEmpty) {
      _logger.info("Last page is empty");
      return;
    }

    if (currentState.status == QueryStatus.loading) {
      _logger.info("Status is loading");
      return;
    }

    _logger.info("Loading next page");

    await _query.getNextPage();
  }

  Widget _buildShimmerCard(BuildContext context, StremioCardSize cardSize) {
    final theme = Theme.of(context);

    return Shimmer.fromColors(
      baseColor: theme.focusColor,
      highlightColor: theme.secondaryHeaderColor,
      child: Container(
        width: cardSize.width,
        height: cardSize.height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cardSize = StremioCardSize.getSize(context, isGrid: true);

    return Scaffold(
      appBar: widget.title != null
          ? AppBar(
              title: Text(widget.title!),
              elevation: 2,
            )
          : null,
      body: InfiniteQueryBuilder(
        query: _query,
        builder: (context, state, query) {
          final allItems = state.data?.expand((page) => page).toList() ??
              widget.initialItems;

          final shouldShowLoading = state.lastPage?.isNotEmpty ?? true;

          return NotificationListener(
            onNotification: (ScrollNotification scrollInfo) {
              if (scrollInfo is ScrollEndNotification) {
                _loadMoreData();
              }
              return true;
            },
            child: GridView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(8),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: cardSize.columns,
                childAspectRatio: 2 / 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount:
                  allItems.length + (shouldShowLoading ? cardSize.columns : 0),
              itemBuilder: (context, index) {
                if (index >= allItems.length) {
                  return _buildShimmerCard(context, cardSize);
                }

                return SizedBox(
                  width: cardSize.width,
                  height: cardSize.height,
                  child: StremioCard(
                    item: allItems[index],
                    onTap: (_) {
                      final item = allItems[index];
                      context.push(
                        "/meta/${item.type}/${item.id}?image=${Uri.encodeQueryComponent(item.poster ?? "")}&name=${item.name == null ? "" : Uri.encodeQueryComponent(item.name!)}&prefix=${Uri.encodeQueryComponent(widget.prefix)}",
                        extra: {
                          "meta": item,
                        },
                      );
                    },
                    focusNode: FocusNode(),
                    prefix: widget.prefix,
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
