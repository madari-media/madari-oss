import 'package:cached_query_flutter/cached_query_flutter.dart';
import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';

import '../../../engine/engine.dart';

class ChatHistory extends StatefulWidget {
  const ChatHistory({super.key});

  @override
  State<ChatHistory> createState() => _ChatHistoryState();
}

class _ChatHistoryState extends State<ChatHistory> {
  final pb = AppEngine.engine.pb;
  late final InfiniteQuery<List<RecordModel>, int> chatHistoryQuery;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    chatHistoryQuery = InfiniteQuery<List<RecordModel>, int>(
      key: "chat_history",
      queryFn: (page) async {
        try {
          final result = await pb.collection("chat").getList(
                page: page,
                perPage: 10, // Adjust perPage as needed
                sort: '-created', // Assuming you want the latest chats first
              );
          return result.items.toList();
        } catch (e) {
          debugPrint('Error fetching chat history: $e');
          throw e;
        }
      },
      getNextArg: (state) {
        if (state.lastPage?.isEmpty ?? false) return null;
        return state.length;
      },
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    "Chat History",
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () {
                    pb.collection("chat").create(
                      body: {},
                    );
                  },
                  icon: const Icon(
                    Icons.create_new_folder_outlined,
                  ),
                  label: const Text("New Chat"),
                ),
                const SizedBox(
                  width: 8,
                ),
              ],
            ),
            const Divider(),
            Expanded(
              child: InfiniteQueryBuilder(
                query: chatHistoryQuery,
                builder: (ctx, state, query) {
                  if (state.status == QueryStatus.loading &&
                      state.data == null) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state.status == QueryStatus.error) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Failed to load chat history.',
                            style: TextStyle(color: Colors.red.shade700),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: query.refetch,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }

                  final items = state.data?.expand((e) => e).toList() ?? [];

                  if (items.isEmpty) {
                    return const Center(child: Text("No chat history yet."));
                  }

                  return RefreshIndicator(
                    onRefresh: query.refetch,
                    child: ListView.separated(
                      controller: _scrollController,
                      itemCount: items.length + (!state.hasReachedMax ? 1 : 0),
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (context, index) {
                        if (index < items.length) {
                          final chat = items[index];
                          return ListTile(
                            title: Text(
                              chat.getStringValue("title") ?? "Untitled Chat",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              'Created: ${chat.created}', // Display creation date
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          );
                        } else if (!query.hasReachedMax()) {
                          return const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        } else {
                          return const SizedBox.shrink();
                        }
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
