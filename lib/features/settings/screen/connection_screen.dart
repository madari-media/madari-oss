import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:madari_client/features/connection/containers/connection_manager.dart';
import 'package:madari_client/features/connection/containers/create_new_connection.dart';
import 'package:madari_client/features/connection/containers/show_handle_connection_type.dart';
import 'package:madari_client/features/library/containers/connection_list.dart';
import 'package:madari_client/features/library/screen/create_new_library.dart';

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
                  return CreateNewConnection(
                    onCallback: (item) {
                      Navigator.of(context).pop();

                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        isDismissible: true,
                        builder: (context) {
                          return Scaffold(
                            body: ShowHandleConnectionType(
                              item: item,
                              onFinish: (item) async {
                                Navigator.of(context).pop();
                                ref.refresh(getConnectionsProvider);

                                if (context.mounted) {
                                  showCupertinoModalPopup(
                                    context: context,
                                    builder: (ctx) {
                                      onCreated() {
                                        Navigator.of(ctx).pop();
                                      }

                                      return CreateNewLibrary(
                                        onCreatedAnother: () {},
                                        item: item,
                                        onCreated: () {
                                          onCreated();
                                        },
                                      );
                                    },
                                  );
                                }
                              },
                            ),
                          );
                        },
                      );
                    },
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
