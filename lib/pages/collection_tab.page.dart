import 'dart:math';

import 'package:flutter/material.dart';
import 'package:madari_client/engine/engine.dart';
import 'package:pocketbase/pocketbase.dart';

import '../features/collection/container/collection_list_item_list.dart';
import '../features/collection/container/create_new_collection.dart';
import '../features/collection/widgets/collection_card.dart';

class CollectionContainer extends StatefulWidget {
  const CollectionContainer({
    super.key,
  });

  @override
  State<CollectionContainer> createState() => _CollectionContainerState();
}

class _CollectionContainerState extends State<CollectionContainer> {
  final PocketBase pb = AppEngine.engine.pb;
  bool _isLoading = true;
  String? _error;
  List<CollectionListModel> _publicCollections = [];
  List<CollectionListModel> _personalCollections = [];

  @override
  void initState() {
    super.initState();
    _fetchCollections();
  }

  Future<void> _deleteCollection(String collectionId) async {
    try {
      await pb.collection('collection').delete(collectionId);
      setState(() {
        _personalCollections.removeWhere((item) => item.id == collectionId);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Collection deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to delete collection: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _fetchCollections() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Fetch public collections
      final publicResult = await pb.collection('collection').getFullList(
            filter: 'isPublic = true',
            sort: 'order',
          );

      // Fetch personal collections
      final personalResult = await pb.collection('collection').getFullList(
            filter: 'isPublic = false',
            sort: 'order',
          );

      setState(() {
        _publicCollections = publicResult
            .map((record) => CollectionListModel.fromRecord(record))
            .toList();
        _personalCollections = personalResult
            .map((record) => CollectionListModel.fromRecord(record))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load collections: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _reorderCollection(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    try {
      final item = _personalCollections.removeAt(oldIndex);
      _personalCollections.insert(newIndex, item);

      // Update the order in the database
      await pb.collection('collection').update(
        item.id,
        body: {'order': newIndex},
      );

      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to reorder: ${e.toString()}')),
      );
      // Revert the change
      _fetchCollections();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!, style: const TextStyle(color: Colors.red)),
            ElevatedButton(
              onPressed: _fetchCollections,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_publicCollections.isEmpty && _personalCollections.isEmpty) {
      return const Center(
        child: Text('No collections found'),
      );
    }

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateCollectionSheet,
        child: const Icon(Icons.add),
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(
            maxWidth: 1200,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_publicCollections.isNotEmpty) ...[
                _buildHorizontalView(),
              ],
              if (_personalCollections.isNotEmpty) ...[
                Expanded(child: _buildDraggableList()),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showCreateCollectionSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => CreateCollectionBottomSheet(
        onCollectionCreated: () {
          _fetchCollections();
        },
      ),
    );
  }

  Widget _buildHorizontalView() {
    final width = MediaQuery.of(context).size.width;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: _publicCollections
              .map(
                (collection) => CollectionCard(
                  collection: collection,
                  width: min(
                    width * .85,
                    360,
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  Widget _buildDraggableList() {
    return ReorderableListView.builder(
      itemCount: _personalCollections.length,
      onReorder: _reorderCollection,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemBuilder: (context, index) {
        final collection = _personalCollections[index];

        return Dismissible(
          key: ValueKey(collection.id),
          background: Container(
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 16),
            child: const Icon(
              Icons.delete,
              color: Colors.white,
            ),
          ),
          direction: DismissDirection.endToStart,
          confirmDismiss: (direction) async {
            return await showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text('Confirm deletion'),
                  content: const Text(
                      'Are you sure you want to delete this collection?'),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('CANCEL'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('DELETE'),
                    ),
                  ],
                );
              },
            );
          },
          onDismissed: (direction) {
            _deleteCollection(collection.id);
          },
          child: ListTile(
            contentPadding: const EdgeInsets.all(4),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (ctx) {
                    return CollectionListItemsScreen(
                      listId: collection.id,
                      title: collection.name,
                      isPublic: collection.isPublic,
                    );
                  },
                ),
              );
            },
            leading: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child:
                    collection.background != null && collection.background != ""
                        ? Image.network(
                            '${pb.baseURL}/api/files/${collection.collectionId}/${collection.id}/${collection.background}',
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Icon(
                              Icons.image_not_supported,
                              color: Theme.of(context).colorScheme.primary,
                              size: 30,
                            ),
                          )
                        : Icon(
                            Icons.collections,
                            color: Theme.of(context).colorScheme.primary,
                            size: 30,
                          ),
              ),
            ),
            title: Text(
              collection.name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: collection.description?.isEmpty == true
                ? null
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (collection.description != null &&
                          collection.description!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            collection.description!,
                            style: TextStyle(
                              color:
                                  Theme.of(context).textTheme.bodySmall?.color,
                              fontSize: 14,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
          ),
        );
      },
    );
  }
}
