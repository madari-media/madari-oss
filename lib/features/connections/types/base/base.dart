import 'package:json_annotation/json_annotation.dart';
import 'package:pocketbase/pocketbase.dart';

part 'base.g.dart';

@JsonSerializable()
class LibraryRecord extends Jsonable {
  final String id;
  final String icon;
  final String title;
  final List<String> types;
  final dynamic config;
  final String connection;
  final String connectionType;

  LibraryRecord({
    required this.id,
    required this.icon,
    required this.title,
    required this.types,
    required this.config,
    required this.connection,
    required this.connectionType,
  });

  factory LibraryRecord.fromRecord(RecordModel record) =>
      LibraryRecord.fromJson(record.toJson());

  factory LibraryRecord.fromJson(Map<String, dynamic> json) =>
      _$LibraryRecordFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$LibraryRecordToJson(this);
}
