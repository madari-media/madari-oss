import 'package:cached_query_flutter/cached_query_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:madari_client/features/connections/service/base_connection_service.dart';

import '../features/connections/widget/base/render_library_list.dart';
import '../features/getting_started/container/getting_started.dart';

class HomeTabPage extends StatefulWidget {
  final String? search;
  final bool hideAppBar;

  static String get routeName => "/";

  const HomeTabPage({
    super.key,
    this.search,
    this.hideAppBar = kIsWeb,
  });

  @override
  State<HomeTabPage> createState() => _HomeTabPageState();
}

class _HomeTabPageState extends State<HomeTabPage> {
  final query = Query(
    queryFn: () => BaseConnectionService.getLibraries(),
    key: [
      "home",
    ],
  );

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      query.refetch();
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDesktop = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      appBar: (widget.hideAppBar || isDesktop) || widget.search?.trim() == ""
          ? null
          : AppBar(
              title: Text(
                "Madari",
                style: GoogleFonts.montserrat(),
              ),
            ),
      body: QueryBuilder(
        query: query,
        builder: (context, state) {
          if (QueryStatus.error == state.status) {
            return _buildError(state.error);
          }

          final data = state.data;

          if (data == null) {
            return const Text("Loading");
          }

          if (data.data.isEmpty) {
            return Padding(
              padding: const EdgeInsets.only(
                bottom: 24,
                left: 12,
                right: 12,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: GettingStartedScreen(
                  onCallback: () {
                    query.refetch();
                  },
                ),
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 8.0,
              horizontal: 16.0,
            ),
            child: ListView.builder(
              itemBuilder: (item, index) {
                final item = data.data[index];

                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            item.title,
                            style: theme.textTheme.bodyLarge,
                          ),
                          const Spacer(),
                          SizedBox(
                            height: 30,
                            child: TextButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) {
                                      return Scaffold(
                                        appBar: AppBar(
                                          title: Text(item.title),
                                        ),
                                        body: SizedBox(
                                          height: MediaQuery.of(context)
                                                  .size
                                                  .height -
                                              96,
                                          child: Padding(
                                            padding: const EdgeInsets.all(10.0),
                                            child: RenderLibraryList(
                                              item: item,
                                              isGrid: true,
                                              filters: [
                                                if ((widget.search ?? "")
                                                        .trim() !=
                                                    "")
                                                  ConnectionFilterItem(
                                                    title: "search",
                                                    value: widget.search,
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                );
                              },
                              child: Text(
                                "Show more",
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: Colors.white70,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 8,
                      ),
                      RenderLibraryList(
                        item: item,
                        filters: [
                          if ((widget.search ?? "").trim() != "")
                            ConnectionFilterItem(
                              title: "search",
                              value: widget.search,
                            ),
                        ],
                      ),
                    ],
                  ),
                );
              },
              itemCount: data.data.length,
            ),
          );
        },
      ),
    );
  }

  _buildError(Error? error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 60,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Oops! Something went wrong',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error?.toString() ?? 'Failed to load libraries',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => query.refetch(),
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}
