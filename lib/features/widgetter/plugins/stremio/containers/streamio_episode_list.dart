import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:madari_engine/madari_engine.dart';

final _logger = Logger('StreamioEpisodeList');

class StreamioEpisodeList extends StatefulWidget {
  final List<Video> videos;
  final Function(Video)? onEpisodeSelected;

  const StreamioEpisodeList({
    super.key,
    required this.videos,
    this.onEpisodeSelected,
  });

  @override
  State<StreamioEpisodeList> createState() => _StreamioEpisodeListState();
}

class _StreamioEpisodeListState extends State<StreamioEpisodeList> {
  final ScrollController _scrollController = ScrollController();
  Video? _hoveredEpisode;
  Video? _focusedEpisode;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration? duration) {
    if (duration == null) return '';
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String hours = duration.inHours > 0 ? '${duration.inHours}:' : '';
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$hours$minutes:$seconds';
  }

  Widget _buildEpisodeCard(Video episode, int index) {
    final isHovered = _hoveredEpisode == episode;
    final isFocused = _focusedEpisode == episode;
    final hasProgress = episode.progress != null && episode.progress! > 0;

    return FocusableActionDetector(
      mouseCursor: SystemMouseCursors.click,
      onShowHoverHighlight: (hovering) {
        if (hovering != (isHovered)) {
          setState(() {
            _hoveredEpisode = hovering ? episode : null;
          });
        }
      },
      onShowFocusHighlight: (focusing) {
        if (focusing != (isFocused)) {
          setState(() {
            _focusedEpisode = focusing ? episode : null;
          });
        }
      },
      child: GestureDetector(
        onTap: () {
          _logger.info('Episode selected: ${episode.name}');
          widget.onEpisodeSelected?.call(episode);
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isFocused
                  ? Theme.of(context).colorScheme.primary
                  : Colors.transparent,
              width: 2,
            ),
          ),
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (episode.thumbnail != null)
                        CachedNetworkImage(
                          imageUrl: episode.thumbnail!,
                          fit: BoxFit.cover,
                          errorWidget: (context, url, error) {
                            _logger.warning(
                                'Error loading thumbnail for episode ${episode.episode}',
                                error);
                            return Container(
                              color: Theme.of(context).colorScheme.surface,
                              child: Center(
                                child: Icon(
                                  Icons.movie_outlined,
                                  size: 32,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withOpacity(0.5),
                                ),
                              ),
                            );
                          },
                        )
                      else
                        Container(
                          color: Theme.of(context).colorScheme.surface,
                          child: Center(
                            child: Icon(
                              Icons.movie_outlined,
                              size: 32,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.5),
                            ),
                          ),
                        ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(isHovered ? 0.9 : 0.7),
                            ],
                            stops: const [0.5, 1.0],
                          ),
                        ),
                      ),
                      if (isHovered || isFocused)
                        Center(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(0.9),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.play_arrow,
                              size: 32,
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                          ),
                        ),
                      if (hasProgress && !(isHovered || isFocused))
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${(episode.progress! * 100).toInt()}%',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                          ),
                        ),
                      Positioned(
                        left: 8,
                        right: 8,
                        bottom: 8,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'E${episode.episode}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onPrimary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                ),
                                if (episode.released != null) ...[
                                  const SizedBox(width: 8),
                                  Text(
                                    episode.released!.toString().split(' ')[0],
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: Colors.white.withOpacity(0.7),
                                        ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),
                            if (episode.name != null)
                              Text(
                                episode.name!,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                          ],
                        ),
                      ),
                      if (hasProgress)
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: LinearProgressIndicator(
                            value: episode.progress,
                            minHeight: 3,
                            backgroundColor: Colors.black.withOpacity(0.3),
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Positioned.fill(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(6),
                    onTap: () {
                      _logger.info('Episode selected: ${episode.name}');
                      widget.onEpisodeSelected?.call(episode);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
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
        Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
          child: Row(
            children: [
              Text(
                'Episodes',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const Spacer(),
              Text(
                '${sortedVideos.length} Episodes',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Colors.white.withOpacity(0.7),
                    ),
              ),
            ],
          ),
        ),
        GridView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 16 / 9,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: sortedVideos.length,
          itemBuilder: (context, index) =>
              _buildEpisodeCard(sortedVideos[index], index),
        ),
      ],
    );
  }
}
