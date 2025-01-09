import 'dart:async';

import 'package:flutter/material.dart';
import 'package:madari_client/features/connections/service/base_connection_service.dart';
import 'package:madari_client/features/trakt/service/trakt.service.dart';

import '../../connections/widget/base/render_library_list.dart';
import '../../settings/screen/trakt_integration_screen.dart';
import '../service/trakt_cache.service.dart';

class TraktContainer extends StatefulWidget {
  final String loadId;
  const TraktContainer({
    super.key,
    required this.loadId,
  });

  @override
  State<TraktContainer> createState() => TraktContainerState();
}

class TraktContainerState extends State<TraktContainer> {
  late final TraktCacheService _cacheService;
  List<LibraryItem>? _cachedItems;
  bool _isLoading = false;
  String? _error;

  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _cacheService = TraktCacheService();
    _loadData();

    _timer = Timer.periodic(
      const Duration(seconds: 30),
      (timer) {
        _loadData();
      },
    );
  }

  @override
  void dispose() {
    super.dispose();
    _timer.cancel();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final items = await _cacheService.fetchData(widget.loadId);
      if (mounted) {
        setState(() {
          _cachedItems = items;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> refresh() async {
    await _cacheService.refresh(widget.loadId);
    await _loadData();
  }

  String get title {
    return traktCategories
        .firstWhere((item) => item.key == widget.loadId)
        .title;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                title,
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
                              title: Text("Trakt - $title"),
                            ),
                            body: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: RenderListItems(
                                items: _cachedItems ?? [],
                                error: _error,
                                hasError: _error != null,
                                heroPrefix: "trakt_up_next${widget.loadId}",
                                service: TraktService.stremioService!,
                                isGrid: true,
                                isWide: false,
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
          Stack(
            children: [
              if ((_cachedItems ?? []).isEmpty && !_isLoading)
                const Positioned.fill(
                  child: Center(
                    child: Text("Nothing to see here"),
                  ),
                ),
              SizedBox(
                height: getListHeight(context),
                child: _isLoading
                    ? SpinnerCards(
                        isWide: widget.loadId == "up_next_series",
                      )
                    : RenderListItems(
                        isWide: widget.loadId == "up_next_series",
                        items: _cachedItems ?? [],
                        error: _error,
                        hasError: _error != null,
                        heroPrefix: "trakt_up_next${widget.loadId}",
                        service: TraktService.stremioService!,
                      ),
              ),
            ],
          )
        ],
      ),
    );
  }
}
