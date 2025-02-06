import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:madari_client/features/streamio_addons/models/stremio_base_types.dart';
import 'package:madari_client/utils/array-extension.dart';
import 'package:universal_platform/universal_platform.dart';

import '../../../../library/container/add_to_list_button.dart';
import '../../../../streamio_addons/service/stremio_addon_service.dart';
import 'stream_list.dart';

final _logger = Logger('StreamioComponents');

Future<String?> openVideoStream(
  BuildContext context,
  Meta meta, {
  bool shouldPop = false,
  String? bingGroup,
}) async {
  final service = StremioAddonService.instance;

  if (bingGroup != null) {
    final result = await Future(() async {
      final List<VideoStream> items = [];

      await service.getStreams(meta, callback: (item, addonName, error) {
        if (item != null) items.addAll(item);
      });

      return items;
    });

    final firstVideo = result.firstWhereOrNull((item) {
      return item.behaviorHints?["bingeGroup"] == bingGroup && item.url != null;
    });

    if (firstVideo != null) {
      return firstVideo.url!;
    }
  }

  return showModalBottomSheet(
    enableDrag: true,
    constraints: const BoxConstraints(
      maxWidth: 780,
    ),
    isScrollControlled: true,
    useSafeArea: true,
    context: context,
    builder: (context) {
      return Scaffold(
        body: StreamioStreamList(
          shouldPop: shouldPop,
          meta: meta.type == "series"
              ? meta.copyWith(
                  selectedVideoIndex: meta.selectedVideoIndex ?? 0,
                )
              : meta,
        ),
      );
    },
  );
}

class StreamioBackground extends StatelessWidget {
  final String? imageUrl;

  const StreamioBackground({
    super.key,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null) return const SizedBox.shrink();

    return SizedBox.expand(
      child: Stack(
        fit: StackFit.expand,
        children: [
          CachedNetworkImage(
            imageUrl: UniversalPlatform.isWeb
                ? "https://proxy-image.syncws.com/insecure/plain/${Uri.encodeQueryComponent(imageUrl!)}@webp"
                : imageUrl!,
            fit: BoxFit.cover,
            errorWidget: (context, url, error) {
              _logger.warning('Error loading background image', error);
              return const SizedBox.shrink();
            },
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.8),
                  Colors.black.withValues(alpha: 0.9),
                  Colors.black,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class StreamioHeroSection extends StatelessWidget {
  final Meta meta;
  final String type;
  final String? prefix;

  const StreamioHeroSection({
    super.key,
    required this.meta,
    required this.type,
    this.prefix,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(
        top: 160,
        left: 16.0,
        right: 16.0,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (meta.poster != null)
            Expanded(
              flex: 2,
              child: SizedBox(
                height: 220,
                width: 130,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Hero(
                      tag: prefix ?? "",
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl:
                              "https://proxy-image.syncws.com/insecure/plain/${Uri.encodeQueryComponent(meta.poster!)}@webp",
                          fit: BoxFit.cover,
                          errorWidget: (context, url, error) {
                            _logger.warning(
                                'Error loading poster image', error);
                            return const Icon(Icons.error);
                          },
                        ),
                      ),
                    ),
                    if (meta.type != "series")
                      IconButton.filled(
                        onPressed: () {
                          _logger.info('Play button pressed for ${meta.name}');

                          openVideoStream(context, meta);
                        },
                        icon: const Icon(Icons.play_arrow, size: 32),
                        style: IconButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          foregroundColor:
                              Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    meta.name ?? 'Unknown Title',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${meta.year ?? ''} • ${meta.genres?.join(', ') ?? ''}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                  ),
                  if (meta.runtime != null)
                    Text(
                      meta.runtime!,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                    ),
                  if (meta.imdbRating.isNotEmpty &&
                      meta.imdbRating.toString() != "null") ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber),
                        const SizedBox(width: 8),
                        Text(
                          meta.imdbRating,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Colors.white,
                                  ),
                        ),
                      ],
                    ),
                  ],
                  if (meta.type != "series") ...[
                    const SizedBox(
                      height: 12,
                    ),
                    OutlinedButton.icon(
                      onPressed: () {
                        openVideoStream(
                          context,
                          meta,
                        );
                      },
                      icon: const Icon(Icons.play_arrow),
                      label: const Text("Play"),
                    ),
                  ],
                  const SizedBox(
                    height: 12,
                  ),
                  SizedBox(
                    height: 40,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        AddToListButton(
                          meta: meta,
                          listName: "Favourites",
                          minimal: true,
                        ),
                        const SizedBox(
                          width: 8,
                        ),
                        AddToListButton(
                          meta: meta,
                          listName: "Watchlist",
                          minimal: true,
                        ),
                        const SizedBox(
                          width: 8,
                        ),
                        AddToListButton(
                          label: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.playlist_add_outlined),
                              SizedBox(
                                width: 8,
                              ),
                              Text("Add to list"),
                            ],
                          ),
                          meta: meta,
                          icon: Icons.add,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class StreamioSeasonSelector extends StatelessWidget {
  final List<Video> videos;
  final int selectedSeason;
  final ValueChanged<int> onSeasonChanged;

  const StreamioSeasonSelector({
    super.key,
    required this.videos,
    required this.selectedSeason,
    required this.onSeasonChanged,
  });

  @override
  Widget build(BuildContext context) {
    final seasons = videos.map((v) => v.season).toSet().toList()..sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Seasons',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white,
              ),
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: seasons.map((season) {
              if (season == null) {
                return const SizedBox.shrink();
              }

              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: FilledButton(
                  onPressed: () => onSeasonChanged(season),
                  style: FilledButton.styleFrom(
                    backgroundColor: selectedSeason == season
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurface,
                  ),
                  child: Text(
                    season == 0 ? "Specials" : "Season $season",
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class StreamioMetaInfo extends StatelessWidget {
  final Meta meta;

  const StreamioMetaInfo({
    super.key,
    required this.meta,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (meta.director != null && meta.director!.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            'Director: ${meta.director!.join(', ')}',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white,
                ),
          ),
        ],
        if (meta.cast != null && meta.cast!.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text(
            'Cast: ${meta.cast!.join(', ')}',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white,
                ),
          ),
        ],
      ],
    );
  }
}

class StreamioDescription extends StatelessWidget {
  final String description;

  const StreamioDescription({super.key, required this.description});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Description',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          description,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.white.withValues(alpha: 0.9),
              ),
        ),
      ],
    );
  }
}

