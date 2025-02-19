import 'package:cached_query_flutter/cached_query_flutter.dart';
import 'package:flutter/material.dart';
import 'package:madari_engine/madari_engine.dart';
import 'package:shimmer/shimmer.dart';

import '../pages/stremio_addons_page.dart';
import 'add_addon_sheet.dart';

class StremioAddonsList extends StatelessWidget {
  final Query<List<StremioManifest>> query;
  final bool showHidden;

  const StremioAddonsList({
    super.key,
    required this.query,
    required this.showHidden,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return QueryBuilder(
      query: query,
      builder: (context, state) {
        if (state.status == QueryStatus.loading) {
          return _buildShimmerList(colorScheme);
        }

        if (state.error != null) {
          return Center(
            child: Card(
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 48,
                      color: colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading addons',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      state.error.toString(),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: () => query.refetch(),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final addons = state.data ?? [];
        if (addons.isEmpty) {
          return RefreshIndicator(
            onRefresh: () => query.refetch(),
            child: CustomScrollView(
              slivers: [
                SliverFillRemaining(
                  child: Center(
                    child: Card(
                      margin: const EdgeInsets.all(16),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.extension_outlined,
                              size: 48,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No Addons Installed',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Add your first addon to get started',
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                            ),
                            const SizedBox(height: 24),
                            FilledButton.icon(
                              onPressed: () => _showAddAddonDialog(context),
                              icon: const Icon(Icons.add),
                              label: const Text('Add Addon'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => query.refetch(),
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
            itemCount: addons.length,
            separatorBuilder: (context, index) => const SizedBox(height: 0),
            itemBuilder: (context, index) {
              final addon = addons[index];
              return _AddonListItem(
                addon: addon,
                onTap: () => _showManageAddonDialog(context, addon),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildShimmerList(ColorScheme colorScheme) {
    return Shimmer.fromColors(
      baseColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
      highlightColor:
          colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
        itemCount: 5,
        separatorBuilder: (context, index) => const SizedBox(height: 8),
        itemBuilder: (context, index) => _ShimmerAddonItem(),
      ),
    );
  }

  void _showAddAddonDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => AddAddonSheet(
        onRefetch: () {
          query.refetch();
        },
      ),
      useSafeArea: true,
      isScrollControlled: true,
    );
  }

  void _showManageAddonDialog(BuildContext context, StremioManifest addon) {
    showDialog(
      context: context,
      builder: (context) => ManageAddonDialog(
        addon: addon,
        showHidden: showHidden,
      ),
    );
  }
}

class _AddonListItem extends StatelessWidget {
  final StremioManifest addon;
  final VoidCallback onTap;

  const _AddonListItem({
    required this.addon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      clipBehavior: Clip.hardEdge,
      color: colorScheme.brightness == Brightness.dark
          ? Colors.black
          : Colors.white,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: addon.logo != null
                    ? Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Image.network(
                          addon.logo!,
                          color: colorScheme.primary,
                        ),
                      )
                    : Icon(
                        Icons.extension,
                        color: colorScheme.onPrimaryContainer,
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      addon.name ?? 'Unknown Addon',
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (addon.description != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        addon.description!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShimmerAddonItem extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 20,
                    width: 150,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 16,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
