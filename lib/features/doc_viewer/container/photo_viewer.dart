import 'dart:io';

import 'package:flutter/material.dart';
import 'package:madari_client/features/doc_viewer/types/doc_source.dart';
import 'package:photo_view/photo_view.dart';

class PhotoViewer extends StatelessWidget {
  final DocSource source;
  const PhotoViewer({
    super.key,
    required this.source,
  });

  @override
  Widget build(BuildContext context) {
    ImageProvider provider;

    if (source is FileSource) {
      provider = FileImage(File((source as FileSource).filePath));
    } else if (source is URLSource) {
      provider = NetworkImage((source as URLSource).url);
    } else {
      throw TypeError();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(source.title),
      ),
      body: PhotoView(
        imageProvider: provider,
      ),
    );
  }
}
