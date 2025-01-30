import 'package:cached_query_flutter/cached_query_flutter.dart';
import 'package:logging/logging.dart';
import 'package:madari_client/features/settings/service/selected_profile.dart';
import 'package:pocketbase/pocketbase.dart';

import '../../pocketbase/service/pocketbase.service.dart';
import '../types/widget_gallery.dart';

final _logger = Logger('HomeLayoutService');

class HomeLayoutService {
  static final HomeLayoutService instance = HomeLayoutService._internal();
  HomeLayoutService._internal();

  Future<List<LayoutWidgetConfig>> loadLayoutWidgets() async {
    try {
      _logger.info('Loading layout widgets');
      final records = await AppPocketBaseService.instance.pb
          .collection('home_layout')
          .getFullList(
            sort: 'order',
            filter:
                'profiles = \'${SelectedProfileService.instance.selectedProfileId}\'',
          );

      return records
          .map((record) => LayoutWidgetConfig.fromRecord(record))
          .toList();
    } catch (e) {
      _logger.severe('Error loading layout widgets', e);
      return [];
    }
  }

  void clearCache() {
    SelectedProfileService.instance.setSelectedProfile(
      SelectedProfileService.instance.selectedProfileId,
    );

    CachedQuery.instance.invalidateCache(filterFn: (item, key) {
      return key.startsWith("home_layout");
    });
  }

  Future<bool> saveLayoutWidget(LayoutWidgetConfig widget) async {
    try {
      _logger.info('Saving layout widget: ${widget.pluginId}');
      await AppPocketBaseService.instance.pb.collection('home_layout').create(
            body: widget.toJson(),
          );
      clearCache();
      return true;
    } catch (e) {
      _logger.severe('Error saving layout widget', e);
      return false;
    }
  }

  Future<bool> updateLayoutOrder(List<LayoutWidgetConfig> widgets) async {
    try {
      _logger.info('Updating layout order for ${widgets.length} widgets');

      final updates = widgets.asMap().entries.map((entry) {
        final widget = entry.value;
        return AppPocketBaseService.instance.pb
            .collection('home_layout')
            .update(
          widget.id,
          body: {
            'order': entry.key,
          },
        );
      }).toList();

      clearCache();

      await Future.wait(updates);
      return true;
    } catch (e) {
      _logger.severe('Error updating layout order', e);
      return false;
    }
  }

  Future<bool> deleteLayoutWidget(String id) async {
    try {
      _logger.info('Deleting layout widget: $id');
      await AppPocketBaseService.instance.pb
          .collection('home_layout')
          .delete(id);

      clearCache();

      return true;
    } catch (e) {
      _logger.severe('Error deleting layout widget', e);
      return false;
    }
  }
}

class LayoutWidgetConfig {
  final String id;
  final String title;
  final Map<String, dynamic> config;
  final int order;
  final String pluginId;
  final String widgetType;
  final PresetWidgetConfig? preset;

  LayoutWidgetConfig({
    required this.title,
    required this.id,
    required this.config,
    required this.order,
    required this.pluginId,
    required this.widgetType,
    this.preset,
  });

  factory LayoutWidgetConfig.fromPreset(
    PresetWidgetConfig preset,
    String userId,
    int order,
  ) {
    return LayoutWidgetConfig(
      id: '',
      title: preset.title,
      config: preset.config ?? {},
      order: order,
      pluginId: preset.pluginId,
      widgetType: preset.widgetType,
      preset: preset,
    );
  }

  factory LayoutWidgetConfig.fromRecord(RecordModel record) {
    return LayoutWidgetConfig(
      id: record.id,
      title: record.getStringValue("title"),
      config: record.get('config'),
      order: record.getIntValue('order'),
      pluginId: record.getStringValue('plugin_id'),
      widgetType: record.getStringValue('type'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'config': config,
      'order': order,
      'plugin_id': pluginId,
      'type': widgetType,
      'profiles': SelectedProfileService.instance.selectedProfileId,
      'user': AppPocketBaseService.instance.pb.authStore.record!.id,
    };
  }

  LayoutWidgetConfig copyWith({
    String? title,
    String? id,
    String? userId,
    Map<String, dynamic>? config,
    int? order,
    String? pluginId,
    String? widgetType,
    PresetWidgetConfig? preset,
  }) {
    return LayoutWidgetConfig(
      id: id ?? this.id,
      title: title ?? this.title,
      config: config ?? this.config,
      order: order ?? this.order,
      pluginId: pluginId ?? this.pluginId,
      widgetType: widgetType ?? this.widgetType,
      preset: preset ?? this.preset,
    );
  }
}
