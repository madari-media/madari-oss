import 'dart:async';
import 'dart:convert';

import 'package:cached_query/cached_query.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:json_annotation/json_annotation.dart';
import 'package:logging/logging.dart';
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
  final Logger _logger = Logger('StremioConnectionService');

  StremioConnectionService({
    required super.connectionId,
    required this.config,
  }) {
    _logger.info('StremioConnectionService initialized with config: $config');
  }

  @override
  Future<LibraryItem?> getItemById(LibraryItem id) async {
    _logger.fine('Fetching item by ID: ${id.id}');
    return Query<LibraryItem?>(
      key: "meta_${id.id}",
      config: QueryConfig(
        cacheDuration: const Duration(days: 30),
        refetchDuration: (id as Meta).type == "movie"
            ? const Duration(days: 30)
            : const Duration(days: 1),
      ),
      queryFn: () async {
        for (final addon in config.addons) {
          _logger.finer('Checking addon: $addon');
          final manifest = await _getManifest(addon);

          if (manifest.resources == null) {
            _logger.finer('No resources found in manifest for addon: $addon');
            continue;
          }

          List<String> idPrefixes = [];
          bool isMeta = false;

          for (final item in manifest.resources!) {
            if (item.name == "meta") {
              idPrefixes
                  .addAll((item.idPrefix ?? []) + (item.idPrefixes ?? []));
              isMeta = true;
              break;
            }
          }

          if (!isMeta) {
            _logger
                .finer('No meta resource found in manifest for addon: $addon');
            continue;
          }

          final ids = ((manifest.idPrefixes ?? []) + idPrefixes)
              .firstWhere((item) => id.id.startsWith(item), orElse: () => "");

          if (ids.isEmpty) {
            _logger.finer('No matching ID prefix found for addon: $addon');
            continue;
          }

          final result = await http.get(
            Uri.parse(
                "${_getAddonBaseURL(addon)}/meta/${id.type}/${id.id}.json"),
          );

          final item = jsonDecode(result.body);

          if (item['meta'] == null) {
            _logger.finer(
                'No meta data found for item: ${id.id} in addon: $addon');
            return null;
          }

          return StreamMetaResponse.fromJson(item).meta;
        }

        _logger.warning('No meta data found for item: ${id.id} in any addon');
        return null;
      },
    )
        .stream
        .where((item) => item.status != QueryStatus.loading)
        .first
        .then((docs) {
      if (docs.error != null) {
        _logger.severe('Error fetching item by ID: ${docs.error}');
        throw docs.error!;
      }
      return docs.data;
    });
  }

  List<InternalManifestItemConfig> getConfig(dynamic configOutput) {
    _logger.fine('Parsing config output');
    final List<InternalManifestItemConfig> configItems = [];

    for (final item in configOutput) {
      final itemToPush = InternalManifestItemConfig.fromJson(
        jsonDecode(item),
      );
      configItems.add(itemToPush);
    }

    _logger.finer('Config parsed successfully: $configItems');
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
    _logger.fine('Fetching items for library: ${library.id}');
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

        if (filterPath.isNotEmpty) {
          url += "/$filterPath";
        }
      }

      url += ".json";

      final result = await Query(
        config: QueryConfig(
          cacheDuration: const Duration(hours: 8),
        ),
        queryFn: () async {
          try {
            _logger.finer('Fetching catalog from URL: $url');
            final httpBody = await http.get(Uri.parse(url));
            return StrmioMeta.fromJson(
              jsonDecode(httpBody.body),
            );
          } catch (e, stack) {
            _logger.severe('Error parsing catalog $url', e, stack);
            rethrow;
          }
        },
        key: url,
      )
          .stream
          .where((item) => item.status != QueryStatus.loading)
          .first
          .then((docs) {
        if (docs.error != null) {
          _logger.severe('Error fetching catalog', docs.error);
          throw docs.error!;
        }
        return docs.data!;
      });

      hasMore = result.hasMore ?? false;
      returnValue.addAll(result.metas ?? []);
    }

    _logger.finer('Items fetched successfully: ${returnValue.length} items');
    return PagePaginatedResult(
      items: returnValue.toList(),
      currentPage: page ?? 1,
      totalPages: 0,
      hasMore: hasMore,
    );
  }

  @override
  Widget renderCard(LibraryItem item, String heroPrefix) {
    _logger.fine('Rendering card for item: ${item.id}');
    return StremioCard(
      item: item,
      prefix: heroPrefix,
      connectionId: connectionId,
      service: this,
    );
  }

  @override
  Future<List<LibraryItem>> getBulkItem(List<LibraryItem> ids) async {
    _logger.fine('Fetching bulk items: ${ids.length} items');
    if (ids.isEmpty) {
      _logger.finer('No items to fetch');
      return [];
    }

    return (await Future.wait(
      ids.map(
        (res) async {
          return getItemById(res).then((item) {
            if (item == null) {
              _logger.finer('Item not found: ${res.id}');
              return null;
            }

            return (item as Meta).copyWith(
              progress: (res as Meta).progress,
              nextSeason: res.nextSeason,
              nextEpisode: res.nextEpisode,
              nextEpisodeTitle: res.nextEpisodeTitle,
              externalIds: res.externalIds,
              episodeExternalIds: res.episodeExternalIds,
            );
          }).catchError((err, stack) {
            _logger.severe('Error fetching item: ${res.id}', err, stack);
            return (res as Meta);
          });
        },
      ),
    ))
        .whereType<Meta>()
        .toList();
  }

  @override
  Widget renderList(LibraryItem item, String heroPrefix) {
    _logger.fine('Rendering list item: ${item.id}');
    return StremioListItem(item: item);
  }

  Future<StremioManifest> _getManifest(String url) async {
    _logger.fine('Fetching manifest from URL: $url');
    return Query(
      key: url,
      config: QueryConfig(
        cacheDuration: const Duration(days: 30),
        refetchDuration: const Duration(days: 1),
      ),
      queryFn: () async {
        final String result;
        if (manifestCache.containsKey(url)) {
          _logger.finer('Manifest found in cache for URL: $url');
          result = manifestCache[url]!;
        } else {
          _logger.finer('Fetching manifest from network for URL: $url');
          result = (await http.get(Uri.parse(url))).body;
          manifestCache[url] = result;
        }

        final body = jsonDecode(result);
        final resultFinal = StremioManifest.fromJson(body);
        _logger.finer('Manifest successfully parsed for URL: $url');
        return resultFinal;
      },
    )
        .stream
        .where((item) => item.status != QueryStatus.loading)
        .first
        .then((docs) {
      if (docs.error != null) {
        _logger.severe('Error fetching manifest: ${docs.error}');
        throw docs.error!;
      }
      return docs.data!;
    });
  }

  String _getAddonBaseURL(String input) {
    return input.endsWith("/manifest.json")
        ? input.replaceAll("/manifest.json", "")
        : input;
  }

  @override
  Future<List<ConnectionFilter<T>>> getFilters<T>(LibraryRecord library) async {
    _logger.fine('Fetching filters for library: ${library.id}');
    final configItems = getConfig(library.config);
    List<ConnectionFilter<T>> filters = [];

    try {
      for (final addon in configItems) {
        final addonManifest = await _getManifest(addon.addon);

        if ((addonManifest.catalogs?.isEmpty ?? true) == true) {
          _logger.finer('No catalogs found for addon: ${addon.addon}');
          continue;
        }

        final catalogs = addonManifest.catalogs!.where((item) {
          return item.id == addon.item.id && item.type == addon.item.type;
        }).toList();

        for (final catalog in catalogs) {
          if (catalog.extra == null) {
            _logger.finer('No extra filters found for catalog: ${catalog.id}');
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
    } catch (e) {
      _logger.severe('Error fetching filters', e);
    }

    _logger.finer('Filters fetched successfully: $filters');
    return filters;
  }

  @override
  Future<void> getStreams(
    LibraryItem id, {
    String? season,
    String? episode,
    OnStreamCallback? callback,
  }) async {
    _logger.fine('Fetching streams for item: ${id.id}');
    final List<StreamList> streams = [];
    final meta = id as Meta;

    final List<Future<void>> promises = [];

    for (final addon in config.addons) {
      final future = Future.delayed(const Duration(seconds: 0), () async {
        final addonManifest = await _getManifest(addon);

        for (final resource_ in (addonManifest.resources ?? [])) {
          final resource = resource_ as ResourceObject;

          if (!doesAddonSupportStream(resource, addonManifest, meta)) {
            _logger.finer(
              'Addon does not support stream: ${addonManifest.name}',
            );
            continue;
          }

          final url =
              "${_getAddonBaseURL(addon)}/stream/${meta.type}/${Uri.encodeComponent(id.currentVideo?.id ?? id.id)}.json";

          final result = await Query(
            key: url,
            queryFn: () async {
              final result = await http.get(Uri.parse(url), headers: {});

              if (result.statusCode == 404) {
                _logger.warning(
                  'Invalid status code for addon: ${addonManifest.name}',
                );
                if (callback != null) {
                  callback(
                    null,
                    ArgumentError(
                      "Invalid status code for the addon ${addonManifest.name} with id ${addonManifest.id}",
                    ),
                  );
                }
              }

              return result.body;
            },
          )
              .stream
              .where((item) => item.status != QueryStatus.loading)
              .first
              .then((docs) {
            return docs.data;
          });

          if (result == null) {
            _logger.finer('No stream data found for URL: $url');
            continue;
          }

          final body = StreamResponse.fromJson(jsonDecode(result));

          streams.addAll(
            body.streams
                .map(
                  (item) => videoStreamToStreamList(
                    item,
                    meta,
                    season,
                    episode,
                    addonManifest,
                  ),
                )
                .whereType<StreamList>()
                .toList(),
          );

          if (callback != null) {
            callback(streams, null);
          }
        }
      }).catchError((error, stacktrace) {
        _logger.severe('Error fetching streams', error, stacktrace);
        if (callback != null) callback(null, error);
      });

      promises.add(future);
    }

    await Future.wait(promises);
    _logger.finer('Streams fetched successfully: ${streams.length} streams');
    return;
  }

  bool doesAddonSupportStream(
    ResourceObject resource,
    StremioManifest addonManifest,
    Meta meta,
  ) {
    if (resource.name != "stream") {
      _logger.finer('Resource is not a stream: ${resource.name}');
      return false;
    }

    final idPrefixes =
        resource.idPrefixes ?? addonManifest.idPrefixes ?? resource.idPrefix;

    final types = resource.types ?? addonManifest.types;

    if (types == null || !types.contains(meta.type)) {
      _logger.finer('Addon does not support type: ${meta.type}');
      return false;
    }

    if ((idPrefixes ?? []).isEmpty == true) {
      _logger.finer('No ID prefixes found, assuming support');
      return true;
    }

    final hasIdPrefix = (idPrefixes ?? []).where(
      (item) => meta.id.startsWith(item),
    );

    if (hasIdPrefix.isEmpty) {
      _logger.finer('No matching ID prefix found');
      return false;
    }

    _logger.finer('Addon supports stream');
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

    String? streamDescription = item.description;

    try {
      streamDescription = item.description != null
          ? utf8.decode((item.description!).runes.toList())
          : null;
    } catch (e) {}

    String title = meta.name ?? item.title ?? "No title";

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
      _logger.finer('No valid source found for stream');
      return null;
    }

    String addonName = addonManifest.name;

    try {
      addonName = utf8.decode((addonName).runes.toList());
    } catch (e) {
      _logger.warning('Failed to decode addon name', e);
    }

    _logger.finer('Stream list created successfully');
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
