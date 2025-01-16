import 'dart:async';
import 'dart:convert';

import 'package:cached_query/cached_query.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:madari_client/utils/common.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:rxdart/rxdart.dart';

import '../../../engine/connection_type.dart';
import '../../../engine/engine.dart';
import '../../connections/service/base_connection_service.dart';
import '../../connections/types/stremio/stremio_base.types.dart';
import '../../settings/types/connection.dart';
import '../types/common.dart';

class TraktService {
  static final Logger _logger = Logger('TraktService');

  static const String _baseUrl = 'https://api.trakt.tv';
  static const String _apiVersion = '2';

  final refetchKey = BehaviorSubject<List<String>>();

  static TraktService? _instance;
  static TraktService? get instance => _instance;
  static BaseConnectionService? stremioService;

  Map<String, dynamic> _cache = {};

  saveCacheToDisk() {
    _logger.fine('Saving cache to disk');
    CachedQuery.instance.storage?.put(
      StoredQuery(
        key: "trakt_integration_cache",
        data: _cache,
        createdAt: DateTime.now(),
      ),
    );
  }

  Future<void> removeFromContinueWatching(String id) async {
    if (!isEnabled()) {
      _logger.info('Trakt integration is not enabled');
      return;
    }

    try {
      _logger.info(
        'Removing item from history (continue watching): $id',
      );

      final response = await http.delete(
        Uri.parse('$_baseUrl/sync/playback/$id'),
        headers: headers,
      );

      if (response.statusCode != 204) {
        _logger.severe(
          'Failed to remove item from history: ${response.statusCode} $id',
        );
        throw Exception('Failed to remove item from history');
      }

      _cache.remove('$_baseUrl/sync/watched/shows');
      _cache.remove('$_baseUrl/sync/playback');

      refetchKey.add(["continue_watching", "up_next_series"]);

      _logger.info(
        'Successfully removed item from history (continue watching)',
      );
    } catch (e, stack) {
      _logger.severe('Error removing item from history: $e', stack);
      rethrow;
    }
  }

  Future<void> removeFromWatchlist(Meta meta) async {
    if (!isEnabled()) {
      _logger.info('Trakt integration is not enabled');
      return;
    }

    try {
      _logger.info('Removing item from watchlist: ${meta.id}');

      final response = await http.post(
        Uri.parse('$_baseUrl/sync/watchlist/remove'),
        headers: headers,
        body: json.encode({
          if (meta.type == "movie")
            'movies': [
              {
                'ids': {
                  'imdb': meta.id,
                },
              },
            ],
          if (meta.type == "shows")
            'shows': [
              {
                'ids': {
                  'imdb': meta.id,
                },
              }
            ],
        }),
      );

      if (response.statusCode != 200) {
        _logger.severe(
            'Failed to remove item from watchlist: ${response.statusCode}');
        throw Exception('Failed to remove item from watchlist');
      }

      _cache.remove('$_baseUrl/sync/watchlist');

      refetchKey.add(["watchlist"]);

      _logger.info('Successfully removed item from watchlist');
    } catch (e, stack) {
      _logger.severe('Error removing item from watchlist: $e', stack);
      rethrow;
    }
  }

  clearCache() {
    _logger.info('Clearing cache');
    _cache.clear();
  }

  static ensureInitialized() async {
    if (_instance != null) {
      _logger.fine('Instance already initialized');
      return _instance;
    }

    _logger.info('Initializing TraktService');

    final result =
        await CachedQuery.instance.storage?.get("trakt_integration_cache");

    AppEngine.engine.pb.authStore.onChange.listen((item) {
      if (!AppEngine.engine.pb.authStore.isValid) {
        _logger.info('Auth store is invalid, clearing cache');
        _instance?._cache.clear();
      }
    });

    final traktService = TraktService();
    await traktService.initStremioService();
    _instance = traktService;

    _instance?._cache = result?.data ?? {};

    _instance!._startCacheRevalidation();
  }

