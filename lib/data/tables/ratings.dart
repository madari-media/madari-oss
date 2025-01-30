import 'package:drift/drift.dart';

class RatingTable extends Table {
  TextColumn get tconst => text()();
  RealColumn get averageRating => real()();
  IntColumn get numVotes => integer()();

  @override
  Set<Column> get primaryKey => {tconst};
}
