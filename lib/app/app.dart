import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:madari_client/features/pocketbase/service/pocketbase.service.dart';
import 'package:madari_client/features/video_player/container/state/video_settings.dart';
import 'package:provider/provider.dart';

import '../features/settings/service/selected_profile.dart';
import '../features/theme/provider/theme_provider.dart';
import 'app_router.dart';

class AppDefault extends StatefulWidget {
  const AppDefault({
    super.key,
  });

  @override
  State<AppDefault> createState() => _AppDefaultState();
}

class _AppDefaultState extends State<AppDefault> {
  late GoRouter _router;

  @override
  void initState() {
    _router = createRouterDesktop();

    if (AppPocketBaseService.instance.pb.authStore.isValid) {
      SelectedProfileService.instance.initialize();
    }

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final theme = themeProvider.getTheme();

        return ChangeNotifierProvider(
          create: (context) => VideoSettingsProvider(),
          child: MaterialApp.router(
            routerConfig: _router,
            title: "Madari",
            theme: theme.copyWith(
              textTheme: GoogleFonts.exo2TextTheme(theme.textTheme),
            ),
            debugShowCheckedModeBanner: false, // comes in the way of the search
          ),
        );
      },
    );
  }
}
