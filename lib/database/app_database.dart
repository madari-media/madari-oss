import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:madari_client/database/quries/watch_history_queries.dart';
import 'package:madari_client/database/tables/watch_history_table.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [
  WatchHistoryTable,
], queries: {}, daos: [
  WatchHistoryQueries,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'madari_db',
      web: DriftWebOptions(
        sqlite3Wasm: Uri.parse('sqlite3.wasm'),
        driftWorker: Uri.parse('assets/assets/drift_worker.dart.js'),
      ),
    );
  }
}
