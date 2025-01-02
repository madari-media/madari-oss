import 'package:flutter/material.dart';

import '../types/collection_item_model.dart';
import 'collection_markdown_renderer.dart';

class CollectionItemRenderer extends StatelessWidget {
  final CollectionItemModel item;

  const CollectionItemRenderer({
    super.key,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    switch (item.type) {
      case 'markdown':
        return MarkdownRenderer(content: item.content?['text'] ?? '');
      // case 'file':
      //   return FileRenderer(filePath: item.file!);
      default:
        return Text('Unsupported type: ${item.type}');
    }
  }
}
