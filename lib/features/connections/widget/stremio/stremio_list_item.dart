import 'package:flutter/material.dart';

import '../../service/base_connection_service.dart';

class StremioListItem extends StatelessWidget {
  final LibraryItem item;

  const StremioListItem({
    super.key,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    return const ListTile();
  }
}
