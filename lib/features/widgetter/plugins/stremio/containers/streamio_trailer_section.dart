import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../streamio_addons/models/stremio_base_types.dart';

final _logger = Logger('StreamioTrailerSection');

class StreamioTrailerSection extends StatelessWidget {
  final List<TrailerStream>? trailerStreams;

  const StreamioTrailerSection({super.key, this.trailerStreams});

  String getYoutubeThumbnail(String ytId) {
    return 'https://img.youtube.com/vi/$ytId/maxresdefault.jpg';
  }

  Future<void> _launchYoutubeVideo(String ytId) async {
    final url = Uri.parse('https://www.youtube-nocookie.com/embed/$ytId');
    try {
      _logger.info('Launching YouTube video: $ytId');
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      } else {
        _logger.warning('Could not launch YouTube URL: $url');
      }
    } catch (e) {
      _logger.severe('Error launching YouTube video', e);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (trailerStreams == null || trailerStreams!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Text(
          'Trailers',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white,
              ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: trailerStreams!.length,
            itemBuilder: (context, index) {
              final trailer = trailerStreams![index];
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: InkWell(
                    onTap: () => _launchYoutubeVideo(trailer.ytId),
                    borderRadius: BorderRadius.circular(8),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Thumbnail
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedNetworkImage(
                            imageUrl: getYoutubeThumbnail(trailer.ytId),
                            fit: BoxFit.cover,
                            errorWidget: (context, url, error) {
                              _logger.warning(
                                  'Error loading thumbnail for video ${trailer.ytId}',
                                  error);
                              return Container(
                                color: Colors.black,
                                child: const Icon(Icons.error,
                                    color: Colors.white),
                              );
                            },
                          ),
                        ),
                        // Gradient Overlay
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.7),
                              ],
                            ),
                          ),
                        ),
                        // Play Button
                        Center(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.9),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.play_arrow,
                              size: 32,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        // Title and Duration
                        Positioned(
                          bottom: 8,
                          left: 8,
                          right: 8,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                trailer.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.play_circle_outline,
                                    size: 16,
                                    color: Colors.red,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Watch on YouTube',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: Colors.white.withOpacity(0.7),
                                        ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
