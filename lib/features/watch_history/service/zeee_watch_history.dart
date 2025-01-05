import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:madari_client/engine/engine.dart';
import 'package:madari_client/features/watch_history/service/base_watch_history.dart';
import 'package:pocketbase/src/auth_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../database/app_database.dart';

String calculateSha1(String input) {
  // Convert the input string to UTF-8 bytes
  List<int> bytes = utf8.encode(input);

  // Create a SHA-256 digest
  Digest digest = sha1.convert(bytes);

  // Convert the digest to a hexadecimal string
  return digest.toString();
}

class ZeeeWatchHistoryStatic {
  static ZeeeWatchHistory? service;
}

class ZeeeWatchHistory extends BaseWatchHistory {
  final http = AppEngine.engine.pb.httpClientFactory();
  Timer? _syncTimer;
  static const _lastSyncTimeKey = 'watch_history_last_sync_time';
  final _prefs = SharedPreferences.getInstance();

  late final StreamSubscription<AuthStoreEvent> _listener;

  Future clear() async {
    (await _prefs).remove(_lastSyncTimeKey);
  }

  ZeeeWatchHistory() {
    _listener = AppEngine.engine.pb.authStore.onChange.listen((auth) {
      if (!AppEngine.engine.pb.authStore.isValid) {
        return;
      }

      _initializeFromServer().then((docs) {
        if (_syncTimer != null) {
          _syncTimer!.cancel();
        }
        // Start periodic sync
        _syncTimer = Timer.periodic(
          const Duration(
            seconds: 60,
          ),
          (_) => _syncWithServer(),
        );
      });
    });
  }

  Future<void> _initializeFromServer() async {
    if (!AppEngine.engine.pb.authStore.isValid) {
      return;
    }

    final db = AppEngine.engine.database;
    final collection = AppEngine.engine.pb.collection("watch_history");

    try {
      final lastSyncTime = (await _prefs).getString(_lastSyncTimeKey);
      DateTime? lastSync;
      if (lastSyncTime != null) {
        lastSync = DateTime.tryParse(lastSyncTime);
      }

      int page = 1;
      const perPage = 50;
      bool hasMore = true;
      final filter = lastSync != null
          ? 'user = "${AppEngine.engine.pb.authStore.record!.id}" && updated >= "${lastSync.toIso8601String()}"'
          : 'user = "${AppEngine.engine.pb.authStore.record!.id}"';

      while (hasMore) {
        final records = await collection.getList(
          page: page,
          perPage: perPage,
          filter: filter,
          sort: '-updated', // Changed to sort by most recent first
        );

        if (records.items.isEmpty) {
          break;
        }

        for (final record in records.items) {
          // Check if local record exists and compare timestamps
          final localRecord = await db.watchHistoryQueries
              .getWatchHistoryById(record.data['id']);
          final serverUpdatedAt = DateTime.parse(record.updated);

          if (localRecord == null ||
              (localRecord.updatedAt.isBefore(serverUpdatedAt) &&
                  (localRecord.lastSyncedAt == null ||
                      localRecord.lastSyncedAt!.isBefore(serverUpdatedAt)))) {
            await db.watchHistoryQueries.insertOrUpdateWatchHistory(
              WatchHistoryTableCompanion.insert(
                id: record.data['id'],
                originalId: record.data['originalId'],
                progress: Value(record.data['progress']),
                duration: Value(
                  record.data['duration'] is double
                      ? record.data['duration']
                      : (record.data['duration'] as int).toDouble(),
                ),
                season: Value(record.data['season']),
                episode: Value(record.data['episode']),
                updatedAt: serverUpdatedAt,
                lastSyncedAt: Value(DateTime.now()),
              ),
            );
          }
        }

        hasMore = records.items.length >= perPage;
        page++;
      }

      // Update last sync time
      await (await _prefs).setString(
        _lastSyncTimeKey,
        DateTime.now().toIso8601String(),
      );
    } catch (e, stack) {
      print('Failed to initialize watch history from server: $e');
      print(stack);
    }
  }

  @override
  Future<List<WatchHistory>> getItemWatchHistory({
    required List<WatchHistoryGetRequest> ids,
  }) async {
    final db = AppEngine.engine.database;

    final idsMapped = ids.map((item) {
      final ids =
          "${Uri.encodeComponent(item.id)}:${Uri.encodeComponent(item.season ?? "")}:${Uri.encodeComponent(item.episode ?? "")}";
      return [item, calculateSha1(ids)];
    }).toList();

    final records = await db.watchHistoryQueries.getWatchHistoryByIds(
      idsMapped.map((item) => item[1] as String).toList(),
    );

    return records.map((record) {
      final history = WatchHistory(
        id: record.originalId,
        progress: record.progress,
        duration: record.duration,
        season: record.season,
        episode: record.episode,
      );
      return history;
    }).toList();
  }

  @override
  Future<void> saveWatchHistory({
    required WatchHistory history,
  }) async {
    final db = AppEngine.engine.database;
    final ids =
        "${Uri.encodeComponent(history.id)}:${Uri.encodeComponent(history.season ?? "")}:${Uri.encodeComponent(history.episode ?? "")}";
    final documentId = calculateSha1(ids);

    await db.watchHistoryQueries.insertOrUpdateWatchHistory(
      WatchHistoryTableCompanion.insert(
        id: documentId,
        originalId: history.id,
        progress: Value(history.progress),
        duration: Value(history.duration),
        season: Value(history.season),
        episode: Value(history.episode),
        updatedAt: DateTime.now(),
      ),
    );
  }

  Future<void> _syncWithServer() async {
    final db = AppEngine.engine.database;
    if (!AppEngine.engine.pb.authStore.isValid) {
      return;
    }

    final unsynced = await db.watchHistoryQueries.getUnsyncedRecords();
    final collection = AppEngine.engine.pb.collection("watch_history");

    for (final record in unsynced) {
      try {
        // Check server record before updating
        try {
          final serverRecord = await collection.getOne(record.id);
          final serverUpdatedAt =
              DateTime.parse(serverRecord.get<String>('updated'));

          // Skip if server has newer data
          if (record.updatedAt.isBefore(serverUpdatedAt)) {
            await db.watchHistoryQueries.updateSyncStatus(
              record.id,
              DateTime.now(),
            );
            continue;
          }
        } catch (e) {
          // Record doesn't exist on server, will create new
        }

        if (record.lastSyncedAt == null) {
          await collection.create(
            body: {
              'id': record.id,
              'originalId': record.originalId,
              'progress': record.progress,
              'duration': record.duration,
              'season': record.season,
              'episode': record.episode,
              'user': AppEngine.engine.pb.authStore.record!.id,
              'updated': record.updatedAt.toIso8601String(),
            },
          );
        } else {
          await collection.update(
            record.id,
            body: {
              'progress': record.progress,
              'duration': record.duration,
              'updated': record.updatedAt.toIso8601String(),
            },
          );
        }

        await db.watchHistoryQueries.updateSyncStatus(
          record.id,
          DateTime.now(),
        );
      } catch (e, stack) {
        print('Failed to sync record ${record.id}: $e');
        print(stack);
      }
    }
  }

  void dispose() {
    _syncTimer?.cancel();
    _listener.cancel();
  }
}
