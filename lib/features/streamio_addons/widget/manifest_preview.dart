import 'package:flutter/material.dart';

import '../models/stremio_base_types.dart';

class ManifestPreview extends StatelessWidget {
  final StremioManifest manifest;
  final VoidCallback onInstall;
  final bool isLoading;
  final String? error;

  const ManifestPreview({
    required this.manifest,
    required this.onInstall,
    required this.isLoading,
    this.error,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final resources = manifest.resources
            ?.map((r) => r.name)
            .where((r) => ['catalog', 'meta', 'stream'].contains(r))
            .toList() ??
        [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (manifest.logo != null)
          Center(
            child: Image.network(
              manifest.logo!,
              height: 120,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.extension, size: 80),
            ),
          ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  manifest.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (manifest.description != null) ...[
                  const SizedBox(height: 8),
                  Text(manifest.description!),
                ],
                const SizedBox(height: 16),
                const Text(
                  'Supported Features',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: resources
                      .map((r) => Chip(
                            label: Text(r),
                            backgroundColor: _getResourceColor(r),
                          ))
                      .toList(),
                ),
                if (manifest.types?.isNotEmpty == true) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Content Types',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: manifest.types!
                        .map((t) => Chip(
                              label: Text(t),
                            ))
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (error != null)
          Text(
            error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: isLoading ? null : onInstall,
            icon: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.add),
            label: const Text('Install Addon'),
          ),
        ),
      ],
    );
  }

  Color _getResourceColor(String resource) {
    switch (resource) {
      case 'catalog':
        return Colors.blue.withOpacity(0.2);
      case 'meta':
        return Colors.green.withOpacity(0.2);
      case 'stream':
        return Colors.orange.withOpacity(0.2);
      default:
        return Colors.grey.withOpacity(0.2);
    }
  }
}
