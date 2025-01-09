import 'package:flutter/material.dart';
import 'package:madari_client/engine/engine.dart';
import 'package:madari_client/features/trakt/service/trakt.service.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../utils/auth_refresh.dart';

class TraktIntegration extends StatefulWidget {
  const TraktIntegration({
    super.key,
  });

  @override
  State<TraktIntegration> createState() => _TraktIntegrationState();
}

class _TraktIntegrationState extends State<TraktIntegration> {
  final pb = AppEngine.engine.pb;
  bool isLoggedIn = false;
  List<TraktCategories> selectedLists = [];
  List<TraktCategories> availableLists = [...traktCategories];

  @override
  void initState() {
    super.initState();
    checkIsLoggedIn();
    _loadSelectedCategories();
  }

  // Check if the user is logged in
  checkIsLoggedIn() {
    final traktToken = pb.authStore.record!.getStringValue("trakt_token");

    setState(() {
      isLoggedIn = traktToken != "";
    });
  }

  // Load selected categories from the database
  void _loadSelectedCategories() async {
    final record = pb.authStore.record!;
    final config = record.get("config") ?? {};
    final savedCategories =
        config["selected_categories"] as List<dynamic>? ?? [];

    setState(() {
      selectedLists = traktCategories
          .where((category) => savedCategories.contains(category.key))
          .toList();
      availableLists = traktCategories
          .where((category) => !savedCategories.contains(category.key))
          .toList();
    });
  }

  // Save selected categories to the database
  void _saveSelectedCategories() async {
    final record = pb.authStore.record!;
    final config = record.get("config") ?? {};

    config["selected_categories"] =
        selectedLists.map((category) => category.key).toList();

    await pb.collection('users').update(
      record.id,
      body: {
        "config": config,
      },
    );

    await refreshAuth();
  }

  // Remove a category
  void _removeCategory(TraktCategories category) {
    setState(() {
      selectedLists.remove(category);
      availableLists.add(category);
    });
    _saveSelectedCategories();
  }

  // Add a category
  void _addCategory(TraktCategories category) {
    setState(() {
      availableLists.remove(category);
      selectedLists.add(category);
    });
    _saveSelectedCategories();
  }

  removeAccount() async {
    final record = pb.authStore.record!;
    record.set("trakt_token", "");

    pb.collection('users').update(
          record.id,
          body: record.toJson(),
        );

    await refreshAuth();
  }

  loginWithTrakt() async {
    await pb.collection("users").authWithOAuth2(
      "oidc",
      (url) async {
        final newUrl = Uri.parse(
          url.toString().replaceFirst(
                "scope=openid&",
                "",
              ),
        );
        await launchUrl(newUrl);
      },
      scopes: ["openid"],
    );

    await refreshAuth();

    checkIsLoggedIn();
  }

  // Show the "Add Category" dialog
  Future<void> _showAddCategoryDialog() async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            "Add Category",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: availableLists.length,
              itemBuilder: (context, index) {
                final category = availableLists[index];
                return ListTile(
                  title: Text(
                    category.title,
                    style: const TextStyle(fontSize: 16),
                  ),
                  trailing: const Icon(Icons.add, color: Colors.blue),
                  onTap: () {
                    _addCategory(category);
                    Navigator.of(context).pop();
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                "Close",
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  // Reorder categories
  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final TraktCategories item = selectedLists.removeAt(oldIndex);
      selectedLists.insert(newIndex, item);
    });
    _saveSelectedCategories();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Trakt Integration",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) {
                  return Scaffold(
                    appBar: AppBar(
                      title: const Text("Logs"),
                    ),
                    body: ListView.builder(
                      itemCount: TraktService.instance!.debugLogs.length,
                      itemBuilder: (context, item) {
                        return Text(
                          TraktService.instance!.debugLogs[item],
                        );
                      },
                    ),
                  );
                }),
              );
            },
            child: Text("Debug logs"),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Padding(
          padding: const EdgeInsets.only(
            bottom: 16.0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (isLoggedIn)
                ElevatedButton(
                  onPressed: () async {
                    await removeAccount();
                    setState(() {
                      isLoggedIn = false;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "Disconnect Account",
                  ),
                )
              else
                ElevatedButton(
                  onPressed: () {
                    loginWithTrakt();
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "Login with Trakt",
                  ),
                ),
              const SizedBox(height: 20),
              if (isLoggedIn) ...[
                const Text(
                  "Selected Categories to show in home",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: ReorderableListView.builder(
                    itemCount: selectedLists.length,
                    onReorder: _onReorder,
                    itemBuilder: (context, index) {
                      final category = selectedLists[index];
                      return Card(
                        key: ValueKey(category.key),
                        elevation: 4,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          title: Text(
                            category.title,
                            style: const TextStyle(fontSize: 16),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => _removeCategory(category),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                if (availableLists.isNotEmpty)
                  ElevatedButton(
                    onPressed: _showAddCategoryDialog,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "Add Category",
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

List<TraktCategories> traktCategories = [
  TraktCategories(
    title: "Up Next - Trakt",
    key: "up_next_series",
  ),
  TraktCategories(
    title: "Continue watching",
    key: "continue_watching",
  ),
  TraktCategories(
    title: "Upcoming Schedule",
    key: "upcoming_schedule",
  ),
  TraktCategories(
    title: "Watchlist",
    key: "watchlist",
  ),
  TraktCategories(
    title: "Show Recommendations",
    key: "show_recommendations",
  ),
  TraktCategories(
    title: "Movie Recommendations",
    key: "movie_recommendations",
  ),
];

class TraktCategories {
  final String title;
  final String key;

  TraktCategories({
    required this.title,
    required this.key,
  });
}
