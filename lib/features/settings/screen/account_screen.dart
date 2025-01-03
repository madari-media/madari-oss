import 'package:flutter/material.dart';
import 'package:madari_client/features/settings/screen/profile_button.dart';

import '../../../engine/engine.dart';
import '../navigation/account_navigation.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  Widget _buildDivider() {
    return const Divider(height: 1, thickness: 1);
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    );
  }

  AppEngine get engine => AppEngine.engine;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('My Account'),
        elevation: 0,
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(
            maxWidth: 600,
          ),
          child: ListView(
            children: [
              ProfileButton(),
              _buildDivider(),
              _buildSectionHeader('ACCOUNT SETTINGS'),
              ListTile(
                leading: const Icon(Icons.email),
                title: const Text('Email Settings'),
                subtitle: const Text('Manage your email preferences'),
                onTap: () => AccountNavigation.navigateToEmailSettings(context),
              ),
              _buildDivider(),
              ListTile(
                leading: const Icon(Icons.security),
                title: const Text('Security'),
                subtitle: const Text('Password and security settings'),
                onTap: () => AccountNavigation.navigateToSecurity(context),
              ),
              _buildDivider(),
              ListTile(
                leading: const Icon(Icons.notifications),
                title: const Text('Notifications'),
                subtitle: const Text('Manage notification preferences'),
                onTap: () => AccountNavigation.navigateToNotifications(context),
              ),
              // _buildSectionHeader('PAYMENT'),
              // ListTile(
              //   leading: const Icon(Icons.payment),
              //   title: const Text('Payment Methods'),
              //   subtitle: const Text('Manage your payment options'),
              //   onTap: () => AccountNavigation.navigateToPayments(context),
              // ),
              // _buildSectionHeader('SUPPORT'),
              // ListTile(
              //   leading: const Icon(Icons.help),
              //   title: const Text('Help Center'),
              //   subtitle: const Text('Get help and contact support'),
              //   onTap: () => AccountNavigation.navigateToHelp(context),
              // ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
