import 'package:flutter/material.dart';
import 'package:madari_client/features/accounts/container/trakt.container.dart';

import '../../settings/widget/setting_wrapper.dart';

class ExternalAccount extends StatelessWidget {
  const ExternalAccount({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("External Accounts"),
      ),
      body: SettingWrapper(
        child: ListView(
          children: [
            _buildSection(
              "Trakt",
              [
                const TraktContainer(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}
