import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:madari_client/engine/engine.dart';
import 'package:madari_client/features/settings/screen/trakt_integration_screen.dart';
import 'package:madari_client/features/watch_history/service/zeee_watch_history.dart';
import 'package:madari_client/pages/sign_in.page.dart';

import '../features/settings/screen/account_screen.dart';
import '../features/settings/screen/connection_screen.dart';
import '../features/settings/screen/playback_settings_screen.dart';
import '../features/settings/screen/profile_button.dart';

class MoreContainer extends StatelessWidget {
  const MoreContainer({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(
          maxWidth: 600,
        ),
        child: ListView(
          children: [
            AppBar(
              title: const Text(
                "My Account",
              ),
            ),
            ProfileButton(),
            _buildListHeader('Account'),
            _buildListItem(
              context,
              icon: Icons.person_outline,
              title: 'My Account',
              subtitle: 'Manage your profile and preferences',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const AccountScreen(),
                ),
              ),
            ),
            _buildListItem(
              context,
              icon: Icons.people_outline,
              title: 'My Connections',
              subtitle: 'Manage your connected accounts',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ConnectionsScreen(),
                ),
              ),
            ),
            _buildListHeader('Settings'),
            _buildListItem(
              context,
              icon: Icons.play_circle_outline,
              title: 'Playback Settings',
              subtitle: 'Configure your playback preferences',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const PlaybackSettingsScreen(),
                ),
              ),
            ),
            _buildListItem(
              context,
              icon: Icons.connect_without_contact,
              title: "Trakt",
              subtitle: "Configure your Trakt account with Madari",
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const TraktIntegration(),
                ),
              ),
            ),
            _buildListItem(
              context,
              icon: Icons.logout,
              title: "Logout",
              onTap: () async {
                AppEngine.engine.pb.authStore.clear();
                await ZeeeWatchHistoryStatic.service?.clear();

                if (context.mounted) {
                  context.go(SignInPage.routeName);
                }
              },
              hideTrailing: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildListItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    bool hideTrailing = false,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: const TextStyle(fontSize: 12),
            )
          : null,
      trailing: hideTrailing ? null : const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
