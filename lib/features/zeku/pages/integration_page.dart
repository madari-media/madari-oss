import 'package:flutter/material.dart';

class IntegrationPage extends StatelessWidget {
  const IntegrationPage({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Integrations"),
      ),
      body: ListView(
        children: [
          TextButton(
            onPressed: () {},
            child: const Text("Choose account"),
          ),
        ],
      ),
    );
  }
}
