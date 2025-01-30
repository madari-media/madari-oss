import 'package:madari_client/features/widgetter/plugin_base.dart';

class WidgetPreview {
  final String pluginId;
  final String type;
  final String title;
  final WidgetFactory factory;
  final List<PresetWidgetConfig> presets;

  WidgetPreview({
    required this.pluginId,
    required this.type,
    required this.title,
    required this.factory,
    required this.presets,
  });
}

class PresetWidgetConfig {
  final String title;
  final Map<String, dynamic> config;
  final String description;
  final String widgetType;
  final String pluginId;
  final bool disabled;

  PresetWidgetConfig({
    required this.title,
    required this.config,
    required this.description,
    required this.widgetType,
    required this.pluginId,
    this.disabled = false,
  });

  factory(Map<String, dynamic> config) {}
}
