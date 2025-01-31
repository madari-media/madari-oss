import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:madari_client/features/streamio_addons/models/stremio_base_types.dart';
import 'package:madari_client/features/widgetter/plugins/stremio/containers/streamio_background.dart';
import 'package:madari_client/features/widgetter/plugins/stremio/containers/streamio_cast_section.dart';
import 'package:madari_client/features/widgetter/plugins/stremio/containers/streamio_trailer_section.dart';
import 'package:madari_client/features/widgetter/plugins/stremio/containers/streamio_video_list.dart';

final _logger = Logger('StreamioViewerContent');

class StreamioViewerContent extends StatefulWidget {
  final Meta meta;
  final String type;
  final String? prefix;

  const StreamioViewerContent({
    super.key,
    required this.meta,
    required this.type,
    this.prefix,
  });

  @override
  State<StreamioViewerContent> createState() => _StreamioViewerContentState();
}

class _StreamioViewerContentState extends State<StreamioViewerContent> {
  final ScrollController _scrollController = ScrollController();
  int _selectedSeason = 1;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        StreamioBackground(
          imageUrl: widget.meta.background ?? widget.meta.poster,
        ),
        Center(
          child: Container(
            constraints: const BoxConstraints(
              maxWidth: 800,
            ),
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  StreamioHeroSection(
                    meta: widget.meta,
                    type: widget.type,
                    prefix: widget.prefix,
                  ),
                  const SizedBox(height: 16),
                  if (widget.meta.description != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: StreamioDescription(
                        description: widget.meta.description!,
                      ),
                    ),
                  const SizedBox(height: 16),
                  if (widget.meta.creditsCast != null &&
                      widget.meta.creditsCast!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: StreamioCastSection(
                        cast: widget.meta.creditsCast!,
                      ),
                    ),
                  const SizedBox(height: 16),
                  if (widget.type == 'series' && widget.meta.videos != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: StreamioSeasonSelector(
                        videos: widget.meta.videos!,
                        selectedSeason: _selectedSeason,
                        onSeasonChanged: (season) {
                          setState(() {
                            _selectedSeason = season;
                          });
                        },
                      ),
                    ),
                  if (widget.type != "series" &&
                      widget.meta.videos?.isNotEmpty == true)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: StremioVideoList(
                        videos: widget.meta.videos,
                        meta: widget.meta,
                      ),
                    ),
                  const SizedBox(height: 8),
                  if (widget.type == 'series' && widget.meta.videos != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: StreamioEpisodeList(
                        meta: widget.meta,
                        videos: widget.meta.videos!
                            .where((v) => v.season == _selectedSeason)
                            .toList(),
                      ),
                    ),
                  const SizedBox(height: 8),
                  if (widget.meta.trailerStreams != null &&
                      widget.meta.trailerStreams!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: StreamioTrailerSection(
                        trailerStreams: widget.meta.trailerStreams!,
                      ),
                    ),
                  const SizedBox(height: 8),
                  if (widget.meta.genre != null || widget.meta.genres != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: StreamioAdditionalInfo(meta: widget.meta),
                    ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
