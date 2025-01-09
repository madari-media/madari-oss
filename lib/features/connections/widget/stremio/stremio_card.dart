import 'package:cached_network_image/cached_network_image.dart';
import 'package:cached_network_image_platform_interface/cached_network_image_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
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
          child: (meta.nextSeason == null || meta.progress != null)
              ? _buildRegular(context, meta)
              : _buildWideCard(context, meta),
        ),
      ),
    );
  }

  bool get isInFuture {
    final video = (item as Meta).currentVideo;
    return video != null &&
        video.firstAired != null &&
        video.firstAired!.isAfter(DateTime.now());
  }

  _buildWideCard(BuildContext context, Meta meta) {
    if (meta.background == null) {
      return Container();
    }

    final video = meta.currentVideo;

    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: CachedNetworkImageProvider(
            "https://proxy-image.syncws.com/insecure/plain/${Uri.encodeQueryComponent(
              meta.currentVideo?.thumbnail ?? meta.background!,
            )}@webp",
            imageRenderMethodForWeb: ImageRenderMethodForWeb.HttpGet,
          ),
          fit: BoxFit.cover,
        ),
      ),
      child: Stack(
        children: [
          if (isInFuture)
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black,
                      Colors.black54,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
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
                  Text(
                    "${meta.name}",
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(
                    height: 4,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      "S${meta.nextSeason} E${meta.nextEpisode}",
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.black,
                          ),
                    ),
                  ),
                  Text(
                    "${meta.nextEpisodeTitle}".trim(),
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ],
              ),
            ),
          ),
          if (isInFuture)
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text(
                getRelativeDate(video!.firstAired!),
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          if (isInFuture)
            const Positioned(
              bottom: 0,
              right: 0,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 10,
                      ),
                      child: Icon(
                        Icons.calendar_month,
                      ),
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
    final backgroundImage =
        meta.poster ?? meta.logo ?? getBackgroundImage(meta);

    return Hero(
      tag: "$prefix${meta.type}${item.id}",
      child: (backgroundImage == null)
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Expanded(
                    child: Center(
                      child: Icon(
                        Icons.image_not_supported,
                        size: 26,
                      ),
                    ),
                  ),
                  Container(
                    color: Colors.grey,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        meta.name ?? "No title",
                        style:
                            Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color: Colors.black54,
                                  fontWeight: FontWeight.w600,
                                ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            )
          : Stack(
              children: [
                Positioned.fill(
                  child: Container(
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
                      value: meta.progress! / 100,
                      minHeight: 5,
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
    );
  }
}

String getRelativeDate(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final tomorrow = DateTime(now.year, now.month, now.day + 1);

  final difference = date.difference(today).inDays;

  if (date.isAtSameMomentAs(today)) {
    return "It's today!";
  } else if (date.isAtSameMomentAs(tomorrow)) {
    return "Coming up tomorrow!";
  } else if (difference > 1 && difference < 7) {
    return "Coming up in $difference days";
  } else if (difference >= 7 && difference < 14) {
    return "Coming up next ${DateFormat('EEEE').format(date)}";
  } else {
    return "On ${DateFormat('MM/dd/yyyy').format(date)}";
  }
}
