import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class ChatBubble extends StatelessWidget {
  final String message;
  final bool isUser;
  final bool isComplete;
  final VoidCallback? onCancel;
  final bool isStreaming = false;
  final int length;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isUser,
    this.isComplete = true,
    this.onCancel,
    this.length = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment:
                isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              const SizedBox(width: 8),
              Flexible(
                child: Container(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                          child: AlertDialog(
                            contentPadding: const EdgeInsets.only(
                              bottom: 12,
                            ),
                            insetPadding: const EdgeInsets.all(10),
                            title: const Text("Message"),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Close'),
                              ),
                              TextButton.icon(
                                onPressed: () {
                                  Clipboard.setData(
                                    ClipboardData(text: message),
                                  );
                                },
                                label: const Text('Copy'),
                                icon: const Icon(Icons.copy),
                              ),
                            ],
                            content: Container(
                              constraints: BoxConstraints(
                                maxHeight:
                                    MediaQuery.of(context).size.height - 220,
                              ),
                              child: SingleChildScrollView(
                                child: Padding(
                                  padding: const EdgeInsets.all(20.0),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const SizedBox(height: 20),
                                      MarkdownBody(
                                        data: message,
                                        selectable: true,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isUser
                            ? Theme.of(context).primaryColor.withOpacity(0.9)
                            : Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(20),
                        border: !isUser
                            ? Border.all(color: Colors.grey.withOpacity(0.2))
                            : null,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          message.trim().isEmpty && isUser
                              ? Column(
                                  children: [
                                    const Icon(Icons.file_present),
                                    Text("Files Attached $length"),
                                  ],
                                )
                              : MarkdownBody(
                                  data: message,
                                  styleSheet: MarkdownStyleSheet(
                                    p: TextStyle(
                                      color: isUser
                                          ? Colors.white
                                          : Theme.of(context)
                                              .textTheme
                                              .bodyLarge
                                              ?.color,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (isUser) _buildAvatar(true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(bool isUser) {
    return CircleAvatar(
      backgroundColor: isUser ? Colors.blue.shade700 : Colors.grey.shade900,
      child: Icon(
        isUser ? Icons.person : Icons.auto_awesome,
        color: Colors.white,
      ),
    );
  }
}
