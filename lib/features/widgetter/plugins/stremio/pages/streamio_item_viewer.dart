import 'package:cached_query_flutter/cached_query_flutter.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:madari_client/features/streamio_addons/service/stremio_addon_service.dart';
import 'package:madari_engine/madari_engine.dart';

import '../containers/shimmer.dart';
import '../containers/streamio_viewer_content.dart';

final _logger = Logger('StreamioItemViewer');

class StreamioItemViewer extends StatefulWidget {
  final Meta? meta;
  final String id;
  final String type;
  final String? name;
  final String? image;
  final String? prefix;

  const StreamioItemViewer({
    super.key,
    this.meta,
    required this.id,
    required this.type,
    this.image,
    this.name,
    this.prefix,
  });

  @override
  State<StreamioItemViewer> createState() => _StreamioItemViewerState();
}

class _StreamioItemViewerState extends State<StreamioItemViewer> {
  final service = StremioAddonService.instance;
  late Query<Meta?> _meta;

  @override
  void initState() {
    super.initState();
    _logger.info('Initializing StreamioItemViewer for ${widget.id}');

    _meta = Query(
      key: "meta${widget.type}${widget.id}",
      config: QueryConfig(
        cacheDuration: const Duration(days: 30),
        refetchDuration: const Duration(hours: 8),
      ),
      queryFn: () async {
        try {
          final result = await service.getMeta(widget.type, widget.id);
          _logger.fine('Meta data fetched successfully');

          if (widget.meta == null) {
            return result;
          }

          if (result == null) {
            return null;
          }

          if (widget.meta?.poster == null) {
            return result;
          }

          return result.copyWith(
            poster: widget.meta!.poster!,
            background: widget.meta?.background ?? result.background,
          );
        } catch (e, stack) {
          _logger.severe('Error fetching meta data', e, stack);
          rethrow;
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      child: Scaffold(
        body: Stack(
          children: [
            QueryBuilder(
              query: _meta,
              builder: (context, data) {
                if (data.status == QueryStatus.loading || data.data == null) {
                  return Container(
                    constraints: const BoxConstraints(
                      maxWidth: 600,
                    ),
                    child: StreamioShimmer(
                      image: widget.image,
                      tag: widget.prefix ?? widget.meta?.id ?? "",
                    ),
                  );
                }

                if (data.status == QueryStatus.error) {
                  _logger.warning('Error in query builder', data.error);
                  return Center(
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
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${data.error}',
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .error
                                        .withValues(alpha: 0.7),
                                  ),
                        ),
                        const SizedBox(height: 24),
                        FilledButton.icon(
                          onPressed: () {
                            _meta.refetch();
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Try Again'),
                        ),
                      ],
                    ),
                  );
                }

                final meta = data.data ?? widget.meta;
                if (meta == null) {
                  _logger.warning('No meta data available');
                  return const Center(child: Text('No content available'));
                }

                return StreamioViewerContent(
                  meta: meta,
                  type: widget.type,
                  prefix: widget.prefix,
                );
              },
            ),
            Positioned(
              child: SafeArea(
                child: IconButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(
                    Icons.arrow_back,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
