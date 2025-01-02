import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:madari_client/engine/library.dart';
import 'package:madari_client/features/connection/services/base_connection_service.dart';
import 'package:madari_client/features/connection/services/stremio_service.dart';
import 'package:madari_client/features/connection/types/stremio.dart';
import 'package:madari_client/features/library_item/container/stremio_item_card.dart';
import 'package:madari_client/features/library_item/container/stremio_item_list.dart';
import 'package:shimmer/shimmer.dart';

import '../../../utils/grid.dart';
import '../../library/component/library_search.dart';
import 'item_viewer.dart';

class ItemList extends ConsumerStatefulWidget {
  final LibraryRecord library;

  const ItemList({
    super.key,
    required this.library,
  });

  @override
  createState() => _ItemListState();
}

class _ItemListState extends ConsumerState<ItemList> {
  int _currentPage = 1;
  final ScrollController _scrollController = ScrollController();
  List<LibraryItemList> _items = [];
  bool _isLoading = false;
  bool _hasMoreItems = true;
  bool _hasInitiallyLoaded = false;
  late bool _isGridView;

  bool get isStremio {
    return widget.library.connectionType == "stremio_addons";
  }

  late BaseConnectionService _service;

  @override
  void initState() {
    super.initState();
    if (isStremio) {
      _isGridView = true;
    } else {
      _isGridView = false;
    }
    _scrollController.addListener(_onScroll);

    Future.microtask(() async {
      _fetchInitialItems();
    });
  }

  BaseConnectionService? _item;
  BaseConnectionService? get service {
    if (_item != null) {
      return _item;
    }

    _item = _service;

    return _item as BaseConnectionService;
  }

