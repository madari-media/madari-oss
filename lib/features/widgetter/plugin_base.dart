import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:madari_client/features/widgetter/types/home_layout_model.dart';
import 'package:madari_client/features/widgetter/types/widget_gallery.dart';

class PluginRegistry extends ChangeNotifier {
  final _logger = Logger('PluginRegistry');

  static final PluginRegistry _instance = PluginRegistry._internal();
  static PluginRegistry get instance => _instance;

  PluginRegistry._internal();

  final _plugins = <String, PluginBase>{};
  final _widgetFactories = <String, Map<String, WidgetFactory>>{};

  void registerPlugin(PluginBase plugin) {
    _logger.info('Registering plugin: ${plugin.id}');
    _plugins[plugin.id] = plugin;
    _widgetFactories[plugin.id] = plugin.widgetFactories;
    notifyListeners();
  }

  List<PluginBase> getAvailablePlugins() {
    _logger.info('Getting available plugins');
    return _plugins.values.toList();
  }

  Widget? buildWidget(
    String pluginId,
    String widgetType,
    Map<String, dynamic> config,
    PluginContext pluginContext,
  ) {
    final factories = _widgetFactories[pluginId];
    if (factories == null) return null;

    final factory = factories[widgetType];
    if (factory == null) return null;

    return factory(
      config,
      pluginContext,
    );
  }

  void reset() {
    _plugins.clear();
    _widgetFactories.clear();
    notifyListeners();
  }

  PluginBase? getPlugin(String pluginId) {
    return _plugins[pluginId];
  }
}

typedef WidgetFactory = Widget Function(
  Map<String, dynamic> config,
  PluginContext context,
);

class PluginContext {
  final int index;
  final bool hasSearch;

  PluginContext({
    required this.index,
    required this.hasSearch,
  });
}

abstract class PluginBase {
  String get id;
  String get name;
  Map<String, WidgetFactory> get widgetFactories;
  Future<List<PresetWidgetConfig>> presets();
}

class PluginWidget extends StatelessWidget {
  final HomeLayoutModel layout;
  final _logger = Logger('PluginWidget');
  final PluginContext pluginContext;

  PluginWidget({
    super.key,
    required this.layout,
    required this.pluginContext,
  });

  @override
  Widget build(BuildContext context) {
    final widget = PluginRegistry.instance.buildWidget(
      layout.pluginId,
      layout.type,
      layout.config,
      pluginContext,
    );

    if (widget == null) {
      _logger.warning(
        'No widget found for plugin: ${layout.pluginId}, type: ${layout.type}',
      );

      return const SizedBox.shrink();
    }

    return FocusTraversalGroup(
      child: widget,
    );
  }
}
