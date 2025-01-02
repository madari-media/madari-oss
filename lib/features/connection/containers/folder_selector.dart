import 'package:flutter/material.dart';
import 'package:madari_client/features/connection/services/stremio_service.dart';
import 'package:madari_client/features/settings/types/connection.dart';

import '../../../engine/library.dart';
import '../services/base_connection_service.dart';

class FolderSelector extends StatefulWidget {
  final void Function(List<FolderItem>) onFolderSelected;
  final Connection item;

  const FolderSelector({
    super.key,
    required this.onFolderSelected,
    required this.item,
  });

  @override
  createState() => _FolderSelectorState();
}

class _FolderSelectorState extends State<FolderSelector> {
  List<FolderItem> _folders = [];
  final List<FolderItem> _selectedFolder = [];
  bool _isLoading = true;
  String? _errorMessage;
  late final BaseConnectionService connectionService;

  final TextEditingController _searchController = TextEditingController();
  List<FolderItem> _filteredFolders = [];

  @override
  void initState() {
    super.initState();

    final connectionId = Future.delayed(
      Duration.zero,
      () => widget.item.id,
    );

    switch (widget.item.type) {
      case "stremio_addons":
        connectionService = StremioService(
          connectionId: connectionId,
          config: widget.item.config ?? "{}",
        );

      default:
        throw TypeError();
    }

    _loadFolders();
    _searchController.addListener(_filterFolders);
  }

  void _filterFolders() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredFolders = _folders.where((folder) {
        return folder.title.toLowerCase().contains(query);
      }).toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFolders() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final folders = await _fetchFolders();

      setState(() {
        _folders = folders;
        _filteredFolders = _folders;
        _isLoading = false;
      });

      _filterFolders();
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load folders';
        _isLoading = false;
      });
      rethrow;
    }
  }

  Future<List<FolderItem>> _fetchFolders() async {
    return connectionService.getFolders();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search folders...',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
        const SizedBox(height: 16),
        if (_isLoading)
          const Center(child: CircularProgressIndicator())
        else if (_errorMessage != null)
          Text(
            _errorMessage!,
            style: const TextStyle(color: Colors.red),
          )
        else if (_filteredFolders.isEmpty)
          const Text('No folders available')
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _filteredFolders.length,
            itemBuilder: (context, index) {
              final folder = _filteredFolders[index];

              final selected =
                  _selectedFolder.where((i) => i.id == folder.id).isNotEmpty;

              return ListTile(
                title: Text(folder.title),
                leading: folder.icon,
                trailing: selected
                    ? Icon(
                        Icons.check,
                        color: Theme.of(context).primaryColorLight,
                      )
                    : const Icon(Icons.circle_outlined),
                selected: selected,
                selectedTileColor: Colors.blue.withOpacity(0.1),
                onTap: () {
                  setState(() {
                    if (!selected) {
                      _selectedFolder.add(folder);
                    } else {
                      _selectedFolder.remove(folder);
                    }
                    widget.onFolderSelected(_selectedFolder);
                  });
                },
              );
            },
          ),
      ],
    );
  }
}
