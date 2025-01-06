import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:madari_client/routes.dart';
import 'package:media_kit/media_kit.dart';

import 'engine/engine.dart';
import 'features/watch_history/service/zeee_watch_history.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  await AppEngine.ensureInitialized();

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
  late final GoRouter _router;

  @override
  void initState() {
    ZeeeWatchHistoryStatic.service = ZeeeWatchHistory();
    _router = createRouter();
    super.initState();
  }

  @override
  void dispose() {
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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
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
