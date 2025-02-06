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
      body: const SettingWrapper(
        child: ServicesGrid(),
      ),
    );
  }
}
