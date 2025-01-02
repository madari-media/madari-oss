import 'package:flutter/material.dart';

class FileItem {
  final String name;
  final bool isDirectory;
  final String? path;

  FileItem({
    required this.name,
    required this.isDirectory,
    this.path,
  });
}

class FilesManagerContainer extends StatefulWidget {
  final Future<List<FileItem>> Function(String? path) onLoadFiles;
  final Future<void> Function(String path, String name) onCreateFolder;

  const FilesManagerContainer({
    super.key,
    required this.onLoadFiles,
    required this.onCreateFolder,
  });

  @override
  State<FilesManagerContainer> createState() => _FilesManagerContainerState();
}

class _FilesManagerContainerState extends State<FilesManagerContainer> {
  late Future<List<FileItem>> _filesFuture;
  String _currentPath = '';
  final List<String> _navigationStack = [];

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  void _loadFiles() {
    _filesFuture = widget.onLoadFiles(_currentPath);
  }

  void _navigateToFolder(String path) {
    setState(() {
      _navigationStack.add(_currentPath);
      _currentPath = path;
      _loadFiles();
    });
  }

  bool _navigateBack() {
    if (_navigationStack.isNotEmpty) {
      setState(() {
        _currentPath = _navigationStack.removeLast();
        _loadFiles();
      });
      return true;
    }
    return false;
  }

  Future<void> _createFolder() async {
    final controller = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Folder'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Folder name',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (result == true && controller.text.isNotEmpty && mounted) {
      try {
        await widget.onCreateFolder(_currentPath, controller.text);
        setState(() {
          _loadFiles();
        });
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to create folder: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return !_navigateBack(); // Return true to exit app, false to stay
      },
      child: Scaffold(
        appBar: AppBar(
          leading: _navigationStack.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: _navigateBack,
                )
              : null,
          title: Text(_currentPath.isEmpty ? 'Files' : _currentPath),
          actions: [
            IconButton(
              icon: const Icon(Icons.create_new_folder),
              onPressed: _createFolder,
            ),
          ],
        ),
        body: FutureBuilder<List<FileItem>>(
          future: _filesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Text('Error: ${snapshot.error}'),
              );
            }

            final files = snapshot.data ?? [];

            if (files.isEmpty) {
              return const Center(
                child: Text('No files found'),
              );
            }

            return ListView.builder(
              itemCount: files.length,
              itemBuilder: (context, index) {
                final file = files[index];
                return ListTile(
                  leading: Icon(
                    file.isDirectory ? Icons.folder : Icons.insert_drive_file,
                    color: file.isDirectory ? Colors.amber : Colors.blue,
                  ),
                  title: Text(file.name),
                  onTap: file.isDirectory
                      ? () => _navigateToFolder(file.path!)
                      : null,
                );
              },
            );
          },
        ),
      ),
    );
  }
}
