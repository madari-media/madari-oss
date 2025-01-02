import 'package:flutter/material.dart';

class EmailSettingsScreen extends StatefulWidget {
  const EmailSettingsScreen({super.key});

  @override
  State<EmailSettingsScreen> createState() => _EmailSettingsScreenState();
}

class _EmailSettingsScreenState extends State<EmailSettingsScreen> {
  bool marketingEmails = true;
  bool newsLetters = true;
  bool accountAlerts = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Email Settings'),
      ),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Marketing Emails'),
            subtitle: const Text('Receive promotional offers and updates'),
            value: marketingEmails,
            onChanged: (bool value) {
              setState(() {
                marketingEmails = value;
              });
            },
          ),
          SwitchListTile(
            title: const Text('Newsletters'),
            subtitle: const Text('Receive weekly newsletters'),
            value: newsLetters,
            onChanged: (bool value) {
              setState(() {
                newsLetters = value;
              });
            },
          ),
          SwitchListTile(
            title: const Text('Account Alerts'),
            subtitle: const Text('Receive important account notifications'),
            value: accountAlerts,
            onChanged: (bool value) {
              setState(() {
                accountAlerts = value;
              });
            },
          ),
        ],
      ),
    );
  }
}
