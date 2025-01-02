import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:madari_client/features/connection/services/base_connection_service.dart';
import 'package:madari_client/features/connection/services/stremio_service.dart';
import 'package:madari_client/features/library_item/container/stremio_item_card.dart';
import 'package:shimmer/shimmer.dart';

import '../../../engine/library.dart';
import '../../connections/types/stremio/stremio_base.types.dart';
import '../../library_item/container/item_list.dart';
import '../../library_item/container/item_viewer.dart';

class HomeItems extends ConsumerStatefulWidget {
  final LibraryRecord library;
  const HomeItems({
    super.key,
    required this.library,
  });

  @override
  createState() => _HomeItemsState();
}

class _HomeItemsState extends ConsumerState<HomeItems> {
  List<LibraryItemList> _items = [];
  bool _hasInitiallyLoaded = false;
  late BaseConnectionService _client;
  bool _unsupportedClient = false;

  @override
  void initState() {
    super.initState();

    Future.microtask(() async {
      _fetchInitialItems();
    });
  }

  double _getItemWidth(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    return screenWidth > 800 ? 200.0 : 120.0;
  }

  double _getListHeight(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    return screenWidth > 800 ? 300.0 : 180.0;
  }

  void _fetchInitialItems() async {
    if (widget.library.connection == "telegram" &&
        (kIsWeb || !Platform.isAndroid)) {
      setState(() {
        _items = [];
        _hasInitiallyLoaded = true;
        _unsupportedClient = true;
      });
    }

    if (!mounted) {
      return;
    }

    final result = ref.read(
      libraryItemListProvider(
        widget.library,
        _items,
        1,
        "",
      ),
    );

    if (result.value != null && mounted) {
      setState(() {
        _items = result.value!.items;
        _hasInitiallyLoaded = true;
      });
    }

    ref
        .read(libraryItemListProvider(
      widget.library,
      _items,
      1, // First page only
      null,
    ).future)
        .then((result) {
      if (mounted) {
        Future.microtask(() {
          setState(() {
            _items = result.items;
            _hasInitiallyLoaded = true;
          });
        });
      }
    });
  }

  StremioService? _item;

  StremioService get service {
    if (_item != null) {
      return _item!;
    }
    _item = _client as StremioService;
    return _item!;
  }

  @override
  Widget build(BuildContext context) {
    final itemWidth = _getItemWidth(context);
    final listHeight = _getListHeight(context);

    if (_items.isEmpty && _hasInitiallyLoaded) {
      return SizedBox(
        height: listHeight,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.hourglass_empty,
                size: 60,
                color: Colors.grey,
              ),
              const SizedBox(height: 16),
              Text(
                _unsupportedClient
                    ? 'Telegram is not supported'
                    : 'No items found',
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.library.title,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ItemList(
                        library: widget.library,
                      ),
                    ),
                  );
                },
                child: const Text('See All'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: listHeight,
          child: _items.isEmpty && !_hasInitiallyLoaded
              ? _buildLoadingList(itemWidth)
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: _items.length,
                  itemBuilder: (context, index) {
                    final item = _items[index];

                    if (widget.library.connectionType == "stremio_addons") {
                      final parsed = Meta.fromJson(
                        jsonDecode(item.config!),
                      );
                      return StremioItemCard(
                        item: item,
                        parsed: parsed,
                        service: service,
                        heroPrefix: widget.library.id,
                      );
                    }

                    return Container(
                      margin: const EdgeInsets.only(right: 6),
                      child: SizedBox(
                        width: itemWidth,
                        child: Card(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Stack(
                              children: [
                                InkWell(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ItemViewer(
                                          item: item,
                                          library: widget.library,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (item.logo != null)
                                        Expanded(
                                          child: AspectRatio(
                                            aspectRatio: 10 / 2,
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              child: Hero(
                                                tag: item.id,
                                                child: _buildImage(item.logo!),
                                              ),
                                            ),
                                          ),
                                        ),
                                      if (item.logo == null)
                                        const Expanded(
                                          child: Center(
                                            child: Icon(
                                              Icons.video_library,
                                              size: 44,
                                            ),
                                          ),
                                        )
                                    ],
                                  ),
                                ),
                                if (item.history != null)
                                  Positioned(
                                    child: LinearProgressIndicator(
                                      minHeight: 4,
                                      value:
                                          (item.history?.progress ?? 0) / 100,
                                    ),
                                  ),
                              ],
                            ),
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

  Widget _buildLoadingList(double itemWidth) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: 14,
      itemBuilder: (context, index) => SizedBox(
        width: itemWidth,
        child: Card(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Shimmer.fromColors(
              baseColor: Colors.grey[800]!,
              highlightColor: Colors.grey[600]!,
              child: Container(
                color: Colors.grey[800],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImage(String logo) {
    if (logo == "") {
      return const Center(
        child: Icon(Icons.browse_gallery),
      );
    }

    if (logo.startsWith("/9j")) {
      return Image.memory(
        base64Decode(logo),
        fit: BoxFit.cover,
      );
    } else if (logo.startsWith("http://") || logo.startsWith("https://")) {
      return Image.network(
        logo,
        fit: BoxFit.cover,
      );
    } else {
      return Image.file(
        File(logo),
        fit: BoxFit.cover,
      );
    }
  }
}
