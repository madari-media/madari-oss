import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:madari_client/engine/connection.dart';

import '../../../engine/engine.dart';
import '../../../engine/library.dart';
import '../../settings/types/connection.dart';

class ConnectionList extends StatefulWidget {
  final bool canDisconnect;
  final void Function(Connection item)? onTap;
  final bool shrinkWrap;

  const ConnectionList({
    super.key,
    this.canDisconnect = false,
    this.onTap,
    this.shrinkWrap = true,
  });

  @override
  State<ConnectionList> createState() => _ConnectionListState();
}

class _ConnectionListState extends State<ConnectionList> {
  @override
  void initState() {
    super.initState();
  }

  void _refresh() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (BuildContext context, WidgetRef ref, Widget? child) {
        final result = ref.watch(getConnectionsProvider);

        return result.when(
          data: (data) {
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: data.length,
              shrinkWrap: widget.shrinkWrap,
              itemBuilder: (context, index) {
                return ConnectionCard(
                  onTap: () {
                    widget.onTap != null ? widget.onTap!(data[index]) : () {};
                  },
                  connection: data[index],
                  canDisconnect: widget.canDisconnect,
                  onRefresh: () {
                    _refresh();
                    ref.refresh(libraryListProvider(1));
                  },
                );
              },
            );
          },
          error: (err, o) {
            return Text("Something went wrong $err");
          },
          loading: () {
            return const Center(
              child: CircularProgressIndicator(),
            );
          },
        );
      },
    );
  }
}

class ConnectionCard extends StatefulWidget {
  final Connection connection;
  final VoidCallback onRefresh;
  final bool canDisconnect;
  final VoidCallback onTap;

  const ConnectionCard({
    super.key,
    required this.connection,
    required this.onRefresh,
    required this.canDisconnect,
    required this.onTap,
  });

  @override
  State<ConnectionCard> createState() => _ConnectionCardState();
}

class _ConnectionCardState extends State<ConnectionCard> {
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (BuildContext context, WidgetRef ref, Widget? child) {
        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onTap: () {
              widget.onTap();
            },
            title: Text(widget.connection.title,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            trailing: widget.canDisconnect
                ? TextButton(
                    onPressed: () => showDialog(
                      builder: (ctx) {
                        return AlertDialog(
                          title: const Text("Confirmation"),
                          content: SizedBox(
                            width: MediaQuery.of(context).size.width,
                            child: Text(
                              "Are your sure you want to delete ${widget.connection.title}?",
                            ),
                          ),
                          actions: [
                            ElevatedButton(
                              onPressed: () {
                                Navigator.of(ctx).pop();
                              },
                              child: const Text("CANCEL"),
                            ),
                            FilledButton(
                              onPressed: () {
                                _handleConnection(context, ref);
                                Navigator.of(context).pop();
                              },
                              child: const Text("DISCONNECT"),
                            ),
                          ],
                        );
                      },
                      context: context,
                    ),
                    child: isLoading
                        ? const CircularProgressIndicator()
                        : const Text("Disconnect"),
                  )
                : null,
          ),
        );
      },
    );
  }

  void _handleConnection(BuildContext context, WidgetRef ref) async {
    if (widget.connection.id == "telegram") {
      try {
        setState(() {
          isLoading = true;
        });
        widget.onRefresh();
      } finally {
        setState(() {
          isLoading = false;
        });
      }

      return;
    }

    await AppEngine.engine.pb
        .collection("connection")
        .delete(widget.connection.id);

    widget.onRefresh();

    ref.refresh(getConnectionsProvider);
  }
}
