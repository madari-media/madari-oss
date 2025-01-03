import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:madari_client/features/connection/containers/connection_manager.dart';
import 'package:madari_client/features/getting_started/container/getting_started.dart';
import 'package:madari_client/features/library/containers/connection_list.dart';

import '../../../engine/connection.dart';

class ConnectionsScreen extends StatefulWidget {
  const ConnectionsScreen({super.key});

  @override
  State<ConnectionsScreen> createState() => _ConnectionsScreenState();
}

class _ConnectionsScreenState extends State<ConnectionsScreen> {
  final scaffoldState = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (BuildContext context, WidgetRef ref, Widget? child) {
        return Scaffold(
          key: scaffoldState,
          appBar: AppBar(
            title: const Text("My Connections"),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                isDismissible: true,
                builder: (context) {
                  return Padding(
                    padding: const EdgeInsets.only(
                      top: 18.0,
                    ),
                    child: GettingStartedScreen(
                      onCallback: () {
                        ref.refresh(getConnectionsProvider);
                      },
                      hasBackground: false,
                    ),
                  );
                },
              );
            },
            icon: const Icon(Icons.add),
            label: const Text(
              "New connection",
            ),
          ),
          body: Center(
            child: Container(
              constraints: const BoxConstraints(
                maxWidth: 600,
              ),
              child: ConnectionList(
                shrinkWrap: false,
                canDisconnect: true,
                onTap: (item) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (ctx) => ConnectionManager(
                        item: item,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
