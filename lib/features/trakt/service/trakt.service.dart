import 'dart:async';
import 'dart:convert';

import 'package:cached_query/cached_query.dart';
import 'package:cached_storage/cached_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:pocketbase/pocketbase.dart';

import '../../../engine/connection_type.dart';
import '../../../engine/engine.dart';
import '../../connections/service/base_connection_service.dart';
import '../../connections/types/stremio/stremio_base.types.dart';
import '../../settings/types/connection.dart';

class TraktService {
  static final Logger _logger = Logger('TraktService');

  static const String _baseUrl = 'https://api.trakt.tv';
  static const String _apiVersion = '2';

  static const int _authedPostLimit = 100;
  static const int _authedGetLimit = 1000;
  static const Duration _rateLimitWindow = Duration(minutes: 5);

  static const Duration _cacheRevalidationInterval = Duration(
    hours: 1,
  );

  static TraktService? _instance;
  static TraktService? get instance => _instance;
  static BaseConnectionService? stremioService;

  int _postRequestCount = 0;
  int _getRequestCount = 0;
  DateTime _lastRateLimitReset = DateTime.now();

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

  Timer? _cacheRevalidationTimer;

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

    final result = await CachedQuery.instance.storage?.get(
      "trakt_integration_cache",
    );

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

    // Start cache revalidation timer
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
        'Accept-Content': 'application/json',
        'trakt-api-version': _apiVersion,
        'trakt-api-key': _traktClient,
        'Authorization': 'Bearer $_token',
      };

  Future<void> _checkRateLimit(String method) async {
    final now = DateTime.now();
    if (now.difference(_lastRateLimitReset) > _rateLimitWindow) {
      _postRequestCount = 0;
      _getRequestCount = 0;
      _lastRateLimitReset = now;
    }

    if (method == 'GET') {
      if (_getRequestCount >= _authedGetLimit) {
        _logger.severe('GET rate limit exceeded');
        throw Exception('GET rate limit exceeded');
      }
      _getRequestCount++;
    } else if (method == 'POST' || method == 'PUT' || method == 'DELETE') {
      if (_postRequestCount >= _authedPostLimit) {
        _logger.severe('POST/PUT/DELETE rate limit exceeded');
        throw Exception('POST/PUT/DELETE rate limit exceeded');
      }
      _postRequestCount++;
    }
  }

  void _startCacheRevalidation() {
    _logger.info('Starting cache revalidation timer');
    _cacheRevalidationTimer = Timer.periodic(
      _cacheRevalidationInterval,
      (_) async {
        await _revalidateCache();
      },
    );
  }

  Future<void> _revalidateCache() async {
    _logger.info('Revalidating cache');
    for (final key in _cache.keys) {
      final cachedData = _cache[key];
      if (cachedData != null) {
        final updatedData = await _makeRequest(key, bypassCache: true);
        _cache[key] = updatedData;
      }
    }

    saveCacheToDisk();
  }

  Future<dynamic> _makeRequest(String url, {bool bypassCache = false}) async {
    if (!bypassCache && _cache.containsKey(url)) {
      _logger.fine('Returning cached data for $url');
      return _cache[url];
    }

    await _checkRateLimit('GET');

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
            ...(meta.externalIds ?? {}),
          },
        },
      };
    } else {
      return {
        "show": {
          "title": meta.name,
          "year": meta.year,
          "ids": {
            "imdb": meta.imdbId ?? meta.id,
            ...(meta.externalIds ?? {}),
          }
        },
        "episode": {
          "season": meta.nextSeason,
          "number": meta.nextEpisode,
        },
      };
    }
  }

  Future<List<LibraryItem>> getUpNextSeries() async {
    await initStremioService();

    if (!isEnabled()) {
      _logger.info('Trakt integration is not enabled');
      return [];
    }

    try {
      _logger.info('Fetching up next series');
      final List<dynamic> watchedShows = await _makeRequest(
        '$_baseUrl/sync/watched/shows',
      );

      final progressFutures = watchedShows.map((show) async {
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
                externalIds: show['show']['ids'],
              ),
            );

            item as Meta;

            return item.copyWith(
              nextEpisode: nextEpisode['number'],
              nextSeason: nextEpisode['season'],
              nextEpisodeTitle: nextEpisode['title'],
            );
          }
        } catch (e) {
          _logger.severe('Error fetching progress for show $showId: $e');
          return null;
        }

        return null;
      }).toList();

      final results = await Future.wait(progressFutures);

      return results.whereType<Meta>().toList();
    } catch (e, stack) {
      _logger.severe('Error fetching up next episodes: $e', stack);
      return [];
    }
  }

  Future<List<LibraryItem>> getContinueWatching() async {
    await initStremioService();

    if (!isEnabled()) {
      _logger.info('Trakt integration is not enabled');
      return [];
    }

    try {
      _logger.info('Fetching continue watching');
      final continueWatching = await _makeRequest('$_baseUrl/sync/playback');

      final Map<String, double> progress = {};

      final result = await stremioService!.getBulkItem(
        continueWatching
            .map((movie) {
              try {
                if (movie['type'] == 'episode') {
                  progress[movie['show']['ids']['imdb']] = movie['progress'];

                  return Meta(
                    type: "series",
                    id: movie['show']['ids']['imdb'],
                    progress: movie['progress'],
                    nextSeason: movie['episode']['season'],
                    nextEpisode: movie['episode']['number'],
                    nextEpisodeTitle: movie['episode']['title'],
                  );
                }

                final imdb = movie['movie']['ids']['imdb'];
                progress[imdb] = movie['progress'];

                return Meta(
                  type: "movie",
                  id: imdb,
                  progress: movie['progress'],
                );
              } catch (e) {
                _logger.warning('Error mapping movie: $e');
                return null;
              }
            })
            .whereType<Meta>()
            .toList(),
      );

      return result.map((res) {
        Meta returnValue = res as Meta;

        if (progress.containsKey(res.id)) {
          returnValue = res.copyWith(
            progress: progress[res.id],
          );
        }

        if (res.type == "series") {
          return returnValue.copyWith();
        }

        return returnValue;
      }).toList();
    } catch (e, stack) {
      _logger.severe('Error fetching continue watching: $e', stack);
      return [];
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
        await _checkRateLimit('POST');

        _logger.info('Making POST request to $url');
        final response = await http.post(
          Uri.parse(url),
          headers: headers,
          body: json.encode(body),
        );

        if (response.statusCode == 201) {
          _logger.info('POST request successful');
          return;
        } else if (response.statusCode == 429) {
          _logger.warning('Rate limit hit, retrying...');
          await Future.delayed(Duration(seconds: 10));
          continue;
        } else {
          _logger.severe('Failed to make POST request: ${response.statusCode}');
          throw Exception(
              'Failed to make POST request: ${response.statusCode}');
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

  Future<List<LibraryItem>> getUpcomingSchedule() async {
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

      final result = await stremioService!.getBulkItem(
        scheduleShows
            .map((show) {
              try {
                final imdb = show['show']['ids']['imdb'];
                return Meta(
                  type: "series",
                  id: imdb,
                );
              } catch (e) {
                _logger.warning('Error mapping show: $e');
                return null;
              }
            })
            .whereType<Meta>()
            .toList(),
      );

      return result;
    } catch (e, stack) {
      _logger.severe('Error fetching upcoming schedule: $e', stack);
      return [];
    }
  }

  Future<List<LibraryItem>> getWatchlist() async {
    await initStremioService();

    if (!isEnabled()) {
      _logger.info('Trakt integration is not enabled');
      return [];
    }

    try {
      _logger.info('Fetching watchlist');
      final watchlistItems = await _makeRequest('$_baseUrl/sync/watchlist');

      final result = await stremioService!.getBulkItem(
        watchlistItems
            .map((item) {
              try {
                final type = item['type'];
                final imdb = item[type]['ids']['imdb'];

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
              } catch (e) {
                _logger.warning('Error mapping watchlist item: $e');
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

  Future<List<LibraryItem>> getShowRecommendations() async {
    await initStremioService();

    if (!isEnabled()) {
      _logger.info('Trakt integration is not enabled');
      return [];
    }

    try {
      _logger.info('Fetching show recommendations');
      final recommendedShows =
          await _makeRequest('$_baseUrl/recommendations/shows');

      final result = (await stremioService!.getBulkItem(
        recommendedShows
            .map((show) {
              final imdb = show['ids']?['imdb'];

              if (imdb == null) {
                return null;
              }

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

  Future<List<LibraryItem>> getMovieRecommendations() async {
    await initStremioService();

    if (!isEnabled()) {
      _logger.info('Trakt integration is not enabled');
      return [];
    }

    try {
      _logger.info('Fetching movie recommendations');
      final recommendedMovies =
          await _makeRequest('$_baseUrl/recommendations/movies');

      final result = await stremioService!.getBulkItem(
        recommendedMovies
            .map((movie) {
              try {
                final imdb = movie['ids']['imdb'];
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

  bool isEnabled() {
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

    await _checkRateLimit('POST');

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

  Future<void> stopScrobbling({
    required Meta meta,
    required double progress,
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
      await _retryPostRequest(
        cacheKey,
        '$_baseUrl/scrobble/stop',
        {
          'progress': progress,
          ..._buildObjectForMeta(meta),
        },
      );

      _cache.remove('$_baseUrl/sync/watched/shows');
      _cache.remove('$_baseUrl/sync/playback');
    } catch (e, stack) {
      _logger.severe('Error stopping scrobbling: $e', stack);
      rethrow;
    } finally {
      _activeScrobbleRequests.remove(cacheKey);
    }
  }

  Future<List<TraktProgress>> getProgress(Meta meta) async {
    if (!isEnabled()) {
      _logger.info('Trakt integration is not enabled');
      return [];
    }

    try {
      if (meta.type == "series") {
        final body = await _makeRequest("$_baseUrl/sync/playback/episodes");

        final List<TraktProgress> result = [];

        for (final item in body) {
          if (item["type"] != "episode") {
            continue;
          }

          final isShow =
              item["show"]["ids"]["imdb"] == (meta.imdbId ?? meta.id);

          final currentEpisode = item["episode"]["number"];
          final currentSeason = item["episode"]["season"];

          if (isShow && meta.nextEpisode != null && meta.nextSeason != null) {
            if (meta.nextSeason == currentSeason &&
                meta.nextEpisode == currentEpisode) {
              result.add(
                TraktProgress(
                  id: meta.id,
                  progress: item["progress"]!,
                  episode: currentEpisode,
                  season: currentSeason,
                ),
              );
            }
          } else if (isShow) {
            result.add(
              TraktProgress(
                id: meta.id,
                progress: item["progress"]!,
                episode: currentEpisode,
                season: currentSeason,
              ),
            );
          }
        }

        return result;
      } else {
        final body = await _makeRequest("$_baseUrl/sync/playback/movies");

        for (final item in body) {
          if (item["type"] != "movie") {
            continue;
          }

          if (item["movie"]["ids"]["imdb"] == (meta.imdbId ?? meta.id)) {
            return [
              TraktProgress(
                id: item["movie"]["ids"]["imdb"],
                progress: item["progress"],
              ),
            ];
          }
        }
      }
    } catch (e) {
      _logger.severe('Error fetching progress: $e');
      return [];
    }

    return [];
  }
}

class TraktProgress {
  final String id;
  final int? episode;
  final int? season;
  final double progress;

  TraktProgress({
    required this.id,
    this.episode,
    this.season,
    required this.progress,
  });
}

extension StaticInstance on CachedStorage {}