  Future<BaseConnectionService> initStremioService() async {
    if (stremioService != null) {
      _logger.fine('StremioService already initialized');
      return stremioService!;
    }

    _logger.info('Initializing StremioService');

    final model_ =
        await AppEngine.engine.pb.collection("connection").getFirstListItem(
              "type.type = 'stremio_addons'",
              expand: "type",
            );

    final connection = ConnectionResponse(
      connection: Connection.fromRecord(model_),
      connectionTypeRecord: ConnectionTypeRecord.fromRecord(
        model_.get<RecordModel>("expand.type"),
      ),
    );

    stremioService = BaseConnectionService.connectionById(connection);

    return stremioService!;
  }

  static String get _traktClient {
    final client = "" ?? DotEnv().get("trakt_client_id");

    if (client == "") {
      _logger.warning('Using default Trakt client ID');
      return "b47864365ac88ecc253c3b0bdf1c82a619c1833e8806f702895a7e8cb06b536a";
    }

    return client;
  }

  get _token {
    return AppEngine.engine.pb.authStore.record!.getStringValue("trakt_token");
  }

  final Map<String, Completer<void>> _activeScrobbleRequests = {};

  List<String> debugLogs = [];

  Map<String, String> get headers => {
        'Content-Type': 'application/json',
        'trakt-api-version': _apiVersion,
        'trakt-api-key': _traktClient,
        'Authorization': 'Bearer $_token',
      };

  void _startCacheRevalidation() {
    _logger.info('Starting cache revalidation timer');
  }

  Future<dynamic> _makeRequest(String url, {bool bypassCache = false}) async {
    if (!bypassCache && _cache.containsKey(url)) {
      _logger.fine('Returning cached data for $url');
      return _cache[url];
    }

    _logger.info('Making GET request to $url');
    final response = await http.get(Uri.parse(url), headers: headers);

    if (response.statusCode != 200) {
      _logger.severe('Failed to fetch data from $url: ${response.statusCode}');
      throw Exception('Failed to fetch data from $url ${response.statusCode}');
    }

    _logger.info('Successfully fetched data from $url');
    final data = json.decode(response.body);
    _cache[url] = data;

    saveCacheToDisk();

    return data;
  }

  Map<String, dynamic> _buildObjectForMeta(Meta meta) {
    if (meta.type == "movie") {
      return {
        'movie': {
          'title': meta.name,
          'year': meta.year,
          'ids': {
            'imdb': meta.imdbId ?? meta.id,
            if (meta.tvdbId != null) 'tvdb': meta.tvdbId,
          },
        },
      };
    } else {
      if (meta.currentVideo?.tvdbId != null) {
        return {
          "episode": {
            "ids": {
              "tvdb": meta.currentVideo?.tvdbId!,
            },
          },
        };
      }

      if (meta.currentVideo?.season != null &&
          meta.currentVideo?.episode != null) {
        return {
          "episode": {
            "season": meta.currentVideo!.season,
            "episode": meta.currentVideo!.episode,
          },
          "show": {
            "ids": {
              "imdb": meta.imdbId ?? meta.id,
            }
          },
        };
      }

      return {
        "episode": {
          "ids": {
            "imdb": meta.currentVideo?.id ?? meta.id,
          }
        }
      };
    }
  }

  Stream<List<LibraryItem>> getUpNextSeries({
    int page = 1,
    int itemsPerPage = 5,
  }) async* {
    await initStremioService();

    if (!isEnabled()) {
      _logger.info('Trakt integration is not enabled');
      yield [];
      return;
    }

    try {
      _logger.info('Fetching up next series');
      final List<dynamic> watchedShows = await _makeRequest(
        '$_baseUrl/sync/watched/shows',
      );

      if (watchedShows.isEmpty) {
        return;
      }

      final startIndex =
          ((page - 1) * itemsPerPage).clamp(0, watchedShows.length - 1);
      final endIndex =
          (startIndex + itemsPerPage).clamp(0, watchedShows.length - 1);

      final items = watchedShows.toList();

      if (startIndex >= items.length) {
        yield [];
        return;
      }

      final paginatedItems = items.sublist(
        startIndex,
        endIndex > items.length ? items.length : endIndex,
      );

      final progressFutures = paginatedItems.map((show) async {
        final showId = show['show']['ids']['trakt'];
        final imdb = show['show']['ids']['imdb'];

        try {
          final progress = await _makeRequest(
            '$_baseUrl/shows/$showId/progress/watched',
          );

          final nextEpisode = progress['next_episode'];

          if (nextEpisode != null && imdb != null) {
            final item = await stremioService!.getItemById(
              Meta(
                type: "series",
                id: imdb,
              ),
            );

            return patchMetaObjectForShow(item as Meta, nextEpisode);
          }
        } catch (e, stack) {
          _logger.severe(
            'Error fetching progress for show $showId: $e',
            e,
            stack,
          );
          return null;
        }

        return null;
      }).toList();

      final results = await Future.wait(progressFutures);
      final validResults = results.whereType<Meta>().toList();

      final paginatedResults = validResults;

      yield paginatedResults;
    } catch (e, stack) {
      _logger.severe('Error fetching up next episodes: $e', stack);
      yield [];
    }
  }

