import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:madari_client/engine/library.dart';
import 'package:madari_client/features/connection/services/stremio_service.dart';

import '../../../engine/engine.dart';
import '../../settings/types/connection.dart';

class AutoImport extends StatefulWidget {
  final Connection item;
  final VoidCallback? onImport;

  const AutoImport({
    super.key,
    required this.item,
    this.onImport,
  });

  @override
  State<AutoImport> createState() => _AutoImportState();
}

class _AutoImportState extends State<AutoImport> {
  late StremioService _stremio;
  final List<FolderItem> _selected = [];
  bool _isLoading = false;

  Future<List<FolderItem>>? _folders;

  @override
  void initState() {
    super.initState();

    initialValueImport();
  }

  void initialValueImport() {
    if ("stremio_addons" == widget.item.type) {
      _stremio = StremioService(
        connectionId: Future.delayed(
          Duration.zero,
          () => widget.item.id,
        ),
        config: widget.item.config!,
      );

      _folders = _stremio.getFolders();
    }
  }

  void createLibraryInBulk() async {
    setState(() {
      _isLoading = true;
    });

    int loaded = 0;
    for (var item in _selected) {
      try {
        await AppEngine.engine.pb.collection("library").create(body: {
          "title": item.title,
          "icon": Icons.video_library.codePoint.toString(),
          "types": ["video"],
          "user": AppEngine.engine.pb.authStore.record!.id,
          "config": [item.config ?? item.id],
          "connection": widget.item.id,
        });

        loaded += 1;
      } catch (e, stack) {
        if (kDebugMode) print("Failed to $e");
        if (kDebugMode) print(stack);
      }
    }

    if (context.mounted && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Imported Libraries $loaded failed ${_selected.length - loaded}",
          ),
        ),
      );

      setState(() {
        _isLoading = false;
      });

      if (widget.onImport != null) widget.onImport!();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text("Import Libraries"),
        backgroundColor: Colors.transparent,
        actions: [
          ElevatedButton.icon(
            onPressed: _selected.isNotEmpty
                ? () {
                    createLibraryInBulk();
                  }
                : null,
            label: const Text("Import"),
            icon: _isLoading
                ? const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(),
                  )
                : const Icon(Icons.save),
          ),
          const SizedBox(
            width: 6,
          ),
        ],
      ),
      body: FutureBuilder(
        future: _folders,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Text("Error: ${snapshot.error}");
          }

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          return ListView.builder(
            itemCount: snapshot.data?.length ?? 0,
            itemBuilder: (item, index) {
              final item = snapshot.data![index];

              final selected =
                  _selected.where((selected) => selected.id == item.id);

              return ListTile(
                onTap: () {
                  setState(() {
                    if (selected.isEmpty) {
                      _selected.add(item);
                    } else {
                      _selected.remove(item);
                    }
                  });
                },
                leading: selected.isNotEmpty
                    ? const Icon(Icons.check)
                    : const Icon(Icons.check_box_outline_blank),
                title: Text(item.title),
              );
            },
          );
        },
      ),
    );
  }
}

class AutoImportData {
  final String id;
  final String title;

  AutoImportData({
    required this.id,
    required this.title,
  });
}
