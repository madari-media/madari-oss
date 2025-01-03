import 'package:cached_query_flutter/cached_query_flutter.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:madari_client/engine/engine.dart';
import 'package:madari_client/features/connections/service/base_connection_service.dart';
import 'package:madari_client/features/connections/types/base/base.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../utils/grid.dart';

final pb = AppEngine.engine.pb;

class RenderLibraryList extends StatefulWidget {
  final LibraryRecord item;
  final List<ConnectionFilterItem> filters;
  final bool isGrid;

  const RenderLibraryList({
    super.key,
    required this.item,
    required this.filters,
    this.isGrid = false,
  });

  @override
  State<RenderLibraryList> createState() => _RenderLibraryListState();
}

class _RenderLibraryListState extends State<RenderLibraryList> {
  late final query = Query(
    key: widget.item.id,
    queryFn: () => BaseConnectionService.connectionByIdRaw(
      widget.item.connection,
    ),
  );

  @override
  Widget build(BuildContext context) {
    return QueryBuilder(
      query: query,
      builder: (ctx, state) {
        if (state.status == QueryStatus.loading) {
          return const SpinnerCards();
        }

        if (state.status == QueryStatus.error) {
          final errorMessage = (
            state.error is ClientException
                ? (state.error as ClientException).response["message"]
                : "",
          );

          return SizedBox(
            height: _getListHeight(context),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                color: Colors.black45,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 16,
                  ),
                  child: Center(
                    child: Text(
                      "Something went wrong while loading library\n${errorMessage.$1}",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.exo2().copyWith(
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }

        try {
          return _RenderLibraryList(
            item: widget.item,
            service: state.data!,
            filters: widget.filters,
            isGrid: widget.isGrid,
          );
        } catch (e) {
          return Text("Error $e");
        }
      },
    );
  }
}

class _RenderLibraryList extends StatefulWidget {
  final LibraryRecord item;
  final ConnectionResponse service;
  final List<ConnectionFilterItem> filters;
  final bool isGrid;

  const _RenderLibraryList({
    required this.item,
    required this.service,
    required this.filters,
    required this.isGrid,
  });

  @override
  State<_RenderLibraryList> createState() => __RenderLibraryListState();
}

class __RenderLibraryListState extends State<_RenderLibraryList> {
  late BaseConnectionService service = BaseConnectionService.connectionById(
    widget.service,
  );

  final _scrollController = ScrollController();

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }

  void _onScroll() {
    if (_isBottom && query.state.status != QueryStatus.loading) {
      query.getNextPage();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    query = getQuery();
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  InfiniteQuery getQuery() {
    return InfiniteQuery<List<LibraryItem>, int>(
      key:
          "loadLibrary${widget.item.id}${widget.filters.map((res) => "${res.title}=${res.value}").join("&")}",
      queryFn: (page) {
        return service
            .getItems(
          widget.item,
          items: widget.filters,
          page: page,
        )
            .then((docs) {
          return docs.items.toList();
        }).catchError((e, stack) {
          print(e);
          print(stack);
          throw e;
        });
      },
      getNextArg: (state) {
        if (state.lastPage?.isEmpty ?? false) return null;
        return state.length;
      },
    );
  }

  late InfiniteQuery query = getQuery();

  bool isUnsupported = false;

  @override
  Widget build(BuildContext context) {
    final itemWidth = _getItemWidth(context);
    final listHeight = _getListHeight(context);

    if (isUnsupported) {
      return SizedBox(
        height: listHeight,
        child: const Text("This connection is not supported "),
      );
    }

    return SizedBox(
      height: listHeight,
      child: InfiniteQueryBuilder(
        query: query,
        builder: (context, data, query) {
          final items = data.data?.expand((e) => e).toList() ?? [];

          if (data.status == QueryStatus.loading && items.isEmpty) {
            return const CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: SpinnerCards(),
                )
              ],
            );
          }

          return CustomScrollView(
            controller: _scrollController,
            physics:
                widget.isGrid ? null : const NeverScrollableScrollPhysics(),
            slivers: [
              if (data.status == QueryStatus.error)
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: listHeight,
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Something went wrong while loading the library \n${data.error}",
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                            const SizedBox(
                              height: 10,
                            ),
                            TextButton.icon(
                              label: const Text("Retry"),
                              onPressed: () {
                                query.refetch();
                              },
                              icon: const Icon(
                                Icons.refresh,
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              if (widget.isGrid)
                SliverGrid.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: getGridResponsiveColumnCount(context),
                    mainAxisSpacing: getGridResponsiveSpacing(context),
                    crossAxisSpacing: getGridResponsiveSpacing(context),
                    childAspectRatio: 2 / 3,
                  ),
                  itemCount: items.length,
                  itemBuilder: (ctx, index) {
                    final item = items[index];

                    return service.renderCard(
                      widget.item,
                      item,
                      "${index}_${widget.item.id}",
                    );
                  },
                ),
              if (!widget.isGrid)
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: listHeight,
                    child: ListView.builder(
                      itemBuilder: (ctx, index) {
                        final item = items[index];

                        return SizedBox(
                          width: itemWidth,
                          child: service.renderCard(
                            widget.item,
                            item,
                            "${index}_${widget.item.id}",
                          ),
                        );
                      },
                      scrollDirection: Axis.horizontal,
                      itemCount: items.length,
                    ),
                  ),
                ),
              SliverPadding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).padding.bottom,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class SpinnerCards extends StatelessWidget {
  const SpinnerCards({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final itemWidth = _getItemWidth(context);
    final itemHeight = _getListHeight(context);

    return SizedBox(
      height: itemHeight,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, _) {
          return SizedBox(
            width: itemWidth,
            child: Container(
              margin: const EdgeInsets.only(
                right: 8,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Shimmer.fromColors(
                  baseColor: Colors.grey[800]!,
                  highlightColor: Colors.grey[700]!,
                  child: Container(
                    color: Colors.grey[800],
                  ),
                ),
              ),
            ),
          );
        },
        itemCount: 10,
      ),
    );
  }
}

double _getItemWidth(BuildContext context) {
  double screenWidth = MediaQuery.of(context).size.width;
  return screenWidth > 800 ? 200.0 : 120.0;
}

double _getListHeight(BuildContext context) {
  double screenWidth = MediaQuery.of(context).size.width;
  return screenWidth > 800 ? 300.0 : 180.0;
}
