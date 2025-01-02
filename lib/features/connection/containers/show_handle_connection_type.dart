import 'package:flutter/material.dart';
import 'package:madari_client/features/settings/types/connection.dart';

import '../../../engine/connection_type.dart';
import 'configure_stremio_connection.dart';

class ShowHandleConnectionType extends StatelessWidget {
  final ConnectionTypeRecord item;
  final void Function(Connection id) onFinish;

  const ShowHandleConnectionType({
    super.key,
    required this.item,
    required this.onFinish,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      constraints: BoxConstraints(
        // Remove fixed height constraints to allow content to resize
        maxHeight: MediaQuery.of(context).size.height * .9,
        minWidth: double.infinity,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: _build(context),
        ),
      ),
    );
  }

  _build(BuildContext context) {
    Widget child = Container();

    switch (item.type) {
      case "stremio_addons":
        child = StremioAddonConnection(
          item: item,
          onConnectionComplete: (id) {
            onFinish(id);
          },
        );
        break;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildBottomSheetHandle(),
        _buildHeader(context),
        child,
      ],
    );
  }

  Widget _buildBottomSheetHandle() {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 8),
      child: Container(
        width: 32,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      child: Column(
        children: [
          Text(
            "Configure connection",
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
