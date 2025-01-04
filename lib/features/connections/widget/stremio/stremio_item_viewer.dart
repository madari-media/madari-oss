import 'package:cached_network_image/cached_network_image.dart';
import 'package:cached_network_image_platform_interface/cached_network_image_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:madari_client/features/connections/service/base_connection_service.dart';
import 'package:madari_client/features/connections/widget/base/render_stream_list.dart';
import 'package:madari_client/features/connections/widget/stremio/stremio_season_selector.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../types/stremio/stremio_base.types.dart';

class StremioItemViewer extends StatefulWidget {
  final Meta? meta;
  final Meta? original;
  final String? hero;
  final BaseConnectionService? service;
  final String library;

  const StremioItemViewer({
    super.key,
    this.meta,
    this.original,
    this.hero,
    this.service,
    required this.library,
  });

  @override
  State<StremioItemViewer> createState() => _StremioItemViewerState();
}

class _StremioItemViewerState extends State<StremioItemViewer> {
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
  }

  bool get _isLoading {
    return widget.original == null;
  }

  Meta? _item;

  Meta? get item {
    return _item ?? widget.meta;
  }

  void _onPlayPressed(BuildContext context) {
    if (item == null) {
      return;
    }

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
          body: widget.service == null
              ? const Center(
                  child: CircularProgressIndicator(),
                )
              : RenderStreamList(
                  service: widget.service!,
                  library: widget.library,
                  id: widget.meta as LibraryItem,
                  shouldPop: false,
                ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 900;
    final contentWidth = isWideScreen ? 900.0 : screenWidth;

    if (_errorMessage != null) {
      return Text("Failed $_errorMessage");
    }

    if (item == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: isWideScreen ? 600 : 500,
            pinned: true,
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
                        item!.name!,
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
                        if (item!.type == "series" && _isLoading) {
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
                  if (item!.background != null)
                    Image.network(
                      item!.background!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        if (item!.poster == null) {
                          return Container();
                        }
                        return Image.network(item!.poster!, fit: BoxFit.cover);
                      },
                    ),
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
                    bottom: 86,
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
                            tag: "${widget.hero}",
                            child: Container(
                              width: 150,
                              height: 225,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                image: item!.poster == null
                                    ? null
                                    : DecorationImage(
                                        image: NetworkImage(item!.poster!),
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
                                    if (item!.year != null)
                                      Chip(
                                        label: Text(item!.year!),
                                        backgroundColor: Colors.white24,
                                        labelStyle: const TextStyle(
                                            color: Colors.white),
                                      ),
                                    const SizedBox(width: 8),
                                    if (item!.imdbRating != null)
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.star,
                                            color: Colors.amber,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            item!.imdbRating!,
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
          if (widget.original != null &&
              widget.original?.type == "series" &&
              widget.original?.videos?.isNotEmpty == true)
            SliverPadding(
              padding: EdgeInsets.symmetric(
                horizontal: isWideScreen ? (screenWidth - contentWidth) / 2 : 0,
                vertical: 0,
              ),
              sliver: StremioItemSeasonSelector(
                meta: item!,
                library: widget.library,
                service: widget.service,
              ),
            ),
          SliverPadding(
            padding: EdgeInsets.symmetric(
              horizontal: isWideScreen ? (screenWidth - contentWidth) / 2 : 16,
              vertical: 16,
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                if (widget.original != null)
                  const SizedBox(
                    height: 12,
                  ),
                // Description
                Text(
                  'Description',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                if (item!.description != null) const SizedBox(height: 8),
                if (item!.description != null)
                  Text(
                    item!.description!,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                const SizedBox(height: 16),

                // Additional Details
                _buildDetailSection(context, 'Additional Information', [
                  if (item!.genre != null)
                    _buildDetailRow('Genres', item!.genre!.join(', ')),
                  if (item!.country != null)
                    _buildDetailRow('Country', item!.country!),
                  if (item!.runtime != null)
                    _buildDetailRow('Runtime', item!.runtime!),
                  if (item!.language != null)
                    _buildDetailRow('Language', item!.language!),
                ]),

                // Cast
                if (item!.creditsCast != null && item!.creditsCast!.isNotEmpty)
                  _buildCastSection(context, item!.creditsCast!),

                // Cast
                if (item!.creditsCrew != null && item!.creditsCrew!.isNotEmpty)
                  _buildCastSection(
                    context,
                    title: "Crew",
                    item!.creditsCrew!.map((item) {
                      return CreditsCast(
                        character: item.department,
                        name: item.name,
                        profilePath: item.profilePath,
                        id: item.id,
                      );
                    }).toList(),
                  ),

                // Trailers
                if (item!.trailerStreams != null &&
                    item!.trailerStreams!.isNotEmpty)
                  _buildTrailersSection(context, item!.trailerStreams!),
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

  Widget _buildCastSection(
    BuildContext context,
    List<CreditsCast> cast, {
    String title = "Cast",
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
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
                          ? CachedNetworkImageProvider(
                              actor.profilePath!.startsWith("/")
                                  ? "https://proxy-image.syncws.com/insecure/plain/${Uri.encodeQueryComponent("https://image.tmdb.org/t/p/original/${actor.profilePath}")}@webp"
                                  : actor.profilePath!,
                              imageRenderMethodForWeb:
                                  ImageRenderMethodForWeb.HttpGet,
                            )
                          : null,
                      child: actor.profilePath == null
                          ? Icon(
                              Icons.person,
                              size: 50,
                              color: Colors.grey[300],
                            )
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

              return GestureDetector(
                onTap: () async {
                  final url = Uri.parse(
                    "https://www.youtube-nocookie.com/embed/${trailer.ytId}?autoplay=1&color=red&disablekb=1&enablejsapi=1&fs=1",
                  );

                  launchUrl(
                    url,
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Container(
                    width: 160,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.black26,
                      image: DecorationImage(
                        image: CachedNetworkImageProvider(
                          "https://proxy-image.syncws.com/insecure/plain/${Uri.encodeQueryComponent("https://i.ytimg.com/vi/${trailer.ytId}/mqdefault.jpg")}@webp",
                          imageRenderMethodForWeb:
                              ImageRenderMethodForWeb.HttpGet,
                        ),
                        fit: BoxFit.contain,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        trailer.title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(
          height: 12,
        ),
      ],
    );
  }
}
