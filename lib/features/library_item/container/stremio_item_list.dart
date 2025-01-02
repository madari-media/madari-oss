import 'package:flutter/material.dart';
import 'package:madari_client/engine/library.dart';
import 'package:madari_client/features/connection/services/stremio_service.dart';
import 'package:madari_client/features/connection/types/stremio.dart';
import 'package:madari_client/features/library_item/container/stremio_item_viewer.dart';

class StremioItemList extends StatelessWidget {
  final LibraryItemList item;
  final Meta parsed;
  final StremioService service;

  const StremioItemList({
    super.key,
    required this.item,
    required this.parsed,
    required this.service,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) {
                  return StremioItemViewer(
                    item: parsed,
                    service: service,
                    heroPrefix: item.id,
                  );
                },
              ),
            );
          },
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 1,
                child: Hero(
                  tag: parsed.id,
                  child: Container(
                    height: 180,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        bottomLeft: Radius.circular(12),
                      ),
                      image: parsed.poster == null
                          ? null
                          : DecorationImage(
                              image: NetworkImage(parsed.poster!),
                              fit: BoxFit.cover,
                            ),
                    ),
                  ),
                ),
              ),
              // Content on the right side
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        parsed.name!,
                        style: Theme.of(context).textTheme.titleLarge,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (parsed.description != null) const SizedBox(height: 8),
                      if (parsed.description != null)
                        Text(
                          parsed.description!,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          if (parsed.year != null)
                            Chip(
                              label: Text(
                                parsed.year!,
                                style: const TextStyle(fontSize: 12),
                              ),
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                            ),
                          const SizedBox(width: 8),
                          if (parsed.imdbRating != null &&
                              parsed.imdbRating != "")
                            Row(
                              children: [
                                const Icon(
                                  Icons.star,
                                  color: Colors.amber,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  parsed.imdbRating!,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
