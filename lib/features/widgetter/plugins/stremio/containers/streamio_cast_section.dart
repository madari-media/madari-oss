import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:madari_engine/madari_engine.dart';
import 'package:universal_platform/universal_platform.dart';

import 'cast_info.dart';

class StreamioCastSection extends StatelessWidget {
  final List<CreditsCast> cast;

  const StreamioCastSection({super.key, required this.cast});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cast',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white,
              ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 120,
          child: Center(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: cast.length,
              itemBuilder: (context, index) {
                final actor = cast[index];

                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: InkWell(
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        enableDrag: true,
                        useSafeArea: true,
                        builder: (context) {
                          return CastInfoLoader(
                            id: "tmdb:${actor.id}",
                          );
                        },
                      );
                    },
                    child: SizedBox(
                      width: 100,
                      child: Column(
                        children: [
                          if (actor.profilePath != null)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(50),
                              child: SizedBox(
                                width: 80,
                                height: 80,
                                child: CachedNetworkImage(
                                  imageUrl: actor.profilePath!.startsWith("/")
                                      ? "https://proxy-image.syncws.com/insecure/plain/${Uri.encodeQueryComponent("https://image.tmdb.org/t/p/original/${actor.profilePath}")}@webp"
                                      : UniversalPlatform.isWeb
                                          ? "https://proxy-image.syncws.com/insecure/plain/${Uri.encodeQueryComponent(actor.profilePath!)}@webp"
                                          : actor.profilePath!,
                                  fit: BoxFit.cover,
                                  errorWidget: (context, url, error) {
                                    return const CircleAvatar(
                                      radius: 40,
                                      child: Icon(Icons.person),
                                    );
                                  },
                                ),
                              ),
                            )
                          else
                            const CircleAvatar(
                              radius: 40,
                              child: Icon(Icons.person),
                            ),
                          const SizedBox(height: 8),
                          Text(
                            actor.name,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.white,
                                    ),
                          ),
                          Text(
                            actor.character,
                            textAlign: TextAlign.center,
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
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class StreamioAdditionalInfo extends StatelessWidget {
  final Meta meta;

  const StreamioAdditionalInfo({super.key, required this.meta});

  @override
  Widget build(BuildContext context) {
    final genres = meta.genre ?? meta.genres;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Additional Information',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white,
              ),
        ),
        const SizedBox(height: 12),
        if (genres != null) ...[
          Text(
            'Genres: ${genres.join(", ")}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withOpacity(0.9),
                ),
          ),
          const SizedBox(height: 8),
        ],
        if (meta.released != null)
          Text(
            'Released: ${meta.released!.toString().split(" ")[0]}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withOpacity(0.9),
                ),
          ),
        if (meta.runtime != null) ...[
          const SizedBox(height: 8),
          Text(
            'Runtime: ${meta.runtime}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withOpacity(0.9),
                ),
          ),
        ],
        if (meta.country != null) ...[
          const SizedBox(height: 8),
          Text(
            'Country: ${meta.country}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withOpacity(0.9),
                ),
          ),
        ],
      ],
    );
  }
}
