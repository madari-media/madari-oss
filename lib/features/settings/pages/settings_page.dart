import 'package:cached_query_flutter/cached_query_flutter.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:madari_client/features/pocketbase/service/pocketbase.service.dart';
import 'package:madari_client/features/settings/pages/settings/profile_selector.dart';
import 'package:madari_client/features/settings/service/selected_profile.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 600;

    final settingsCategories = [
      _SettingsCategory(
        title: 'Account',
        items: [
          const _SettingsItem(
            title: 'My Account',
            icon: Icons.person,
            path: '/settings/profile',
            description: 'Account settings and preferences',
          ),
          const _SettingsItem(
            title: 'Profiles',
            icon: Icons.group,
            path: '/settings/subprofiles',
            description: 'Manage your profiles',
          ),
          const _SettingsItem(
            title: 'Theme',
            icon: Icons.dark_mode,
            path: '/settings/appearance',
            description: 'Modify application theme',
          ),
          _SettingsItem(
            title: 'Logout',
            icon: Icons.logout,
            onClick: () {
              CachedQuery.instance.deleteCache(
                deleteStorage: true,
              );
              AppPocketBaseService.instance.pb.authStore.clear();
              SelectedProfileService.instance.setSelectedProfile(null);
              context.go("/signin");
            },
          ),
        ],
      ),
      const _SettingsCategory(
        title: "Layout",
        items: [
          _SettingsItem(
            title: "Home Layout",
            icon: Icons.layers_outlined,
            path: "/layout",
            description: "Customize your home page",
          ),
        ],
      ),
      const _SettingsCategory(
        title: "Connections",
        items: [
          _SettingsItem(
            title: 'Addons',
            icon: Icons.extension_rounded,
            path: '/settings/stremio',
            description: 'Configure external Addons',
          ),
          _SettingsItem(
            title: 'External Accounts',
            icon: Icons.supervisor_account_sharp,
            path: '/settings/external-account',
            description: 'Configure accounts integration',
          ),
        ],
      ),
      const _SettingsCategory(
        title: 'Preferences',
        items: [
          _SettingsItem(
            title: 'Playback',
            icon: Icons.play_circle,
            path: '/settings/playback',
            description: 'Configure playback settings',
          ),
        ],
      ),
      _SettingsCategory(
        title: 'System',
        items: [
          const _SettingsItem(
            title: 'Debug',
            icon: Icons.bug_report,
            path: '/settings/debug',
            description: 'Debug options and logs',
          ),
          const _SettingsItem(
            title: 'Offline Ratings',
            icon: Icons.offline_bolt,
            path: '/settings/offline-ratings',
            description: 'Configure offline ratings',
          ),
          _SettingsItem(
            title: 'About US',
            icon: Icons.perm_identity,
            description: 'About US',
            onClick: () {
              showAboutDialog(
                context: context,
                applicationIcon: const Image(
                  width: 28,
                  image: AssetImage("assets/icon/icon_mini.png"),
                ),
                children: [
                  const Text("Powered by TMDB"),
                  const Image(
                    image: NetworkImage(
                      "https://upload.wikimedia.org/wikipedia/commons/6/6e/Tmdb-312x276-logo.png",
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    ];

    if (isCompact) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Settings'),
          elevation: 0,
          backgroundColor: colorScheme.surface,
        ),
        body: ListView(
          children: [
            const ProfileSelector(),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: settingsCategories.length,
              itemBuilder: (context, categoryIndex) {
                final category = settingsCategories[categoryIndex];

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                      child: Text(
                        category.title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    ...category.items.map((item) => ListTile(
                          leading: Icon(item.icon),
                          title: Text(item.title),
                          subtitle: item.description != null
                              ? Text(
                                  item.description!,
                                  style: theme.textTheme.bodySmall,
                                )
                              : null,
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            if (item.path != null) context.push(item.path!);
                            if (item.onClick != null) item.onClick!();
                          },
                        )),
                    if (categoryIndex < settingsCategories.length - 1)
                      const Divider(height: 32),
                  ],
                );
              },
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            itemCount: settingsCategories.length,
            itemBuilder: (context, categoryIndex) {
              final category = settingsCategories[categoryIndex];

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 8, bottom: 8),
                    child: Text(
                      category.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: theme.dividerColor,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        for (int i = 0; i < category.items.length; i++) ...[
                          if (i > 0) const Divider(height: 1),
                          ListTile(
                            leading: Icon(category.items[i].icon),
                            title: Text(category.items[i].title),
                            subtitle: category.items[i].description != null
                                ? Text(
                                    category.items[i].description!,
                                    style: theme.textTheme.bodySmall,
                                  )
                                : null,
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              final item = category.items[i];

                              if (item.path != null) context.push(item.path!);
                              if (item.onClick != null) item.onClick!();
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _SettingsCategory {
  final String title;
  final List<_SettingsItem> items;

  const _SettingsCategory({
    required this.title,
    required this.items,
  });
}

class _SettingsItem {
  final String title;
  final IconData icon;
  final String? path;
  final String? description;
  final VoidCallback? onClick;

  const _SettingsItem({
    required this.title,
    required this.icon,
    this.path,
    this.description,
    this.onClick,
  });
}
