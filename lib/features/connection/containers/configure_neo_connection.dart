import 'package:flutter/material.dart';
import 'package:madari_client/engine/connection_type.dart';

class ConfigureNeoConnection extends StatefulWidget {
  final ConnectionTypeRecord item;
  final void Function(String id) onConnectionComplete;

  const ConfigureNeoConnection({
    super.key,
    required this.item,
    required this.onConnectionComplete,
  });

  @override
  State<ConfigureNeoConnection> createState() => _ConfigureNeoConnectionState();
}

class _ConfigureNeoConnectionState extends State<ConfigureNeoConnection> {
  final _formKey = GlobalKey<FormState>();
  final _urlController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _urlController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _saveConnection() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Connection saved successfully'),
          backgroundColor: Colors.green,
        ),
      );

      // widget.onConnectionComplete("");
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving connection: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _urlController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Server URL',
                prefixIcon: Icon(Icons.sensors_rounded),
                hintText: 'https://neo.example.com',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.url,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter server URL';
                }
                if (!(Uri.tryParse(value)?.hasAuthority ?? true)) {
                  return 'Please enter a valid URL';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter email';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter password';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _saveConnection,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save Connection'),
            ),
          ],
        ),
      ),
    );
  }
}