  Widget _buildItem(LibraryItemList item) {
    if (isStremio) {
      final parsed = Meta.fromJson(
        jsonDecode(item.config!),
      );

      if (_isGridView) {
        return StremioItemCard(
          heroPrefix: widget.library.id,
          item: item,
          parsed: parsed,
          service: service as StremioService,
        );
      } else {
        return StremioItemList(
          item: item,
          parsed: parsed,
          service: service as StremioService,
        );
      }
    }

    Widget image;

    if (item.logo == "" || item.logo == null) {
      image = Icon(
        Icons.file_copy,
        size: _isGridView ? 46 : 32,
      );
    } else {
      if (item.logo?.startsWith("/9j") == true) {
        image = Image.memory(
          base64Decode(item.logo!),
          fit: BoxFit.cover,
          width: 64,
          height: 64,
        );
      } else if (item.logo?.startsWith("http://") == true ||
          item.logo?.startsWith("https://") == true) {
        image = Image.network(
          item.logo!,
          fit: BoxFit.cover,
          width: 64,
          height: 64,
        );
      } else {
        image = Image.file(
          File(item.logo!),
          fit: BoxFit.cover,
          width: 64,
          height: 64,
        );
      }
    }

    onTap() => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) {
              return ItemViewer(
                item: item,
                library: widget.library,
              );
            },
          ),
        );

    return Container(
      margin: _isGridView
          ? const EdgeInsets.all(8)
          : const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: _isGridView
          ? ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                children: [
                  Card(
                    elevation: 0,
                    child: InkWell(
                      onTap: onTap,
                      child: Stack(
                        children: [
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 24.0),
                              child: AspectRatio(
                                aspectRatio: 16 / 9,
                                child: image,
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            left: 0,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Text(
                                item.title,
                                style: Theme.of(context).textTheme.titleMedium,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (item.history != null)
                    Positioned(
                      child: LinearProgressIndicator(
                        minHeight: 4,
                        value: item.history!.progress / 100,
                      ),
                    ),
                ],
              ),
            )
          : InkWell(
              onTap: onTap,
              child: ListTile(
                leading: item.logo == null
                    ? SizedBox(
                        width: 64,
                        height: 64,
                        child: Stack(
                          children: [
                            SizedBox(
                              width: 64,
                              height: 64,
                              child: image,
                            ),
                            if (item.history != null)
                              Positioned(
                                top: 0,
                                bottom: 0,
                                left: 0,
                                right: 0,
                                child: Center(
                                  child: CircularProgressIndicator(
                                    value: item.history!.progress / 100,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: SizedBox(
                          height: 40,
                          child: image,
                        ),
                      ),
                title: Text(
                  item.title,
                  maxLines: 1,
                ),
                subtitle: subtitleBuilder(item),
              ),
            ),
    );
  }

  Widget subtitleBuilder(LibraryItemList item) {
    String data = "";

    if ((item.size ?? 0) > 0) {
      data += "${_formatSize(item.size!)}\n";
    }

    if (item.date != null) {
      data += "${_formatDate(item.date ?? DateTime.now())}\n";
    }

    if (item.extra != null) {
      data += item.extra!;
    }

    return Text(data);
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();

    if (DateFormat('yyyy-MM-dd').format(now) ==
        DateFormat('yyyy-MM-dd').format(date)) {
      return 'Today';
    } else if (DateFormat('yyyy-MM-dd')
            .format(now.subtract(const Duration(days: 1))) ==
        date) {
      return 'Yesterday';
    }
    return DateFormat('MMMM d, yyyy').format(date);
  }

  String _formatSize(int size) {
    if (size == 0) return '';
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    var i = 0;
    double formattedSize = size.toDouble();
    while (formattedSize >= 1024 && i < suffixes.length - 1) {
      formattedSize /= 1024;
      i++;
    }
    return '${formattedSize.toStringAsFixed(1)} ${suffixes[i]}';
  }

  Widget _buildShimmerItem() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[800]!,
        highlightColor: Colors.grey[600]!,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: _isGridView
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Card(
                    elevation: 0,
                    margin: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Image placeholder
                        AspectRatio(
                          aspectRatio: isStremio ? 2 / 3 : 16 / 9,
                          child: Container(
                            color: Colors.grey[800],
                          ),
                        ),
                        // Title placeholder
                        if (!isStremio)
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Container(
                              height: 16,
                              width: double.infinity,
                              color: Colors.grey[800],
                            ),
                          ),
                      ],
                    ),
                  ),
                )
              : ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      width: 40,
                      height: 40,
                      color: Colors.grey[800],
                    ),
                  ),
                  title: Container(
                    height: 16,
                    color: Colors.grey[800],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Container(
                        height: 12,
                        width: 100,
                        color: Colors.grey[800],
                      ),
                      const SizedBox(height: 4),
                      Container(
                        height: 12,
                        width: 150,
                        color: Colors.grey[800],
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  void _fetchInitialItems() async {
    ref
        .read(libraryItemListProvider(
      widget.library,
      _items,
      _currentPage,
      null,
    ).future)
        .then((result) {
      if (mounted) {
        setState(() {
          _items = result.items;
          _hasMoreItems = result.items.isNotEmpty;
          _hasInitiallyLoaded = true;
        });
      }
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoading &&
        _hasMoreItems) {
      _loadMoreItems();
    }
  }

  Future<void> _loadMoreItems() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      _currentPage++;
      final result = await ref.read(
        libraryItemListProvider(
          widget.library,
          _items,
          _currentPage,
          null,
        ).future,
      );

      setState(() {
        _items.addAll(result.items);
        _hasMoreItems = result.items.isNotEmpty;
        _isLoading = false;
      });
    } catch (err) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load more items: $err')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.library.title),
        actions: [
          IconButton(
            icon: Icon(_isGridView ? Icons.list : Icons.grid_view),
            onPressed: () {
              setState(() {
                _isGridView = !_isGridView;
              });
            },
          ),
          IconButton(
            onPressed: () async {
              final result = await showSearch(
                context: context,
                delegate: LibraryItemSearchDelegate(
                  library: widget.library,
                  items: _items,
                  ref: ref,
                  service: service,
                ),
              );

              if (result != null && context.mounted) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => ItemViewer(
                      item: result,
                      library: widget.library,
                    ),
                  ),
                );
              }
            },
            icon: const Icon(Icons.search),
          ),
        ],
      ),
      body: _items.isEmpty && (_isLoading || !_hasInitiallyLoaded)
          ? GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: isStremio
                  ? SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: getGridResponsiveColumnCount(context),
                      mainAxisSpacing: getGridResponsiveSpacing(context),
                      crossAxisSpacing: getGridResponsiveSpacing(context),
                      childAspectRatio: 2 / 3,
                    )
                  : const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 1,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
              itemCount: 12,
              itemBuilder: (context, index) => _buildShimmerItem(),
            )
          : _isGridView
              ? GridView.builder(
                  controller: _scrollController,
                  gridDelegate: isStremio
                      ? SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: getGridResponsiveColumnCount(context),
                          mainAxisSpacing: getGridResponsiveSpacing(context),
                          crossAxisSpacing: getGridResponsiveSpacing(context),
                          childAspectRatio: 2 / 3,
                        )
                      : SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: getGridResponsiveColumnCount(context),
                          childAspectRatio: 1,
                          crossAxisSpacing: isStremio ? 0 : 8,
                          mainAxisSpacing: isStremio ? 0 : 8,
                        ),
                  itemCount: _items.length + (_isLoading ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index < _items.length) {
                      return _buildItem(_items[index]);
                    } else {
                      return _buildShimmerItem();
                    }
                  },
                )
              : Center(
                  child: Container(
                    constraints: const BoxConstraints(
                      maxWidth: 600,
                    ),
                    child: ListView.builder(
                      controller: _scrollController,
                      itemCount: _items.length + (_isLoading ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index < _items.length) {
                          return _buildItem(_items[index]);
                        } else {
                          return _buildShimmerItem();
                        }
                      },
                    ),
                  ),
                ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
