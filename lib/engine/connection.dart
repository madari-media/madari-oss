import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:madari_client/features/settings/types/connection.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'engine.dart';

part 'connection.g.dart';

@riverpod
Future<List<Connection>> getConnections(Ref ref) async {
  final List<Connection> returnValue = [];

  final result = await AppEngine.engine.pb
      .collection("connection")
      .getFullList(expand: "type");

  for (final item in result) {
    if (item.id == "telegram") {
      continue;
    }
    returnValue.add(
      Connection(
        id: item.id,
        title: item.getStringValue("title"),
        type: item.getStringValue("expand.type.type"),
        config: jsonEncode(item.get("config")),
      ),
    );
  }

  return returnValue;
}