  Meta patchMetaObjectForShow(
    Meta meta,
    dynamic obj, {
    double? progress,
  }) {
    if (meta.videos?.isEmpty == true) {
      meta.videos = [];
      meta.videos?.add(
        Video(
          season: obj['season'],
          number: obj['number'],
          thumbnail: meta.poster,
          id: _traktIdsToMetaId(obj['ids']),
        ),
      );
      return meta;
    }

    final videoIndexByTvDB = meta.videos?.firstWhereOrNull((item) {
      return item.tvdbId == obj['ids']['tvdb'] && item.tvdbId != null;
    });

    final videoBySeasonOrEpisode = meta.videos?.firstWhereOrNull((item) {
      return item.season == obj['season'] && item.episode == obj['number'];
    });

    final video = videoIndexByTvDB ?? videoBySeasonOrEpisode;

    if (video == null) {
      final id = _traktIdsToMetaId(obj['ids']);

      meta.videos = meta.videos ?? [];

      meta.videos?.add(
        Video(
          name: obj['title'],
          season: obj['season'],
          number: obj['number'],
          thumbnail: meta.poster,
          id: id,
          episode: obj['number'],
        ),
      );

      final videosIndex = meta.videos?.length ?? 1;

      return meta.copyWith(
        selectedVideoIndex: videosIndex - 1,
      );
    }

    final index = meta.videos?.indexOf(video);

    meta.videos![index!].name = obj['title'];
    meta.videos![index].tvdbId =
        meta.videos![index].tvdbId ?? obj['ids']['tvdb'];
    meta.videos![index].ids = obj['ids'];

    return meta.copyWith(
      selectedVideoIndex: index,
    );
  }

  String _traktIdsToMetaId(dynamic ids) {
    String id;

    if (ids['imdb'] != null) {
      id = ids['imdb'];
    } else if (ids['tmdb'] != null) {
      id = "tmdb:${ids['tmdb']}";
    } else if (ids['trakt']) {
      id = "trakt:${ids['trakt']}";
    } else {
      id = "na";
    }

    return id;
  }

  Future<List<LibraryItem>> getContinueWatching({
    int page = 1,
    int itemsPerPage = 5,
  }) async {
    await initStremioService();

    if (!isEnabled()) {
      _logger.info('Trakt integration is not enabled');
      return [];
    }

    try {
      _logger.info('Fetching continue watching');
      final List<dynamic> continueWatching =
          await _makeRequest('$_baseUrl/sync/playback');

      if (continueWatching.isEmpty) {
        return [];
      }

      continueWatching.sort((v2, v1) => DateTime.parse(v1["paused_at"])
          .compareTo(DateTime.parse(v2["paused_at"])));

      final startIndex =
          ((page - 1) * itemsPerPage).clamp(0, continueWatching.length - 1);
      final endIndex =
          (startIndex + itemsPerPage).clamp(0, continueWatching.length - 1);

      if (startIndex >= continueWatching.length) {
        return [];
      }

      final metaList = (await Future.wait(continueWatching
              .sublist(
        startIndex,
        endIndex,
      )
              .map((movie) async {
        try {
          if (movie['type'] == 'episode') {
            final meta = Meta(
              type: "series",
              id: _traktIdsToMetaId(
                movie['show']['ids'],
              ),
            );

            return patchMetaObjectForShow(
              (await stremioService!.getItemById(meta) as Meta),
              movie['episode'],
            ).copyWith(
              forceRegular: true,
              progress: movie['progress'],
              traktProgressId: movie['id'],
            );
          }

          final movieId = _traktIdsToMetaId(movie['movie']['ids']);

          final meta = Meta(
            type: "movie",
            id: movieId,
          );

          return ((await stremioService!.getItemById(meta)) as Meta).copyWith(
            progress: movie['progress'],
            traktProgressId: movie['id'],
          );
        } catch (e, stack) {
          _logger.warning(
            'Error mapping movie: $e',
            e,
            stack,
          );
          return null;
        }
      })))
          .whereType<Meta>()
          .toList();

      return metaList;
    } catch (e, stack) {
      _logger.severe('Error fetching continue watching: $e', stack);
      return [];
    }
  }

