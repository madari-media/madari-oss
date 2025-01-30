import 'package:cached_query/cached_query.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:madari_client/features/streamio_addons/extension/query_extension.dart';
import 'package:madari_client/features/streamio_addons/models/stremio_base_types.dart';
import 'package:madari_client/features/streamio_addons/service/stremio_addon_service.dart';
import 'package:madari_client/utils/array-extension.dart';

import '../../widgetter/plugins/stremio/widgets/catalog_grid_full.dart';
import '../../widgetter/plugins/stremio/widgets/error_card.dart';

final _logger = Logger('ExploreAddon');

class ExploreAddon extends StatefulWidget {
  final List<StremioManifest> data;
  const ExploreAddon({
    super.key,
    required this.data,
  });

  @override
  State<ExploreAddon> createState() => _ExploreAddonState();
}

class _ExploreAddonState extends State<ExploreAddon> {
  String? selectedType;
  String? selectedId;
  String? selectedGenre;
  StremioManifest? selectedAddon;
  static const int pageSize = 50;
  final service = StremioAddonService.instance;

  InfiniteQuery<List<Meta>, int>? _query;

  @override
  void initState() {
    super.initState();

    setFirstThing();
    setOptionValues();
    setQuery();
  }

  setQuery() {
    _query = buildQuery();

    setState(() {});
  }

  String get queryKey {
    return "explorer_page_${selectedType}_${selectedId}_$selectedGenre";
  }

  InfiniteQuery<List<Meta>, int> buildQuery() {
    return InfiniteQuery(
      key: queryKey,
      config: QueryConfig(
        cacheDuration: const Duration(days: 30),
        refetchDuration: const Duration(hours: 8),
      ),
      getNextArg: (state) {
        final lastPage = state.lastPage;
        if (lastPage == null) return 1;
        if (lastPage.length < pageSize) return null;
        return state.length + 1;
      },
      queryFn: (page) async {
        _logger.info('Fetching catalog for page: $page');
        try {
          final addonManifest = await service
              .validateManifest(selectedAddon!.manifestUrl!)
              .queryFn();

          List<ConnectionFilterItem> items = [];

          if (selectedGenre != null) {
            items.add(
              ConnectionFilterItem(
                title: "genre",
                value: selectedGenre,
              ),
            );
          }

          return service.getCatalog(
            addonManifest,
            selectedType!,
            selectedId!,
            page - 1,
            items,
          );
        } catch (e, stack) {
          _logger.severe('Error fetching catalog: $e', e, stack);
          throw Exception('Failed to fetch catalog');
        }
      },
    );
  }

  setFirstThing() {
    final Set<String> genres = {};

    StremioManifest? selectedAddon;

    for (final item in widget.data) {
      for (final value in item.catalogs!) {
        selectedType ??= value.type;

        selectedAddon ??= item;

        if (selectedType == value.type) {
          selectedId ??= value.id;
          selectedAddon = item;
        }

        if (selectedType == value.type && selectedId == value.id) {
          final extra = value.extra?.firstWhereOrNull((extra) {
            return extra.name == "genre";
          });

          if (extra != null && extra.options?.isNotEmpty == true) {
            for (final option in extra.options!) {
              selectedGenre ??= option;

              selectedAddon = item;

              genres.add(option);
            }
          }
        }
      }
    }

    this.selectedAddon = selectedAddon;

    this.genres = genres.toList();
  }

  setOptionValues() {
    final Set<String> types = {};

    for (final item in widget.data) {
      for (final value in item.catalogs!) {
        if (value.type != selectedType) {
          continue;
        }

        types.add(value.id);
      }
    }

    categories = types.toList();
  }

  List<String> get types {
    final Set<String> allTypes = {};

    for (final item in widget.data) {
      if (item.catalogs == null) {
        continue;
      }
      for (final value in item.catalogs!) {
        allTypes.add(value.type);
      }
    }

    return allTypes.toList();
  }

  List<String> categories = [];
  List<String> genres = [];

  void _showSelectionSheet(
    List<String> items,
    String title,
    String current,
    Function(String) onSelect, {
    List<String> resetTypes = const [],
  }) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(title, style: Theme.of(context).textTheme.titleLarge),
          ),
          Expanded(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: items.length,
              itemBuilder: (context, index) => ListTile(
                title: Text(
                  items[index]
                      .replaceAll(".", " ")
                      .split(" ")
                      .map((item) => item.capitalize)
                      .join(" "),
                ),
                selected: items[index] == current,
                trailing: items[index] == current
                    ? Icon(
                        Icons.check_circle,
                        color: Theme.of(context).highlightColor,
                      )
                    : null,
                onTap: () {
                  onSelect(items[index]);

                  if (resetTypes.contains('categories')) {
                    selectedId = null;
                  }

                  if (resetTypes.contains('genres')) {
                    selectedGenre = null;
                  }
                  setFirstThing();
                  setOptionValues();

                  setQuery();

                  Navigator.pop(context);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (selectedId == null || selectedType == null) {
      return const Scaffold(
        body: ErrorCard(error: "No addon with support for catalog"),
      );
    }

    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                FilterChip(
                  selected: true,
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        selectedType!
                            .replaceAll(".", " ")
                            .split(" ")
                            .map((item) => item.capitalize)
                            .join(" "),
                      ),
                      const Icon(Icons.arrow_drop_down, size: 18)
                    ],
                  ),
                  onSelected: (_) => _showSelectionSheet(
                    types,
                    'Select Type',
                    selectedType!,
                    (value) => setState(() => selectedType = value),
                    resetTypes: [
                      'categories',
                      'genres',
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  selected: true,
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        selectedId!
                            .replaceAll(".", " ")
                            .split(" ")
                            .map((item) => item.capitalize)
                            .join(" "),
                      ),
                      const Icon(Icons.arrow_drop_down, size: 18)
                    ],
                  ),
                  onSelected: (_) => _showSelectionSheet(
                    categories,
                    'Select Category',
                    selectedId!,
                    (value) => setState(() => selectedId = value),
                    resetTypes: [
                      'genres',
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (genres.isNotEmpty)
                  FilterChip(
                    selected: selectedGenre != null,
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          (selectedGenre ?? 'Genre')
                              .replaceAll(".", " ")
                              .split(" ")
                              .map((item) => item.capitalize)
                              .join(" "),
                        ),
                        const Icon(Icons.arrow_drop_down, size: 18)
                      ],
                    ),
                    onSelected: (_) => _showSelectionSheet(
                      genres,
                      'Select Genre',
                      selectedGenre ?? '',
                      (value) => setState(() => selectedGenre = value),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: _query != null
                ? CatalogFullView(
                    initialItems: const [],
                    prefix: "explore",
                    query: buildQuery(),
                    key: ValueKey(queryKey),
                  )
                : const Center(
                    child: CircularProgressIndicator(),
                  ),
          ),
        ],
      ),
    );
  }
}
