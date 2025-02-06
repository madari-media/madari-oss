import 'package:cached_query_flutter/cached_query_flutter.dart';
import 'package:cached_storage/cached_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:madari_client/features/settings/service/selected_profile.dart';
import 'package:media_kit/media_kit.dart';
import 'package:universal_platform/universal_platform.dart';
import 'package:window_manager/window_manager.dart';

import '../../pocketbase/service/pocketbase.service.dart';
import '../../theme/theme/app_theme.dart';
import '../../widgetter/plugin_base.dart';
import '../../widgetter/plugins/stremio/stremio_plugin.dart';

final _logger = Logger('StartupApp');

Future startupApp() async {
  MediaKit.ensureInitialized();

  await AppPocketBaseService.ensureInitialized();
  await AppTheme().ensureInitialized();
  await SelectedProfileService.instance.initialize();

  final pb = AppPocketBaseService.instance.pb;
  final userCollection = pb.collection("users");

  if (pb.authStore.isValid) {
    try {
      final user = await userCollection.authRefresh();

      pb.authStore.save(user.token, user.record);
    } catch (e) {
      pb.authStore.clear();
    }
  }

  if (UniversalPlatform.isDesktop) {
    await windowManager.ensureInitialized();
  }

  if (kDebugMode) {
    PluginRegistry.instance.reset();
  }

  PluginRegistry.instance.registerPlugin(
    StremioCatalogPlugin(),
  );

  try {
    CachedQuery.instance.configFlutter(
      storage: await CachedStorage.ensureInitialized(),
      config: QueryConfigFlutter(
        refetchDuration: const Duration(minutes: 60),
        cacheDuration: const Duration(minutes: 60),
        refetchOnResume: false,
        refetchOnConnection: false,
        refetchOnResumeMinBackgroundDuration: const Duration(days: 30),
      ),
    );
  } catch (e) {
    _logger.warning("Unable initialize cache");
  }
}