  Future<List<LibraryItem>> getUpcomingSchedule({
    int page = 1,
    int itemsPerPage = 5,
  }) async {
    await initStremioService();

    if (!isEnabled()) {
      _logger.info('Trakt integration is not enabled');
      return [];
    }

    try {
      _logger.info('Fetching upcoming schedule');
      final List<dynamic> scheduleShows = await _makeRequest(
        '$_baseUrl/calendars/my/shows/${DateFormat('yyyy-MM-dd').format(DateTime.now())}/7',
      );

      if (scheduleShows.isEmpty) {
        return [];
      }

      final startIndex =
          ((page - 1) * itemsPerPage).clamp(0, scheduleShows.length - 1);
      final endIndex =
          (startIndex + itemsPerPage).clamp(0, scheduleShows.length - 1);

      if (startIndex >= scheduleShows.length) {
        return [];
      }

      final result = (await Future.wait(scheduleShows
              .sublist(
        startIndex,
        endIndex > scheduleShows.length ? scheduleShows.length : endIndex,
      )
              .map((show) async {
        try {
          final imdb = _traktIdsToMetaId(
            show['show']['ids'],
          );

          final result = Meta(
            type: "series",
            id: imdb,
          );

          final item = await stremioService!.getItemById(result);

          return patchMetaObjectForShow(
            (item ?? result) as Meta,
            show['episode'],
          ).copyWith(
            progress: null,
          );
        } catch (e) {
          _logger.warning('Error mapping show: $e');
          return null;
        }
      })))
          .whereType<Meta>()
          .toList();

      return result;
    } catch (e, stack) {
      _logger.severe('Error fetching upcoming schedule: $e', stack);
      return [];
    }
  }

  Future<List<LibraryItem>> getWatchlist(
      {int page = 1, int itemsPerPage = 5}) async {
    await initStremioService();

    if (!isEnabled()) {
      _logger.info('Trakt integration is not enabled');
      return [];
    }

    try {
      _logger.info('Fetching watchlist');
      final List<dynamic> watchlistItems =
          await _makeRequest('$_baseUrl/sync/watchlist');
      _logger.info('Got watchlist');

      if (watchlistItems.isEmpty) {
        return [];
      }

      final startIndex =
          ((page - 1) * itemsPerPage).clamp(0, watchlistItems.length - 1);
      final endIndex =
          (startIndex + itemsPerPage).clamp(0, watchlistItems.length - 1);

      if (startIndex >= watchlistItems.length) {
        return [];
      }

      final result = await stremioService!.getBulkItem(
        watchlistItems
            .sublist(
              startIndex,
              endIndex > watchlistItems.length
                  ? watchlistItems.length
                  : endIndex,
            )
            .map((item) {
              try {
                final type = item['type'];
                final imdb = _traktIdsToMetaId(item[type]['ids']);

                if (type == "show") {
                  return Meta(
                    type: "series",
                    id: imdb,
                  );
                }

                return Meta(
                  type: type,
                  id: imdb,
                );
              } catch (e, stack) {
                _logger.warning('Error mapping watchlist item: $e', e, stack);
                return null;
              }
            })
            .whereType<Meta>()
            .toList(),
      );

      return result;
    } catch (e, stack) {
      _logger.severe('Error fetching watchlist: $e', stack);
      return [];
    }
  }

