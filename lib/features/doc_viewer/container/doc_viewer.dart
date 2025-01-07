import 'package:flutter/material.dart';
import 'package:madari_client/features/connections/service/base_connection_service.dart';
import 'package:madari_client/features/doc_viewer/container/pdf_viewer.dart';
import 'package:madari_client/features/doc_viewer/container/photo_viewer.dart';
import 'package:madari_client/features/doc_viewer/container/video_viewer.dart';
import 'package:madari_client/features/doc_viewer/types/doc_source.dart';

import 'iframe.dart';

class DocViewer extends StatefulWidget {
  final DocSource source;

  final String? library;

  final LibraryItem? meta;
  final String? season;
  final BaseConnectionService? service;

  final double? progress;

  const DocViewer({
    super.key,
    required this.source,
    this.service,
    this.library,
    this.meta,
    this.season,
    this.progress,
  });

  @override
  State<DocViewer> createState() => _DocViewerState();
}

class _DocViewerState extends State<DocViewer> {
  bool isReady = false;
  String? _errorMessage;

  @override
  void dispose() {
    super.dispose();
    widget.source.dispose();
  }

  @override
  void initState() {
    super.initState();

    widget.source.init().then((_) {
      setState(() {
        isReady = true;
      });
    }).catchError((err) {
      setState(() {
        if (mounted) {
          _errorMessage = err.toString();
        }
      });
      widget.source.dispose();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!isReady) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: Text(widget.source.title),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_errorMessage != null) {
      return Text("Error $_errorMessage");
    }

    if (widget.source is IframeSource) {
      return IframeViewer(
        source: widget.source as IframeSource,
      );
    }

    switch (widget.source.getType()) {
      case DocType.pdf:
        return PDFViewerContainer(source: widget.source);
      case DocType.photo:
        return PhotoViewer(source: widget.source);
      case DocType.video:
        return VideoViewer(
          source: widget.source,
          meta: widget.meta,
          service: widget.service,
          currentSeason: widget.season,
          library: widget.library,
        );
      default:
        return Scaffold(
          extendBody: true,
          appBar: AppBar(
            title: Text(widget.source.title),
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(
                  Icons.broken_image,
                  size: 42,
                ),
                const SizedBox(
                  height: 12,
                ),
                Text(
                  "Unsupported file ${widget.source.title}",
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ],
            ),
          ),
        );
    }
  }
}
