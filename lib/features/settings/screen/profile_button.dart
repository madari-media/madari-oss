import 'package:flutter/material.dart';
import 'package:madari_client/engine/engine.dart';

import '../navigation/account_navigation.dart';

class ProfileButton extends StatelessWidget {
  final engine = AppEngine.engine;

  ProfileButton({super.key});

  @override
  Widget build(BuildContext context) {
    final record = engine.pb.authStore.record;

    final name = record?.getStringValue("name") ?? "";
    final email = record?.getStringValue("email") ?? "";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          leading: const CircleAvatar(
            child: Icon(Icons.person),
          ),
          title: Text("$name ($email)"),
          subtitle: const Text('View and edit profile'),
          onTap: () => AccountNavigation.navigateToProfile(context),
        )
      ],
    );
  }
}
