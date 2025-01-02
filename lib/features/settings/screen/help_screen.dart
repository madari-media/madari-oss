import 'package:flutter/material.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help Center'),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.article),
            title: const Text('FAQs'),
            onTap: () {
              // Navigate to FAQs
            },
          ),
          ListTile(
            leading: const Icon(Icons.chat),
            title: const Text('Contact Support'),
            onTap: () {
              // Open chat support
            },
          ),
          ListTile(
            leading: const Icon(Icons.email),
            title: const Text('Email Support'),
            onTap: () {
              // Open email support
            },
          ),
          ListTile(
            leading: const Icon(Icons.phone),
            title: const Text('Call Support'),
            onTap: () {
              // Make support call
            },
          ),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Support Hours:\nMonday - Friday: 9:00 AM - 5:00 PM\nWeekends: 10:00 AM - 3:00 PM',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}
