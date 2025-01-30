import 'package:logging/logging.dart';

import '../data/global_logs.data.dart';

void setupLogger() {
  Logger.root.level = Level.INFO;

  Logger.root.onRecord.listen((record) {
    final logs =
        '${record.level.name.padRight(10)}${record.loggerName.padRight(30)}${record.time.hour}:${record.time.minute}:${record.time.second}:${record.time.millisecond}: ${record.message}';

    print(logs);

    globalLogs.add(logs);
    if (globalLogs.length > 1000) {
      globalLogs.removeAt(0);
    }

    if (record.error != null) {
      final error = 'Error: ${record.time} ${record.error}';
      print(error);
      globalLogs.add(error);
      if (globalLogs.length > 1000) {
        globalLogs.removeAt(0);
      }
    }
    if (record.stackTrace != null) {
      final error = 'StackTrace: ${record.stackTrace}';
      print(error);
      globalLogs.add(error);
      if (globalLogs.length > 1000) {
        globalLogs.removeAt(0);
      }
    }
  });
}
