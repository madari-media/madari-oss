import 'package:cached_query_flutter/cached_query_flutter.dart';
import 'package:flutter/material.dart';
import 'package:madari_client/features/streamio_addons/extension/query_extension.dart';
import 'package:madari_engine/madari_engine.dart';
import 'package:pocketbase/pocketbase.dart';

import '../service/stremio_addon_service.dart';

class AddAddonSheet extends StatefulWidget {
  final VoidCallback onRefetch;

  const AddAddonSheet({
    super.key,
    required this.onRefetch,
  });

  @override
  State<AddAddonSheet> createState() => _AddAddonSheetState();
}

class _AddAddonSheetState extends State<AddAddonSheet> {
  final _urlController = TextEditingController();
  Query<StremioManifest>? _validateQuery;
  bool _isInstalling = false;

  final _exampleAddons = {
    "Madari Catalog": "https://catalog.madari.media/manifest.json",
    "Watchhub": "https://watchhub.strem.io/manifest.json",
    "Subtitles": "https://opensubtitles-v3.strem.io/manifest.json",
  };

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  void _validateManifest([String? url]) async {
    final manifestUrl = (url ?? _urlController.text).replaceFirst(
      "stremio://",
      "https://",
    );

    if (manifestUrl.isEmpty) return;

    setState(() {
      _isInstalling = true;
    });

    final query = await StremioAddonService.instance
        .validateManifest(
          manifestUrl.trim(),
        )
        .queryFn();

    await _installAddon(query);

    setState(() {
      _isInstalling = false;
    });
  }

  Future<void> _handleExampleAddonTap(String name, String url) async {
    final query = StremioAddonService.instance.validateManifest(url);

    final manifest = await query.queryFn();
    if (!mounted) return;

    await _installAddon(manifest);
  }

  Future<void> _installAddon(StremioManifest manifest) async {
    setState(() => _isInstalling = true);

    try {
      await StremioAddonService.instance.saveAddon(manifest);
      widget.onRefetch();

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      print(e);
      if (mounted) {
        if (e is ClientException) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to install addon: ${e.response}')),
          );
          return;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to install addon: ${e}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isInstalling = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.8,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              child: Row(
                children: [
                  const Text(
                    'Add Stremio Addon',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  TextField(
                    controller: _urlController,
                    decoration: const InputDecoration(
                      labelText: 'Manifest URL',
                      hintText: 'Enter manifest URL',
                    ),
                    onSubmitted: (_) => _validateManifest(),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => _validateManifest(),
                    icon: const Icon(Icons.check),
                    label: _isInstalling
                        ? const Text("Installing")
                        : const Text('Install'),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Popular Addons',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _exampleAddons.entries
                        .map((entry) => ActionChip(
                              label: Text(entry.key),
                              avatar: const Icon(Icons.add, size: 18),
                              onPressed: () => _handleExampleAddonTap(
                                entry.key,
                                entry.value,
                              ),
                            ))
                        .toList(),
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
