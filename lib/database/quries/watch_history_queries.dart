import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/watch_history_table.dart';

part 'watch_history_queries.g.dart';

@DriftAccessor(tables: [WatchHistoryTable])
class WatchHistoryQueries extends DatabaseAccessor<AppDatabase>
    with _$WatchHistoryQueriesMixin {
  WatchHistoryQueries(super.db);

  Future<List<WatchHistoryTableData>> getWatchHistoryByIds(List<String> ids) {
    return (select(watchHistoryTable)..where((t) => t.id.isIn(ids))).get();
  }

  Future<List<WatchHistoryTableData>> getUnsyncedRecords() {
    return (select(watchHistoryTable)
          ..where((t) =>
              t.lastSyncedAt.isNull() |
              t.updatedAt.isBiggerThan(t.lastSyncedAt)))
        .get();
  }

  Future<void> insertOrUpdateWatchHistory(WatchHistoryTableCompanion entry) {
    return into(watchHistoryTable).insertOnConflictUpdate(entry);
  }

  Future<void> updateSyncStatus(String id, DateTime syncTime) {
    return (update(watchHistoryTable)..where((t) => t.id.equals(id)))
        .write(WatchHistoryTableCompanion(lastSyncedAt: Value(syncTime)));
  }

  Future<WatchHistoryTableData?> getWatchHistoryById(String id) {
    return (select(watchHistoryTable)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<void> clearWatchHistory() async {
    await delete(watchHistoryTable).go();
  }
}
