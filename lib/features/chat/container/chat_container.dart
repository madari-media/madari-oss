import 'package:flutter/material.dart';
import 'package:madari_client/features/chat/container/chat_empty_state.dart';

import 'chat_bubble.dart';
import 'chat_input_area.dart';

class ChatMessage {
  final String message;
  final bool isUser;
  final bool isComplete;
  final List<String> files;
  final CancellationToken? cancellationToken;
  final String? actionId;

  ChatMessage({
    required this.message,
    required this.isUser,
    this.files = const [],
    this.isComplete = true,
    this.cancellationToken,
    this.actionId,
  });
}

class CancellationToken {
  bool _isCancelled = false;
  bool get isCancelled => _isCancelled;
  void cancel() => _isCancelled = true;
}

class ChatContainer extends StatefulWidget {
  final List<ChatMessage>? initialMessages;
  final Future<void> Function(String, List<String>?, String?)? onSendMessage;
  final ScrollController scrollController;

  const ChatContainer({
    super.key,
    this.initialMessages,
    this.onSendMessage,
    required this.scrollController,
  });

  @override
  State<ChatContainer> createState() => _ChatContainerState();
}

class _ChatContainerState extends State<ChatContainer> {
  List<ChatMessage> messages = [];
  bool isLoading = false;
  final FocusNode _focusNode = FocusNode();
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialMessages != null) {
      messages = widget.initialMessages!;
    }
    _focusNode.addListener(() {
      setState(() {
        _isExpanded = _focusNode.hasFocus;
      });
    });
  }

  Future<void> _handleSubmit(
    String text,
    String? actionId,
    List<String> files,
  ) async {
    if (text.trim().isEmpty && actionId == null) return;

    setState(() {
      isLoading = true;
    });

    if (widget.onSendMessage != null) {
      await widget.onSendMessage!(text, files, actionId);
    }

    setState(() {
      isLoading = false;
      files = [];
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  Widget _buildEmptyState() {
    return ChatEmpty(
      handleSubmit: (text) => _handleSubmit(
        text,
        null,
        [],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: messages.isEmpty
              ? _buildEmptyState()
              : Container(
                  constraints: const BoxConstraints(
                    maxWidth: 1100,
                  ),
                  child: ListView.builder(
                    controller: widget.scrollController,
                    padding: const EdgeInsets.all(8.0),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      return ChatBubble(
                        message: message.message,
                        isUser: message.isUser,
                        isComplete: message.isComplete,
                        length: message.files.length,
                      );
                    },
                  ),
                ),
        ),
        Center(
          child: Container(
            constraints: const BoxConstraints(
              maxWidth: 1100,
            ),
            child: ChatInputArea(
              isLoading: isLoading,
              onSubmitted: (text, files, actionId) => _handleSubmit(
                text,
                actionId,
                files,
              ),
              focusNode: _focusNode,
              cancellationToken: messages.lastOrNull?.cancellationToken,
            ),
          ),
        ),
      ],
    );
  }
}
