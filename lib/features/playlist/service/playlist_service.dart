import 'package:pocketbase/pocketbase.dart';

import '../../../engine/engine.dart';
import '../types/playlist.dart';
import '../types/playlist_item.dart';

class PlaylistServiceException implements Exception {
  final String message;
  final dynamic originalError;

  PlaylistServiceException(this.message, [this.originalError]);

  @override
  String toString() => 'PlaylistServiceException: $message';
}

class PlaylistService {
  static const int _itemsPerPage = 20;
  late final PocketBase _pb;

  static PlaylistService? _instance;
  PlaylistService._();

  static void initialize() {
    _instance ??= PlaylistService._();
    _instance!._pb = AppEngine.engine.pb;
  }

  PlaylistService(this._pb);

  static PlaylistService get instance {
    if (_instance == null) {
      throw PlaylistServiceException(
        'PlaylistService not initialized. Call PlaylistService.initialize() first.',
      );
    }
    return _instance!;
  }

  /// Creates a new playlist
  Future<Playlist> createPlaylist(String name) async {
    try {
      final record = await _pb.collection('playlist').create(body: {
        'name': name,
        'user': _pb.authStore.record!.id,
      });

      return Playlist.fromJson(record.toJson());
    } catch (e) {
      throw PlaylistServiceException('Failed to create playlist', e);
    }
  }

  /// Gets items from a playlist with pagination
  Future<List<PlaylistItem>> getItems(String playlistId, {int page = 1}) async {
    try {
      final result = await _pb.collection('playlist_item').getList(
            page: page,
            perPage: _itemsPerPage,
            filter: 'playlist = "$playlistId"',
            sort: '-created',
          );

      return result.items
          .map((record) => PlaylistItem.fromJson(record.toJson()))
          .toList();
    } catch (e) {
      throw PlaylistServiceException('Failed to fetch playlist items', e);
    }
  }

  /// Adds an item to a playlist
  Future<PlaylistItem> addToPlaylist(
    String playlistId,
  ) async {
    try {
      // Verify if the item already exists in the playlist
      final existing = await _pb.collection('playlist_item').getList(
            filter: 'playlist = "$playlistId"',
            page: 1,
            perPage: 1,
          );

      if (existing.items.isNotEmpty) {
        throw PlaylistServiceException('Item already exists in playlist');
      }

      final record = await _pb.collection('playlist_item').create(body: {
        'playlist': playlistId,
      });

      return PlaylistItem.fromJson(record.toJson());
    } catch (e) {
      if (e is PlaylistServiceException) rethrow;
      throw PlaylistServiceException('Failed to add item to playlist', e);
    }
  }

  /// Removes an item from a playlist
  Future<void> removeFromPlaylist(String itemId) async {
    try {
      await _pb.collection('playlist_item').delete(itemId);
    } catch (e) {
      throw PlaylistServiceException('Failed to remove item from playlist', e);
    }
  }

  /// Gets all playlists for a user
  Future<List<Playlist>> getUserPlaylists({int page = 1}) async {
    try {
      final result = await _pb.collection('playlist').getList(
            page: page,
            perPage: _itemsPerPage,
            filter: 'user = "${_pb.authStore.record!.id}"',
            sort: '-created',
          );

      return result.items
          .map((record) => Playlist.fromJson(record.toJson()))
          .toList();
    } catch (e) {
      throw PlaylistServiceException('Failed to fetch user playlists', e);
    }
  }

  /// Deletes a playlist and all its items
  Future<void> deletePlaylist(String playlistId) async {
    try {
      // First, delete all items in the playlist
      final items = await _pb.collection('playlist_item').getList(
            filter: 'playlist = "$playlistId"',
            page: 1,
            perPage: 500, // Use a large number to get all items
          );

      for (final item in items.items) {
        await _pb.collection('playlist_item').delete(item.id);
      }

      // Then delete the playlist itself
      await _pb.collection('playlist').delete(playlistId);
    } catch (e) {
      throw PlaylistServiceException('Failed to delete playlist', e);
    }
  }
}
