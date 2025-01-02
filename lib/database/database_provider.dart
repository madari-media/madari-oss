import 'package:madari_client/database/app_database.dart';

class DatabaseProvider {
  late final AppDatabase database;

  DatabaseProvider() {
    database = AppDatabase();
  }

  Future<void> close() async {
    await database.close();
  }
}
