import 'package:flutter/material.dart';
import 'package:madari_client/engine/library.dart';
import 'package:madari_client/features/doc_viewer/container/doc_viewer.dart';

import '../../doc_viewer/types/doc_source.dart';

class ItemViewer extends StatefulWidget {
  final LibraryRecord library;
  final LibraryItemList item;

  const ItemViewer({
    super.key,
    required this.library,
    required this.item,
  });

  @override
  State<ItemViewer> createState() => _ItemViewerState();
}

class _ItemViewerState extends State<ItemViewer> {
  Stream<List<DocSource>>? source;

  @override
  void initState() {
    super.initState();

    Future.microtask(() async {
      setState(() {
        this.source = source;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (source == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return StreamBuilder(
      stream: source,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            body: Text("Something went wrong ${snapshot.error}"),
          );
        }

        final hasData = snapshot.data ?? [];

        if (hasData.isEmpty) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final firstData = snapshot.data!.first;

        if (firstData is ProgressStatus) {
          final result = firstData;

          final bool isDarkMode =
              Theme.of(context).brightness == Brightness.dark;
          final ColorScheme colorScheme = isDarkMode
              ? ColorScheme.dark(
                  primary: Colors.blue.shade300,
                  surface: Colors.black,
                  onSurface: Colors.white,
                )
              : ColorScheme.light(
                  primary: Colors.blue.shade600,
                  surface: Colors.white,
                  onSurface: Colors.black87,
                );

          return Theme(
            data: ThemeData(
              colorScheme: colorScheme,
              scaffoldBackgroundColor: colorScheme.surface,
            ),
            child: Scaffold(
              appBar: AppBar(
                elevation: 0,
                backgroundColor: Colors.transparent,
                title: Text(
                  result.title,
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                centerTitle: true,
              ),
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 200,
                            height: 200,
                            child: CircularProgressIndicator(
                              value: result.percentage,
                              strokeWidth: 12,
                              backgroundColor: isDarkMode
                                  ? Colors.grey.shade800
                                  : Colors.grey.shade300,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                colorScheme.primary,
                              ),
                            ),
                          ),
                          Text(
                            '${result.percentage?.toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text(
                        result.progressText ?? 'Downloading...',
                        style: TextStyle(
                          fontSize: 16,
                          color: isDarkMode
                              ? Colors.grey.shade300
                              : Colors.grey.shade700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        return DocViewer(
          source: firstData,
        );
      },
    );
  }
}
