import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:madari_client/engine/engine.dart';
import 'package:madari_client/features/watch_history/service/base_watch_history.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../features/connections/types/base/base.dart';
import '../features/watch_history/service/zeee_watch_history.dart';

export '../features/connections/types/base/base.dart';

part 'library.g.dart';

final Map<String, ResultList<LibraryRecord>> _libraryListCache = {};

@riverpod
Future<ResultList<LibraryRecord>> libraryList(Ref ref, int page) async {
  if (_libraryListCache.containsKey(page.toString())) {
    return _libraryListCache[page.toString()]!;
  }

  final result = await AppEngine.engine.pb.collection("library").getList(
        page: page,
        sort: "+order",
      );

  final returnValue = ResultList<LibraryRecord>();

  returnValue.totalItems = result.totalItems;
  returnValue.perPage = result.perPage;
  returnValue.page = result.page;
  returnValue.totalPages = result.totalPages;
  returnValue.items = result.items.where((item) {
    final connectionType = item.getStringValue("connectionType");

    if (connectionType != "telegram") {
      return true;
    }

    return false;
  }).map((item) {
    final i = item;
    return LibraryRecord.fromJson({
      "id": i.id,
      "connectionType": i.getStringValue("connectionType"),
      "icon": i.getStringValue("icon"),
      "title": i.getStringValue("title"),
      "types": i.getListValue<String>("types"),
      "config": i.getStringValue("config"),
      "connection": i.getStringValue("connection"),
    });
  }).toList();

  _libraryListCache[page.toString()] = returnValue;

  return returnValue;
}

final Map<String, ResultList<LibraryItemList>> _cache = {};

@riverpod
Future<ResultList<LibraryItemList>> libraryItemList(
  Ref ref,
  LibraryRecord library,
  List<LibraryItemList>? item,
  int page,
  String? search,
) async {
  final cache = "${library.id}_${page}_$search";

  final history = ZeeeWatchHistoryStatic.service;

  final result = _cache[cache]!.items.map((item) {
    return WatchHistoryGetRequest(
      id: item.id,
    );
  }).toList();

  final watchHistory = await history!.getItemWatchHistory(ids: result);

  _cache[cache]!.items = _cache[cache]!.items.map((item) {
    final history = watchHistory.where((history) => history.id == item.id);

    item.history = history.isEmpty ? null : history.first;
    return item;
  }).toList();

  return _cache[cache]!;
}

@JsonSerializable()
class LibraryItemList extends Jsonable {
  final String title;
  final String? logo;
  final int? size;
  final String? extra;
  final dynamic id;
  final String? config;
  final DateTime? date;
  final double? popularity;
  WatchHistory? history;

  LibraryItemList({
    required this.id,
    required this.title,
    this.config,
    this.logo,
    this.size,
    this.date,
    this.extra,
    this.popularity = 0,
    this.history,
  });

  factory LibraryItemList.fromRecord(RecordModel record) =>
      LibraryItemList.fromJson(record.toJson());

  factory LibraryItemList.fromJson(Map<String, dynamic> json) =>
      _$LibraryItemListFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$LibraryItemListToJson(this);
}

class FolderItem {
  final String title;
  final String id;
  final Widget? icon;
  final String? config;

  FolderItem({
    required this.title,
    required this.id,
    this.icon,
    this.config,
  });
}
