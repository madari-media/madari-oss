import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:madari_client/engine/connection_type.dart';
import 'package:pocketbase/pocketbase.dart';

import '../../../engine/engine.dart';
import '../../settings/types/connection.dart';

class StremioAddonConnection extends StatefulWidget {
  final void Function(Connection connection) onConnectionComplete;
  final ConnectionTypeRecord item;

  const StremioAddonConnection({
    super.key,
    required this.onConnectionComplete,
    required this.item,
  });

  @override
  State<StremioAddonConnection> createState() => _StremioAddonConnectionState();
}

class _StremioAddonConnectionState extends State<StremioAddonConnection> {
  final PocketBase pb = AppEngine.engine.pb;
  final _formKey = GlobalKey<FormState>();
  final _urlController = TextEditingController();
  final _nameController = TextEditingController(text: "Stremio");

  static const String cinemetaURL =
      'https://v3-cinemeta.strem.io/manifest.json';

  bool _isLoading = false;
  String? _errorMessage;

  final List<Map<String, dynamic>> _addons = [];

  Future<void> _validateAddonUrl(String url) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final manifest = json.decode(response.body);

        if (manifest['name'] == null || manifest['id'] == null) {
          throw 'Invalid addon manifest';
        }

        if (_addons.any((addon) => addon['url'] == url)) {
          throw 'Addon already added to the list';
        }

        setState(() {
          _addons.add({
            'name': manifest['name'],
            'icon': manifest['logo'] ?? manifest['icon'],
            'url': url,
          });
          _urlController.clear();
        });
      } else {
        throw 'Failed to fetch addon manifest';
      }
    } catch (e) {
      if (e is FormatException) {
        setState(() {
          _errorMessage = 'Invalid addon URL';
        });
      } else {
        setState(() {
          _errorMessage = 'Invalid addon URL: ${e.toString()}';
        });
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveAddons() async {
    if (!_formKey.currentState!.validate() || _addons.isEmpty) return;

    try {
      setState(() => _isLoading = true);

      final body = await pb.collection('connection').create(body: {
        'title': _nameController.text,
        'user': pb.authStore.record!.id,
        'type': widget.item.id,
        'config': {
          'addons': _addons
              .map(
                (item) => item["url"],
              )
              .toList()
        },
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Saved successfully"),
          ),
        );
      }

      widget.onConnectionComplete(
        Connection(
          title: body.getStringValue("title"),
          id: body.id,
          config: jsonEncode({
            'addons': _addons
                .map(
                  (item) => item["url"],
                )
                .toList()
          }),
          type: "stremio_addons",
        ),
      );
    } catch (e) {
      if (e is ClientException) {
        final response = e.response["data"];

        final result = response.values.map((item) => item["message"]).join(" ");

        setState(() {
          if (kDebugMode) print(result);
          _errorMessage = "Error: $result";
        });

        return;
      }

      setState(() {
        _errorMessage = "Error: ${e.toString()}";
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _removeAddon(int index) {
    setState(() {
      _addons.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 16.0,
        right: 16.0,
        bottom: 16.0,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Connection name',
              ),
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  return null;
                }
                return "Connection name is required";
              },
            ),
            const SizedBox(
              height: 12,
            ),
            TextFormField(
              controller: _urlController,
              decoration: InputDecoration(
                labelText: 'Addon URL',
                hintText: 'https://example.com/manifest.json',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => _validateAddonUrl(_urlController.text),
                ),
              ),
              validator: (value) {
                if (_addons.isEmpty) {
                  return 'Please add at least one addon';
                }
                if (value != null && value.isNotEmpty) {
                  try {
                    final uri = Uri.parse(value);
                    if (!uri.isScheme('http') && !uri.isScheme('https')) {
                      return 'Please enter a valid HTTP/HTTPS URL';
                    }
                  } catch (e) {
                    return 'Please enter a valid URL';
                  }
                }
                return null;
              },
            ),
            if (_isLoading) const Center(child: CircularProgressIndicator()),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(
                  top: 8.0,
                ),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            const SizedBox(
              height: 12,
            ),
            Text(
              'Suggested Addons:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(
              height: 6,
            ),
            Row(
              children: [
                ActionChip.elevated(
                  label: const Text("Cinemeta"),
                  onPressed: () {
                    _validateAddonUrl(cinemetaURL);
                  },
                  avatar: const Icon(Icons.extension),
                )
              ],
            ),
            if (_addons.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Added Addons:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(
                height: 6,
              ),
              ListView.builder(
                shrinkWrap: true,
                itemCount: _addons.length,
                itemBuilder: (context, index) {
                  final addon = _addons[index];
                  return Container(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Card(
                      margin: EdgeInsets.zero,
                      child: ListTile(
                        leading: addon['icon'] != null
                            ? Image.network(
                                addon['icon'],
                                width: 40,
                                height: 40,
                                errorBuilder: (_, __, ___) =>
                                    const Icon(Icons.extension),
                              )
                            : const Icon(
                                Icons.extension,
                                size: 40,
                              ),
                        title: Text(addon['name']),
                        subtitle: Text(
                          addon['url'],
                          maxLines: 1,
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: () => _removeAddon(index),
                          color: Colors.red,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _addons.isNotEmpty && !_isLoading ? _saveAddons : null,
              child: const Text('Save Configuration'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }
}
