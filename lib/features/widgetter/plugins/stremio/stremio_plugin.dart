import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:madari_client/features/pocketbase/service/pocketbase.service.dart';
import 'package:madari_client/features/streamio_addons/extension/query_extension.dart';

import '../../../streamio_addons/service/stremio_addon_service.dart';
import '../../plugin_base.dart';
import '../../types/widget_gallery.dart';
import 'widgets/catalog_grid.dart';

class StremioCatalogPlugin extends PluginBase {
  @override
  String get id => 'stremio_catalog';

  @override
  String get name => 'Stremio Catalog';

  @override
  Map<String, WidgetFactory> get widgetFactories => {
        'catalog_grid': (config, pluginContext) {
          if (pluginContext.hasSearch) {
            if (config["can_search"]) {
              return CatalogGrid(
                config: config,
                pluginContext: pluginContext,
              );
            }

            return const SizedBox.shrink();
          }

          return CatalogGrid(
            config: config,
            pluginContext: pluginContext,
          );
        },
        'catalog_grid_big': (config, pluginContext) => CatalogGrid(
              config: config,
              isWide: true,
              pluginContext: pluginContext,
            ),
      };

  @override
  Future<List<PresetWidgetConfig>> presets() async {
    final addons = StremioAddonService.instance.getInstalledAddons(
      enabledOnly: true,
    );

    final List<PresetWidgetConfig> items = [];

    final traktEnable = AppPocketBaseService.instance.pb.authStore.record!
        .getStringValue("trakt_token");

    if (traktEnable != "") {
      items.addAll(trakt);
    }

    final result = await addons.queryFn();

    for (final item in result) {
      if (item.catalogs?.isNotEmpty != true) {
        continue;
      }

      for (final catalog in item.catalogs!) {
        final hasSearch = catalog.extraRequired?.contains("search") ?? false;

        final result = PresetWidgetConfig(
          title: "${catalog.name ?? ""} ${catalog.type.capitalize}",
          pluginId: id,
          description: item.name,
          config: {
            "description": item.name,
            "type": catalog.type,
            "name": catalog.name,
            "id": catalog.id,
            "can_search": hasSearch,
            "extra_supported": catalog.extraSupported ?? [],
            "extra_required": catalog.extraRequired ?? [],
            "addon": item.manifestUrl,
          },
          widgetType: "catalog_grid",
        );

        items.add(result);
      }
    }

    return items;
  }

  late final List<PresetWidgetConfig> trakt = [];
}
