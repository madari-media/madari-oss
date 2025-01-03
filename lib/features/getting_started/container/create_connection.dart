import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:madari_client/features/connection/services/stremio_service.dart';
import 'package:madari_client/features/connection/types/stremio.dart';
import 'package:pocketbase/pocketbase.dart';

import '../../../engine/engine.dart';
import '../../settings/types/connection.dart';

class CreateConnectionStep extends StatefulWidget {
  final void Function(Connection connection) onConnectionComplete;

  const CreateConnectionStep({
    super.key,
    required this.onConnectionComplete,
  });

  @override
  State<CreateConnectionStep> createState() => _CreateConnectionStepState();
}

class _CreateConnectionStepState extends State<CreateConnectionStep> {
  final PocketBase pb = AppEngine.engine.pb;
  final _formKey = GlobalKey<FormState>();
  final _urlController = TextEditingController();
  final _nameController = TextEditingController(text: "Stremio Addons");
  Connection? _existingConnection;

  bool _isLoading = false;
  String? _errorMessage;

  final List<Map<String, dynamic>> _addons = [];

  @override
  void initState() {
    super.initState();

    loadExistingConnection();
  }

  loadExistingConnection() async {
    try {
      final existingConnection = await pb
          .collection("connection")
          .getFirstListItem("type.type = 'stremio_addons'");

      final connection = Connection.fromRecord(existingConnection);

      _nameController.text = connection.title;
      final config = connection.config;

      if (config['addons'] != null) {
        for (var url in config['addons']) {
          _validateAddonUrl(url);
        }
      }

      _existingConnection = connection;
    } catch (e) {
      if (e is! ClientException) {
        rethrow;
      }
    }
  }

  Future<void> _validateAddonUrl(String url) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final manifest = json.decode(response.body);

        final _manifest = StremioManifest.fromJson(manifest);

        if (manifest['name'] == null || manifest['id'] == null) {
          throw 'Invalid addon manifest';
        }

        if (_addons.any((addon) => addon['url'] == url)) {
          throw 'Addon already added to the list';
        }

        List<String> supportedTypes = [];

        _manifest.resources?.forEach((item) {
          supportedTypes.add(item.name);
        });

        setState(() {
          _addons.add({
            'name': _manifest.name,
            'icon': manifest['logo'] ?? manifest['icon'],
            'url': url,
            'addons': manifest,
            'types': supportedTypes,
          });
          _urlController.clear();
        });
      } else {
        throw 'Failed to fetch addon manifest';
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Invalid addon URL: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveConnection() async {
    if (!_formKey.currentState!.validate() || _addons.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final connectionType =
          await pb.collection("connection_type").getFirstListItem(
                "type = \"stremio_addons\"",
              );

      final body = {
        'title': _nameController.text,
        'user': pb.authStore.record!.id,
        'type': connectionType.id,
        'config': jsonEncode({
          'addons': _addons.map((item) => item['url']).toList(),
        }),
      };

      if (_existingConnection != null) {
        // Update existing connection
        await pb
            .collection('connection')
            .update(_existingConnection!.id, body: body);
      } else {
        // Create new connection
        final result = await pb.collection('connection').create(body: body);

        _existingConnection = Connection.fromRecord(result);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Connection saved successfully"),
          ),
        );
      }

      widget.onConnectionComplete(
        Connection(
          title: _nameController.text,
          id: _existingConnection!.id ?? '',
          config: jsonEncode({
            'addons': _addons.map((item) => item['url']).toList(),
          }),
          type: 'stremio_addons',
        ),
      );
    } catch (e) {
      setState(() {
        _errorMessage = "Error: ${e.toString()}";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  final Map<String, String> _items = {
    "Cinemeta": "https://v3-cinemeta.strem.io/manifest.json",
    "Watchhub": "https://watchhub.strem.io/manifest.json",
  };

  void _removeAddon(int index) {
    setState(() {
      _addons.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize:
                MainAxisSize.min, // Add this to shrink-wrap the Column
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Connection Name',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a connection name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
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
              const SizedBox(height: 12),
              SizedBox(
                height: 36,
                child: ListView.builder(
                  itemCount: _items.length,
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (context, index) {
                    return Container(
                      margin: const EdgeInsets.only(right: 4),
                      child: ActionChip(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        label: Text(_items.keys.toList()[index]),
                        avatar: const Icon(Icons.add),
                        onPressed: () {
                          _validateAddonUrl(_items.values.toList()[index]);
                        },
                      ),
                    );
                  },
                ),
              ),
              if (_isLoading) const Center(child: CircularProgressIndicator()),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              const SizedBox(height: 20),
              if (_addons.isNotEmpty) ...[
                const Text(
                  'Added Addons:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Flexible(
                  fit: FlexFit.loose,
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _addons.length,
                    itemBuilder: (context, index) {
                      final addon = _addons[index];
                      final name = utf8.decode(
                        (addon['name'] ?? 'Unknown Addon').runes.toList(),
                      );

                      return Card(
                        margin: EdgeInsets.only(
                          bottom: index + 1 != _addons.length ? 10 : 0,
                        ),
                        child: ListTile(
                          leading: addon['icon'] != null
                              ? Image.network(
                                  addon['icon'],
                                  width: 40,
                                  height: 40,
                                  errorBuilder: (_, __, ___) =>
                                      const Icon(Icons.extension),
                                )
                              : const Icon(Icons.extension, size: 40),
                          title: Text(
                            name,
                            maxLines: 1,
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                addon['url'],
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(
                                height: 4,
                              ),
                              SizedBox(
                                height: 40,
                                child: ListView(
                                  scrollDirection: Axis.horizontal,
                                  children: [
                                    for (int i = 0;
                                        i < addon['types'].length;
                                        i++)
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(right: 4),
                                        child: RawChip(
                                          padding: EdgeInsets.zero,
                                          label: Text(
                                            (addon['types'][i] as String)
                                                .capitalize(),
                                          ),
                                          visualDensity: VisualDensity.compact,
                                        ),
                                      ),
                                  ],
                                ),
                              )
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.remove_circle_outline,
                                color: Colors.red),
                            onPressed: () => _removeAddon(index),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(
                    bottom: 10.0,
                  ),
                  child: ElevatedButton(
                    onPressed: _addons.isEmpty ? null : _saveConnection,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white70,
                      foregroundColor: Colors.black,
                    ),
                    child: Text(
                      'Next',
                      style: GoogleFonts.exo2().copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                )
              ],
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _urlController.dispose();
    _nameController.dispose();
    super.dispose();
  }
}
