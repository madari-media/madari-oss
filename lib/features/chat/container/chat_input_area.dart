import 'package:flutter/material.dart';
import 'package:madari_client/engine/engine.dart';
import 'package:madari_client/features/chat/container/chat_container.dart';

import 'chat_action.dart';

class ChatInputArea extends StatefulWidget {
  final bool isLoading;
  final Future Function(
    String text,
    List<String> files,
    String? actionId,
  ) onSubmitted;
  final FocusNode focusNode;
  final CancellationToken? cancellationToken;

  const ChatInputArea({
    super.key,
    required this.isLoading,
    required this.onSubmitted,
    required this.focusNode,
    this.cancellationToken,
  });

  @override
  State<ChatInputArea> createState() => _ChatInputAreaState();
}

class _ChatInputAreaState extends State<ChatInputArea> {
  final TextEditingController _textController = TextEditingController();
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  final Map<String, String> files =
      {}; // key is file name and string is the content
  String? actionId;

  @override
  void initState() {
    super.initState();
    _textController.addListener(_handleTextChange);

    AppEngine.engine.pb
        .collection("ai_action")
        .getList(perPage: 50)
        .then((docs) {});
  }

  @override
  void dispose() {
    _hideCommandPalette();
    _textController.removeListener(_handleTextChange);
    super.dispose();
  }

  void _handleTextChange() {
    if (_textController.text == '/') {
      _showCommandPalette();
    } else if (_textController.text.isEmpty) {
      _hideCommandPalette();
    }
  }

  void _showCommandPalette() {
    _hideCommandPalette();

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: MediaQuery.of(context).size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, -5),
          targetAnchor: Alignment.topCenter,
          followerAnchor: Alignment.bottomCenter,
          child: TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            tween: Tween(begin: 0, end: 1),
            builder: (context, value, child) => Transform.scale(
              scale: value,
              child: Opacity(
                opacity: value,
                child: child,
              ),
            ),
            child: ChatAction(
              actionId: actionId,
              onClose: ({
                actionId,
                files,
              }) {
                _textController.clear();
                _hideCommandPalette();

                setState(() {
                  this.files.addAll(files ?? {});
                  if (actionId != null) this.actionId = actionId;
                });
              },
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);

    setState(() {});
  }

  void _hideCommandPalette() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (mounted && context.mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (files.isNotEmpty)
          Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: files.length,
              itemBuilder: (context, index) {
                final fileName = files.keys.elementAt(index);
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          insetPadding: const EdgeInsets.all(4),
                          actions: [
                            TextButton.icon(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              label: const Text("Close"),
                            ),
                            TextButton.icon(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              label: const Text("Copy"),
                              icon: const Icon(Icons.copy),
                            ),
                          ],
                          title: Text(
                            fileName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          content: SingleChildScrollView(
                            child: Text(
                              files[fileName]!,
                            ),
                          ),
                        ),
                      );
                    },
                    child: Chip(
                      visualDensity: VisualDensity.compact,
                      label: Row(
                        children: [
                          const Icon(
                            Icons.picture_as_pdf_outlined,
                            size: 16,
                          ),
                          const SizedBox(
                            width: 12,
                          ),
                          Container(
                            constraints: const BoxConstraints(
                              maxWidth: 100,
                            ),
                            child: Text(
                              fileName,
                              style: const TextStyle(
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      onDeleted: () {
                        setState(() {
                          files.remove(fileName);
                        });
                      },
                      deleteIcon: const Icon(Icons.close, size: 16),
                      backgroundColor:
                          Theme.of(context).primaryColor.withOpacity(0.1),
                    ),
                  ),
                );
              },
            ),
          ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              IconButton(
                icon: _overlayEntry == null
                    ? const Icon(Icons.add_circle_outline)
                    : const Icon(Icons.close),
                onPressed: _overlayEntry == null
                    ? _showCommandPalette
                    : _hideCommandPalette,
                tooltip: 'Open commands',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
                ),
              ),
              const SizedBox(
                width: 8,
              ),
              Expanded(
                child: CompositedTransformTarget(
                  link: _layerLink,
                  child: Container(
                    constraints: const BoxConstraints(
                      minHeight: 40,
                      maxHeight: 120,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.withOpacity(0.2)),
                      color: Theme.of(context).scaffoldBackgroundColor,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: TextField(
                        controller: _textController,
                        focusNode: widget.focusNode,
                        maxLines: null,
                        decoration: const InputDecoration(
                          hintText: 'Message...',
                          border: InputBorder.none,
                          hintStyle: TextStyle(color: Colors.grey),
                        ),
                        onSubmitted: (value) async {
                          await widget.onSubmitted(
                            value,
                            files.values.toList(),
                            actionId,
                          );
                          setState(() {
                            files.clear();
                            actionId = null;
                          });
                          _textController.clear();
                        },
                        enabled: !widget.isLoading,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                margin: const EdgeInsets.only(bottom: 2),
                child: AnimatedScale(
                  duration: const Duration(milliseconds: 200),
                  scale: _textController.text.isEmpty ? 0.8 : 1.0,
                  child: Container(
                    height: 40,
                    width: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.isLoading
                          ? Colors.grey
                          : Theme.of(context).primaryColor.withOpacity(0.9),
                    ),
                    child: widget.cancellationToken == null ||
                            widget.cancellationToken?.isCancelled == true
                        ? IconButton(
                            padding: EdgeInsets.zero,
                            icon: const Icon(Icons.send,
                                color: Colors.white, size: 20),
                            onPressed: widget.isLoading
                                ? null
                                : () async {
                                    await widget.onSubmitted(
                                      _textController.text,
                                      files.values.toList(),
                                      actionId,
                                    );
                                    setState(() {
                                      files.clear();
                                      actionId = null;
                                    });
                                    _textController.clear();
                                  },
                          )
                        : IconButton(
                            onPressed: () {
                              widget.cancellationToken?.cancel();
                            },
                            icon: const Icon(
                              Icons.stop_circle,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
