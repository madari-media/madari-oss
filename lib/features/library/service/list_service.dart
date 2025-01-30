import 'package:logging/logging.dart';

import '../../pocketbase/service/pocketbase.service.dart';
import '../../settings/service/selected_profile.dart';
import '../types/library_types.dart';

class ListsService {
  static final ListsService instance = ListsService._internal();
  final _logger = Logger('ListsService');

  ListsService._internal();

  Future<List<ListModel>> getLists() async {
    try {
      final records =
          await AppPocketBaseService.instance.pb.collection('list').getFullList(
                filter:
                    "account_profile = '${SelectedProfileService.instance.selectedProfileId}'",
              );
      return records
          .map((record) => ListModel.fromJson(record.toJson()))
          .toList();
    } catch (e) {
      _logger.severe('Error fetching lists', e);
      rethrow;
    }
  }

  Future<void> createList(CreateListRequest request) async {
    try {
      await AppPocketBaseService.instance.pb.collection('list').create(
            body: request.toJson(),
          );
    } catch (e) {
      _logger.severe('Error creating list', e);
      rethrow;
    }
  }

  Future<void> importTraktList(ListModel traktList) async {
    try {
      await AppPocketBaseService.instance.pb.collection('list').create(
            body: traktList.toJson(),
          );
    } catch (e) {
      _logger.severe('Error importing Trakt list', e);
      rethrow;
    }
  }

  Future<void> updateList(String id, UpdateListRequest request) async {
    try {
      await AppPocketBaseService.instance.pb.collection('list').update(
            id,
            body: request.toJson(),
          );
    } catch (e) {
      _logger.severe('Error updating list', e);
      rethrow;
    }
  }

  Future<void> deleteList(String id) async {
    try {
      await AppPocketBaseService.instance.pb.collection('list').delete(id);
    } catch (e) {
      _logger.severe('Error deleting list', e);
      rethrow;
    }
  }

  Future<void> addListItem(String listId, ListItemModel item) async {
    try {
      final itemData = item.toJson();
      itemData['list'] = listId;

      await AppPocketBaseService.instance.pb.collection('list_item').create(
            body: itemData,
          );
    } catch (e) {
      _logger.severe('Error adding list item', e);
      rethrow;
    }
  }

  Future<List<ListItemModel>> getListItems(String listId) async {
    try {
      final records = await AppPocketBaseService.instance.pb
          .collection('list_item')
          .getFullList(
            filter: 'list = "$listId"',
            sort: '-created',
          );

      return records
          .map((record) => ListItemModel.fromJson(record.toJson()))
          .toList();
    } catch (e) {
      _logger.severe('Error fetching list items', e);
      rethrow;
    }
  }

  Future<void> removeListItem(String listId, String itemId) async {
    try {
      await AppPocketBaseService.instance.pb
          .collection('list_item')
          .delete(itemId);
    } catch (e) {
      _logger.severe('Error removing list item', e);
      rethrow;
    }
  }
}
