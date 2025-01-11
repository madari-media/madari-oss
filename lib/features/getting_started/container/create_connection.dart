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
  final _nameController = TextEditingController(
    text: "Stremio Addons",
  );
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
      final existingConnection =
          await pb.collection("connection").getFirstListItem(
                "type.type = 'stremio_addons'",
              );

      final connection = Connection.fromRecord(existingConnection);

      _nameController.text = connection.title;
      final config = connection.config;

      if (config['addons'] != null) {
        for (var url in config['addons']) {
          try {
            await _validateAddonUrl(url);
          } catch (e) {
            print("Failed to load addon");
          }
        }
      }

      _existingConnection = connection;
    } catch (e) {
      if (e is! ClientException) {
        rethrow;
      }
    }
  }

  Future<void> _validateAddonUrl(String url_) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final url = url_.replaceFirst("stremio://", "https://");

    try {
      final response = await http.get(
        Uri.parse(
          url.replaceFirst("stremio://", "https://"),
        ),
      );
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
            'manifestParsed': _manifest,
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

  Future<bool> showAddonWarningDialog(
    BuildContext context, {
    required bool isMeta,
    required bool isAddon,
  }) async {
    bool continueAnyway = false;

    if (isMeta && isAddon) {
      return true;
    }

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Warning!'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isMeta || !isAddon)
                const Text(
                  'You are missing the following addons:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              const SizedBox(
                height: 4,
              ),
              if (!isMeta) const Text('🔴 Meta Addon'),
              if (!isAddon) const Text('🔴 Streaming Addon'),
              const SizedBox(height: 10),
              const Text(
                'Continuing without these addons may limit functionality. Are you sure you want to proceed?',
                style: TextStyle(color: Colors.red),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                // User chooses to continue anyway
                Navigator.of(context).pop();
                continueAnyway = true;
              },
              child: const Text('CONTINUE ANYWAY'),
            ),
            ElevatedButton(
              onPressed: () {
                // User chooses to add addon
                Navigator.of(context).pop();
                continueAnyway = false;
              },
              child: const Text('ADD ADDON'),
            ),
          ],
        );
      },
    );

    return continueAnyway;
  }

  Future<void> _saveConnection() async {
    if (!_formKey.currentState!.validate() || _addons.isEmpty) return;

    bool hasMeta = false;
    bool hasStream = false;

    for (final item in _addons) {
      final manifest = item['manifestParsed'] as StremioManifest;

      if (manifest.resources == null) {
        continue;
      }

      for (final resource in manifest.resources!) {
        if (resource.name == "meta") {
          hasMeta = true;
        }

        if (resource.name == "stream") {
          hasStream = true;
        }
      }
    }

    final result = await showAddonWarningDialog(
      context,
      isAddon: hasStream,
      isMeta: hasMeta,
    );

    if (!result) {
      return;
    }

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
    "Subtitles": "https://opensubtitles-v3.strem.io/manifest.json",
  };

  void _removeAddon(int index) {
    setState(() {
      _addons.removeAt(index);
    });
  }

  void _reorderAddon(int oldIndex, int newIndex) {
    setState(() {
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      final item = _addons.removeAt(oldIndex);
      _addons.insert(newIndex, item);
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
              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: CircularProgressIndicator(),
                  ),
                ),
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
                  child: ReorderableListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _addons.length,
                    onReorder: _reorderAddon,
                    itemBuilder: (context, index) {
                      final addon = _addons[index];
                      final name = utf8.decode(
                        (addon['name'] ?? 'Unknown Addon').runes.toList(),
                      );

                      return Card(
                        key: Key('$index'),
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
              ],
              Padding(
                padding: const EdgeInsets.only(
                  bottom: 12.0,
                  top: 12.0,
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
              ),
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
