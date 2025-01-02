import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:pocketbase/pocketbase.dart';

import '../../../../engine/engine.dart';
import 'magic_page_selector_bottom_sheet.dart';

class MagicBottomSheet extends StatefulWidget {
  final PdfViewerController controller;
  const MagicBottomSheet({
    super.key,
    required this.controller,
  });

  @override
  State<MagicBottomSheet> createState() => _MagicBottomSheetState();
}

class _MagicBottomSheetState extends State<MagicBottomSheet> {
  final pb = AppEngine.engine.pb;

  late Future<ResultList<RecordModel>> item;

  @override
  void initState() {
    super.initState();

    item = pb.collection("ai_action").getList(perPage: 100);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: item,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            body: Text("Error: ${snapshot.error}"),
          );
        }

        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {},
            ),
            title: const Text("AI Actions"),
          ),
          body: ListView.builder(
            itemCount: snapshot.data!.items.length,
            itemBuilder: (ctx, index) {
              final item = snapshot.data!.items[index];
              final description = item.getStringValue("description");

              return ListTile(
                onTap: () async {
                  final result = await showModalBottomSheet(
                    context: context,
                    builder: (ctx) {
                      return MagicPageSelectorBottomSheet(
                        item: item,
                        controller: widget.controller,
                      );
                    },
                  );

                  if (context.mounted && mounted) {
                    Navigator.pop(context, [item, result]);
                  }
                },
                leading: const Icon(Icons.question_answer_outlined),
                title: Text(
                  snapshot.data!.items[index].getStringValue("title"),
                ),
                subtitle: description != ""
                    ? Text(
                        description,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      )
                    : null,
              );
            },
          ),
        );
      },
    );
  }
}
