import 'package:cached_network_image/cached_network_image.dart';
import 'package:cached_network_image_platform_interface/cached_network_image_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:madari_client/features/connection/services/stremio_service.dart';
import 'package:madari_client/features/library_item/container/stremio_item_viewer.dart';

import '../../../engine/library.dart';
import '../../connection/types/stremio.dart';

class StremioItemCard extends StatelessWidget {
  final LibraryItemList item;
  final Meta parsed;
  final StremioService service;
  final String heroPrefix;

  const StremioItemCard({
    super.key,
    required this.item,
    required this.parsed,
    required this.service,
    required this.heroPrefix,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) {
                  return StremioItemViewer(
                    item: parsed,
                    service: service,
                    heroPrefix: heroPrefix,
                  );
                },
              ),
            );
          },
          child: Hero(
            tag: "$heroPrefix${parsed.id}",
            child: AspectRatio(
              aspectRatio: 2 / 3, // Typical poster aspect ratio
              child: (parsed.poster == null)
                  ? Container()
                  : Container(
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: CachedNetworkImageProvider(
                            parsed.poster!,
                            imageRenderMethodForWeb:
                                ImageRenderMethodForWeb.HttpGet,
                          ),
                          fit: BoxFit.cover,
                        ),
                      ),
                      child:
                          parsed.imdbRating != null && parsed.imdbRating != ""
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
                                            parsed.imdbRating!,
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
