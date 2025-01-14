import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:madari_client/features/connections/service/base_connection_service.dart';
import 'package:madari_client/features/trakt/service/trakt.service.dart';
import 'package:madari_client/utils/common.dart';

import '../../connections/types/stremio/stremio_base.types.dart';
import '../../connections/widget/base/render_library_list.dart';
import '../../settings/screen/trakt_integration_screen.dart';

class TraktContainer extends StatefulWidget {
  final String loadId;
  final int itemsPerPage;

  const TraktContainer({
    super.key,
    required this.loadId,
    this.itemsPerPage = 5,
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
        refresh();
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
                itemsPerPage: widget.itemsPerPage,
              )
              .first;
          break;
        case "continue_watching":
          newItems = await TraktService.instance!.getContinueWatching(
            page: page,
            itemsPerPage: widget.itemsPerPage,
          );
          break;
        case "upcoming_schedule":
          newItems = await TraktService.instance!.getUpcomingSchedule(
            page: page,
            itemsPerPage: widget.itemsPerPage,
          );
          break;
        case "watchlist":
          newItems = await TraktService.instance!.getWatchlist(
            page: page,
            itemsPerPage: widget.itemsPerPage,
          );
          break;
        case "show_recommendations":
          newItems = await TraktService.instance!.getShowRecommendations(
            page: page,
            itemsPerPage: widget.itemsPerPage,
          );
          break;
        case "movie_recommendations":
          newItems = await TraktService.instance!.getMovieRecommendations(
            page: page,
            itemsPerPage: widget.itemsPerPage,
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

  late final Map<String, List<ContextMenuItem>> actions = {
    "continue_watching": [
      ContextMenuItem(
        id: "remove",
        icon: CupertinoIcons.clear,
        title: 'Remove',
        isDestructiveAction: true,
        onCallback: (action, key) async {
          if (key is! Meta) {
            return;
          }

          if (key.traktProgressId == null) {
            return;
          }

          await TraktService.instance!.removeFromContinueWatching(
            key.traktProgressId!.toString(),
          );

          if (context.mounted && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Removed successfully"),
              ),
            );
          }
        },
      ),
    ],
    "watchlist": [
      ContextMenuItem(
        id: "remove",
        icon: CupertinoIcons.clear,
        title: 'Remove',
        isDestructiveAction: true,
        onCallback: (action, key) {
          TraktService.instance!.removeFromWatchlist(key as Meta);
        },
      ),
    ],
  };

  Future<void> refresh() async {
    try {
      _logger.info('Refreshing data for ${widget.loadId}');
      _cachedItems = [];
      _currentPage = 1;
      await _loadData();
    } catch (e) {}
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
                                contextMenuItems:
                                    actions.containsKey(widget.loadId)
                                        ? actions[widget.loadId]!
                                        : [],
                                onContextMenu: (action, items) {
                                  actions[widget.loadId]!
                                      .firstWhereOrNull((item) {
                                    return item.id == action;
                                  })?.onCallback!(action, items);
                                },
                                isLoadingMore: _isLoading,
                                hasError: _error != null,
                                heroPrefix: "trakt_up_next${widget.loadId}",
                                service: TraktService.stremioService!,
                                isGrid: true,
                                isWide: widget.loadId == "up_next_series",
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
              if ((_cachedItems ?? []).isEmpty && !_isLoading && _error != null)
                const Positioned.fill(
                  child: Center(
                    child: Text("Nothing to see here"),
                  ),
                ),
              if (_isLoading && (_cachedItems ?? []).isEmpty)
                const SpinnerCards(),
              if (_error != null) Text(_error!),
              if (_error != null)
                Positioned.fill(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Error: $_error",
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.red,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _error = null;
                            });
                            _loadData();
                          },
                          child: const Text("Retry"),
                        ),
                      ],
                    ),
                  ),
                ),
              if (_error == null)
                SizedBox(
                  height: getListHeight(context),
                  child: RenderListItems(
                    isWide: widget.loadId == "up_next_series" ||
                        widget.loadId == "upcoming_schedule",
                    items: _cachedItems ?? [],
                    error: _error,
                    contextMenuItems: actions.containsKey(widget.loadId)
                        ? actions[widget.loadId]!
                        : [],
                    onContextMenu: (action, items) async {
                      actions[widget.loadId]!.firstWhereOrNull((item) {
                        return item.id == action;
                      })?.onCallback!(action, items);

                      Navigator.of(context, rootNavigator: true).pop();
                    },
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
