import 'package:flutter/material.dart';
import 'package:madari_client/features/doc_viewer/container/pdf/magic_show_markdown.dart';
import 'package:madari_client/features/doc_viewer/types/doc_source.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:url_launcher/url_launcher.dart';

import 'pdf/magic_bottom_sheet.dart';
import 'pdf/markers_view.dart';
import 'pdf/outline_view.dart';
import 'pdf/password_dialog.dart';
import 'pdf/search_view.dart';

class PDFViewerContainer extends StatefulWidget {
  final DocSource source;

  const PDFViewerContainer({
    super.key,
    required this.source,
  });

  @override
  State<PDFViewerContainer> createState() => _PDFViewerContainerState();
}

class _PDFViewerContainerState extends State<PDFViewerContainer> {
  final documentRef = ValueNotifier<PdfDocumentRef?>(null);
  final controller = PdfViewerController();
  final showLeftPane = ValueNotifier<bool>(false);
  final outline = ValueNotifier<List<PdfOutlineNode>?>(null);
  late final textSearcher = PdfTextSearcher(controller)..addListener(_update);
  final _markers = <int, List<Marker>>{};
  List<PdfTextRanges>? _textSelections;

  void _update() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    textSearcher.removeListener(_update);
    textSearcher.dispose();
    showLeftPane.dispose();
    outline.dispose();
    documentRef.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          widget.source.title,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.list),
            onPressed: () {
              showLeftPane.value = !showLeftPane.value;
            },
          ),
          IconButton(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: (context) {
                  return Padding(
                    padding: const EdgeInsets.all(12),
                    child: search(),
                  );
                },
              );
            },
            icon: const Icon(
              Icons.search,
            ),
          )
        ],
      ),
      floatingActionButton: Row(
        children: [
          const Spacer(),
          IconButton.filledTonal(
            icon: const Icon(Icons.zoom_in),
            onPressed: () => controller.zoomUp(),
          ),
          IconButton.filledTonal(
            icon: const Icon(Icons.zoom_out),
            onPressed: () => controller.zoomDown(),
          ),
          const SizedBox(
            width: 8,
          ),
          FloatingActionButton.extended(
            label: const Text("Magic"),
            onPressed: () async {
              final result = await showModalBottomSheet(
                context: context,
                builder: (ctx) {
                  return MagicBottomSheet(
                    controller: controller,
                  );
                },
              );

              if (result == null ||
                  !context.mounted ||
                  (result is List) && result.length != 2) {
                return;
              }

              if (result[1] == null || result[0] == null) {
                return;
              }

              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (ctx) {
                    return MagicShowMarkdown(
                      record: result[0] as RecordModel,
                      pages: result[1] as List<int>,
                      controller: controller,
                      fileName: widget.source.title,
                    );
                  },
                ),
              );
            },
            icon: const Icon(
              Icons.auto_awesome,
            ),
          )
        ],
      ),
      body: Row(
        children: [
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            child: ValueListenableBuilder(
              valueListenable: showLeftPane,
              builder: (context, showLeftPane, child) => SizedBox(
                width: showLeftPane ? 300 : 0,
                child: child!,
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(1, 0, 4, 0),
                child: ValueListenableBuilder(
                  valueListenable: outline,
                  builder: (context, outline, child) => OutlineView(
                    outline: outline,
                    controller: controller,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                if (widget.source is FileSource)
                  PdfViewer.file(
                    (widget.source as FileSource).filePath,
                    passwordProvider: () => passwordDialog(context),
                    controller: controller,
                    params: params,
                  ),
                if (widget.source is URLSource)
                  PdfViewer.uri(
                    Uri.parse((widget.source as URLSource).url),
                    passwordProvider: () => passwordDialog(context),
                    headers: (widget.source as URLSource).headers,
                    controller: controller,
                    params: params,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget search() {
    return ValueListenableBuilder(
      valueListenable: documentRef,
      builder: (context, documentRef, child) => TextSearchView(
        textSearcher: textSearcher,
      ),
    );
  }

  PdfViewerParams get params {
    return PdfViewerParams(
      enableTextSelection: true,
      maxScale: 8,
      onViewSizeChanged: (viewSize, oldViewSize, controller) {
        if (oldViewSize != null) {
          final centerPosition = controller.value.calcPosition(oldViewSize);
          final newMatrix = controller.calcMatrixFor(centerPosition);
          Future.delayed(
            const Duration(milliseconds: 200),
            () => controller.goTo(newMatrix),
          );
        }
      },
      viewerOverlayBuilder: (context, size, handleLinkTap) => [
        GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTapUp: (details) {
            handleLinkTap(details.localPosition);
          },
          onDoubleTap: () {
            if (controller.currentZoom <= 1) {
              controller.zoomUp(loop: true);
            } else {
              controller.zoomDown(
                loop: false,
              );
            }
          },
          child: IgnorePointer(
            child: SizedBox(width: size.width, height: size.height),
          ),
        ),
        PdfViewerScrollThumb(
          controller: controller,
          orientation: ScrollbarOrientation.right,
          thumbSize: const Size(44, 28),
          thumbBuilder: (context, thumbSize, pageNumber, controller) =>
              ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              color: Colors.black,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  const SizedBox(
                    width: 4,
                  ),
                  const Icon(
                    Icons.drag_indicator,
                    size: 14,
                  ),
                  Center(
                    child: Text(
                      pageNumber.toString(),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(
                    width: 8,
                  ),
                ],
              ),
            ),
          ),
        ),
        PdfViewerScrollThumb(
          controller: controller,
          orientation: ScrollbarOrientation.bottom,
          thumbSize: const Size(80, 22),
          thumbBuilder: (context, thumbSize, pageNumber, controller) =>
              ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Container(
              color: Colors.black,
              child: const Center(
                child: Icon(
                  Icons.drag_indicator_outlined,
                  size: 18,
                ),
              ),
            ),
          ),
        ),
      ],
      loadingBannerBuilder: (context, bytesDownloaded, totalBytes) => Center(
        child: CircularProgressIndicator(
          value: totalBytes != null ? bytesDownloaded / totalBytes : null,
          backgroundColor: Colors.grey,
        ),
      ),
      linkHandlerParams: PdfLinkHandlerParams(
        onLinkTap: (link) {
          if (link.url != null) {
            navigateToUrl(link.url!);
          } else if (link.dest != null) {
            controller.goToDest(link.dest);
          }
        },
      ),
      pagePaintCallbacks: [
        textSearcher.pageTextMatchPaintCallback,
        _paintMarkers,
      ],
      onDocumentChanged: (document) async {
        if (document == null) {
          documentRef.value = null;
          outline.value = null;
          _textSelections = null;
          _markers.clear();
        }
      },
      onViewerReady: (document, controller) async {
        documentRef.value = controller.documentRef;
        outline.value = await document.loadOutline();
      },
      onTextSelectionChange: (selections) {
        _textSelections = selections;
      },
    );
  }

  void _paintMarkers(Canvas canvas, Rect pageRect, PdfPage page) {
    final markers = _markers[page.pageNumber];
    if (markers == null) {
      return;
    }
    for (final marker in markers) {
      final paint = Paint()
        ..color = marker.color.withAlpha(100)
        ..style = PaintingStyle.fill;

      for (final range in marker.ranges.ranges) {
        final f = PdfTextRangeWithFragments.fromTextRange(
          marker.ranges.pageText,
          range.start,
          range.end,
        );
        if (f != null) {
          canvas.drawRect(
            f.bounds.toRectInPageRect(page: page, pageRect: pageRect),
            paint,
          );
        }
      }
    }
  }

  Future<void> navigateToUrl(Uri url) async {
    if (await shouldOpenUrl(context, url)) {
      await launchUrl(url);
    }
  }

  Future<bool> shouldOpenUrl(BuildContext context, Uri url) async {
    final result = await showDialog<bool?>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Navigate to URL?'),
          content: SelectionArea(
            child: Text.rich(
              TextSpan(
                children: [
                  const TextSpan(
                      text:
                          'Do you want to navigate to the following location?\n'),
                  TextSpan(
                    text: url.toString(),
                    style: const TextStyle(color: Colors.blue),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Go'),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }
}
