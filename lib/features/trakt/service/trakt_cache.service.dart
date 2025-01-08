import 'package:madari_client/features/trakt/service/trakt.service.dart';

import '../../connections/service/base_connection_service.dart';

class TraktCacheService {
  static final TraktCacheService _instance = TraktCacheService._internal();
  factory TraktCacheService() => _instance;
  TraktCacheService._internal();

  final Map<String, List<LibraryItem>> _cache = {};
  final Map<String, bool> _isLoading = {};
  final Map<String, String?> _errors = {};

  Future<List<LibraryItem>> fetchData(String loadId) async {
    if (_cache.containsKey(loadId)) {
      return _cache[loadId]!;
    }

    _isLoading[loadId] = true;
    _errors[loadId] = null;

    try {
      final data = await _fetchFromTrakt(loadId);
      _cache[loadId] = data;
      return data;
    } catch (e) {
      _errors[loadId] = e.toString();
      rethrow;
    } finally {
      _isLoading[loadId] = false;
    }
  }

  Future<void> refresh(String loadId) async {
    _cache.remove(loadId);
    _errors.remove(loadId);
    await fetchData(loadId);
  }

  List<LibraryItem>? getCachedData(String loadId) => _cache[loadId];

  bool isLoading(String loadId) => _isLoading[loadId] ?? false;

  String? getError(String loadId) => _errors[loadId];

  Future<List<LibraryItem>> _fetchFromTrakt(String loadId) async {
    switch (loadId) {
      case "up_next":
      case "up_next_series":
        return TraktService.instance!.getUpNextSeries();
      case "continue_watching":
        return TraktService.instance!.getContinueWatching();
      case "upcoming_schedule":
        return TraktService.instance!.getUpcomingSchedule();
      case "watchlist":
        return TraktService.instance!.getWatchlist();
      case "show_recommendations":
        return TraktService.instance!.getShowRecommendations();
      case "movie_recommendations":
        return TraktService.instance!.getMovieRecommendations();
      default:
        throw Exception("Invalid loadId: $loadId");
    }
  }
}
