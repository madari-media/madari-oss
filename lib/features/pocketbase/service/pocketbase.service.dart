import 'package:flutter/foundation.dart';
import 'package:madari_engine/madari_engine.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppPocketBaseService {
  AppPocketBaseService._();

  static AppPocketBaseService? _instance;

  late final PocketBase pb;
  late final MadariEngine engine;

  static AppPocketBaseService get instance {
    if (_instance == null) {
      throw StateError(
          'AppPocketBaseService not initialized. Call ensureInitialized() first.');
    }
    return _instance!;
  }

  static Future<void> ensureInitialized() async {
    if (_instance != null) return;

    final prefs = await SharedPreferences.getInstance();

    final store = AsyncAuthStore(
      save: (String data) async => prefs.setString('pb_auth', data),
      initial: prefs.getString('pb_auth'),
      clear: prefs.clear,
    );

    _instance = AppPocketBaseService._();
    await _instance!._initialize(store);
  }

  Future<void> _initialize(AuthStore authStore) async {
    pb = PocketBase(
      kDebugMode ? 'http://100.64.0.1:8090' : 'https://api-v2.madari.media',
      authStore: authStore,
    );
    engine = MadariEngine(pb: pb);
  }
}
