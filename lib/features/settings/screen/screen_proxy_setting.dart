import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:madari_client/engine/engine.dart';
import 'package:pocketbase/pocketbase.dart';

class ScreenProxySetting extends StatefulWidget {
  const ScreenProxySetting({super.key});

  @override
  State<ScreenProxySetting> createState() => _ScreenProxySettingState();
}

class _ScreenProxySettingState extends State<ScreenProxySetting> {
  final PocketBase pb = AppEngine.engine.pb;

  late Future<ResultList<RecordModel>> _collectionItems;

  RecordService get collection => pb.collection("proxy_setting");

  @override
  void initState() {
    super.initState();
    _collectionItems = collection.getList();
  }

  void _showAddProxySheet(BuildContext context) {
    final nameController = TextEditingController();
    final urlController = TextEditingController();
    final passwordController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        builder: (BuildContext context, ScrollController scrollController) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 16,
              right: 16,
              top: 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: urlController,
                  decoration: const InputDecoration(labelText: 'URL'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: passwordController,
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      final url = urlController.text.endsWith("/")
                          ? urlController.text.substring(0, -1)
                          : urlController.text;

                      final result = await http.get(
                        Uri.parse(
                          "$url/proxy/ip?api_password=${Uri.encodeQueryComponent(passwordController.text)}",
                        ),
                      );

                      if (result.statusCode == 403) {
                        return;
                      }

                      if (result.statusCode != 200) {
                        throw Error();
                      }

                      await collection.create(body: {
                        'name': nameController.text,
                        'url': url,
                        'password': passwordController.text,
                        'user': AppEngine.engine.pb.authStore.record!.id,
                      });

                      setState(() {
                        _collectionItems = collection.getList();
                      });

                      if (context.mounted) {
                        Navigator.pop(context);
                        _collectionItems = collection.getList();
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(
                                  'Error: ${(e is ClientException) ? e.response[e.response.keys.first] : e}')),
                        );
                      }
                    }
                  },
                  child: const Text('Add Proxy'),
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Proxy Settings'),
      ),
      body: FutureBuilder<ResultList<RecordModel>>(
        future: _collectionItems,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final items = snapshot.data!.items;

          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return ListTile(
                title: Text(item.data['name']),
                subtitle: Text(item.data['url']),
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () async {
                    try {
                      await collection.delete(item.id);
                      setState(() {
                        _collectionItems = collection.getList();
                      });
                      if (context.mounted && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Proxy deleted')),
                        );
                      }
                    } catch (e) {
                      if (mounted && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e')),
                        );
                      }
                    }
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddProxySheet(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}
