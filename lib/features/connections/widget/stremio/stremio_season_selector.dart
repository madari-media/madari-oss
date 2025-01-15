import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'package:madari_client/features/connection/types/stremio.dart';
import 'package:madari_client/features/connections/service/base_connection_service.dart';
import 'package:madari_client/features/connections/widget/base/render_stream_list.dart';
import 'package:madari_client/features/trakt/service/trakt.service.dart';
import 'package:madari_client/utils/common.dart';

import '../../../doc_viewer/types/doc_source.dart';
import '../../../watch_history/service/base_watch_history.dart';
import '../../../watch_history/service/zeee_watch_history.dart';

class StremioItemSeasonSelector extends StatefulWidget {
  final Meta meta;
  final int? season;
  final BaseConnectionService? service;
  final bool shouldPop;

  const StremioItemSeasonSelector({
    super.key,
    required this.meta,
    this.season,
    required this.service,
    this.shouldPop = false,
  });

  @override
  State<StremioItemSeasonSelector> createState() =>
      _StremioItemSeasonSelectorState();
}

class _StremioItemSeasonSelectorState extends State<StremioItemSeasonSelector>
    with SingleTickerProviderStateMixin {
  int? selectedSeason;
  late TabController? _tabController;
  late final Map<int, List<Video>> seasonMap;
  final zeeeWatchHistory = ZeeeWatchHistoryStatic.service;

  late Meta meta = widget.meta;

  final Map<String, double> _progress = {};

  @override
  void initState() {
    super.initState();

    seasonMap = _organizeEpisodes();

    if (seasonMap.keys.isEmpty) {
      return;
    }

    final index = getSelectedSeason();

    _tabController = TabController(
      length: seasonMap.keys.length,
      vsync: this,
      initialIndex: index.clamp(
        0,
        seasonMap.keys.isNotEmpty ? seasonMap.keys.length - 1 : 0,
      ),
    );

    // This is for rendering the component again for the selection of another tab
    _tabController!.addListener(() {
      setState(() {});
    });

    getWatchHistory();
  }

  int getSelectedSeason() {
    return widget.meta.currentVideo?.season ??
        widget.meta.videos?.lastWhereOrNull((item) {
          return item.progress != null;
        })?.season ??
        widget.season ??
        0;
  }

  getWatchHistory() async {
    final traktService = TraktService.instance;

    try {
      if (TraktService.isEnabled()) {
        final result = await traktService!.getProgress(
          widget.meta,
          bypassCache: false,
        );

        setState(() {
          meta = result;
        });

        final index = getSelectedSeason();
        _tabController?.animateTo(index);

        return;
      }
    } catch (e, stack) {
      print(e);
      print(stack);
      print("Unable to get trakt progress");
    }

    final docs = await zeeeWatchHistory!.getItemWatchHistory(
      ids: widget.meta.videos!.map((item) {
        return WatchHistoryGetRequest(
          id: item.id,
          episode: item.episode.toString(),
          season: item.season.toString(),
        );
      }).toList(),
    );

    for (var item in docs) {
      _progress[item.id] = item.progress.toDouble();
    }

    final index = getSelectedSeason();

    _tabController?.animateTo(index);
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  Map<int, List<Video>> _organizeEpisodes() {
    final episodes = meta.videos ?? [];
    return groupBy(episodes, (Video video) => video.season);
  }

  void openEpisode({
    required int index,
  }) async {
    if (widget.service == null) {
      return;
    }
    final onClose = showModalBottomSheet(
      context: context,
      builder: (context) {
        final meta = this.meta.copyWith(
              selectedVideoIndex: index,
            );

        return Scaffold(
          appBar: AppBar(
            title: Text(
              "Streams for S${meta.currentVideo?.season} E${meta.currentVideo?.episode}",
            ),
          ),
          body: RenderStreamList(
            service: widget.service!,
            id: meta,
            shouldPop: widget.shouldPop,
          ),
        );
      },
    );

    if (widget.shouldPop) {
      final val = await onClose;

      if (val is MediaURLSource && context.mounted && mounted) {
        Navigator.pop(
          context,
          val,
        );
      }

      return;
    }

    onClose.then((data) {
      getWatchHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    final seasons = seasonMap.keys.toList()..sort();
    final colorScheme = Theme.of(context).colorScheme;

    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 900;
    final contentWidth = isWideScreen ? 900.0 : screenWidth;

    if (_tabController == null) {
      return const SliverMainAxisGroup(
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              children: [
                SizedBox(
                  height: 0,
                )
              ],
            ),
          ),
        ],
      );
    }

    return SliverMainAxisGroup(
      slivers: [
        SliverPadding(
          padding: EdgeInsets.symmetric(
            horizontal: isWideScreen ? (screenWidth - contentWidth) / 2 : 8,
          ),
          sliver: SliverToBoxAdapter(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  height: 12,
                ),
                Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 320),
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.shuffle),
                      label: const Text("Random Episode"),
                      onPressed: () {
                        Random random = Random();
                        int randomIndex = random.nextInt(
                          widget.meta.videos!.length,
                        );

                        openEpisode(index: randomIndex);
                      },
                    ),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: colorScheme.surface.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TabBar(
                    tabAlignment: TabAlignment.start,
                    dividerColor: Colors.transparent,
                    controller: _tabController,
                    isScrollable: true,
                    splashBorderRadius: BorderRadius.circular(8),
                    padding: const EdgeInsets.all(4),
                    tabs: seasons.map((season) {
                      return Tab(
                        text: season == 0 ? "Specials" : 'Season $season',
                        height: 40,
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.symmetric(
            horizontal: isWideScreen ? (screenWidth - contentWidth) / 2 : 8,
          ),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final currentSeason = seasons[_tabController!.index];
                final episodes = seasonMap[currentSeason]!;
                final episode = episodes[index];

                final videoIndex = meta.videos?.indexOf(episode);

                final progress = ((!TraktService.isEnabled()
                            ? (_progress[episode.id] ?? 0) / 100
                            : videoIndex != -1
                                ? (meta.videos![videoIndex!].progress)
                                : 0.toDouble()) ??
                        0) /
                    100;

                return InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () async {
                    if (videoIndex != null) {
                      openEpisode(
                        index: videoIndex,
                      );
                    }
                  },
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 8.0,
                          top: 8.0,
                          bottom: 8.0,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Stack(
                            children: [
                              Container(
                                child: episode.thumbnail != null &&
                                        episode.thumbnail!.isNotEmpty
                                    ? Image.network(
                                        episode.thumbnail!,
                                        width: 140,
                                        height: 90,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          return Container(
                                            width: 140,
                                            height: 90,
                                            color: colorScheme
                                                .surfaceContainerHighest,
                                            child: Icon(
                                              Icons.movie,
                                              color:
                                                  colorScheme.onSurfaceVariant,
                                            ),
                                          );
                                        },
                                      )
                                    : Container(
                                        width: 140,
                                        height: 90,
                                        color:
                                            colorScheme.surfaceContainerHighest,
                                        child: Icon(
                                          Icons.movie,
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                              ),
                              Positioned(
                                top: 0,
                                bottom: 0,
                                right: 0,
                                left: 0,
                                child: Stack(
                                  children: [
                                    const Center(
                                      child: Icon(
                                        Icons.play_arrow,
                                      ),
                                    ),
                                    Center(
                                      child: CircularProgressIndicator(
                                        value: progress,
                                      ),
                                    )
                                  ],
                                ),
                              ),
                              if (progress > .9)
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Padding(
                                    padding: const EdgeInsets.all(4.0),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        color: Colors.teal,
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.only(
                                          right: 4.0,
                                          bottom: 2.0,
                                          left: 4.0,
                                          top: 2.0,
                                        ),
                                        child: Center(
                                          child: Text(
                                            "Watched",
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  color: Colors.black,
                                                ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(
                            top: 8.0,
                            bottom: 8.0,
                          ),
                          child: Center(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '${index + 1}. ${episode.name ?? 'Episode ${episode.episode}'}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (episode.released != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    intl.DateFormat('MMMM dd yyyy')
                                        .format(episode.released!),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: colorScheme.onSurface
                                          .withOpacity(0.7),
                                    ),
                                  ),
                                ],
                                if (episode.overview != null) ...[
                                  Text(
                                    episode.overview!,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: colorScheme.onSurface
                                          .withOpacity(0.9),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
              childCount:
                  seasonMap[seasons[_tabController!.index]]?.length ?? 0,
            ),
          ),
        ),
      ],
    );
  }
}

Map<T, List<E>> groupBy<E, T>(Iterable<E> items, T Function(E) key) {
  final map = <T, List<E>>{};

  for (final item in items) {
    final keyValue = key(item);
    if (!map.containsKey(keyValue)) {
      map[keyValue] = [];
    }
    map[keyValue]!.add(item);
  }

  return map;
}
