import 'package:flutter/material.dart';
import 'package:madari_client/engine/engine.dart';
import 'package:madari_client/features/settings/types/connection.dart';
import 'package:pocketbase/pocketbase.dart';

import '../../../engine/library.dart';
import '../../connection/containers/folder_selector.dart';

class CreateNewLibrary extends StatefulWidget {
  final PocketBase engine = AppEngine.engine.pb;
  final Connection item;
  final VoidCallback onCreated;
  final VoidCallback onCreatedAnother;
  final ScrollController? scrollController;

  CreateNewLibrary({
    super.key,
    required this.item,
    required this.onCreated,
    required this.onCreatedAnother,
    this.scrollController,
  });

  @override
  createState() => _CreateNewLibraryState();
}

class _CreateNewLibraryState extends State<CreateNewLibrary> {
  final _formKey = GlobalKey<FormState>();
  String _libraryName = '';
  IconData _selectedIcon = Icons.folder;
  final List<String> _selectedTypes = [];
  List<FolderItem> _folder = [];

  final List<String> _libraryTypes = [
    'Document',
    'Video',
    'Audio',
    'Photo',
  ];

  final List<IconData> _availableIcons = [
    // Media Type Icons
    Icons.video_library,
    Icons.music_note,
    Icons.movie,
    Icons.library_music,
    Icons.photo_library,
    Icons.book,
    Icons.library_books,
    Icons.library_add,

    // Folder and Collection Icons
    Icons.folder,
    Icons.folder_open,
    Icons.create_new_folder,
    Icons.collections_bookmark,
    Icons.collections,
    Icons.local_library,

    // Specific Media Icons
    Icons.headphones,
    Icons.camera_alt,
    Icons.slideshow,
    Icons.movie_filter,
    Icons.featured_video,

    // Abstract and Conceptual Icons
    Icons.category,
    Icons.inventory,
    Icons.storage,
    Icons.my_library_add,
    Icons.my_library_books,
    Icons.list,

    // Additional Representational Icons
    Icons.article,
    Icons.topic,
    Icons.bookmark,
    Icons.label,
    Icons.turned_in,
    Icons.palette,

    // Device and Storage Icons
    Icons.sd_storage,
    Icons.cloud,
    Icons.cloud_circle,
    Icons.device_hub,

    // Miscellaneous
    Icons.view_module,
    Icons.view_list,
    Icons.dashboard,
    Icons.grid_view,
    Icons.apps,
  ];

  void _saveLibrary() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedTypes.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Select at-least one type",
            ),
          ),
        );
        return;
      }

      if (_folder.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Folder is required",
            ),
          ),
        );
        return;
      }

      _formKey.currentState!.save();

      try {
        await AppEngine.engine.pb.collection("library").create(body: {
          "title": _libraryName,
          "icon": _selectedIcon.codePoint.toString(),
          "types": _selectedTypes.map((item) {
            return item.toLowerCase();
          }).toList(),
          "user": AppEngine.engine.pb.authStore.record!.id,
          "config": _folder.map((item) => item.config ?? item.id).toList(),
          "connection": widget.item.id,
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Library "$_libraryName" created'),
            ),
          );

          widget.onCreated();
        }
      } catch (e) {
        if (mounted) {
          if (e is ClientException) {
            final data = e.response["data"] as Map<String, dynamic>?;

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    'Error ${data?.values.first?["message"] ?? e.response["message"]}'),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error ${e.toString()}')),
            );
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Create Library"),
        leading: GestureDetector(
          onTap: () {
            Navigator.of(context).pop();
          },
          child: const Icon(
            Icons.close,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          controller: widget.scrollController,
          padding: const EdgeInsets.all(16.0),
          children: [
            TextFormField(
              textCapitalization: TextCapitalization.sentences,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Library Name',
                hintText: 'Enter library name',
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a library name';
                }
                return null;
              },
              onSaved: (value) {
                _libraryName = value ?? "";
              },
            ),
            const SizedBox(height: 16),

            // Library Icon Selection
            Text(
              'Select Library Icon',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(
              height: 4,
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _availableIcons.map((icon) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: ChoiceChip(
                      label: Icon(icon),
                      visualDensity: VisualDensity.compact,
                      selected: _selectedIcon == icon,
                      onSelected: (bool selected) {
                        setState(() {
                          _selectedIcon = icon;
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 16),

            // Library Types Selection
            Text(
              'Select Content Types',
              style: Theme.of(context).textTheme.titleMedium,
            ),

            Wrap(
              spacing: 8.0,
              children: _libraryTypes.map((type) {
                return FilterChip(
                  label: Text(type),
                  selected: _selectedTypes.contains(type),
                  onSelected: (bool selected) {
                    setState(() {
                      if (selected) {
                        _selectedTypes.add(type);
                      } else {
                        _selectedTypes.remove(type);
                      }
                    });
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: 16),

            FolderSelector(
              item: widget.item,
              onFolderSelected: (item) {
                setState(() {
                  _folder = item;
                });
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SizedBox(
          width: double.infinity,
          child: FilledButton(
            style: OutlinedButton.styleFrom(),
            onPressed: () {
              _saveLibrary();
            },
            child: const Text("SAVE"),
          ),
        ),
      ),
    );
  }
}
