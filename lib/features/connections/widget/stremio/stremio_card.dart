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
  final String libraryId;

  const StremioCard({
    super.key,
    required this.item,
    required this.prefix,
    required this.connectionId,
    required this.libraryId,
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
              "/info/stremio/$connectionId/$libraryId/${meta.type}/${meta.id}?hero=$prefix${meta.type}${item.id}",
              extra: meta,
            );
          },
          child: Hero(
            tag: "$prefix${meta.type}${item.id}",
            child: AspectRatio(
              aspectRatio: 2 / 3, // Typical poster aspect ratio
              child: (meta.poster == null)
                  ? Container()
                  : Container(
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: CachedNetworkImageProvider(
                            "https://proxy-image.syncws.com/insecure/plain/${meta.poster}@webp",
                            imageRenderMethodForWeb:
                                ImageRenderMethodForWeb.HttpGet,
                          ),
                          fit: BoxFit.cover,
                        ),
                      ),
                      child: meta.imdbRating != null && meta.imdbRating != ""
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
          ),
        ),
      ),
    );
  }
}
