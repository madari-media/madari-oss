import 'dart:convert';

import 'package:cached_query_flutter/cached_query_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:madari_client/data/db.dart';
import 'package:madari_client/features/streamio_addons/extension/query_extension.dart';
import 'package:madari_client/utils/array-extension.dart';

import '../../pocketbase/service/pocketbase.service.dart';
import '../../widgetter/plugins/stremio/models/cast_info.dart';
import '../models/stremio_base_types.dart';

typedef OnStreamCallback = void Function(
  List<VideoStream>? items,
  String? addonName,
  Error?,
);

class StremioAddonService {
  final _logger = Logger('StremioAddonService');

  static final StremioAddonService instance = StremioAddonService._internal();
  final _manifestQueryConfig = QueryConfig(
    cacheDuration: const Duration(hours: 8),
  );

  StremioAddonService._internal();

  Future<void> getStreams(
    Meta meta, {
    OnStreamCallback? callback,
  }) async {
    _logger.fine('Fetching streams for item: ${meta.id}');
    final List<VideoStream> streams = [];

    final List<Future<void>> promises = [];

    final addons = await getInstalledAddons(enabledOnly: true).queryFn();

    for (final addon in addons) {
      final future = Future.delayed(const Duration(seconds: 0), () async {
        final addonManifest = addon;
        for (final resource_ in (addonManifest.resources ?? [])) {
          final resource = resource_ as ResourceObject;

          if (!doesAddonSupportStream(resource, addonManifest, meta)) {
            _logger.finer(
              'Addon does not support stream: ${addonManifest.name}',
            );
            continue;
          }

          final url =
              "${_getAddonBaseURL(addon.manifestUrl!)}/stream/${meta.type}/${Uri.encodeComponent(meta.currentVideo?.id ?? meta.imdbId ?? meta.id)}.json";

          _logger.info("Loading streams from $url");

          final result = await http.get(Uri.parse(url), headers: {});

          if (result.statusCode == 404) {
            _logger.warning(
              'Invalid status code for addon: ${addonManifest.name}',
            );
            if (callback != null) {
              callback(
                null,
                addon.name,
                ArgumentError(
                  "Invalid status code for the addon ${addonManifest.name} with id ${addonManifest.id}",
                ),
              );
            }
          }

          final body = StreamResponse.fromJson(
            jsonDecode(
              utf8.decode(result.bodyBytes),
            ),
          );

          if (body.streams.isEmpty) {
            _logger.finer('No stream data found for URL: $url');
            continue;
          }

          streams.addAll(
            body.streams.toList(),
          );

          if (callback != null) {
            callback(streams, addonManifest.name, null);
          }
        }
      }).catchError((error, stacktrace) {
        _logger.severe('Error fetching streams', error, stacktrace);
        if (callback != null) callback(null, null, error);
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
      (item) =>
          meta.id.startsWith(item) || meta.imdbId?.startsWith(item) == true,
    );

    if (hasIdPrefix.isEmpty) {
      _logger.finer('No matching ID prefix found');
      return false;
    }

    _logger.finer('Addon supports stream');
    return true;
  }

  Query<StremioManifest> validateManifest(
    String url, {
    bool noCache = false,
  }) {
    url = url.replaceFirst(
      "stremio://",
      "https://",
    );

    return Query<StremioManifest>(
      config: noCache
          ? QueryConfig(
              shouldRefetch: (context, a) => true,
            )
          : _manifestQueryConfig,
      key: 'manifest-validation-$url-v2',
      queryFn: () async {
        try {
          final response = await http.get(
            Uri.parse(
              url,
            ),
          );
          if (response.statusCode != 200) {
            throw Exception('Failed to load manifest');
          }

          final manifest = StremioManifest.fromJson(
            jsonDecode(response.body),
            url,
          );

          final hasRequiredResources = manifest.resources?.any((r) {
                final name = r is String ? r : r.name;
                return ['catalog', 'meta', 'stream', 'subtitles']
                    .contains(name);
              }) ??
              false;

          if (!hasRequiredResources) {
            throw Exception(
              'Manifest must include catalog, meta, or stream resources',
            );
          }

          return manifest;
        } catch (e) {
          throw Exception('Invalid manifest: $e');
        }
      },
    );
  }

  Future<void> saveAddon(StremioManifest manifest) async {
    try {
      final data = {
        'url': manifest.manifestUrl,
        'title': manifest.name,
        'icon': manifest.logo ?? manifest.icon,
        'enabled': true,
        'user': AppPocketBaseService.instance.pb.authStore.record!.id,
      };

      await AppPocketBaseService.instance.pb
          .collection('stremio_addons')
          .create(body: data);

      await getInstalledAddons().refetch();
    } catch (e, stack) {
      print(e);
      print(stack);
      throw Exception('Failed to save addon: $e');
    }
  }

  Query<List<StremioManifest>> getInstalledAddons({bool enabledOnly = true}) {
    return Query<List<StremioManifest>>(
      config: _manifestQueryConfig,
      key: 'installed-addons-${enabledOnly ? 'enabled' : 'all'}',
      queryFn: () async {
        try {
          final records = await AppPocketBaseService.instance.pb
              .collection('stremio_addons')
              .getFullList(
                filter: enabledOnly ? 'enabled = true' : null,
              );

          final manifestFutures = records.map((record) async {
            try {
              final manifestQuery = validateManifest(record.data['url']);
              return await manifestQuery.queryFn();
            } catch (e) {
              _logger.warning(
                  'Failed to load manifest: ${record.data['url']}, Error: $e');
              return null;
            }
          }).toList();

          final results = await Future.wait(manifestFutures);

          final addons = results.whereType<StremioManifest>().toList();

          return addons;
        } catch (e) {
          throw Exception('Failed to load installed addons: $e');
        }
      },
    );
  }

  Future<void> toggleAddonState(String url, bool enabled) async {
    try {
      final records = await AppPocketBaseService.instance.pb
          .collection('stremio_addons')
          .getFirstListItem(
            'url = "$url"',
          );

      records.set("enabled", enabled);

      await AppPocketBaseService.instance.pb
          .collection('stremio_addons')
          .update(
            records.id,
            body: records.toJson(),
          );
    } catch (e, stack) {
      _logger.warning("failed to toggle the state", e, stack);
      throw Exception('Failed to update addon state: $e');
    }
  }

  Future<List<Meta>> getCatalog(
    StremioManifest manifest,
    String type,
    String id,
    int? page,
    List<ConnectionFilterItem> items,
  ) async {
    String url = "${_getAddonBaseURL(manifest.manifestUrl!)}/catalog/$type/$id";

    final catalog = manifest.catalogs?.firstWhereOrNull((item) {
      return item.type == type && item.id == id;
    });

    if (catalog == null) {
      _logger.info("Catalog not found $type $id");
      return [];
    }

    if (page != null && catalog.extraSupported?.contains("region") == true) {
      final region = AppPocketBaseService.instance.pb.authStore.record!
          .getStringValue("region");

      if (region.isNotEmpty) {
        items.add(
          ConnectionFilterItem(
            title: "region",
            value: region,
          ),
        );
      }
    }

    if (page != null && catalog.extraSupported?.contains("language") == true) {
      final language = AppPocketBaseService.instance.pb.authStore.record!
          .getStringValue("language");

      if (language.isNotEmpty) {
        items.add(
          ConnectionFilterItem(
            title: "language",
            value: language,
          ),
        );
      }
    }

    final required = (catalog.extraRequired ?? [])
        .where((item) => item != "featured")
        .every((item) {
      final result = items.firstWhereOrNull((allItem) {
        return allItem.title == item;
      });

      return result != null;
    });

    if (required == false) {
      _logger.info(
        "required param is not available in the params for catalog ${catalog.type} ${catalog.id} ${catalog.extraRequired?.join(", ")}",
      );
      return [];
    }

    final isSearch = items.firstWhereOrNull((item) {
          return item.title == "search";
        }) !=
        null;

    const perPage = 50;

    if (manifest.manifestVersion == "v2") {
      if (page != null &&
          catalog.extraSupported?.contains("skip") == true &&
          !isSearch) {
        items.add(
          ConnectionFilterItem(
            title: "skip",
            value: page * catalog.itemCount,
          ),
        );
      }

      if (items.isNotEmpty) {
        String filterPath = items
            .map((filter) {
              final value = catalog.extraSupported?.contains(filter.title);

              if (value == null) {
                return null;
              }

              return "${filter.title}=${Uri.encodeComponent(filter.value.toString())}";
            })
            .whereType<String>()
            .join('&');

        if (filterPath.isNotEmpty) {
          url += "?$filterPath";
        }
      }

      if (page != null &&
          catalog.extraSupported?.contains("skip") == true &&
          !isSearch) {
        items.add(
          ConnectionFilterItem(
            title: "skip",
            value: page * perPage,
          ),
        );
      }

      final httpBody = await http.get(Uri.parse(url));
      _logger.info("getting catalog from $url");

      final metaInfo = StrmioMeta.fromJson(
        jsonDecode(httpBody.body),
      );

      final db = AppDatabase();

      return Future.wait(
        (metaInfo.metas ?? []).map((item) async {
          if (item.imdbId != null) {
            final imdbRating = await db.getRatingByTConst(item.imdbId!);

            if (imdbRating == null) {
              return item;
            }

            return item.copyWith(imdbRating: imdbRating.toString());
          }

          return item;
        }).toList(),
      );
    }

    if (items.isNotEmpty) {
      String filterPath = items
          .map((filter) {
            final value = catalog.extraSupported?.contains(filter.title);

            if (value == null) {
              return null;
            }

            return "${filter.title}=${Uri.encodeComponent(filter.value.toString())}";
          })
          .whereType<String>()
          .join('/');

      if (filterPath.isNotEmpty) {
        url += "/$filterPath";
      }
    }

    url += ".json";

    final httpBody = await http.get(Uri.parse(url));
    _logger.info("getting catalog from $url");
    final metaInfo = StrmioMeta.fromJson(
      jsonDecode(httpBody.body),
    );

    return metaInfo.metas ?? [];
  }

  _getAddonBaseURL(String input) {
    return input.endsWith("/manifest.json")
        ? input.replaceAll("/manifest.json", "")
        : input;
  }

  Future<void> removeAddon(String url) async {
    try {
      final records = await AppPocketBaseService.instance.pb
          .collection('stremio_addons')
          .getFullList(
            filter: 'url = "$url"',
          );

      if (records.isNotEmpty) {
        await AppPocketBaseService.instance.pb
            .collection('stremio_addons')
            .delete(records.first.id);
      }
      await getInstalledAddons().refetch();
    } catch (e) {
      throw Exception('Failed to remove addon: $e');
    }
  }

  Future<Meta?> getMeta(String type, String id) async {
    final addons = await getInstalledAddons(enabledOnly: true).queryFn();

    for (final addon in addons) {
      _logger.finer('Checking addon: $addon');

      final manifest = addon;

      if (manifest.resources == null) {
        _logger.finer('No resources found in manifest for addon: $addon');
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

      if (!isMeta) {
        _logger.finer('No meta resource found in manifest for addon: $addon');
        continue;
      }

      final ids = ((manifest.idPrefixes ?? []) + idPrefixes)
          .firstWhere((item) => id.startsWith(item), orElse: () => "");

      if (ids.isEmpty) {
        _logger.finer('No matching ID prefix found for addon: $addon');
        continue;
      }

      final result = await http.get(
        Uri.parse(
          "${_getAddonBaseURL(addon.manifestUrl!)}/meta/$type/$id.json",
        ),
      );

      final item = jsonDecode(result.body);

      if (item['meta'] == null) {
        _logger.finer('No meta data found for item: $id in addon: $addon');
        return null;
      }

      final meta = StreamMetaResponse.fromJson(item).meta;

      final db = AppDatabase();

      if (meta.imdbId != null) {
        final rating = await db.getRatingByTConst(meta.imdbId!);

        return meta.copyWith(
          imdbRating: rating != null ? rating.toString() : meta.imdbRating,
        );
      }

      return meta;
    }

    return Meta(type: "type", id: "id");
  }

  Future<CastMember?> getPerson(String id) async {
    final getInstalledAddon = await getInstalledAddons(
      enabledOnly: true,
    ).queryFn();

    for (final value in getInstalledAddon) {
      final resource = value.resources?.firstWhereOrNull((item) {
        return item.name == "person";
      });

      if (resource == null) {
        continue;
      }

      String url =
          "${_getAddonBaseURL(value.manifestUrl!)}/person/tmdb:$id.json";

      final result = await http.get(Uri.parse(url));

      if (result.statusCode != 200) {
        _logger.warning("failed with status ${result.statusCode}");
        continue;
      }

      final person = utf8.decode(result.bodyBytes);

      final personData = jsonDecode(person);

      return CastMember.fromJson(personData['person']);
    }

    return null;
  }
}

enum ConnectionFilterType {
  text,
  options,
}

class ConnectionFilterItem {
  final String title;
  final dynamic value;

  ConnectionFilterItem({
    required this.title,
    required this.value,
  });
}
