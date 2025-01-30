import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';
import 'package:madari_client/features/settings/service/selected_profile.dart';
import 'package:madari_client/features/settings/widget/setting_wrapper.dart';

import '../service/list_service.dart';
import '../service/trakt_service.dart';
import '../types/library_types.dart';

class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key});

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  final _logger = Logger('LibraryPage');
  List<ListModel> _lists = [];
  bool _isLoading = true;
  bool _isRefreshing = false;

  late StreamSubscription<String?> _item;

  @override
  void initState() {
    super.initState();
    _loadLists();

    _item =
        SelectedProfileService.instance.selectedProfileStream.listen((item) {
      _loadLists();
    });
  }

  @override
  void dispose() {
    super.dispose();

    _item.cancel();
  }

  Future<void> _loadLists() async {
    try {
      setState(() => _isLoading = true);
      final lists = await ListsService.instance.getLists();
      setState(() {
        _lists = lists;
        _isLoading = false;
      });
    } catch (e) {
      _logger.severe('Error loading lists', e);
      setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshLists() async {
    try {
      setState(() => _isRefreshing = true);
      final lists = await ListsService.instance.getLists();
      setState(() {
        _lists = lists;
        _isRefreshing = false;
      });
    } catch (e) {
      _logger.severe('Error refreshing lists', e);
      setState(() => _isRefreshing = false);
    }
  }

  Future<void> _deleteList(String listId) async {
    try {
      await ListsService.instance.deleteList(listId);
      _loadLists();
    } catch (e) {
      _logger.severe('Error deleting list', e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isTablet = MediaQuery.of(context).size.width >= 600;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        title: Text(
          'My Library',
          style: theme.textTheme.headlineSmall?.copyWith(
            color: colorScheme.onSurface,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              await context.push('/library/create');

              _refreshLists();
            },
            tooltip: 'Create new list',
          ),
          if (TraktService.instance.isAuthenticated)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _isRefreshing ? null : _refreshLists,
              tooltip: 'Refresh lists',
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: colorScheme.primary,
              ),
            )
          : _lists.isEmpty
              ? _buildEmptyState(colorScheme)
              : SettingWrapper(
                  child: _buildListGrid(
                    isTablet,
                    colorScheme,
                  ),
                ),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_outlined,
            size: 64,
            color: colorScheme.primary.withAlpha(150),
          ),
          const SizedBox(height: 16),
          Text(
            'No Lists Yet',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: colorScheme.onSurface,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create a list to start organizing your movies and shows',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurface.withAlpha(150),
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () async {
              await context.push('/library/create');
              _refreshLists();
            },
            icon: const Icon(Icons.add),
            label: const Text('Create New List'),
          ),
          if (TraktService.instance.isAuthenticated) ...[
            const SizedBox(height: 16),
            FilledButton.tonalIcon(
              onPressed: () => context.push('/library/create'),
              icon: const Icon(Icons.cloud_download),
              label: const Text('Import from Trakt'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildListGrid(bool isTablet, ColorScheme colorScheme) {
    return RefreshIndicator(
      onRefresh: _refreshLists,
      child: ListView.builder(
        itemCount: _lists.length,
        itemBuilder: (context, index) {
          final list = _lists[index];
          return _buildListCard(list, colorScheme);
        },
      ),
    );
  }

  Widget _buildListCard(ListModel list, ColorScheme colorScheme) {
    IconData getIconForList() {
      if (list.name.toLowerCase() == 'watchlist') {
        return Icons.bookmark_outlined;
      }
      if (list.name.toLowerCase() == 'watch later') {
        return Icons.watch_later_outlined;
      }
      return list.sync ? Icons.sync : Icons.folder_outlined;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Dismissible(
          key: Key(list.id),
          background: Container(
            color: colorScheme.error,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 16),
            child: Icon(
              Icons.delete,
              color: colorScheme.onError,
            ),
          ),
          direction: DismissDirection.endToStart,
          onDismissed: (direction) => _deleteList(list.id),
          confirmDismiss: (direction) async {
            return await showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Delete List'),
                content:
                    Text('Are you sure you want to delete "${list.name}"?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Delete'),
                  ),
                ],
              ),
            );
          },
          child: ListTile(
            onTap: () => context.push('/library/${list.id}', extra: list),
            leading: Icon(
              getIconForList(),
              color: colorScheme.primary,
              size: 20,
            ),
            title: Text(list.name),
            subtitle:
                list.description.isNotEmpty ? Text(list.description) : null,
          ),
        ),
        const Divider(height: 1),
      ],
    );
  }
}
