import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../engine/engine.dart';
import '../../doc_viewer/container/doc_viewer.dart';
import '../../doc_viewer/types/doc_source.dart';
import '../service/service.dart';
import '../types/collection_item_model.dart';
import 'collection_markdown_renderer.dart';

class CollectionSearchDelegate extends SearchDelegate<String> {
  final String listId;

  CollectionSearchDelegate(this.listId);

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
        close(context, '');
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults();
  }

  Widget _buildSearchResults() {
    if (query.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Start typing to search'),
          ],
        ),
      );
    }

    return FutureBuilder<List<CollectionItemModel>>(
      future: CollectionService.getCollectionItems(
        listId: listId,
        searchQuery: query,
        sortBy: 'created',
        ascending: false,
      ),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
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
                Icon(Icons.search_off, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No results found'),
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
                  final fileToken = await AppEngine.engine.pb.files.getToken();

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

                if (context.mounted) {
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
    );
  }

  String formatDate(DateTime created) {
    return DateFormat("dd MMM yyyy").format(created);
  }
}
