import 'package:logging/logging.dart';

import '../../pocketbase/service/pocketbase.service.dart';
import '../../widgetter/plugin_base.dart';
import '../../widgetter/service/home_layout_service.dart';

class LayoutService {
  static final LayoutService _instance = LayoutService._internal();
  static LayoutService get instance => _instance;

  final _logger = Logger('LayoutService');

  LayoutService._internal();

  Future<(int, String?)> addAllHomeWidgets() async {
    try {
      _logger.info('Adding all widgets for new account');

      final userId = AppPocketBaseService.instance.pb.authStore.record!.id;
      int successCount = 0;

      final result = PluginRegistry.instance.getAvailablePlugins();
      final presets = await Future.wait(
        result.map((item) => item.presets()),
      );

      final allWidgets = presets.expand((element) => element).toList();

      for (final preset in allWidgets) {
        final newWidget = LayoutWidgetConfig.fromPreset(
          preset,
          userId,
          successCount,
        );

        final success = await HomeLayoutService.instance.saveLayoutWidget(
          newWidget,
        );

        if (success) {
          successCount++;
        }
      }

      if (successCount > 0) {
        _logger.info('Successfully added $successCount widgets');
        return (successCount, null);
      } else {
        return (0, 'Failed to add widgets. Please try again.');
      }
    } catch (e) {
      _logger.severe('Error adding all widgets', e);
      return (0, 'Failed to add widgets. Please check your connection.');
    }
  }
}
