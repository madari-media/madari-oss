import 'package:flutter/material.dart';
import 'package:madari_client/engine/engine.dart';
import 'package:madari_client/engine/library.dart';
import 'package:madari_client/features/library_item/container/item_list.dart';
import 'package:pocketbase/pocketbase.dart';

class LibraryCard extends StatefulWidget {
  final LibraryRecord library;

  const LibraryCard({
    super.key,
    required this.library,
  });

  @override
  State<LibraryCard> createState() => _LibraryCardState();
}

class _LibraryCardState extends State<LibraryCard> {
  final PocketBase pb = AppEngine.engine.pb;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ItemList(
                library: widget.library,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.library.title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
