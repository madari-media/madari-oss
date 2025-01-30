import 'package:flutter/material.dart';
import 'package:madari_client/app/app_web.dart';
import 'package:provider/provider.dart';

import 'features/common/utils/startup_app.dart';
import 'features/logger/service/logger.service.dart';
import 'features/theme/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  setupLogger();
  await startupApp();

  runApp(
    ChangeNotifierProvider.value(
      value: AppTheme().themeProvider,
      child: const AppWeb(),
    ),
  );
}
