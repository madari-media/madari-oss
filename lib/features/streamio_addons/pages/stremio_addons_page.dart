import 'package:flutter/material.dart';
import 'package:madari_engine/madari_engine.dart';

import '../../settings/widget/setting_wrapper.dart';
import '../service/stremio_addon_service.dart';
import '../widget/add_addon_sheet.dart';
import '../widget/stremio_addons_list.dart';

class StremioAddonsPage extends StatefulWidget {
  final bool showHidden;
  const StremioAddonsPage({
    super.key,
    this.showHidden = false,
  });

  @override
  State<StremioAddonsPage> createState() => _StremioAddonsPageState();
}

class _StremioAddonsPageState extends State<StremioAddonsPage> {
  late final query = StremioAddonService.instance.getInstalledAddons(
    enabledOnly: widget.showHidden != true,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stremio Addons'),
        actions: [
          if (!widget.showHidden)
            ElevatedButton.icon(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  builder: (context) {
                    return const StremioAddonsPage(
                      showHidden: true,
                    );
                  },
                );
              },
              icon: const Icon(
                Icons.hide_image,
              ),
              label: const Text("Show disabled addons"),
            ),
        ],
      ),
      body: SettingWrapper(
        child: StremioAddonsList(
          query: query,
          showHidden: widget.showHidden,
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddAddonSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Addon'),
      ),
    );
  }

  void _showAddAddonSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => AddAddonSheet(onRefetch: () {
        query.refetch();
      }),
    );
  }
}

class ManageAddonDialog extends StatelessWidget {
  final StremioManifest addon;
  final bool showHidden;

  const ManageAddonDialog({
    required this.addon,
    super.key,
    required this.showHidden,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                addon.name,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              if (addon.description != null) ...[
                const SizedBox(height: 8),
                Text(addon.description!),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _disableAddon(context),
                  icon: const Icon(Icons.update_disabled),
                  label: const Text('Enable Addon'),
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _removeAddon(context),
                  icon: const Icon(Icons.delete),
                  label: const Text('Remove Addon'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _disableAddon(BuildContext context) async {
    try {
      if (addon.manifestUrl == null) {
        throw Exception('Addon manifest URL is null');
      }

      await StremioAddonService.instance.toggleAddonState(
        addon.manifestUrl!,
        showHidden == true,
      );

      if (context.mounted) {
        Navigator.of(context).pop();
      }

      StremioAddonService.instance.getInstalledAddons().refetch();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to disable addon: $e')),
        );
      }
    }
  }

  Future<void> _removeAddon(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Addon'),
        content: Text('Are you sure you want to remove ${addon.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      try {
        if (context.mounted) {
          Navigator.of(context).pop();
        }
        await StremioAddonService.instance.removeAddon(addon.manifestUrl!);
        StremioAddonService.instance.getInstalledAddons().refetch();
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to remove addon: $e')),
          );
        }
      }
    }
  }
}

class AddonListTile extends StatelessWidget {
  final StremioManifest addon;

  const AddonListTile({
    required this.addon,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        leading: addon.logo != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  addon.logo!,
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.extension, size: 48),
                ),
              )
            : const Icon(Icons.extension, size: 48),
        title: Text(addon.name),
        subtitle: addon.description != null
            ? Text(
                addon.description!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              )
            : null,
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
