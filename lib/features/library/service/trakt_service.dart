import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

import '../../pocketbase/service/pocketbase.service.dart';
import '../types/library_types.dart';
import 'list_service.dart';

final _logger = Logger('TraktService');

class TraktService {
  static final TraktService instance = TraktService._internal();

  static const _baseUrl = 'https://api.trakt.tv';
  static String get _traktClient {
    final client = "" ?? DotEnv().get("trakt_client_id");

    if (client == "") {
      _logger.warning('Using default Trakt client ID');
      return "b47864365ac88ecc253c3b0bdf1c82a619c1833e8806f702895a7e8cb06b536a";
    }

    return client;
  }

  TraktService._internal();

  String? get _traktToken => AppPocketBaseService.instance.pb.authStore.record
      ?.getStringValue("trakt_token");

  bool get isAuthenticated => _traktToken?.isNotEmpty ?? false;

  Future<List<TraktList>> getLists() async {
    try {
      if (!isAuthenticated) {
        throw Exception('Trakt not authenticated');
      }

      final listsResponse = await http.get(
        Uri.parse('$_baseUrl/users/me/lists'),
        headers: _getHeaders(),
      );

      if (listsResponse.statusCode != 200) {
        throw Exception('Failed to fetch lists: ${listsResponse.statusCode}');
      }

      final List<dynamic> listsData = json.decode(listsResponse.body);
      final List<TraktList> customLists =
          listsData.map((list) => TraktList.fromJson(list)).toList();

      final TraktList watchlist = TraktList(
        id: 'watchlist', // Special ID for watchlist
        name: 'Watchlist',
        description: 'My Watchlist',
        itemCount: 0,
        privacy: 'private',
        displayNumbers: false,
        allowComments: false,
        ids: {},
        lastUpdated: DateTime.now(),
      );

      final TraktList favorites = TraktList(
        id: 'favorites', // Special ID for favorites
        name: 'Favorites',
        description: 'My Favorites',
        itemCount: 0,
        privacy: 'private',
        displayNumbers: false,
        allowComments: false,

        ids: {},
        lastUpdated: DateTime.now(),
      );

      return [
        watchlist,
        favorites,
        ...customLists,
      ];
    } catch (e, stack) {
      _logger.severe('Error fetching Trakt lists', e, stack);
      rethrow;
    }
  }

  Future<TraktList> getList(String listId) async {
    try {
      if (!isAuthenticated) {
        throw Exception('Trakt not authenticated');
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/users/me/lists/$listId'),
        headers: _getHeaders(),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to fetch list: ${response.statusCode}');
      }

      final data = json.decode(response.body);
      return TraktList.fromJson(data);
    } catch (e) {
      _logger.severe('Error fetching Trakt list', e);
      rethrow;
    }
  }

  Future<List<TraktListItem>> getListItems(String listId) async {
    try {
      if (!isAuthenticated) {
        throw Exception('Trakt not authenticated');
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/users/me/lists/$listId/items'),
        headers: _getHeaders(),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to fetch list items: ${response.statusCode}');
      }

      final List<dynamic> data = json.decode(response.body);
      return data.map((item) => TraktListItem.fromJson(item)).toList();
    } catch (e) {
      _logger.severe('Error fetching Trakt list items', e);
      rethrow;
    }
  }

  Future<void> syncList(String listId) async {
    try {
      if (!isAuthenticated) {
        throw Exception('Trakt not authenticated');
      }

      final items = await getListItems(listId);

      for (final item in items) {
        await ListsService.instance.addListItem(
          listId,
          ListItemModel(
            id: '',
            type: item.type,
            imdbId: item.ids['imdb'] ?? '',
            ids: item.ids,
            title: item.title,
            description: item.overview ?? '',
            poster: '', // You'll need to fetch this from TMDB or similar
            rating: item.rating ?? 0.0,
          ),
        );
      }
    } catch (e) {
      _logger.severe('Error syncing Trakt list', e);
      rethrow;
    }
  }

  Map<String, String> _getHeaders() {
    return {
      'Content-Type': 'application/json',
      'trakt-api-version': '2',
      'trakt-api-key': _traktClient,
      'Authorization': 'Bearer $_traktToken',
    };
  }
}

class TraktList {
  final String id;
  final String name;
  final String? description;
  final String privacy;
  final bool displayNumbers;
  final bool allowComments;
  final int itemCount;
  final DateTime lastUpdated;
  final Map<String, dynamic> ids;

  TraktList({
    required this.id,
    required this.name,
    this.description,
    required this.privacy,
    required this.displayNumbers,
    required this.allowComments,
    required this.itemCount,
    required this.lastUpdated,
    required this.ids,
  });

  factory TraktList.fromJson(Map<String, dynamic> json) {
    return TraktList(
      id: json['ids']['trakt'].toString(),
      name: json['name'],
      description: json['description'],
      privacy: json['privacy'],
      displayNumbers: json['display_numbers'],
      allowComments: json['allow_comments'],
      itemCount: json['item_count'],
      lastUpdated: DateTime.parse(json['updated_at']),
      ids: Map<String, dynamic>.from(json['ids']),
    );
  }
}

class TraktListItem {
  final String type;
  final String title;
  final String? overview;
  final double? rating;
  final Map<String, dynamic> ids;

  TraktListItem({
    required this.type,
    required this.title,
    this.overview,
    this.rating,
    required this.ids,
  });

  factory TraktListItem.fromJson(Map<String, dynamic> json) {
    return TraktListItem(
      type: json['type'],
      title: json[json['type']]['title'],
      overview: json[json['type']]['overview'],
      rating: json[json['type']]['rating']?.toDouble(),
      ids: json[json['type']]['ids'],
    );
  }
}
