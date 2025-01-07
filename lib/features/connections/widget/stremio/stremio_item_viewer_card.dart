import 'package:cached_network_image/cached_network_image.dart';
import 'package:cached_network_image_platform_interface/cached_network_image_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:madari_client/features/connections/service/base_connection_service.dart';
import 'package:madari_client/features/connections/widget/base/render_stream_list.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../types/stremio/stremio_base.types.dart';

class StremioItemViewerTV extends StatefulWidget {
  final Meta? meta;
  final Meta? original;
  final String? hero;
  final BaseConnectionService? service;
  final String library;

  const StremioItemViewerTV({
    super.key,
    this.meta,
    this.original,
    this.hero,
    this.service,
    required this.library,
  });

  @override
  State<StremioItemViewerTV> createState() => _StremioItemViewerTVState();
}

class _StremioItemViewerTVState extends State<StremioItemViewerTV> {
  String? _errorMessage;
  final FocusNode _playButtonFocusNode = FocusNode();
  final FocusNode _trailersFocusNode = FocusNode();
  bool _showTrailers = false;

  @override
  void initState() {
    super.initState();
    // Set initial focus to the Play button
    _playButtonFocusNode.requestFocus();
  }

  @override
  void dispose() {
    _playButtonFocusNode.dispose();
    _trailersFocusNode.dispose();
    super.dispose();
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
                  id: widget.meta as LibraryItem,
                  shouldPop: false,
                ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null) {
      return Center(
        child: Text("Failed $_errorMessage"),
      );
    }

    if (item == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          // Static Background
          if (item!.background != null)
            Positioned.fill(
              child: Image.network(
                item!.background!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  if (item!.poster == null) {
                    return Container();
                  }
                  return Image.network(item!.poster!, fit: BoxFit.cover);
                },
              ),
            ),
          // Gradient Overlay
          Positioned.fill(
            child: DecoratedBox(
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
          ),
          // Content
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Title
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    item!.name ?? "No Title",
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ),
                // Poster and Details Section
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: 900,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Poster
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
                                                image:
                                                    NetworkImage(item!.poster!),
                                                fit: BoxFit.cover,
                                              ),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.3),
                                            spreadRadius: 2,
                                            blurRadius: 8,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  // Details
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Year and Rating
                                        Row(
                                          children: [
                                            if (item!.year != null)
                                              Chip(
                                                label:
                                                    Text("${item!.year ?? ""}"),
                                                backgroundColor: Colors.white24,
                                                labelStyle: const TextStyle(
                                                    color: Colors.white),
                                              ),
                                            const SizedBox(width: 8),
                                            if (item!.imdbRating != "")
                                              Row(
                                                children: [
                                                  const Icon(
                                                    Icons.star,
                                                    color: Colors.amber,
                                                    size: 20,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    item!.imdbRating,
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .bodyMedium
                                                        ?.copyWith(
                                                            color:
                                                                Colors.white),
                                                  ),
                                                ],
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 16),
                                        // Description
                                        Text(
                                          'Description',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleLarge,
                                        ),
                                        if (item!.description != null)
                                          const SizedBox(height: 8),
                                        if (item!.description != null)
                                          Text(
                                            item!.description!,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium,
                                          ),
                                        const SizedBox(height: 16),
                                        // Additional Details
                                        _buildDetailSection(
                                            context, 'Additional Information', [
                                          if (item!.genre != null)
                                            _buildDetailRow('Genres',
                                                item!.genre!.join(', ')),
                                          if (item!.country != null)
                                            _buildDetailRow(
                                                'Country', item!.country!),
                                          if (item!.runtime != null)
                                            _buildDetailRow(
                                                'Runtime', item!.runtime!),
                                          if (item!.language != null)
                                            _buildDetailRow(
                                                'Language', item!.language!),
                                        ]),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              // Play Button
                              Focus(
                                focusNode: _playButtonFocusNode,
                                onKey: (node, event) {
                                  if (event is RawKeyDownEvent) {
                                    if (event.logicalKey ==
                                        LogicalKeyboardKey.arrowDown) {
                                      // Show Trailers
                                      setState(() {
                                        _showTrailers = true;
                                      });
                                      FocusScope.of(context)
                                          .requestFocus(_trailersFocusNode);
                                      return KeyEventResult.handled;
                                    } else if (event.logicalKey ==
                                        LogicalKeyboardKey.enter) {
                                      // Play the item
                                      _onPlayPressed(context);
                                      return KeyEventResult.handled;
                                    }
                                  }
                                  return KeyEventResult.ignored;
                                },
                                child: ElevatedButton.icon(
                                  icon: _isLoading
                                      ? Container(
                                          margin:
                                              const EdgeInsets.only(right: 6),
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
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (_showTrailers &&
                    item!.trailerStreams != null &&
                    item!.trailerStreams!.isNotEmpty)
                  Focus(
                    focusNode: _trailersFocusNode,
                    onKey: (node, event) {
                      if (event is RawKeyDownEvent) {
                        if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                          // Hide Trailers and move focus back to Play Button
                          setState(() {
                            _showTrailers = false;
                          });
                          FocusScope.of(context)
                              .requestFocus(_playButtonFocusNode);
                          return KeyEventResult.handled;
                        }
                      }
                      return KeyEventResult.ignored;
                    },
                    child:
                        _buildTrailersSection(context, item!.trailerStreams!),
                  ),
              ],
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

  Widget _buildTrailersSection(
      BuildContext context, List<TrailerStream> trailers) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
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
        ],
      ),
    );
  }
}
