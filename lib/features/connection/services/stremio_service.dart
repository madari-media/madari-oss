import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:json_annotation/json_annotation.dart';
import 'package:madari_client/engine/library.dart';
import 'package:madari_client/features/connection/services/base_connection_service.dart';
import 'package:madari_client/features/connection/types/stremio.dart';
import 'package:madari_client/features/doc_viewer/types/doc_source.dart';
import 'package:pocketbase/pocketbase.dart';

import '../../../engine/engine.dart';

part 'stremio_service.g.dart';

class StremioService extends BaseConnectionService {
  @override
  Future<String> connectionId;
  String config;

  static final Map<String, StremioManifest> _cache = {};

  late StremioConfig configParsed;

  StremioService({
    required this.connectionId,
    required this.config,
  }) {
    configParsed = StremioConfig.fromJson(jsonDecode(config));

    connectionId.then((item) {
      AppEngine.engine.pb.collection("connection").getOne(item).then((docs) {
        configParsed = StremioConfig.fromJson(docs.get("config"));
      });
    });
  }

  Future<StremioManifest> getManifest(String url) async {
    if (_cache.containsKey(url)) {
      return _cache[url]!;
    }

    final result = await http.get(Uri.parse(url));
    final resultFinal = StremioManifest.fromJson(jsonDecode(result.body));
    _cache[url] = resultFinal;

    return resultFinal;
  }

  Future<Meta?> getItemMetaById(String type, String id) async {
    for (final addon in configParsed.addons) {
      final manifest = await getManifest(addon);

      if (manifest.resources?.contains("meta") != true) {
        if (kDebugMode) print("ignoring because meta is not there");
        continue;
      }

      final ids = manifest.idPrefixes
          ?.firstWhere((item) => id.startsWith(item), orElse: () => "");

      if (ids == null) {
        continue;
      }

      final result = await http.get(
        Uri.parse("${_getAddonBaseURL(addon)}/meta/$type/$id.json"),
      );

      return StreamMetaResponse.fromJson(jsonDecode(result.body)).meta;
    }

    return null;
  }

  @override
  Future<List<FolderItem>> getFolders() async {
    final List<FolderItem> result = [];

    for (final addon in configParsed.addons) {
      final manifest = await getManifest(addon);

      final List<String> resources = (manifest.resources ?? []).map(
        (item) {
          return item.name;
        },
      ).toList();

      if (resources.contains("catalog")) {
        for (final item
            in (manifest.catalogs ?? [] as List<StremioManifestCatalog>)) {
          print(item.toJson());
          result.add(
            FolderItem(
              title: item.name == null
                  ? "${manifest.name} - ${item.type.capitalize()}".trim()
                  : "${item.type.capitalize()} - ${item.name}",
              id: "${item.type}-${item.id}",
              icon: const Icon(Icons.movie),
              config: jsonEncode(
                {
                  "type": item.type,
                  "id": "${item.type}-${item.id}",
                  "title":
                      "${item.type} ${item.name?.trim() != "" ? item.name : ""}"
                          .trim(),
                  'addon': addon,
                  'item': item,
                },
              ),
            ),
          );
        }
      }
    }

    return result;
  }

  @override
  Stream<List<DocSource>> getItem(LibraryItemList item) {
    throw UnimplementedError();
  }

  @override
  Future<ResultList<LibraryItemList>> getList({
    int page = 1,
    required String config,
    List<LibraryItemList>? lastItem,
    required List<String> type,
    String? search,
  }) async {
    final configOutput = jsonDecode(config);

    final List<InternalManifestItemConfig> items = [];

    for (final item in configOutput) {
      final itemToPush = InternalManifestItemConfig.fromJson(item);
      items.add(itemToPush);
    }

    final result = ResultList<LibraryItemList>();
    result.page = page;
    result.perPage = 50;
    result.items = List<LibraryItemList>.empty(growable: true);

    for (final item in items) {
      String url =
          "${_getAddonBaseURL(item.addon)}/catalog/${item.item.type}/${item.item.id}.json";

      if (page != 1) {
        final skip = result.perPage * (page - 1);

        url =
            "${_getAddonBaseURL(item.addon)}/catalog/${item.item.type}/${item.item.id}/skip=${Uri.encodeComponent(skip.toString())}.json";
      }

      if ((search ?? "").isNotEmpty) {
        url =
            "${_getAddonBaseURL(item.addon)}/catalog/${item.item.type}/${item.item.id}/search=${Uri.encodeComponent(search!)}.json";
      }

      final httpBody = await http.get(
        Uri.parse(
          url,
        ),
      );

      final meta = StrmioMeta.fromJson(json.decode(httpBody.body));

      for (final meta in meta.metas ?? []) {
        result.items.add(
          LibraryItemList(
            id: meta.id,
            title: meta.name!,
            logo: meta.poster,
            extra: meta.description,
            config: jsonEncode(meta),
            popularity: (meta.popularity ?? 0),
          ),
        );
      }
    }

    return result;
  }

  _getAddonBaseURL(String input) {
    return input.endsWith("/manifest.json")
        ? input.replaceAll("/manifest.json", "")
        : input;
  }

  Stream<List<VideoStream>> getStreams(
    String type,
    String id, {
    String? season,
    String? episode,
  }) async* {
    final List<VideoStream> streams = [];

    for (final addon in configParsed.addons) {
      final addonManifest = await getManifest(addon);

      for (final resource in (addonManifest.resources ?? [])) {
        if ((resource is String && resource == "stream") ||
            ((resource is ResourceObject) &&
                resource.types?.contains(type) == true)) {
          final url =
              "${_getAddonBaseURL(addon)}/stream/$type/${Uri.encodeComponent(id)}.json";

          final result = await http.get(Uri.parse(url), headers: {});

          final body = StreamResponse.fromJson(jsonDecode(result.body));

          streams.addAll(body.streams);

          yield streams;
        }
      }
    }

    return;
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}

@JsonSerializable()
class InternalManifestItemConfig {
  final InternalItem item;
  final String addon;

  InternalManifestItemConfig({
    required this.item,
    required this.addon,
  });

  factory InternalManifestItemConfig.fromJson(Map<String, dynamic> json) =>
      _$InternalManifestItemConfigFromJson(json);

  Map<String, dynamic> toJson() => _$InternalManifestItemConfigToJson(this);
}

@JsonSerializable()
class InternalItem {
  final String id;
  final String? name;
  final String type;

  InternalItem({
    required this.id,
    this.name,
    required this.type,
  });

  factory InternalItem.fromJson(Map<String, dynamic> json) =>
      _$InternalItemFromJson(json);

  Map<String, dynamic> toJson() => _$InternalItemToJson(this);
}
