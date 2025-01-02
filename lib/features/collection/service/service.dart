import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';

import '../../../engine/engine.dart';
import '../types/collection_item_model.dart';

class CollectionService {
  static Future<List<CollectionItemModel>> getCollectionItems({
    required String listId,
    String searchQuery = '',
    String sortBy = 'created',
    bool ascending = false,
  }) async {
    try {
      final List<String> filters = ['list = "$listId"'];

      if (searchQuery.isNotEmpty) {
        filters.add('name ~ "$searchQuery"');
      }

      final String sort = ascending ? sortBy : '-$sortBy';

      final result =
          await AppEngine.engine.pb.collection('collection_item').getList(
                filter: filters.join(' && '),
                sort: sort,
                fields: "file, id, name, type, updated, list, user, created",
              );

      return result.items.map(
        (item) {
          final res = CollectionItemModel.fromJson(item.toJson());

          if (res.file != null) {
            final url = AppEngine.engine.pb.files.getURL(
              item,
              item.getStringValue('file'),
            );

            res.file = url.toString().replaceFirst(
                  "api/files//",
                  "api/files/pbc_2910457697/",
                );
          }

          return res;
        },
      ).toList();
    } catch (e) {
      print('Error fetching collection items: $e');
      rethrow;
    }
  }

  // Add new item
  static Future<CollectionItemModel> addItem({
    required String listId,
    required String name,
    required String type,
    PlatformFile? file,
    dynamic content,
  }) async {
    final data = {
      'list': listId,
      'name': name,
      'type': type,
      'content': content,
      'user': AppEngine.engine.pb.authStore.record!.id,
    };

    final record =
        await AppEngine.engine.pb.collection('collection_item').create(
      body: data,
      files: [
        if (file != null)
          http.MultipartFile.fromBytes(
            "file",
            (file.bytes)!.toList(),
            filename: basename(file.path!),
          ),
      ],
    );

    return CollectionItemModel.fromJson(record.toJson());
  }

  // Update existing item
  static Future<CollectionItemModel> updateItem({
    required String itemId,
    String? name,
    String? type,
    String? file,
    Map<String, dynamic>? content,
  }) async {
    final data = {
      if (name != null) 'name': name,
      if (type != null) 'type': type,
      if (file != null) 'file': file,
      if (content != null) 'content': content,
    };

    final record =
        await AppEngine.engine.pb.collection('collection_item').update(
              itemId,
              body: data,
            );

    return CollectionItemModel.fromJson(record.toJson());
  }

  // Delete item
  static Future<void> deleteItem(String itemId) async {
    await AppEngine.engine.pb.collection('collection_item').delete(itemId);
  }
}
