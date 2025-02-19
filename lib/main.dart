import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rinf/rinf.dart';

import './messages/all.dart';
import 'app/app.dart';
import 'features/common/utils/startup_app.dart';
import 'features/logger/service/logger.service.dart';
import 'features/theme/theme/app_theme.dart';
import 'features/widgetter/state/widget_state_provider.dart';

void main() async {
  await initializeRust(assignRustSignal);
  WidgetsFlutterBinding.ensureInitialized();

  setupLogger();
  await startupApp();

  runApp(
    ChangeNotifierProvider.value(
      value: AppTheme().themeProvider,
      child: ChangeNotifierProvider(
        create: (context) => StateProvider(),
        child: const AppDefault(),
      ),
    ),
  );
}
