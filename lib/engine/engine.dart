import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http_client;
import 'package:pocketbase/pocketbase.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../database/app_database.dart';
import '../database/database_provider.dart';

class AppEngine {
  static late AppEngine _instance;
  late final DatabaseProvider _databaseProvider;

  static Future<void> ensureInitialized() async {
    final prefs = await SharedPreferences.getInstance();

    final store = AsyncAuthStore(
      save: (String data) async => prefs.setString('pb_auth', data),
      initial: prefs.getString('pb_auth'),
      clear: prefs.clear,
    );

    _instance = AppEngine(store);
  }

  static AppEngine get engine => _instance;

  late final PocketBase pb;
  late final http_client.Client http;

  AppDatabase get database => _databaseProvider.database;

  Future<void> dispose() async {
    await _databaseProvider.close();
  }

  AppEngine(AuthStore authStore) {
    pb = PocketBase(
      // 'https://zeee.fly.dev' ??
      (kDebugMode ? 'http://100.64.0.1:8090' : 'https://zeee.fly.dev'),
      authStore: authStore,
    );
    _databaseProvider = DatabaseProvider();
    http = pb.httpClientFactory();
  }

  Future<RecordAuth> signIn(String username, String password) {
    return pb.collection('users').authWithPassword(username, password);
  }
}
