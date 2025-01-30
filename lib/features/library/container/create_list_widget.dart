import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';

import '../../pocketbase/service/pocketbase.service.dart';
import '../service/list_service.dart';
import '../service/trakt_service.dart';
import '../types/library_types.dart';

class CreateListPage extends StatefulWidget {
  const CreateListPage({super.key});

  @override
  State<CreateListPage> createState() => _CreateListPageState();
}

class _CreateListPageState extends State<CreateListPage> {
  final _logger = Logger('CreateListPage');
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isLoadingTrakt = false;
  List<dynamic> _traktLists = [];

  @override
  void initState() {
    super.initState();

    if (TraktService.instance.isAuthenticated) {
      _loadTraktLists();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadTraktLists() async {
    try {
      setState(() => _isLoadingTrakt = true);
      final lists = await TraktService.instance.getLists();
      setState(() {
        _traktLists = lists;
        _isLoadingTrakt = false;
      });
    } catch (e) {
      _logger.severe('Error loading Trakt lists', e);
      setState(() => _isLoadingTrakt = false);
    }
  }

  Future<void> _createList() async {
    try {
      final request = CreateListRequest(
        name: _nameController.text,
        description: _descriptionController.text,
      );
      await ListsService.instance.createList(request);
      if (mounted) {
        context.pop(true);
      }
    } catch (e) {
      _logger.severe('Error creating list', e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text('Create New List', style: theme.textTheme.headlineSmall),
        actions: [
          FilledButton(
            onPressed: _nameController.text.isEmpty ? null : _createList,
            child: const Text('Create'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            Container(
              color: colorScheme.surface,
              child: TabBar(
                tabs: const [
                  Tab(text: 'Create New'),
                  Tab(text: 'Import from Trakt'),
                ],
                labelColor: colorScheme.primary,
                unselectedLabelColor: colorScheme.onSurface.withAlpha(150),
                indicatorColor: colorScheme.primary,
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildCreateNewTab(colorScheme),
                  _buildTraktImportTab(colorScheme),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateNewTab(ColorScheme colorScheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'List Details',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: colorScheme.onSurface,
                ),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Name',
              hintText: 'Enter list name',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: Icon(
                Icons.format_list_bulleted,
                color: colorScheme.primary,
              ),
            ),
            onChanged: (value) => setState(() {}),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _descriptionController,
            decoration: InputDecoration(
              labelText: 'Description',
              hintText: 'Enter list description',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: Icon(
                Icons.description,
                color: colorScheme.primary,
              ),
            ),
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildTraktImportTab(ColorScheme colorScheme) {
    if (!AppPocketBaseService.instance.pb.authStore.record!
        .getStringValue("trakt_token")
        .isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off,
              size: 64,
              color: colorScheme.primary.withAlpha(150),
            ),
            const SizedBox(height: 16),
            Text(
              'Trakt Account Not Connected',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: colorScheme.onSurface,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Connect your Trakt account in settings to import lists',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurface.withAlpha(150),
                  ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () {
                // TODO: Navigate to settings
              },
              icon: const Icon(Icons.settings),
              label: const Text('Go to Settings'),
            ),
          ],
        ),
      );
    }

    return _isLoadingTrakt
        ? const Center(child: CircularProgressIndicator())
        : ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 16),
            itemCount: _traktLists.length,
            itemBuilder: (context, index) {
              final TraktList list = _traktLists[index];
              return ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.cloud_download),
                ),
                title: Text(list.name),
                subtitle: Text(
                  '${list.itemCount} items • Updated ${list.lastUpdated}',
                ),
                trailing: FilledButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => const Dialog(
                        child: Text("Not implemented"),
                      ),
                    );
                  },
                  child: const Text('Import'),
                ),
              );
            },
          );
  }
}
