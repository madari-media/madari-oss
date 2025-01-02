import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:json_annotation/json_annotation.dart';
import 'package:madari_client/features/connections/types/base/base.dart';
import 'package:madari_client/features/connections/widget/stremio/stremio_card.dart';
import 'package:madari_client/features/connections/widget/stremio/stremio_list_item.dart';
import 'package:madari_client/features/doc_viewer/types/doc_source.dart';
import 'package:pocketbase/pocketbase.dart';

import '../../connection/services/stremio_service.dart';
import '../types/stremio/stremio_base.types.dart';
import './base_connection_service.dart';

part 'stremio_connection_service.g.dart';

class StremioConnectionService extends BaseConnectionService {
  final StremioConfig config;

  StremioConnectionService({
    required super.connectionId,
    required this.config,
  });

  @override
  Future<LibraryItem?> getItemById(LibraryItem id) async {
    for (final addon in config.addons) {
      final manifest = await _getManifest(addon);

      if (manifest.resources?.contains("meta") != true) {
        continue;
      }

      final ids = manifest.idPrefixes
          ?.firstWhere((item) => id.id.startsWith(item), orElse: () => "");

      if (ids == null) {
        continue;
      }

      final result = await http.get(
        Uri.parse(
          "${_getAddonBaseURL(addon)}/meta/${(id as Meta).type}/${id.id}.json",
        ),
      );

      return StreamMetaResponse.fromJson(jsonDecode(result.body)).meta;
    }

    return null;
  }

  List<InternalManifestItemConfig> getConfig(dynamic configOutput) {
    final List<InternalManifestItemConfig> configItems = [];

    for (final item in configOutput) {
      final itemToPush = InternalManifestItemConfig.fromJson(
        jsonDecode(item),
      );
      configItems.add(itemToPush);
    }

    return configItems;
  }

  @override
  Future<PaginatedResult<LibraryItem>> getItems(
    LibraryRecord library, {
    List<ConnectionFilterItem>? items,
    int? page,
    int? perPage,
    String? cursor,
  }) async {
    final List<Meta> returnValue = [];
    final configItems = getConfig(library.config);

    bool hasMore = false;

    const perPage = 50;

    items = [...(items ?? [])];

    if (page != null) {
      items.add(
        ConnectionFilterItem(
          title: "skip",
          value: page * perPage,
        ),
      );
    }

    for (final item in configItems) {
      String url =
          "${_getAddonBaseURL(item.addon)}/catalog/${item.item.type}/${item.item.id}";

      if (items.isNotEmpty) {
        String filterPath = items.map((filter) {
          return "${filter.title}=${Uri.encodeComponent(filter.value.toString())}";
        }).join('&');

        // Add filters to URL
        if (filterPath.isNotEmpty) {
          url += "/$filterPath";
        }
      }

      url += ".json";

      final httpBody = await http.get(
        Uri.parse(url),
      );

      final result = StrmioMeta.fromJson(jsonDecode(httpBody.body));

      hasMore = result.hasMore ?? false;
      returnValue.addAll(result.metas ?? []);
    }

    return PagePaginatedResult(
      items: returnValue.toList(),
      currentPage: page ?? 1,
      totalPages: 0,
      hasMore: hasMore,
    );
  }

  @override
  Widget renderCard(
      LibraryRecord library, LibraryItem item, String heroPrefix) {
    return StremioCard(
      item: item,
      prefix: heroPrefix,
      connectionId: connectionId,
      libraryId: library.id,
    );
  }

  @override
  Widget renderList(
      LibraryRecord library, LibraryItem item, String heroPrefix) {
    return StremioListItem(item: item);
  }

  Future<StremioManifest> _getManifest(String url) async {
    final result = await http.get(Uri.parse(url));
    final body = jsonDecode(result.body);
    final resultFinal = StremioManifest.fromJson(body);
    return resultFinal;
  }

  _getAddonBaseURL(String input) {
    return input.endsWith("/manifest.json")
        ? input.replaceAll("/manifest.json", "")
        : input;
  }

  @override
  Future<List<ConnectionFilter<T>>> getFilters<T>(LibraryRecord library) async {
    return [];
  }

  @override
  Stream<List<StreamList>> getStreams(
    LibraryRecord library,
    LibraryItem id, {
    String? season,
    String? episode,
  }) async* {
    final List<StreamList> streams = [];
    final meta = id as Meta;

    for (final addon in config.addons) {
      final addonManifest = await _getManifest(addon);

      for (final _resource in (addonManifest.resources ?? [])) {
        final resource = _resource as ResourceObject;

        if (resource.name != "stream") {
          continue;
        }

        final idPrefixes = resource.idPrefixes ?? addonManifest.idPrefixes;
        final types = resource.types ?? addonManifest.types;

        if (types == null || !types.contains(meta.type)) {
          continue;
        }

        final hasIdPrefix =
            (idPrefixes ?? []).where((item) => meta.id.startsWith(item));

        if (hasIdPrefix.isEmpty) {
          continue;
        }

        final url =
            "${_getAddonBaseURL(addon)}/stream/${meta.type}/${Uri.encodeComponent(id.id)}.json";

        final result = await http.get(Uri.parse(url), headers: {});

        if (result.statusCode == 404) {
          continue;
        }

        final body = StreamResponse.fromJson(jsonDecode(result.body));

        streams.addAll(
          body.streams
              .map((item) {
                String streamTitle = item.title ?? item.name ?? "No title";

                try {
                  streamTitle = utf8.decode(
                    (item.title ?? item.name ?? "No Title").runes.toList(),
                  );
                } catch (e) {}

                final streamDescription = item.description != null
                    ? utf8.decode(
                        (item.description!).runes.toList(),
                      )
                    : null;

                String title = meta.name ?? item.title ?? "No title";

                if (season != null) title += " S$season";
                if (episode != null) title += " E$episode";

                DocSource? source;

                if (item.url != null) {
                  source = MediaURLSource(
                    title: title,
                    url: item.url!,
                    id: meta.id,
                  );
                }

                if (item.infoHash != null) {
                  source = TorrentSource(
                    title: title,
                    infoHash: item.infoHash!,
                    id: meta.id,
                    fileName: "$title.mp4",
                    season: season,
                    episode: episode,
                  );
                }

                if (source == null) {
                  return null;
                }

                return StreamList(
                  title: streamTitle,
                  description: streamDescription,
                  source: source,
                );
              })
              .whereType<StreamList>()
              .toList(),
        );

        yield streams;
      }
    }

    yield streams;

    return;
  }
}

@JsonSerializable()
class StremioConfig {
  List<String> addons;

  StremioConfig({
    required this.addons,
  });

  factory StremioConfig.fromRecord(RecordModel record) =>
      StremioConfig.fromJson(record.toJson());

  factory StremioConfig.fromJson(Map<String, dynamic> json) =>
      _$StremioConfigFromJson(json);

  Map<String, dynamic> toJson() => _$StremioConfigToJson(this);
}
