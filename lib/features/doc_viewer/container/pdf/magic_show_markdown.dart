import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:madari_client/engine/engine.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:url_launcher/url_launcher.dart';

class MagicShowMarkdown extends StatefulWidget {
  final RecordModel record;
  final List<int> pages;
  final PdfViewerController controller;
  final String fileName;

  const MagicShowMarkdown({
    super.key,
    required this.record,
    required this.pages,
    required this.controller,
    required this.fileName,
  });

  @override
  State<MagicShowMarkdown> createState() => _MagicShowMarkdownState();
}

class _MagicShowMarkdownState extends State<MagicShowMarkdown> {
  final List<String> markdownChunks = [];
  bool isLoading = true;
  String? error;
  bool isStreaming = false;
  final Set<int> selectedChunks = {};
  bool isSelectionMode = false;
  final RegExp mermaidRegex = RegExp(r'```mermaid\n([\s\S]*?)```');

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _extractAndStream();
  }

  Future<String> _extractPdfText() async {
    return "";
  }

  void _extractAndStream() async {}

  void _retryStreaming() {
    setState(() {
      error = null;
      isLoading = true;
      markdownChunks.clear();
    });
    _extractAndStream();
  }

  void _handleMarkdownTap(String text, String? href) {
    if (href != null) {
      launchUrl(Uri.parse(href));
    }
  }

  void _copyText(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied to clipboard')),
    );
  }

  void _deleteChunk(int index) {
    setState(() {
      markdownChunks.removeAt(index);
      selectedChunks.remove(index);
    });
  }

  void _saveSelectedChunks() async {
    try {
      final selectedTexts = selectedChunks.toList()..sort();

      final textItem =
          selectedTexts.map((index) => markdownChunks[index]).toList();

      await AppEngine.engine.pb.collection('saved_responses').create(
        body: {
          'content': textItem.join("\n\n"),
          'file_name': widget.fileName,
          'user': AppEngine.engine.pb.authStore.record!.id,
        },
      );

      if (context.mounted && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Saved successfully')),
        );
      }
      setState(() {
        isSelectionMode = false;
        selectedChunks.clear();
      });
    } catch (e) {
      if (context.mounted && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error saving: ${(e as ClientException).response["message"]}',
            ),
          ),
        );
      }
    }
  }

  Widget _buildMarkdownContent(String chunk) {
    final mermaidMatches = mermaidRegex.allMatches(chunk);

    if (mermaidMatches.isNotEmpty) {
      List<Widget> contentWidgets = [];
      int lastEnd = 0;

      // Process each match and the text between matches
      for (var match in mermaidMatches) {
        // Add markdown content before the diagram if exists
        if (match.start > lastEnd) {
          final beforeText = chunk.substring(lastEnd, match.start);
          if (beforeText.trim().isNotEmpty) {
            contentWidgets.add(
              MarkdownBody(
                data: beforeText,
                selectable: true,
                onTapLink: (text, href, title) =>
                    _handleMarkdownTap(text, href),
              ),
            );
          }
        }

        lastEnd = match.end;
      }

      // Add any remaining markdown content after the last diagram
      if (lastEnd < chunk.length) {
        final afterText = chunk.substring(lastEnd);
        if (afterText.trim().isNotEmpty) {
          contentWidgets.add(
            MarkdownBody(
              data: afterText,
              selectable: true,
              onTapLink: (text, href, title) => _handleMarkdownTap(text, href),
            ),
          );
        }
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: contentWidgets,
      );
    }

    return MarkdownBody(
      data: chunk,
      selectable: true,
      onTapLink: (text, href, title) => _handleMarkdownTap(text, href),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Output"),
        actions: [
          if (isSelectionMode) ...[
            TextButton.icon(
              onPressed: selectedChunks.isEmpty ? null : _saveSelectedChunks,
              icon: const Icon(Icons.save),
              label: Text('Save ${selectedChunks.length}'),
            ),
            IconButton(
              onPressed: () => setState(() {
                isSelectionMode = false;
                selectedChunks.clear();
              }),
              icon: const Icon(Icons.close),
            ),
          ] else
            IconButton(
              onPressed: () => setState(() => isSelectionMode = true),
              icon: const Icon(Icons.checklist),
            ),
        ],
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(
            maxWidth: 800,
          ),
          child: ListView.builder(
            itemCount:
                markdownChunks.length + (isStreaming || error != null ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == markdownChunks.length) {
                if (error != null) {
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading content',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          error!,
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: _retryStreaming,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                return _buildStreamingIndicator();
              }

              final chunk =
                  markdownChunks[index].replaceAll("---", "\n").trim();
              final isSelected = selectedChunks.contains(index);

              return Card(
                margin: const EdgeInsets.all(8),
                child: InkWell(
                  onTap: isSelectionMode
                      ? () => setState(() {
                            if (isSelected) {
                              selectedChunks.remove(index);
                            } else {
                              selectedChunks.add(index);
                            }
                          })
                      : null,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (isSelectionMode)
                              Checkbox(
                                value: isSelected,
                                onChanged: (value) => setState(() {
                                  if (value ?? false) {
                                    selectedChunks.add(index);
                                  } else {
                                    selectedChunks.remove(index);
                                  }
                                }),
                              ),
                            Expanded(
                              child: _buildMarkdownContent(chunk),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              onPressed: () => _copyText(chunk),
                              icon: const Icon(Icons.copy),
                              tooltip: 'Copy',
                            ),
                            IconButton(
                              onPressed: () => _deleteChunk(index),
                              icon: const Icon(Icons.delete_outline),
                              tooltip: 'Delete',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildStreamingIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      alignment: Alignment.center,
      child: Column(
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            'Loading content...',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