class StreamioEpisodeList extends StatefulWidget {
  final List<Video> videos;
  final Meta meta;

  const StreamioEpisodeList({
    super.key,
    required this.videos,
    required this.meta,
  });

  @override
  State<StreamioEpisodeList> createState() => _StreamioEpisodeListState();
}

class _StreamioEpisodeListState extends State<StreamioEpisodeList> {
  Video? _expandedEpisode;

  onTap(Video episode) {
    openVideoStream(
      context,
      widget.meta.copyWith(
        selectedVideoIndex: widget.meta.videos?.indexOf(episode) ?? 0,
      ),
    );
  }

  Widget _buildEpisodeItem(Video episode, bool isExpanded) {
    const duration = Duration(milliseconds: 200);

    return AnimatedContainer(
      duration: duration,
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isExpanded
            ? Colors.black.withValues(alpha: 0.4)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Container(
            height: 70,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: isExpanded
                  ? const BorderRadius.vertical(top: Radius.circular(8))
                  : BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                if (episode.thumbnail != null)
                  InkWell(
                    onTap: () {
                      onTap(episode);
                    },
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.horizontal(
                            left: Radius.circular(8),
                          ),
                          child: SizedBox(
                            width: 125,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Hero(
                                  tag: 'episode_thumb_${episode.id}',
                                  child: CachedNetworkImage(
                                    imageUrl: UniversalPlatform.isWeb
                                        ? "https://proxy-image.syncws.com/insecure/plain/${episode.thumbnail!}@webp"
                                        : episode.thumbnail!,
                                    fit: BoxFit.cover,
                                    errorWidget: (context, url, error) {
                                      _logger.warning(
                                        'Error loading thumbnail',
                                        error,
                                      );
                                      return Container(
                                        color:
                                            Colors.black.withValues(alpha: 0.3),
                                        child: const Icon(
                                          Icons.error,
                                          color: Colors.white,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                      colors: [
                                        Colors.black.withValues(alpha: 0.7),
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                ),
                                if (episode.progress != null)
                                  Positioned(
                                    bottom: 0,
                                    left: 0,
                                    right: 0,
                                    child: LinearProgressIndicator(
                                      value: episode.progress,
                                      minHeight: 3,
                                      backgroundColor:
                                          Colors.black.withValues(alpha: 0.3),
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                Align(
                                  alignment: Alignment.bottomLeft,
                                  child: Container(
                                    margin: const EdgeInsets.all(8),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          Theme.of(context).colorScheme.surface,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'E${episode.episode}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelMedium
                                          ?.copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface,
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Positioned.fill(
                          child: Center(
                            child: Material(
                              color: Colors.transparent,
                              child: Icon(
                                Icons.play_arrow,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    width: 125,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      borderRadius: const BorderRadius.horizontal(
                        left: Radius.circular(8),
                      ),
                    ),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'E${episode.episode}',
                          style:
                              Theme.of(context).textTheme.labelMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                      ),
                    ),
                  ),
                Expanded(
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _expandedEpisode = isExpanded ? null : episode;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (episode.name != null)
                            Text(
                              episode.name!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                          const SizedBox(height: 2),
                          if (!isExpanded && episode.overview != null)
                            Text(
                              episode.overview!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.7),
                                  ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (episode.progress != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${(episode.progress! * 100).toInt()}%',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white,
                          ),
                    ),
                  ),
                AnimatedRotation(
                  duration: duration,
                  turns: isExpanded ? 0.5 : 0,
                  child: IconButton(
                    onPressed: () {
                      setState(() {
                        _expandedEpisode = isExpanded ? null : episode;
                      });
                    },
                    icon: const Icon(
                      Icons.keyboard_arrow_down,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(8),
            ),
            child: AnimatedCrossFade(
              duration: duration,
              crossFadeState: isExpanded
                  ? CrossFadeState.showFirst
                  : CrossFadeState.showSecond,
              firstChild: _buildExpandedInfo(episode),
              secondChild: const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedInfo(Video episode) {
    return Container(
      color: Colors.black.withValues(alpha: 0.3),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (episode.overview != null) ...[
            Text(
              episode.overview!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
            ),
            const SizedBox(height: 16),
          ],
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              if (episode.released != null)
                _buildInfoChip(
                  Icons.calendar_today,
                  'Released: ${episode.released!.toString().split(' ')[0]}',
                ),
              if (episode.firstAired != null)
                _buildInfoChip(
                  Icons.live_tv,
                  'Aired: ${episode.firstAired!.toString().split(' ')[0]}',
                ),
              if (episode.tvdbId != null)
                _buildInfoChip(
                  Icons.tv,
                  'TVDB: ${episode.tvdbId}',
                ),
              if (episode.moviedbId != null)
                _buildInfoChip(
                  Icons.movie,
                  'TMDB: ${episode.moviedbId}',
                ),
              if (episode.description != null &&
                  episode.description != episode.overview)
                _buildInfoChip(
                  Icons.description,
                  episode.description!,
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () {
                    _logger.info('Play episode ${episode.episode}');
                    openVideoStream(
                      context,
                      widget.meta.copyWith(
                        selectedVideoIndex:
                            widget.meta.videos?.indexOf(episode) ?? 0,
                      ),
                    );
                  },
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Play Episode'),
                ),
              ),
              const SizedBox(width: 8),
              if (episode.progress != null)
                IconButton.outlined(
                  onPressed: () {
                    _logger.info('Mark episode ${episode.episode} as watched');
                  },
                  icon: const Icon(Icons.check),
                ),
              // const SizedBox(width: 8),
              // IconButton.outlined(
              //   onPressed: () {
              //     _logger.info('More options for episode ${episode.episode}');
              //   },
              //   icon: const Icon(Icons.more_vert),
              // ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: Colors.white.withValues(alpha: 0.7),
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.7),
                ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sortedVideos = List<Video>.from(widget.videos)
      ..sort((a, b) => (a.episode ?? 0).compareTo(b.episode ?? 0));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Episodes',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${sortedVideos.length}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
              ),
            ),
          ],
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: sortedVideos.length,
          itemBuilder: (context, index) {
            final episode = sortedVideos[index];
            return _buildEpisodeItem(episode, _expandedEpisode == episode);
          },
        ),
      ],
    );
  }
}
