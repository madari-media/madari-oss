import 'package:json_annotation/json_annotation.dart';
import 'package:pocketbase/pocketbase.dart';

part 'connection.g.dart';

@JsonSerializable()
class Connection {
  final String id;
  final String title;
  final String type;
  final dynamic config;

  const Connection({
    required this.id,
    required this.title,
    required this.type,
    required this.config,
  });

  factory Connection.fromJson(Map<String, dynamic> json) =>
      _$ConnectionFromJson(json);

  factory Connection.fromRecord(RecordModel record) => Connection.fromJson(
        record.toJson(),
      );

  Map<String, dynamic> toJson() => _$ConnectionToJson(this);
}

class ConnectionType {
  final String id;
  final String title;

  ConnectionType({
    required this.id,
    required this.title,
  });
}
