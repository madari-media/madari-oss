import 'package:flutter/material.dart';
import 'package:madari_client/features/connection/services/stremio_service.dart';
import 'package:madari_client/features/connection/types/stremio.dart';
import 'package:madari_client/features/library_item/container/stremio_stream_selector.dart';

import 'stremio_item_season_selector.dart';

class StremioItemViewer extends StatefulWidget {
  final Meta item;
  final StremioService service;
  final String heroPrefix;

  const StremioItemViewer({
    super.key,
    required this.item,
    required this.service,
    required this.heroPrefix,
  });

  @override
  State<StremioItemViewer> createState() => _StremioItemViewerState();
}

class _StremioItemViewerState extends State<StremioItemViewer> {
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    widget.service
        .getItemMetaById(widget.item.type, widget.item.id)
        .then((itemGet) {
      if (mounted) {
        setState(() {
          _item = itemGet;
          _isLoading = false;
        });
      }
    }).catchError((err) {
      setState(() {
        _isLoading = false;
        _errorMessage = err.toString();
      });
    });

    super.initState();
  }

  Meta? _item;

  Meta get item {
    return _item ?? widget.item;
  }

  void _onPlayPressed(BuildContext context) {
    if (item.type == "series") {
      showModalBottomSheet(
        context: context,
        builder: (context) {
          return Scaffold(
            appBar: AppBar(
              leading: IconButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                icon: const Icon(Icons.close),
              ),
              title: const Text("Seasons"),
            ),
            body: StremioItemSeasonSelector(
              meta: item,
            ),
          );
        },
      );
    } else {
      showModalBottomSheet(
        context: context,
        builder: (context) {
          return Scaffold(
            appBar: AppBar(
              leading: IconButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                icon: const Icon(Icons.close),
              ),
              title: const Text("Streams"),
            ),
            body: StremioStreamSelector(
              stremio: widget.service,
              item: item,
              id: item.id,
            ),
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 900;
    final contentWidth = isWideScreen ? 900.0 : screenWidth;

    if (_errorMessage != null) {
      return Text("Failed $_errorMessage");
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: isWideScreen ? 600 : 500,
            pinned: true,
            // Add bottom widget to keep controls visible
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(40),
              child: Container(
                width: double.infinity,
                color: Colors.black,
                padding: EdgeInsets.symmetric(
                  horizontal:
                      isWideScreen ? (screenWidth - contentWidth) / 2 : 16,
                  vertical: 16,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.name!,
                        style: Theme.of(context).textTheme.titleLarge,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      icon: _isLoading
                          ? Container(
                              margin: const EdgeInsets.only(right: 6),
                              child: const SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(),
                              ),
                            )
                          : const Icon(
                              Icons.play_arrow_rounded,
                              size: 24,
                              color: Colors.black87,
                            ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                      ),
                      onPressed: () {
                        if (item.type == "series" && _isLoading) {
                          return;
                        }

                        _onPlayPressed(context);
                      },
                      label: Text(
                        "Play",
                        style: Theme.of(context)
                            .primaryTextTheme
                            .bodyMedium
                            ?.copyWith(
                              color: Colors.black87,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (item.background != null)
                    Image.network(
                      item.background!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        if (item.poster == null) {
                          return Container();
                        }
                        return Image.network(item.poster!, fit: BoxFit.cover);
                      },
                    ),
                  // Gradient overlay
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.8),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 86, // Adjusted to account for bottom widget
                    left: 16,
                    right: 16,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isWideScreen
                            ? (screenWidth - contentWidth) / 2
                            : 16,
                        vertical: 16,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Hero(
                            tag: "${widget.heroPrefix}${item.id}",
                            child: Container(
                              width: 150,
                              height: 225,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                image: item.poster == null
                                    ? null
                                    : DecorationImage(
                                        image: NetworkImage(item.poster!),
                                        fit: BoxFit.cover,
                                      ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    spreadRadius: 2,
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    if (item.year != null)
                                      Chip(
                                        label: Text(item.year!),
                                        backgroundColor: Colors.white24,
                                        labelStyle: const TextStyle(
                                            color: Colors.white),
                                      ),
                                    const SizedBox(width: 8),
                                    if (item.imdbRating != null)
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.star,
                                            color: Colors.amber,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            item.imdbRating!,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium
                                                ?.copyWith(color: Colors.white),
                                          ),
                                        ],
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
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.symmetric(
              horizontal: isWideScreen ? (screenWidth - contentWidth) / 2 : 16,
              vertical: 16,
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(
                  height: 12,
                ),
                // Description
                Text(
                  'Description',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                if (item.description != null) const SizedBox(height: 8),
                if (item.description != null)
                  Text(
                    item.description!,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                const SizedBox(height: 16),

                // Additional Details
                _buildDetailSection(context, 'Additional Information', [
                  if (item.genre != null)
                    _buildDetailRow('Genres', item.genre!.join(', ')),
                  if (item.country != null)
                    _buildDetailRow('Country', item.country!),
                  if (item.runtime != null)
                    _buildDetailRow('Runtime', item.runtime!),
                  if (item.language != null)
                    _buildDetailRow('Language', item.language!),
                ]),

                // Cast
                if (item.creditsCast != null && item.creditsCast!.isNotEmpty)
                  _buildCastSection(context, item.creditsCast!),

                // Trailers
                if (item.trailerStreams != null &&
                    item.trailerStreams!.isNotEmpty)
                  _buildTrailersSection(context, item.trailerStreams!),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailSection(
      BuildContext context, String title, List<Widget> details) {
    if (details.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        ...details,
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildCastSection(BuildContext context, List<CreditsCast> cast) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cast',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 150,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: cast.length,
            itemBuilder: (context, index) {
              final actor = cast[index];
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: actor.profilePath != null
                          ? NetworkImage(actor.profilePath!)
                          : null,
                      child: actor.profilePath == null
                          ? Icon(Icons.person,
                              size: 50, color: Colors.grey[300])
                          : null,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      actor.name,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Text(
                      actor.character,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildTrailersSection(
      BuildContext context, List<TrailerStream> trailers) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Trailers',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: trailers.length,
            itemBuilder: (context, index) {
              final trailer = trailers[index];
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Container(
                  width: 160,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.black26,
                  ),
                  child: Center(
                    child: Text(
                      trailer.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white),
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
