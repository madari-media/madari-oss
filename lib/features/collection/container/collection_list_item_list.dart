import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:madari_client/features/doc_viewer/container/doc_viewer.dart';
import 'package:madari_client/features/doc_viewer/types/doc_source.dart';

import '../../../engine/engine.dart';
import '../service/service.dart';
import '../types/collection_item_model.dart';
import 'add_collection_item.dart';
import 'collection_markdown_renderer.dart';
import 'collection_search_delegate.dart';

class CollectionListItemsScreen extends StatefulWidget {
  final String listId;
  final bool isPublic;
  final String title;

  const CollectionListItemsScreen({
    super.key,
    required this.listId,
    required this.isPublic,
    required this.title,
  });

  @override
  State<CollectionListItemsScreen> createState() =>
      _CollectionListItemsScreenState();
}

class _CollectionListItemsScreenState extends State<CollectionListItemsScreen> {
  String _sortBy = 'created';
  bool _ascending = false;
  late Future<List<CollectionItemModel>> _itemsFuture;

  Future<void> _showAddItemSheet() async {
    final result = await showModalBottomSheet(
      context: context,
      builder: (context) => AddCollectionItemSheet(listId: widget.listId),
    );

    if (result == true) {
      setState(() => _refreshItems());
    }
  }

  @override
  void initState() {
    super.initState();
    _refreshItems();
  }

  void _refreshItems() {
    _itemsFuture = CollectionService.getCollectionItems(
      listId: widget.listId,
      searchQuery: '',
      sortBy: _sortBy,
      ascending: _ascending,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<CollectionItemModel>>(
      future: _itemsFuture,
      builder: (context, snapshot) {
        return Scaffold(
          floatingActionButton: snapshot.hasData &&
                  !widget.isPublic &&
                  !kIsWeb &&
                  (Platform.isIOS || Platform.isAndroid)
              ? FloatingActionButton(
                  onPressed: _showAddItemSheet,
                  child: const Icon(Icons.add),
                )
              : null,
          appBar: AppBar(
            title: Text(widget.title),
            actions: [
              // Search action
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: () {
                  showSearch(
                    context: context,
                    delegate: CollectionSearchDelegate(widget.listId),
                  );
                },
              ),
              // Sort menu
              PopupMenuButton<String>(
                icon: const Icon(Icons.sort),
                onSelected: (value) {
                  setState(() {
                    if (value == _sortBy) {
                      _ascending = !_ascending;
                    } else {
                      _sortBy = value;
                    }
                    _refreshItems();
                  });
                },
                itemBuilder: (context) => [
                  CheckedPopupMenuItem(
                    value: 'created',
                    checked: _sortBy == 'created',
                    child: Row(
                      children: [
                        const Text('Created'),
                        if (_sortBy == 'created')
                          Icon(_ascending
                              ? Icons.arrow_upward
                              : Icons.arrow_downward),
                      ],
                    ),
                  ),
                  CheckedPopupMenuItem(
                    value: 'updated',
                    checked: _sortBy == 'updated',
                    child: Row(
                      children: [
                        const Text('Updated'),
                        if (_sortBy == 'updated')
                          Icon(_ascending
                              ? Icons.arrow_upward
                              : Icons.arrow_downward),
                      ],
                    ),
                  ),
                ],
              ),
              // Refresh button
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => setState(() => _refreshItems()),
              ),
            ],
          ),
          body: FutureBuilder(
            future: Future.delayed(Duration.zero),
            builder: (ctx, _) {
              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('Error: ${snapshot.error}'),
                    ],
                  ),
                );
              }

              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final items = snapshot.data!;

              if (items.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inbox, size: 48, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No items found'),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return ListTile(
                    onTap: () async {
                      if (item.file != null && item.file != "") {
                        final fileToken =
                            await AppEngine.engine.pb.files.getToken();

                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) {
                              return DocViewer(
                                source: URLSource(
                                  title: item.name,
                                  url: "${item.file}?token=$fileToken",
                                  id: item.id,
                                ),
                              );
                            },
                          ),
                        );
                        return;
                      }

                      final file = await AppEngine.engine.pb
                          .collection("collection_item")
                          .getOne(item.id);

                      if (context.mounted && mounted) {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) => FullMarkdownSheet(
                            content: file.getStringValue("content") ?? "",
                          ),
                        );
                      }
                    },
                    leading: item.type == "markdown"
                        ? const Icon(Icons.document_scanner_outlined)
                        : const Icon(Icons.file_present),
                    title: Text(item.name),
                    subtitle: Text(formatDate(item.updated)),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  String formatDate(DateTime created) {
    return DateFormat("dd MMM yyyy").format(created);
  }
}
