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

final Map<String, String> manifestCache = {};

typedef OnStreamCallback = void Function(List<StreamList>? items, Error?);

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

      print(manifest);

      print(addon);

      if (manifest.resources == null) {
        continue;
      }

      List<String> idPrefixes = [];

      bool isMeta = false;
      for (final item in manifest.resources!) {
        if (item.name == "meta") {
          idPrefixes.addAll((item.idPrefix ?? []) + (item.idPrefixes ?? []));
          isMeta = true;
          break;
        }
      }

      if (isMeta == false) {
        continue;
      }

      final ids = ((manifest.idPrefixes ?? []) + idPrefixes)
          .firstWhere((item) => id.id.startsWith(item), orElse: () => "");

      if (ids.isEmpty) {
        continue;
      }

      final result = await http.get(
        Uri.parse(
          "${_getAddonBaseURL(addon)}/meta/${(id as Meta).type}/${id.id}.json",
        ),
      );

      print("${_getAddonBaseURL(addon)}/meta/${(id).type}/${id.id}.json");

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
    final String result;
    if (manifestCache.containsKey(url)) {
      result = manifestCache[url]!;
    } else {
      result = (await http.get(Uri.parse(url))).body;
      manifestCache[url] = result;
    }

    final body = jsonDecode(result);
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
    final configItems = getConfig(library.config);
    List<ConnectionFilter<T>> filters = [];

    try {
      for (final addon in configItems) {
        final addonManifest = await _getManifest(addon.addon);

        if ((addonManifest.catalogs?.isEmpty ?? true) == true) {
          continue;
        }

        final catalogs = addonManifest.catalogs!.where((item) {
          return item.id == addon.item.id && item.type == addon.item.type;
        }).toList();

        for (final catalog in catalogs) {
          if (catalog.extra == null) {
            continue;
          }
          for (final extraItem in catalog.extra!) {
            if (extraItem.options == null ||
                extraItem.options?.isEmpty == true) {
              filters.add(
                ConnectionFilter<T>(
                  title: extraItem.name,
                  type: ConnectionFilterType.text,
                ),
              );
            } else {
              filters.add(
                ConnectionFilter<T>(
                  title: extraItem.name,
                  type: ConnectionFilterType.options,
                  values: extraItem.options?.whereType<T>().toList(),
                ),
              );
            }
          }
        }
      }
    } catch (e) {}

    return filters;
  }

  @override
  Future<void> getStreams(
    LibraryRecord library,
    LibraryItem id, {
    String? season,
    String? episode,
    OnStreamCallback? callback,
  }) async {
    final List<StreamList> streams = [];
    final meta = id as Meta;

    final List<Future<void>> promises = [];

    for (final addon in config.addons) {
      final future = Future.delayed(const Duration(seconds: 0), () async {
        final addonManifest = await _getManifest(addon);

        for (final resource_ in (addonManifest.resources ?? [])) {
          final resource = resource_ as ResourceObject;

          if (!doesAddonSupportStream(resource, addonManifest, meta)) {
            continue;
          }

          final url =
              "${_getAddonBaseURL(addon)}/stream/${meta.type}/${Uri.encodeComponent(id.id)}.json";

          final result = await http.get(Uri.parse(url), headers: {});

          if (result.statusCode == 404) {
            if (callback != null) {
              callback(
                null,
                ArgumentError(
                  "Invalid status code for the addon ${addonManifest.name} with id ${addonManifest.id}",
                ),
              );
            }
            continue;
          }

          final body = StreamResponse.fromJson(jsonDecode(result.body));

          streams.addAll(
            body.streams
                .map(
                  (item) => videoStreamToStreamList(
                      item, meta, season, episode, addonManifest),
                )
                .whereType<StreamList>()
                .toList(),
          );

          if (callback != null) {
            callback(streams, null);
          }
        }
      }).catchError((error) {
        if (callback != null) callback(null, error);
      });

      promises.add(future);
    }

    await Future.wait(promises);

    return;
  }

  bool doesAddonSupportStream(
    ResourceObject resource,
    StremioManifest addonManifest,
    Meta meta,
  ) {
    if (resource.name != "stream") {
      return false;
    }

    final idPrefixes =
        resource.idPrefixes ?? addonManifest.idPrefixes ?? resource.idPrefix;

    final types = resource.types ?? addonManifest.types;

    if (types == null || !types.contains(meta.type)) {
      return false;
    }

    final hasIdPrefix = (idPrefixes ?? []).where(
      (item) => meta.id.startsWith(item),
    );

    if (hasIdPrefix.isEmpty) {
      return false;
    }

    return true;
  }

  StreamList? videoStreamToStreamList(
    VideoStream item,
    Meta meta,
    String? season,
    String? episode,
    StremioManifest addonManifest,
  ) {
    String streamTitle = (item.name != null
            ? "${(item.name ?? "")} ${(item.title ?? "")}"
            : item.title) ??
        "No title";

    try {
      streamTitle = utf8.decode(streamTitle.runes.toList());
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

    String addonName = addonManifest.name;

    try {
      addonName = utf8.decode(
        (addonName).runes.toList(),
      );
    } catch (e) {}

    return StreamList(
      title: streamTitle,
      description: streamDescription,
      source: source,
      streamSource: StreamSource(
        title: addonName,
        id: addonManifest.id,
      ),
    );
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
