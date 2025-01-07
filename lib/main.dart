import 'dart:io';

import 'package:cached_query_flutter/cached_query_flutter.dart';
import 'package:cached_storage/cached_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:madari_client/engine/engine.dart';
import 'package:madari_client/features/doc_viewer/container/doc_viewer.dart';
import 'package:madari_client/features/doc_viewer/types/doc_source.dart';
import 'package:madari_client/routes.dart';
import 'package:madari_client/utils/cached_storage_static.dart';
import 'package:media_kit/media_kit.dart';
import 'package:path/path.dart' as path;
import 'package:window_manager/window_manager.dart';

import 'features/doc_viewer/container/iframe.dart';
import 'features/downloads/service/service.dart';
import 'features/watch_history/service/zeee_watch_history.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    print("Unable");
  }

  StaticCachedStorage.storage = await CachedStorage.ensureInitialized();

  try {
    CachedQuery.instance.configFlutter(
      storage: StaticCachedStorage.storage,
      config: QueryConfigFlutter(
        refetchDuration: const Duration(minutes: 60),
        cacheDuration: const Duration(minutes: 60),
      ),
    );
  } catch (e) {
    print("Unable initialize cache");
  }

  MediaKit.ensureInitialized();

  AdblockList.str = await rootBundle.loadString("assets/adblock_list.txt");

  if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
    await windowManager.ensureInitialized();
  }

  await AppEngine.ensureInitialized();

  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.edgeToEdge,
    overlays: [],
  );

  final pb = AppEngine.engine.pb;
  final userCollection = pb.collection("users");

  if (pb.authStore.isValid) {
    try {
      final user = await userCollection.getOne(
        AppEngine.engine.pb.authStore.record!.id,
      );
      pb.authStore.save(pb.authStore.token, user);
    } catch (e) {
      pb.authStore.clear();
    }
  }

  runApp(
    const ProviderScope(
      child: MadariApp(),
    ),
  );
}

class MadariApp extends StatefulWidget {
  const MadariApp({super.key});

  @override
  State<MadariApp> createState() => _MadariAppState();
}

class _MadariAppState extends State<MadariApp> {
  static const platform = MethodChannel('media.madari.client/file');
  Map<String, dynamic>? _openedFileData;
  late final GoRouter _router;

  @override
  void initState() {
    DownloadService.instance.initialize();
    ZeeeWatchHistoryStatic.service = ZeeeWatchHistory();
    _initializeFileHandling();
    _router = createRouter();
    super.initState();
  }

  void _initializeFileHandling() {
    platform.setMethodCallHandler((call) async {
      if (call.method == "openFile") {
        // Handle the new file data structure
        _openedFileData = call.arguments as Map<String, dynamic>?;

        if (_openedFileData != null) {
          final filePath = _openedFileData!['path'] as String;

          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => DocViewer(
                source: FileSource(
                  title: path.basenameWithoutExtension(filePath),
                  filePath: filePath,
                  id: "external",
                ),
              ),
            ),
          );
        }
      }
    });
  }

  @override
  void dispose() {
    DownloadService.instance.dispose();
    ZeeeWatchHistoryStatic.service?.dispose();
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: _router,
      title: "Madari",
      debugShowCheckedModeBanner: false, // comes in the way of the search
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.red,
        ),
        useMaterial3: true,
      ),
      darkTheme: _buildTheme(Brightness.dark),
      themeMode: ThemeMode.dark,
    );
  }
}

ThemeData _buildTheme(brightness) {
  var baseTheme = ThemeData(brightness: brightness);

  return baseTheme.copyWith(
    textTheme: GoogleFonts.exo2TextTheme(baseTheme.textTheme),
  );
}