  Future<List<LibraryItem>> getShowRecommendations({
    int page = 1,
    int itemsPerPage = 5,
  }) async {
    await initStremioService();

    if (!isEnabled()) {
      _logger.info('Trakt integration is not enabled');
      return [];
    }

    try {
      _logger.info('Fetching show recommendations');
      final List<dynamic> recommendedShows = await _makeRequest(
        '$_baseUrl/recommendations/shows',
      );

      if (recommendedShows.isEmpty) {
        return [];
      }

      final startIndex =
          ((page - 1) * itemsPerPage).clamp(0, recommendedShows.length - 1);
      final endIndex =
          (startIndex + itemsPerPage).clamp(0, recommendedShows.length - 1);

      if (startIndex >= recommendedShows.length) {
        return [];
      }

      final result = (await stremioService!.getBulkItem(
        recommendedShows
            .sublist(
              startIndex,
              endIndex > recommendedShows.length
                  ? recommendedShows.length
                  : endIndex,
            )
            .map((show) {
              final imdb = _traktIdsToMetaId(show['ids']);

              return Meta(
                type: "series",
                id: imdb,
              );
            })
            .whereType<Meta>()
            .toList(),
      ));

      return result;
    } catch (e, stack) {
      _logger.severe('Error fetching show recommendations: $e', stack);
      return [];
    }
  }

  Future<List<LibraryItem>> getMovieRecommendations({
    int page = 1,
    int itemsPerPage = 5,
  }) async {
    await initStremioService();

    if (!isEnabled()) {
      _logger.info('Trakt integration is not enabled');
      return [];
    }

    try {
      _logger.info('Fetching movie recommendations');
      final List<dynamic> recommendedMovies = await _makeRequest(
        '$_baseUrl/recommendations/movies',
      );

      if (recommendedMovies.isEmpty) {
        return [];
      }

      final startIndex =
          ((page - 1) * itemsPerPage).clamp(0, recommendedMovies.length - 1);
      final endIndex =
          (startIndex + itemsPerPage).clamp(0, recommendedMovies.length - 1);

      if (startIndex >= recommendedMovies.length) {
        return [];
      }

      final result = await stremioService!.getBulkItem(
        recommendedMovies
            .sublist(
              startIndex,
              endIndex > recommendedMovies.length
                  ? recommendedMovies.length
                  : endIndex,
            )
            .map((movie) {
              try {
                final imdb = _traktIdsToMetaId(movie['ids']);
                return Meta(
                  type: "movie",
                  id: imdb,
                );
              } catch (e) {
                _logger.warning('Error mapping movie: $e');
                return null;
              }
            })
            .whereType<Meta>()
            .toList(),
      );

      return result;
    } catch (e, stack) {
      _logger.severe('Error fetching movie recommendations: $e', stack);
      return [];
    }
  }

  List<String> getHomePageContent() {
    final List<String> config = ((AppEngine.engine.pb.authStore.record
                ?.get("config")?["selected_categories"] ??
            []) as List<dynamic>)
        .whereType<String>()
        .toList();

    if (!isEnabled()) {
      _logger.info('Trakt integration is not enabled');
      return [];
    }

    return config;
  }

  static bool isEnabled() {
    return AppEngine.engine.pb.authStore.record!
            .getStringValue("trakt_token") !=
        "";
  }

  Future<int?> getTraktIdForMovie(String imdb) async {
    _logger.info('Fetching Trakt ID for movie with IMDb ID: $imdb');
    final body = await _makeRequest("$_baseUrl/search/imdb/$imdb");

    if (body.isEmpty) {
      _logger.warning('No Trakt ID found for IMDb ID: $imdb');
      return null;
    }

    final firstItem = body.first;

    if (firstItem["type"] == "show") {
      return body[0]['show']['ids']['trakt'];
    }

    if (firstItem["type"] == "movie") {
      return body[0]['movie']['ids']['trakt'];
    }

    return null;
  }

