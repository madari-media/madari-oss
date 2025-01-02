import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:http/http.dart' as http;
import 'package:madari_client/engine/engine.dart';
import 'package:madari_client/features/chat/container/chat_history.dart';

import '../features/chat/container/chat_container.dart';
import '../utils/stream_base.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<ChatMessage> messages = [];
  CancellationToken? _currentCancellationToken;
  final ScrollController _scrollController = ScrollController();
  bool _userScrolling = false;
  double? _lastScrollPosition;

  @override
  void dispose() {
    super.dispose();

    _scrollController.dispose();
  }

  @override
  void initState() {
    super.initState();

    // Add scroll listener to detect user interaction
    _scrollController.addListener(() {
      if (_scrollController.position.userScrollDirection !=
          ScrollDirection.idle) {
        _userScrolling = true;
        _lastScrollPosition = _scrollController.position.pixels;
      }
    });
  }

  void _scrollToBottom() {
    // Only auto-scroll if user isn't manually scrolling
    if (!_userScrolling) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (!mounted) return;
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  // Add the disclaimer text
  final String disclaimerText =
      "AI can make mistakes. Consider checking important information.";

  void _clearChat() {
    setState(() {
      _currentCancellationToken?.cancel();
      messages.clear();
    });
  }

  Future<void> _handleMessageStream({
    required String userMessage,
    List<String>? list,
    String? actionId,
    CancellationToken? cancellationToken,
  }) async {
    _userScrolling = false;
    if (_currentCancellationToken != null) {
      _currentCancellationToken!.cancel();
    }

    _currentCancellationToken = cancellationToken ?? CancellationToken();

    messages.add(ChatMessage(
      message: userMessage,
      isUser: true,
      files: list ?? [],
      actionId: actionId,
    ));

    final payload = messages.map((item) {
      return {
        'role': item.isUser ? 'user' : 'system',
        'content': userMessage,
        'files': item.files,
        'actionId': actionId,
      };
    }).toList();

    messages.add(ChatMessage(
      files: list ?? [],
      message: '',
      isUser: false,
      isComplete: false,
      cancellationToken: _currentCancellationToken,
    ));

    setState(() {});

    final client = http.Client();
    try {
      final request = http.Request(
        'POST',
        Uri.parse('${AppEngine.engine.pb.baseURL}/api/v1/chat/completions'),
      );
      request.headers.addAll({
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${AppEngine.engine.pb.authStore.token}',
      });
      request.body = jsonEncode({
        'messages': payload,
      });

      final response = await getStream(request);

      final stream = response.transform(utf8.decoder);
      String currentMessage = '';

      await for (var chunk in stream) {
        if (_currentCancellationToken!.isCancelled) {
          client.close();
          return;
        }

        // Split the chunk into lines and process each SSE event
        for (var line in chunk.split('\n')) {
          if (line.trim() == "") {
            continue;
          }
          try {
            if (!chunk.startsWith('data: ')) {
              continue;
            }

            final json = jsonDecode(
              line.substring(6),
            );

            final content = json['choices'][0]['delta']['content'];
            if (content != null) {
              currentMessage += content;
              setState(() {
                messages.last = ChatMessage(
                  message: currentMessage,
                  isUser: false,
                  isComplete: false,
                  cancellationToken: _currentCancellationToken,
                );
              });

              _scrollToBottom();
            }
          } catch (e) {
            print(e);
            continue;
          }
        }
      }

      // Mark message as complete
      setState(() {
        messages.last = ChatMessage(
          message: currentMessage,
          isUser: false,
          isComplete: true,
          cancellationToken: null,
        );
      });
    } catch (e) {
      setState(() {
        messages.last = ChatMessage(
          message: 'Error: Failed to get response',
          isUser: false,
          isComplete: true,
          cancellationToken: null,
        );
      });
    } finally {
      client.close();
      _currentCancellationToken = null;
    }
  }

  final _scafoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scafoldKey,
      drawer: const ChatHistory(),
      appBar: AppBar(
        title: const Text('Chat'),
        leading: messages.isEmpty
            ? IconButton(
                onPressed: () {
                  _scafoldKey.currentState?.openDrawer();
                },
                icon: const Icon(Icons.menu),
              )
            : IconButton(
                onPressed: _clearChat,
                icon: const Icon(
                  Icons.arrow_back,
                ),
              ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: ChatContainer(
              initialMessages: messages,
              onSendMessage: (message, files, action) {
                return _handleMessageStream(
                  userMessage: message,
                  list: files,
                  actionId: action,
                );
              },
              scrollController: _scrollController,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              disclaimerText,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
