import 'package:flutter/material.dart';

class PaymentScreen extends StatelessWidget {
  const PaymentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Methods'),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.add_circle_outline),
            title: const Text('Add Payment Method'),
            onTap: () {
              // Implement add payment method logic
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.credit_card),
            title: const Text('•••• •••• •••• 1234'),
            subtitle: const Text('Expires 12/24'),
            trailing: IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () {
                // Show card options
              },
            ),
          ),
          ListTile(
            leading: const Icon(Icons.payment),
            title: const Text('PayPal'),
            subtitle: const Text('john.doe@example.com'),
            trailing: IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () {
                // Show PayPal options
              },
            ),
          ),
        ],
      ),
    );
  }
}