  Future<void> startScrobbling({
    required Meta meta,
    required double progress,
  }) async {
    if (!isEnabled()) {
      _logger.info('Trakt integration is not enabled');
      return;
    }

    try {
      _logger.info('Starting scrobbling for ${meta.type} with ID: ${meta.id}');

      final response = await http.post(
        Uri.parse('$_baseUrl/scrobble/start'),
        headers: headers,
        body: json.encode({
          'progress': progress,
          ..._buildObjectForMeta(meta),
        }),
      );

      if (response.statusCode == 404) {
        _logger.severe('Failed to start scrobbling: ${response.statusCode}');
        _logger.severe("${_buildObjectForMeta(meta)}");
        return;
      }

      if (response.statusCode != 201) {
        _logger.severe('Failed to start scrobbling: ${response.statusCode}');
        throw Exception('Failed to start scrobbling');
      }

      _logger.info('Scrobbling started successfully');
      _cache.remove('$_baseUrl/sync/watched/shows');
      _cache.remove('$_baseUrl/sync/playback');
    } catch (e, stack) {
      _logger.severe('Error starting scrobbling: $e', stack);
      rethrow;
    }
  }

  Future<void> pauseScrobbling({
    required Meta meta,
    required double progress,
  }) async {
    if (!isEnabled()) {
      _logger.info('Trakt integration is not enabled');
      return;
    }

    final cacheKey = '${meta.id}_pauseScrobbling';

    _activeScrobbleRequests[cacheKey]?.completeError('Cancelled');
    _activeScrobbleRequests[cacheKey] = Completer<void>();

    try {
      _logger.info('Pausing scrobbling for ${meta.type} with ID: ${meta.id}');
      await _retryPostRequest(
        cacheKey,
        '$_baseUrl/scrobble/pause',
        {
          'progress': progress,
          ..._buildObjectForMeta(meta),
        },
      );
    } catch (e, stack) {
      _logger.severe('Error pausing scrobbling: $e', stack);
      rethrow;
    } finally {
      _activeScrobbleRequests.remove(cacheKey);
    }
  }

  Future<void> _retryPostRequest(
    String cacheKey,
    String url,
    Map<String, dynamic> body, {
    int retryCount = 2,
  }) async {
    for (int i = 0; i < retryCount; i++) {
      try {
        _logger.info('Making POST request to $url');
        final response = await http.post(
          Uri.parse(url),
          headers: headers,
          body: json.encode(body),
        );

        if (response.statusCode == 404) {
          _logger.warning('could not find episode');
        } else if (response.statusCode == 201) {
          _logger.info('POST request successful');
          return;
        } else if (response.statusCode == 429) {
          _logger.warning('Rate limit hit, retrying...');
          await Future.delayed(
            const Duration(seconds: 10),
          );
          continue;
        } else {
          _logger.severe('Failed to make POST request: ${response.statusCode}');
          throw Exception(
            'Failed to make POST request: ${response.statusCode}',
          );
        }
      } catch (e) {
        if (i == retryCount - 1) {
          _logger
              .severe('Failed to make POST request after $retryCount attempts');
          if (_cache.containsKey(cacheKey)) {
            _logger.info('Returning cached data');
            return _cache[cacheKey];
          }
          rethrow;
        }
      }
    }
  }

  Future<void> stopScrobbling({
    required Meta meta,
    required double progress,
    bool shouldClearCache = false,
    int? traktId,
  }) async {
    if (!isEnabled()) {
      _logger.info('Trakt integration is not enabled');
      return;
    }

    final cacheKey = '${meta.id}_stopScrobbling';

    _activeScrobbleRequests[cacheKey]?.completeError('Cancelled');
    _activeScrobbleRequests[cacheKey] = Completer<void>();

    try {
      _logger.info('Stopping scrobbling for ${meta.type} with ID: ${meta.id}');
      _logger.info(_buildObjectForMeta(meta));
      await _retryPostRequest(
        cacheKey,
        '$_baseUrl/scrobble/stop',
        {
          'progress': progress,
          ..._buildObjectForMeta(meta),
        },
      );

      if (shouldClearCache) {
        _cache.remove('$_baseUrl/sync/watched/shows');
        _cache.remove('$_baseUrl/sync/playback');

        final keys = [
          if (traktId != null) "$_baseUrl/shows/$traktId/progress/watched",
          "continue_watching",
          if (meta.type == "series") "up_next_series",
        ];
        refetchKey.add(keys);

        _logger.info(
          "pushing refetch key ${keys.join(", ")} still in cache ${_cache.keys.join(", ")}",
        );
      }
    } catch (e, stack) {
      _logger.severe('Error stopping scrobbling: $e', stack);
      rethrow;
    } finally {
      _activeScrobbleRequests.remove(cacheKey);
    }
  }

