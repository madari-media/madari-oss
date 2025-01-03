import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:madari_client/features/connection/containers/auto_import.dart';
import 'package:madari_client/features/settings/types/connection.dart';
import 'package:pocketbase/pocketbase.dart';

import '../../../engine/engine.dart';
import '../../../engine/library.dart';
import '../../library/screen/create_new_library.dart';

class ConnectionManager extends StatefulWidget {
  final Connection item;

  const ConnectionManager({
    super.key,
    required this.item,
  });

  @override
  State<ConnectionManager> createState() => _ConnectionManagerState();
}

class _ConnectionManagerState extends State<ConnectionManager> {
  final PocketBase pb = AppEngine.engine.pb;
  late Future<ResultList<RecordModel>> _items;
  bool _isLoading = false;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _refreshItems();
  }

  void _refreshItems() {
    setState(() {
      _items = pb.collection("library").getList(
            filter: "connection.id = ${jsonEncode(widget.item.id)}",
            sort: "+order",
          );
    });
  }

  Future<void> _updateOrder(
      int oldIndex, int newIndex, List<RecordModel> items) async {
    setState(() => _isDragging = true);
    try {
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }

      final item = items.removeAt(oldIndex);
      items.insert(newIndex, item);

      // Update order for all affected items
      for (int i = 0; i < items.length; i++) {
        await pb.collection("library").update(
          items[i].id,
          body: {"order": i},
        );
      }
    } finally {
      setState(() => _isDragging = false);
      _refreshItems();
    }
  }

  Future<void> _showEditDialog(RecordModel item) async {
    final TextEditingController titleController = TextEditingController(
      text: item.getStringValue("title"),
    );

    return showDialog(
      context: context,
      barrierDismissible: !_isLoading,
      builder: (context) => AlertDialog(
        title: const Text('Edit Library'),
        content: TextField(
          controller: titleController,
          decoration: const InputDecoration(labelText: 'Library Name'),
          autofocus: true,
          enabled: !_isLoading,
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: _isLoading
                ? null
                : () async {
                    setState(() => _isLoading = true);
                    try {
                      await pb.collection("library").update(
                        item.id,
                        body: {"title": titleController.text},
                      );
                      if (context.mounted) if (mounted) Navigator.pop(context);
                      _refreshItems();
                    } finally {
                      setState(() => _isLoading = false);
                    }
                  },
            child: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(RecordModel item) async {
    return showDialog(
      context: context,
      barrierDismissible: !_isLoading,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this library?'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: _isLoading
                ? null
                : () async {
                    setState(() => _isLoading = true);
                    try {
                      await pb.collection("library").delete(item.id);
                      if (mounted && context.mounted) Navigator.pop(context);
                      _refreshItems();
                    } finally {
                      setState(() => _isLoading = false);
                    }
                  },
            child: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Connection ${widget.item.title}"),
        actions: [
          const SizedBox(width: 6),
          ElevatedButton.icon(
            onPressed: _isDragging || _isLoading
                ? null
                : () {
                    showModalBottomSheet(
                      context: context,
                      builder: (ctx) => AutoImport(item: widget.item),
                    ).then((_) => _refreshItems());
                  },
            label: const Text("Auto Import"),
            icon: const Icon(Icons.auto_awesome),
          ),
          const SizedBox(width: 10),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isDragging || _isLoading
            ? null
            : () {
                showModalBottomSheet(
                  context: context,
                  builder: (context) => Consumer(
                    builder: (context, ref, child) => CreateNewLibrary(
                      item: widget.item,
                      onCreatedAnother: () {},
                      onCreated: () {
                        Navigator.pop(context);
                        ref.refresh(libraryListProvider(1).future);
                        _refreshItems();
                      },
                    ),
                  ),
                );
              },
        label: const Text("Add new library"),
        icon: const Icon(Icons.add),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: FutureBuilder(
            future: _items,
            builder: (ctx, result) {
              if (result.hasError) {
                return Center(
                  child: Text("Error: ${result.error}"),
                );
              }

              if (!result.hasData) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              final items = result.data!.items;

              return ReorderableListView.builder(
                padding: const EdgeInsets.all(8.0),
                itemCount: items.length,
                onReorder: (oldIndex, newIndex) =>
                    _updateOrder(oldIndex, newIndex, items),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return Card(
                    key: ValueKey(item.id),
                    margin:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: ListTile(
                      title: Text(
                        item.getStringValue("title"),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: _isDragging || _isLoading
                                ? null
                                : () => _showEditDialog(item),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: _isDragging || _isLoading
                                ? null
                                : () => _confirmDelete(item),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
