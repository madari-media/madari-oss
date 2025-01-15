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
  late final Map<int, List<Video>> seasonMap;
  final zeeeWatchHistory = ZeeeWatchHistoryStatic.service;

  late Meta meta = widget.meta;

  final Map<String, double> _progress = {};
  Map<int, Set<int>> watchedEpisodesBySeason = {};

  @override
  void initState() {
    super.initState();

    seasonMap = _organizeEpisodes();

    if (seasonMap.keys.isEmpty) {
      return;
    }
    if (seasonMap.isNotEmpty) {
      final seasons = seasonMap.keys.toList()..sort();
      int initialSeason = getSelectedSeason();

      if (seasons.contains(initialSeason)) {
        // Check if initialSeason is in seasons
        selectedSeason = initialSeason;
      } else if (seasons.isNotEmpty) {
        selectedSeason = seasons.first; // Or any other default if not found
      }
    }

    getWatchHistory();
    getWatchedHistory();
  }

getWatchedHistory() async {
  final traktService = TraktService.instance;
  try {
    final result =
    await traktService!.getWatchedShowsWithEpisodes(widget.meta);
    watchedEpisodesBySeason.clear();
    for (final show in result) {
      if (show.episodes != null) {
        for (final episode in show.episodes!) {
          if (!watchedEpisodesBySeason.containsKey(episode.season)) {
            watchedEpisodesBySeason[episode.season] = {};
          }
          watchedEpisodesBySeason[episode.season]!.add(episode.episode);
        }
      } else {
        //print("No episodes found for ${show.title}");
      }
    }

    setState(() {});
    return;
  } catch (e, stack) {
    print("Error fetching Trakt data: $e");
    print("Stack Trace: $stack");
  }
}
bool isEpisodeWatched(int season, int episode) {
  return watchedEpisodesBySeason.containsKey(season) &&
      watchedEpisodesBySeason[season]!.contains(episode);
}

bool isSeasonWatched(int season) {
  if (!watchedEpisodesBySeason.containsKey(season)) {
    return false; // No episodes watched in this season
  }
  if (seasonMap.containsKey(season)) {
    return watchedEpisodesBySeason[season]!.length ==
        seasonMap[season]!.length;
  }
  return false;
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

  }

  @override
  void dispose() {
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

    if (seasonMap.keys.isEmpty) {
      return const SliverMainAxisGroup(
        slivers: [
          SliverToBoxAdapter(
            child: Center(child: Text("No seasons available")),
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
              crossAxisAlignment: CrossAxisAlignment.start,
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
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 120),
                    child: DropdownButtonFormField<int>(
                      isExpanded: true,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surface.withOpacity(0.3),
                      ),

                      value: selectedSeason,
                      onChanged: (newValue) {
                        setState(() {
                          selectedSeason = newValue!;
                        });
                      },
                      items: seasons.map((season) {
                        final isWatched = isSeasonWatched(season);
                        return DropdownMenuItem<int>(
                          value: season,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Text(season == 0 ? "Specials" : 'Season $season'),
                              if (isWatched) ...[
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.check_circle,
                                  color: Theme.of(context).colorScheme.primary,
                                  size: 16,

                                )
                              ]
                            ],
                          ),
                        );
                      }).toList(),
                    ),
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
                final currentSeason = selectedSeason;
                if (currentSeason == null ||
                    !seasonMap.containsKey(currentSeason)) {
                  return const Center(child: Text("Select a season"));
                }
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
                              if (isEpisodeWatched(
                                  currentSeason, episode.episode!))
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Padding(
                                    padding: const EdgeInsets.all(4.0),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        color: Colors.grey.shade900,
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.only(
                                          right: 4.0,
                                          bottom: 2.0,
                                          left: 4.0,
                                          top: 2.0,
                                        ),
                                        child: Center(
                                          child: Icon(
                                            Icons.done_all,
                                            size: Theme.of(context)
                                                .textTheme
                                                .bodyLarge!
                                                .fontSize,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary, // Use primary color from theme
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
              childCount: selectedSeason != null &&
                  seasonMap.containsKey(selectedSeason!)
                  ? seasonMap[selectedSeason!]!.length
                  : 0,
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
