import 'dart:async';

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:madari_client/features/connections/service/base_connection_service.dart';
import 'package:madari_client/features/trakt/service/trakt.service.dart';

import '../../connections/widget/base/render_library_list.dart';
import '../../settings/screen/trakt_integration_screen.dart';

class TraktContainer extends StatefulWidget {
  final String loadId;
  const TraktContainer({
    super.key,
    required this.loadId,
  });

  @override
  State<TraktContainer> createState() => TraktContainerState();
}

class TraktContainerState extends State<TraktContainer> {
  final Logger _logger = Logger('TraktContainerState');

  List<LibraryItem>? _cachedItems;
  bool _isLoading = false;
  String? _error;

  int _currentPage = 1;

  static const _itemsPerPage = 5;

  final _scrollController = ScrollController();

  StreamSubscription<List<String>>? _steam;

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }

  @override
  void initState() {
    super.initState();
    _logger.info('Initializing TraktContainerState');
    _loadData();

    _steam = TraktService.instance?.refetchKey.stream.listen((item) {
      if (item.contains(widget.loadId)) {
        _logger.info("refreshing widget ${widget.loadId}");
        _cachedItems = [];
        _loadData();
      }
    });

    _scrollController.addListener(() {
      if (_isBottom) {
        _loadData(isLoadMore: true);
      }
    });
  }

  @override
  void dispose() {
    _logger.info('Disposing TraktContainerState');
    _scrollController.dispose();
    _steam?.cancel();
    super.dispose();
  }

  Future<void> _loadData({
    bool isLoadMore = false,
  }) async {
    _logger.info('Started loading data for the _loadData');
    if (_isLoading) {
      _logger.warning('Load data called while already loading');
      return;
    }
    _isLoading = true;

    setState(() {
      _error = null;
    });

    try {
      final page = isLoadMore ? _currentPage + 1 : _currentPage;

      List<LibraryItem>? newItems;

      _logger.info('Loading data for loadId: ${widget.loadId}, page: $page');

      switch (widget.loadId) {
        case "up_next_series":
          newItems = await TraktService.instance!
              .getUpNextSeries(
                page: page,
                itemsPerPage: _itemsPerPage,
              )
              .first;
          break;
        case "continue_watching":
          newItems = await TraktService.instance!.getContinueWatching(
            page: page,
            itemsPerPage: _itemsPerPage,
          );
          break;
        case "upcoming_schedule":
          newItems = await TraktService.instance!.getUpcomingSchedule(
            page: page,
            itemsPerPage: _itemsPerPage,
          );
          break;
        case "watchlist":
          newItems = await TraktService.instance!.getWatchlist(
            page: page,
            itemsPerPage: _itemsPerPage,
          );
          break;
        case "show_recommendations":
          newItems = await TraktService.instance!.getShowRecommendations(
            page: page,
            itemsPerPage: _itemsPerPage,
          );
          break;
        case "movie_recommendations":
          newItems = await TraktService.instance!.getMovieRecommendations(
            page: page,
            itemsPerPage: _itemsPerPage,
          );
          break;
        default:
          _logger.severe('Invalid loadId: ${widget.loadId}');
          throw Exception("Invalid loadId: ${widget.loadId}");
      }

      if (mounted) {
        setState(() {
          _currentPage = page;
          _cachedItems = [...?_cachedItems, ...?newItems];
          _isLoading = false;
        });

        _logger.info('Data loaded successfully for loadId: ${widget.loadId}');
      }
    } catch (e) {
      _logger.severe('Error loading data: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> refresh() async {
    _logger.info('Refreshing data');
    _cachedItems = [];
    await _loadData();
  }

  String get title {
    return traktCategories
        .firstWhere((item) => item.key == widget.loadId)
        .title;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                title,
                style: theme.textTheme.bodyLarge,
              ),
              const Spacer(),
              SizedBox(
                height: 30,
                child: TextButton(
                  onPressed: () {
                    _logger.info('Navigating to Trakt details page');
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) {
                          return Scaffold(
                            appBar: AppBar(
                              title: Text("Trakt - $title"),
                            ),
                            body: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: RenderListItems(
                                loadMore: () {
                                  _loadData(
                                    isLoadMore: true,
                                  );
                                },
                                items: _cachedItems ?? [],
                                error: _error,
                                isLoadingMore: _isLoading,
                                hasError: _error != null,
                                heroPrefix: "trakt_up_next${widget.loadId}",
                                service: TraktService.stremioService!,
                                isGrid: true,
                                isWide: false,
                              ),
                            ),
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
          Stack(
            children: [
              if ((_cachedItems ?? []).isEmpty && !_isLoading)
                const Positioned.fill(
                  child: Center(
                    child: Text("Nothing to see here"),
                  ),
                ),
              if (_isLoading && (_cachedItems ?? []).isEmpty)
                const SpinnerCards(),
              SizedBox(
                height: getListHeight(context),
                child: RenderListItems(
                  isWide: widget.loadId == "up_next_series",
                  items: _cachedItems ?? [],
                  error: _error,
                  itemScrollController: _scrollController,
                  hasError: _error != null,
                  heroPrefix: "trakt_up_next${widget.loadId}",
                  service: TraktService.stremioService!,
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}