  Future<Meta> getProgress(
    Meta meta, {
    bool bypassCache = true,
  }) async {
    if (!isEnabled()) {
      _logger.info('Trakt integration is not enabled');
      return meta;
    }

    try {
      if (meta.type == "series") {
        final List<dynamic> body = await _makeRequest(
          "$_baseUrl/sync/playback/episodes",
          bypassCache: bypassCache,
        );

        for (final item in body) {
          final isCurrentShow =
              item["show"]?["ids"]?["imdb"] == (meta.imdbId ?? meta.id);

          if (isCurrentShow == false) {
            continue;
          }

          meta.videos = meta.videos ?? [];

          final result = meta.videos?.firstWhereOrNull((video) {
            if (video.tvdbId != null &&
                item['episode']['ids']['tvdb'] != null) {
              return video.tvdbId == item['episode']['ids']['tvdb'];
            }

            return video.season == item['season'] &&
                video.number == item['number'];
          });

          if (result == null) {
            continue;
          }

          final videoIndex = meta.videos!.indexOf(result);

          meta.videos![videoIndex].progress = item['progress'];

          _logger.info(
            "Setting progress for ${meta.videos![videoIndex].name} to ${item['progress']}",
          );
        }
        return meta;
      } else {
        final body = await _makeRequest(
          "$_baseUrl/sync/playback/movies",
          bypassCache: true,
        );

        for (final item in body) {
          if (item["type"] != "movie") {
            continue;
          }

          if (item["movie"]["ids"]["imdb"] == (meta.imdbId ?? meta.id)) {
            return meta.copyWith(
              progress: item["progress"],
            );
          }
        }
      }
    } catch (e) {
      _logger.severe('Error fetching progress: $e');
      return meta;
    }

    return meta;
  }

  Future<List<TraktShowWatched>> getWatchedShowsWithEpisodes(Meta meta) async {
    if (!isEnabled()) {
      _logger.info('Trakt integration is not enabled');
      return [];
    }
    if (meta.type == "series") {
      final watchedShows = await getWatchedShows();
      for (final show in watchedShows) {
        if (show.ids.imdb == meta.imdbId) {
          show.episodes = await _getWatchedEpisodes(show.ids.trakt);
        }
      }
      return watchedShows;
    }
    return [];
  }

  Future<List<TraktShowWatched>> getWatchedShows() async {
    if (!isEnabled()) {
      _logger.info('Trakt integration is not enabled');
      return [];
    }
    try {
      final body = await _makeRequest(
        "$_baseUrl/sync/watched/shows/",
        bypassCache: true,
      );
      final List<TraktShowWatched> result = [];
      for (final item in body) {
        try {
          result.add(
            TraktShowWatched(
              title: item["show"]["title"],
              seasons: item["seasons"],
              ids: TraktIds.fromJson(item["show"]["ids"]),
              lastWatchedAt: item["last_watched_at"] != null
                  ? DateTime.parse(item["last_watched_at"])
                  : null,
              plays: item["plays"],
            ),
          );
        } catch (e, stack) {
          _logger.warning('Error parsing watched show: $e\n$stack item: $item');
        }
      }
      return result;
    } catch (e, stack) {
      _logger.severe('Error fetching watched shows: $e\n$stack');
      return [];
    }
  }

  Future<List<TraktEpisodeWatched>> _getWatchedEpisodes(int? traktId) async {
    if (traktId == null) return [];
    int page = 1;
    const int limit = 1000;
    try {
      final body = await _makeRequest(
        "$_baseUrl/sync/history/shows/$traktId?page=$page&limit=$limit",
        bypassCache: true,
      );
      final List<TraktEpisodeWatched> episodes = [];
      for (final item in body) {
        if (item['episode'] != null) {
          episodes.add(
            TraktEpisodeWatched(
              season: item['episode']['season'],
              episode: item['episode']['number'],
              watchedAt: DateTime.parse(item['watched_at']),
            ),
          );
        }
      }
      return episodes;
    } catch (e, stack) {
      _logger.severe('Error fetching watched episodes: $e\n$stack');
      return [];
    }
  }
}
