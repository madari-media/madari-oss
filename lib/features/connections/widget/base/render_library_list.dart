import 'package:cached_query_flutter/cached_query_flutter.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:madari_client/engine/engine.dart';
import 'package:madari_client/features/connections/service/base_connection_service.dart';
import 'package:madari_client/features/connections/types/base/base.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../utils/grid.dart';
import '../stremio/stremio_filter.dart';

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
          return const Center(
            child: SpinnerCards(),
          );
        }

        if (state.status == QueryStatus.error) {
          final errorMessage = (
            state.error is ClientException
                ? (state.error as ClientException).response["message"]
                : "",
          );

          return SizedBox(
            height: getListHeight(context),
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
    loadFilters();
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  List<ConnectionFilterItem> filters = [];

  InfiniteQuery getQuery() {
    return InfiniteQuery<List<LibraryItem>, int>(
      key:
          "loadLibrary${widget.item.id}${(widget.filters + filters).map((res) => "${res.title}=${res.value}").join("&")}",
      queryFn: (page) {
        return service
            .getItems(
          widget.item,
          items: widget.filters + filters,
          page: page,
        )
            .then((docs) {
          return docs.items.toList();
        }).catchError((e, stack) {
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

  loadFilters() async {
    final filters = await service.getFilters(widget.item);

    if (mounted) {
      setState(() {
        filterList = filters;
      });
    }
  }

  List<ConnectionFilter>? filterList;

  @override
  Widget build(BuildContext context) {
    if (widget.isGrid) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.item.title),
        ),
        body: SizedBox(
          height: MediaQuery.of(context).size.height - 96,
          child: Flex(
            direction: Axis.vertical,
            children: [
              const SizedBox(
                height: 10,
              ),
              if (filterList == null)
                Row(
                  children: [
                    SizedBox(
                      height: 36,
                      width: 120,
                      child: Padding(
                        padding: const EdgeInsets.only(
                          left: 10.0,
                          right: 10.0,
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const SizedBox(
                            height: 36,
                            width: 120,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              if (filterList != null)
                InlineFilters(
                  filters: filterList ?? [],
                  filterCallback: (item) {
                    filters = item;

                    setState(() {
                      query = getQuery();
                    });
                  },
                ),
              const SizedBox(
                height: 10,
              ),
              Expanded(
                child: SizedBox(
                  height: MediaQuery.of(context).size.height - 96,
                  child: Padding(
                    padding: const EdgeInsets.only(
                      left: 10.0,
                      right: 10.0,
                    ),
                    child: _buildBody(),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return _buildBody();
  }

  _buildBody() {
    final listHeight = getListHeight(context);

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
          final items = (data.data?.expand((e) => e).toList() ?? [])
              .whereType<LibraryItem>()
              .toList();

          if (data.status == QueryStatus.loading && items.isEmpty) {
            return const CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: SpinnerCards(),
                )
              ],
            );
          }

          return RenderListItems(
            hasError: data.status == QueryStatus.error,
            onRefresh: () {
              query.refetch();
            },
            isGrid: widget.isGrid,
            items: items,
            heroPrefix: widget.item.id,
            service: service,
          );
        },
      ),
    );
  }
}

class RenderListItems extends StatelessWidget {
  final ScrollController? controller;
  final ScrollController? itemScrollController;
  final bool isGrid;
  final bool hasError;
  final VoidCallback? onRefresh;
  final BaseConnectionService service;
  final List<LibraryItem> items;
  final String heroPrefix;
  final dynamic error;
  final bool isWide;

  const RenderListItems({
    super.key,
    this.controller,
    this.isGrid = false,
    this.hasError = false,
    this.onRefresh,
    required this.items,
    required this.service,
    required this.heroPrefix,
    this.itemScrollController,
    this.error,
    this.isWide = false,
  });

  @override
  Widget build(BuildContext context) {
    final listHeight = getListHeight(context);
    final itemWidth = getItemWidth(
      context,
      isWide: isWide,
    );

    return CustomScrollView(
      controller: controller,
      physics: isGrid ? null : const NeverScrollableScrollPhysics(),
      slivers: [
        if (hasError)
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
                        "Something went wrong while loading the library \n$error",
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      TextButton.icon(
                        label: const Text("Retry"),
                        onPressed: onRefresh,
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
        if (isGrid)
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
                item,
                "${index}_$heroPrefix",
              );
            },
          ),
        if (!isGrid)
          SliverToBoxAdapter(
            child: SizedBox(
              height: listHeight,
              child: ListView.builder(
                itemBuilder: (ctx, index) {
                  final item = items[index];

                  return SizedBox(
                    width: itemWidth,
                    child: Container(
                      decoration: const BoxDecoration(),
                      child: service.renderCard(
                        item,
                        "${index}_${heroPrefix}",
                      ),
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
  }
}

class SpinnerCards extends StatelessWidget {
  final bool isWide;
  const SpinnerCards({
    super.key,
    this.isWide = false,
  });

  @override
  Widget build(BuildContext context) {
    final itemWidth = getItemWidth(
      context,
      isWide: isWide,
    );
    final itemHeight = getListHeight(context);

    return SizedBox(
      height: itemHeight,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
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

double getItemWidth(BuildContext context, {bool isWide = false}) {
  double screenWidth = MediaQuery.of(context).size.width;
  return screenWidth > 800
      ? (isWide ? 400.0 : 200.0)
      : (isWide ? 280.0 : 120.0);
}

double getListHeight(BuildContext context) {
  double screenWidth = MediaQuery.of(context).size.width;
  return screenWidth > 800 ? 300.0 : 180.0;
}
