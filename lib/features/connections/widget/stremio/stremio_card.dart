import 'package:cached_network_image/cached_network_image.dart';
import 'package:cached_network_image_platform_interface/cached_network_image_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:madari_client/features/connection/types/stremio.dart';
import 'package:madari_client/features/connections/service/base_connection_service.dart';

class StremioCard extends StatelessWidget {
  final LibraryItem item;
  final String prefix;
  final String connectionId;
  final BaseConnectionService service;

  const StremioCard({
    super.key,
    required this.item,
    required this.prefix,
    required this.connectionId,
    required this.service,
  });

  @override
  Widget build(BuildContext context) {
    final meta = item as Meta;

    return Card(
      margin: const EdgeInsets.only(right: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            context.push(
              "/info/stremio/$connectionId/${meta.type}/${meta.id}?hero=$prefix${meta.type}${item.id}",
              extra: {
                'meta': meta,
                'service': service,
              },
            );
          },
          child: meta.nextSeason == null || meta.progress != null
              ? _buildRegular(context, meta)
              : _buildWideCard(context, meta),
        ),
      ),
    );
  }

  _buildWideCard(BuildContext context, Meta meta) {
    if (meta.background == null) {
      return Container();
    }

    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: CachedNetworkImageProvider(
            "https://proxy-image.syncws.com/insecure/plain/${Uri.encodeQueryComponent(meta.background!)}@webp",
            imageRenderMethodForWeb: ImageRenderMethodForWeb.HttpGet,
          ),
          fit: BoxFit.cover,
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black,
                    Colors.transparent,
                  ],
                  begin: Alignment.bottomLeft,
                  end: Alignment.center,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text("S${meta.nextSeason} E${meta.nextEpisode}"),
                  Text(
                    "${meta.nextEpisodeTitle}".trim(),
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ],
              ),
            ),
          ),
          const Positioned(
            child: Center(
              child: IconButton.filled(
                onPressed: null,
                icon: Icon(
                  Icons.play_arrow,
                  size: 24,
                ),
              ),
            ),
          ),
          meta.imdbRating != ""
              ? Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.star,
                            color: Colors.amber,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            meta.imdbRating,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ],
      ),
    );
  }

  String? getBackgroundImage(Meta meta) {
    String? backgroundImage;

    if (meta.nextEpisode != null &&
        meta.nextSeason != null &&
        meta.videos != null) {
      for (final video in meta.videos!) {
        if (video.season == meta.nextSeason &&
            video.episode == meta.nextEpisode) {
          return video.thumbnail ?? meta.poster;
        }
      }
    }

    if (meta.poster != null) {
      backgroundImage = meta.poster;
    }

    return backgroundImage;
  }

  _buildRegular(BuildContext context, Meta meta) {
    final backgroundImage = getBackgroundImage(meta);

    return Hero(
      tag: "$prefix${meta.type}${item.id}",
      child: AspectRatio(
        aspectRatio: 2 / 3,
        child: (backgroundImage == null)
            ? Text("${meta.name}")
            : Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: CachedNetworkImageProvider(
                          "https://proxy-image.syncws.com/insecure/plain/${Uri.encodeQueryComponent(backgroundImage)}@webp",
                          imageRenderMethodForWeb:
                              ImageRenderMethodForWeb.HttpGet,
                        ),
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: meta.imdbRating != ""
                        ? Align(
                            alignment: Alignment.topRight,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.star,
                                      color: Colors.amber,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      meta.imdbRating!,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                  if (meta.progress != null)
                    const Positioned.fill(
                      child: IconButton(
                        onPressed: null,
                        icon: Icon(
                          Icons.play_arrow,
                          size: 24,
                        ),
                      ),
                    ),
                  if (meta.progress != null)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: LinearProgressIndicator(
                        value: meta.progress,
                      ),
                    ),
                  if (meta.nextEpisode != null && meta.nextSeason != null)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.grey,
                              Colors.transparent,
                            ],
                            begin: Alignment.bottomLeft,
                            end: Alignment.topRight,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 4, horizontal: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Text(
                                meta.name ?? "",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              Text(
                                "S${meta.nextSeason} E${meta.nextEpisode}",
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                ],
              ),
      ),
    );
  }
}
