import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables/ratings.dart';

part 'db.g.dart';

@DriftDatabase(tables: [RatingTable])
class AppDatabase extends _$AppDatabase {
  AppDatabase._() : super(_openConnection());

  static AppDatabase? _instance;

  factory AppDatabase() {
    _instance ??= AppDatabase._();
    return _instance!;
  }

  Future<double?> getRatingByTConst(String tconst) async {
    try {
      final query = select(ratingTable)
        ..where((tbl) => tbl.tconst.equals(tconst));

      final result = await query.getSingleOrNull();
      return result?.averageRating;
    } catch (e) {
      print('Error fetching IMDb rating: $e');
      return null;
    }
  }

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'app_db',
      web: DriftWebOptions(
        sqlite3Wasm: Uri.parse("wasm"),
        driftWorker: Uri.parse("worker"),
      ),
    );
  }

  @override
  Future<void> close() async {
    try {
      await super.close();
      _instance = null;
    } catch (e) {
      throw Exception('Failed to close database connection: $e');
    }
  }

  static void clearInstance() {
    _instance?.close();
    _instance = null;
  }
}
