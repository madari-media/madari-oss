import 'package:madari_client/engine/engine.dart';
import 'package:madari_client/features/doc_viewer/types/doc_source.dart';
import 'package:pocketbase/pocketbase.dart';

import '../../../engine/library.dart';

abstract class BaseConnectionService {
  Future<List<FolderItem>> getFolders();
  Future<ResultList<LibraryItemList>> getList({
    int page = 1,
    required String config,
    List<LibraryItemList>? lastItem,
    required List<String> type,
    String? search,
  });
  abstract Future<String> connectionId;

  Future<void> createLibrary({
    required String title,
    required String icon,
    required List<String> types,
    required String config,
  }) async {
    AppEngine.engine.pb.collection("library").create(
      body: {
        "title": title,
        "icon": icon,
        "types": types,
        "user": AppEngine.engine.pb.authStore.record?.id,
        "config": config,
        "connection": connectionId,
      },
    );
  }

  Stream<List<DocSource>> getItem(LibraryItemList item);
}
