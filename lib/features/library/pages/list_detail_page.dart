import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';
import 'package:madari_client/features/pocketbase/service/pocketbase.service.dart';
import 'package:madari_client/features/widgetter/plugins/stremio/utils/size.dart';
import 'package:madari_engine/madari_engine.dart';

import '../service/trakt_service.dart';

class ListDetailsPage extends StatefulWidget {
  final ListModel list;

  const ListDetailsPage({
    super.key,
    required this.list,
  });

  @override
  State<ListDetailsPage> createState() => _ListDetailsPageState();
}

class _ListDetailsPageState extends State<ListDetailsPage> {
  final _logger = Logger('ListDetailsPage');
  List<ListItemModel> _items = [];
  bool _isLoading = true;
  bool _isRefreshing = false;
  bool _isGridView = true;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    try {
      setState(() => _isLoading = true);
      final items = await AppPocketBaseService.instance.engine.listService
          .getListItems(widget.list.id);
      setState(() {
        _items = items;
        _isLoading = false;
      });
    } catch (e) {
      _logger.severe('Error loading list items', e);
      setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshItems() async {
    if (widget.list.sync) {
      try {
        setState(() => _isRefreshing = true);
        await TraktService.instance.syncList(widget.list.id);
        await _loadItems();
        setState(() => _isRefreshing = false);
      } catch (e) {
        _logger.severe('Error syncing list items', e);
        setState(() => _isRefreshing = false);
      }
    } else {
      await _loadItems();
    }
  }

  Future<void> _removeItem(ListItemModel item) async {
    try {
      await AppPocketBaseService.instance.engine.listService
          .removeListItem(widget.list.id, item.id);
      _loadItems();
    } catch (e) {
      _logger.severe('Error removing list item', e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isTablet = MediaQuery.of(context).size.width >= 600;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(colorScheme),
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_items.isEmpty)
            SliverFillRemaining(
              child: _buildEmptyState(colorScheme),
            )
          else
            _isGridView
                ? _buildGridView(isTablet, colorScheme)
                : _buildListView(colorScheme),
        ],
      ),
    );
  }

  Widget _buildAppBar(ColorScheme colorScheme) {
    return SliverAppBar.large(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.list.name),
          if (widget.list.description.isNotEmpty)
            Text(
              widget.list.description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withAlpha(200),
                  ),
            ),
        ],
      ),
      actions: [
        if (widget.list.sync)
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: _isRefreshing ? null : _refreshItems,
            tooltip: 'Sync with Trakt',
          ),
        IconButton(
          icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view),
          onPressed: () => setState(() => _isGridView = !_isGridView),
          tooltip: _isGridView ? 'Switch to list view' : 'Switch to grid view',
        ),
        IconButton(
          icon: const Icon(Icons.edit),
          onPressed: () => {},
          tooltip: "Edit",
        ),
      ],
      bottom: _isRefreshing
          ? PreferredSize(
              preferredSize: const Size.fromHeight(2),
              child: LinearProgressIndicator(
                color: colorScheme.primary,
                backgroundColor: colorScheme.surfaceContainerHighest,
              ),
            )
          : null,
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.movie_outlined,
            size: 64,
            color: colorScheme.primary.withAlpha(150),
          ),
          const SizedBox(height: 16),
          Text(
            'No Items Yet',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: colorScheme.onSurface,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add movies and shows from their detail pages',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurface.withAlpha(150),
                ),
            textAlign: TextAlign.center,
          ),
          if (widget.list.sync) ...[
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _refreshItems,
              icon: const Icon(Icons.sync),
              label: const Text('Sync with Trakt'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGridView(bool isTablet, ColorScheme colorScheme) {
    final result = StremioCardSize.getSize(context, isGrid: true);

    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: result.columns,
          childAspectRatio: 2 / 3,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) => _buildGridItem(_items[index], colorScheme),
          childCount: _items.length,
        ),
      ),
    );
  }

  onTap(ListItemModel item) {
    context.push(
      "/meta/${item.type}/${item.imdbId}?image=${Uri.encodeQueryComponent(item.poster)}",
    );
  }

  Widget _buildGridItem(ListItemModel item, ColorScheme colorScheme) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          onTap(item);
        },
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Image.network(
                    item.poster,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: colorScheme.surfaceContainerHighest,
                        child: Icon(
                          item.type == 'movie' ? Icons.movie : Icons.tv,
                          size: 48,
                          color: colorScheme.primary,
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            item.type == 'movie' ? Icons.movie : Icons.tv,
                            size: 16,
                            color: colorScheme.onSurface.withAlpha(150),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            item.type.toUpperCase(),
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: colorScheme.onSurface.withAlpha(150),
                                ),
                          ),
                          const Spacer(),
                          const Icon(
                            Icons.star,
                            size: 16,
                            color: Colors.amber,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            item.rating.toStringAsFixed(1),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.remove_circle),
                style: IconButton.styleFrom(
                  backgroundColor: colorScheme.surface.withAlpha(200),
                  foregroundColor: colorScheme.error,
                ),
                onPressed: () => _removeItem(item),
                tooltip: 'Remove from list',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListView(ColorScheme colorScheme) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => _buildListItem(_items[index], colorScheme),
          childCount: _items.length,
        ),
      ),
    );
  }

  Widget _buildListItem(ListItemModel item, ColorScheme colorScheme) {
    return Dismissible(
      key: Key(item.id),
      background: Container(
        color: colorScheme.error,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: Icon(
          Icons.delete,
          color: colorScheme.onError,
        ),
      ),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) => _removeItem(item),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Image.network(
            item.poster,
            width: 40,
            height: 60,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: 40,
                height: 60,
                color: colorScheme.surfaceContainerHighest,
                child: Icon(
                  item.type == 'movie' ? Icons.movie : Icons.tv,
                  color: colorScheme.primary,
                ),
              );
            },
          ),
        ),
        title: Text(item.title),
        subtitle: Row(
          children: [
            Icon(
              item.type == 'movie' ? Icons.movie : Icons.tv,
              size: 16,
              color: colorScheme.onSurface.withAlpha(150),
            ),
            const SizedBox(width: 4),
            Text(item.type.toUpperCase()),
            const SizedBox(width: 8),
            const Icon(
              Icons.star,
              size: 16,
              color: Colors.amber,
            ),
            const SizedBox(width: 4),
            Text(item.rating.toStringAsFixed(1)),
          ],
        ),
        onTap: () {
          onTap(item);
        },
      ),
    );
  }
}
