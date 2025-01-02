import 'package:drift/drift.dart';

class WatchHistoryTable extends Table {
  TextColumn get id => text()();
  TextColumn get originalId => text()();
  TextColumn get season => text().nullable()();
  TextColumn get episode => text().nullable()();
  IntColumn get progress => integer().withDefault(const Constant(0))();
  RealColumn get duration => real().withDefault(const Constant(0))();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get lastSyncedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
