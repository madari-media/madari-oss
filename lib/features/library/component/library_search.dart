import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:madari_client/features/connection/services/base_connection_service.dart';

import '../../../engine/library.dart';
import '../../connection/services/stremio_service.dart';
import '../../connection/types/stremio.dart';
import '../../connections/types/stremio/stremio_base.types.dart';
import '../../library_item/container/stremio_item_list.dart';

class LibraryItemSearchDelegate extends SearchDelegate<LibraryItemList?> {
  final LibraryRecord library;
  final List<LibraryItemList> items;
  final WidgetRef ref;
  Timer? _debounceTimer;
  final _debounceDuration = const Duration(milliseconds: 300);
  String _debouncedQuery = '';
  BaseConnectionService? service;

  LibraryItemSearchDelegate({
    required this.library,
    required this.items,
    required this.ref,
    this.service,
  });

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults();
  }

  double _calculateRelevance(LibraryItemList item, String searchQuery) {
    final queryLower = searchQuery.toLowerCase();
    final titleLower = item.title.toLowerCase();
    final extraLower = (item.extra ?? '').toLowerCase();

    double score = 0.0;

    // Exact matches get highest score
    if (titleLower == queryLower) {
      score += 100;
    }
    // Title starts with query
    else if (titleLower.startsWith(queryLower)) {
      score += 75;
    }
    // Title contains query
    else if (titleLower.contains(queryLower)) {
      score += 50;
    }

    // Extra field matches
    if (extraLower.contains(queryLower)) {
      score += 25;
    }

    if (item.popularity != null) {
      score += (item.popularity!) * 10000000;
    }

    return score;
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults();
  }

  Widget _buildSearchResults() {
    if (query.isEmpty) {
      return const Center(
        child: Text('Type to search...'),
      );
    }

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final isMobile = constraints.maxWidth < 600;

        return StreamBuilder(
          stream: Stream.fromFuture(() async {
            // Create a completer that will be completed after debounce
            final completer = Completer<void>();

            // Cancel any existing timer
            _debounceTimer?.cancel();

            // Only update if query changed
            if (_debouncedQuery != query) {
              _debounceTimer = Timer(_debounceDuration, () {
                _debouncedQuery = query;
                completer.complete();
              });
            } else {
              completer.complete();
            }

            await completer.future;

            return ref.read(
              libraryItemListProvider(
                library,
                items,
                1,
                _debouncedQuery,
              ).future,
            );
          }()),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            final searchResults = snapshot.data?.items ?? [];

            if (searchResults.isEmpty) {
              return const Center(child: Text('No results found'));
            }

            searchResults.sort((a, b) {
              final scoreA = _calculateRelevance(a, query);
              final scoreB = _calculateRelevance(b, query);
              return scoreB.compareTo(scoreA);
            });

            return GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isMobile
                    ? 1
                    : (constraints.maxWidth ~/ 300), // Reduced from 300 to 200
                childAspectRatio:
                    isMobile ? 2.3 : 1.63, // Adjusted ratios for both layouts
                mainAxisSpacing: 4, // Reduced spacing
                crossAxisSpacing: 4,
              ),
              padding: const EdgeInsets.all(8),
              itemCount: searchResults.length,
              itemBuilder: (context, index) {
                final item = searchResults[index];

                if (library.connectionType == "stremio_addons") {
                  final parsed = Meta.fromJson(jsonDecode(item.config!));
                  return StremioItemList(
                    item: item,
                    parsed: parsed,
                    service: service as StremioService,
                  );
                }

                return Card(
                  margin:
                      const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                  child: InkWell(
                    onTap: () => close(context, item),
                    child: isMobile
                        ? ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            leading: item.logo != null
                                ? SizedBox(
                                    width: 40, // Fixed size for consistency
                                    height: 40,
                                    child: Image.network(
                                      item.logo!,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : null,
                            title: Text(
                              item.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 14),
                            ),
                            subtitle: item.extra != null
                                ? Text(
                                    item.extra!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 12),
                                  )
                                : null,
                          )
                        : Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              children: [
                                if (item.logo != null)
                                  SizedBox(
                                    width: 50, // Fixed size for desktop
                                    height: 50,
                                    child: Image.network(
                                      item.logo!,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        item.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      if (item.extra != null)
                                        Text(
                                          item.extra!,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontSize: 12),
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
            );
          },
        );
      },
    );
  }
}
