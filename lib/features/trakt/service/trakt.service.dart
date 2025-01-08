import 'dart:convert';

import 'package:cached_storage/cached_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:pocketbase/pocketbase.dart';

import '../../../engine/connection_type.dart';
import '../../../engine/engine.dart';
import '../../connections/service/base_connection_service.dart';
import '../../connections/types/stremio/stremio_base.types.dart';
import '../../settings/types/connection.dart';

class TraktService {
  static const String _baseUrl = 'https://api.trakt.tv';
  static const String _apiVersion = '2';

  static TraktService? _instance;
  static TraktService? get instance => _instance;
  static BaseConnectionService? stremioService;

  static ensureInitialized() async {
    if (_instance != null) {
      return _instance;
    }

    final traktService = TraktService();
    await traktService.initStremioService();
    _instance = traktService;
  }

  Future<BaseConnectionService> initStremioService() async {
    if (stremioService != null) {
      return stremioService!;
    }

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
      return "b47864365ac88ecc253c3b0bdf1c82a619c1833e8806f702895a7e8cb06b536a";
    }

    return client;
  }

  get _token {
    return AppEngine.engine.pb.authStore.record!.getStringValue("trakt_token");
  }

  Map<String, String> get headers => {
        'Content-Type': 'application/json',
        'Accept-Content': 'application/json',
        'trakt-api-version': _apiVersion,
        'trakt-api-key': _traktClient,
        'Authorization': 'Bearer $_token',
      };

  Future<List<LibraryItem>> getUpNextSeries() async {
    await initStremioService();

    if (!isEnabled()) {
      return [];
    }

    try {
      final watchedResponse = await http.get(
        Uri.parse('$_baseUrl/sync/watched/shows'),
        headers: headers,
      );

      if (watchedResponse.statusCode != 200) {
        throw ArgumentError('Failed to fetch watched shows');
      }

      final watchedShows = json.decode(watchedResponse.body) as List;

      final progressFutures = watchedShows.map((show) async {
        final showId = show['show']['ids']['trakt'];
        final imdb = show['show']['ids']['imdb'];

        try {
          final progressResponse = await http.get(
            Uri.parse('$_baseUrl/shows/$showId/progress/watched'),
            headers: headers,
          );

          if (progressResponse.statusCode != 200) {
            return null;
          }

          final progress = json.decode(progressResponse.body);

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
          print('Error fetching progress for show $showId: $e');
          return null;
        }

        return null;
      }).toList();

      final results = await Future.wait(progressFutures);

      return results.whereType<Meta>().toList();
    } catch (e, stack) {
      print('Error fetching up next episodes: $e');
      print(stack);
      return [];
    }
  }

  Future<List<LibraryItem>> getContinueWatching() async {
    await initStremioService();

    if (!isEnabled()) {
      return [];
    }

    try {
      final watchedResponse = await http.get(
        Uri.parse('$_baseUrl/sync/playback'),
        headers: headers,
      );

      if (watchedResponse.statusCode != 200) {
        throw Exception('Failed to fetch watched movies');
      }

      final continueWatching = json.decode(watchedResponse.body) as List;

      final Map<String, double> progress = {};

      final result = await stremioService!.getBulkItem(
        continueWatching.map((movie) {
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
        }).toList(),
      );

      return result.sublist(0, 20).map((res) {
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
      print('Error fetching up next movies: $e');
      print(stack);
      return [];
    }
  }

  Future<List<LibraryItem>> getUpcomingSchedule() async {
    await initStremioService();

    if (!isEnabled()) {
      return [];
    }

    try {
      final scheduleResponse = await http.get(
        Uri.parse(
          '$_baseUrl/calendars/my/shows/${DateFormat('yyyy-MM-dd').format(DateTime.now())}/7',
        ),
        headers: headers,
      );

      if (scheduleResponse.statusCode != 200) {
        print(scheduleResponse.body);
        print(scheduleResponse.statusCode);
        print('Failed to fetch upcoming schedule');
        throw Error();
      }

      final scheduleShows = json.decode(scheduleResponse.body) as List;

      final result = await stremioService!.getBulkItem(
        scheduleShows.map((show) {
          final imdb = show['show']['ids']['imdb'];
          return Meta(
            type: "series",
            id: imdb,
          );
        }).toList(),
      );

      return result;
    } catch (e, stack) {
      print('Error fetching upcoming schedule: $e');
      print(stack);
      return [];
    }
  }

  Future<List<LibraryItem>> getWatchlist() async {
    await initStremioService();

    if (!isEnabled()) {
      return [];
    }

    try {
      final watchlistResponse = await http.get(
        Uri.parse('$_baseUrl/sync/watchlist'),
        headers: headers,
      );

      if (watchlistResponse.statusCode != 200) {
        throw Exception('Failed to fetch watchlist');
      }

      final watchlistItems = json.decode(watchlistResponse.body) as List;

      final result = await stremioService!.getBulkItem(
        watchlistItems.map((item) {
          final type = item['type'];
          final imdb = item[type]['ids']['imdb'];
          return Meta(
            type: type,
            id: imdb,
          );
        }).toList(),
      );

      return result;
    } catch (e, stack) {
      print('Error fetching watchlist: $e');
      print(stack);
      return [];
    }
  }

  Future<List<LibraryItem>> getShowRecommendations() async {
    await initStremioService();

    if (!isEnabled()) {
      return [];
    }

    try {
      final recommendationsResponse = await http.get(
        Uri.parse('$_baseUrl/recommendations/shows'),
        headers: headers,
      );

      if (recommendationsResponse.statusCode != 200) {
        throw Exception('Failed to fetch show recommendations');
      }

      final recommendedShows =
          json.decode(recommendationsResponse.body) as List;

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
      print('Error fetching show recommendations: $e');
      print(stack);
      return [];
    }
  }

  Future<List<LibraryItem>> getMovieRecommendations() async {
    await initStremioService();

    if (!isEnabled()) {
      return [];
    }

    try {
      final recommendationsResponse = await http.get(
        Uri.parse('$_baseUrl/recommendations/movies'),
        headers: headers,
      );

      if (recommendationsResponse.statusCode != 200) {
        throw Exception('Failed to fetch movie recommendations');
      }

      final recommendedMovies =
          json.decode(recommendationsResponse.body) as List;

      final result = await stremioService!.getBulkItem(
        recommendedMovies.map((movie) {
          final imdb = movie['ids']['imdb'];
          return Meta(
            type: "movie",
            id: imdb,
          );
        }).toList(),
      );

      return result;
    } catch (e, stack) {
      print('Error fetching movie recommendations: $e');
      print(stack);
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
    final id = await http.get(
      Uri.parse("$_baseUrl/search/imdb/$imdb"),
      headers: headers,
    );

    if (id.statusCode != 200) {
      throw ArgumentError("failed to get trakt id");
    }

    final body = jsonDecode(id.body) as List<dynamic>;

    if (body.isEmpty) {
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
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/scrobble/start'),
        headers: headers,
        body: json.encode({
          'progress': progress,
          ..._buildObjectForMeta(meta),
        }),
      );

      if (response.statusCode != 201) {
        print(response.statusCode);
        print(response.body);
        throw Exception('Failed to start scrobbling');
      }
    } catch (e, stack) {
      print('Error starting scrobbling: $e');
      print(stack);
      rethrow;
    }
  }

  Future<void> pauseScrobbling({
    required Meta meta,
    required double progress,
  }) async {
    if (!isEnabled()) {
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/scrobble/pause'),
        headers: headers,
        body: json.encode({
          'progress': progress,
          ..._buildObjectForMeta(meta),
        }),
      );

      if (response.statusCode != 201) {
        print(response.statusCode);
        throw Exception('Failed to pause scrobbling');
      }
    } catch (e, stack) {
      print('Error pausing scrobbling: $e');
      print(stack);
      rethrow;
    }
  }

  Map<String, dynamic> _buildObjectForMeta(Meta meta) {
    if (meta.type == "movie") {
      return {
        'movie': {
          'title': meta.name,
          'year': meta.year,
          'ids': {
            'imdb': meta.imdbId ?? meta.id,
          },
        },
      };
    } else {
      if (meta.nextEpisode == null && meta.nextSeason == null) {
        throw ArgumentError("");
      }

      return {
        "show": {
          "title": meta.name,
          "year": meta.year,
          "ids": {
            "imdb": meta.imdbId ?? meta.id,
          }
        },
        "episode": {
          "season": meta.nextSeason,
          "number": meta.nextEpisode,
        },
      };
    }
  }

  Future<void> stopScrobbling({
    required Meta meta,
    required double progress,
  }) async {
    if (!isEnabled()) {
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/scrobble/stop'),
        headers: headers,
        body: json.encode({
          'progress': progress,
          ..._buildObjectForMeta(meta),
        }),
      );

      if (response.statusCode != 201) {
        print(response.statusCode);
        throw Exception('Failed to stop scrobbling');
      }
    } catch (e, stack) {
      print('Error stopping scrobbling: $e');
      print(stack);
      rethrow;
    }
  }

  Future<List<TraktProgress>> getProgress(Meta meta) async {
    if (!isEnabled()) {
      return [];
    }

    if (meta.type == "series") {
      final response = await http.get(
        Uri.parse("$_baseUrl/sync/playback/episodes"),
        headers: headers,
      );

      if (response.statusCode != 200) {
        return [];
      }

      final body = jsonDecode(response.body) as List;

      final List<TraktProgress> result = [];

      for (final item in body) {
        if (item["type"] != "episode") {
          continue;
        }

        final isShow = item["show"]["ids"]["imdb"] == (meta.imdbId ?? meta.id);

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
      final response = await http.get(
        Uri.parse("$_baseUrl/sync/playback/movies"),
        headers: headers,
      );

      if (response.statusCode != 200) {
        return [];
      }

      final body = jsonDecode(response.body) as List;

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
