import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:madari_client/engine/engine.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'connection_type.g.dart';

@riverpod
Future<ResultList<ConnectionTypeRecord>> connectionTypeList(Ref ref,
    {int page = 1}) async {
  final result = await AppEngine.engine.pb
      .collection("connection_type")
      .getList(page: page, sort: "order");

  return ResultList(
    items: result.items
        .map(
          (item) => ConnectionTypeRecord.fromRecord(item),
        )
        .toList(),
    page: result.page,
    perPage: result.perPage,
    totalItems: result.totalItems,
    totalPages: result.totalPages,
  );
}

class ConnectionTypeRecord extends Jsonable {
  final String title;
  final String icon;
  final String type;
  final String id;

  ConnectionTypeRecord({
    required this.title,
    required this.icon,
    required this.type,
    required this.id,
  });

  factory ConnectionTypeRecord.fromRecord(RecordModel record) =>
      ConnectionTypeRecord.fromJson(record.toJson());

  factory ConnectionTypeRecord.fromJson(Map<String, dynamic> json) =>
      _$ConnectionTypeRecordFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$ConnectionTypeRecordToJson(this);
}

ConnectionTypeRecord _$ConnectionTypeRecordFromJson(
        Map<String, dynamic> json) =>
    ConnectionTypeRecord(
      id: json['id'] as String,
      title: json['title'] as String,
      icon: json['icon'] as String,
      type: json['type'] as String,
    );

Map<String, dynamic> _$ConnectionTypeRecordToJson(
        ConnectionTypeRecord instance) =>
    <String, dynamic>{
      'title': instance.title,
      'icon': instance.icon,
      'type': instance.type,
      'id': instance.id,
    };
