import 'package:cached_query_flutter/cached_query_flutter.dart';
import 'package:flutter/material.dart';
import 'package:madari_client/features/connections/service/base_connection_service.dart';
import 'package:madari_client/features/trakt/service/trakt.service.dart';

import '../../connections/widget/base/render_library_list.dart';
import '../../settings/screen/trakt_integration_screen.dart';

class TraktContainer extends StatefulWidget {
  final String loadId;
  const TraktContainer({
    super.key,
    required this.loadId,
  });

  @override
  State<TraktContainer> createState() => _TraktContainerState();
}

class _TraktContainerState extends State<TraktContainer> {
  late Query<List<LibraryItem>> _query;

  @override
  void initState() {
    super.initState();

    _query = Query(
      key: widget.loadId,
      config: QueryConfig(
        cacheDuration: const Duration(days: 30),
        refetchDuration: const Duration(minutes: 1),
        storageDuration: const Duration(days: 30),
      ),
      queryFn: () {
        switch (widget.loadId) {
          case "up_next":
          case "up_next_series":
            return TraktService.instance!.getUpNextSeries();
          case "continue_watching":
            return TraktService.instance!.getContinueWatching();
          case "upcoming_schedule":
            return TraktService.instance!.getUpcomingSchedule();
          case "watchlist":
            return TraktService.instance!.getWatchlist();
          case "show_recommendations":
            return TraktService.instance!.getShowRecommendations();
          case "movie_recommendations":
            return TraktService.instance!.getMovieRecommendations();
          default:
            throw Exception("Invalid loadId: ${widget.loadId}");
        }
      },
    );
  }

  String get title {
    return traktCategories
        .firstWhere((item) => item.key == widget.loadId)
        .title;
  }

  @override
  Widget build(BuildContext context) {
    return QueryBuilder(
      query: _query,
      builder: (context, snapshot) {
        final theme = Theme.of(context);
        final item = snapshot.data;

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
                                    items: item ?? [],
                                    error: snapshot.error,
                                    hasError:
                                        snapshot.status == QueryStatus.error,
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
                  if ((item ?? []).isEmpty &&
                      snapshot.status != QueryStatus.loading)
                    const Positioned.fill(
                      child: Center(
                        child: Text("Nothing to see here"),
                      ),
                    ),
                  SizedBox(
                    height: getListHeight(context),
                    child: snapshot.status == QueryStatus.loading
                        ? SpinnerCards(
                            isWide: widget.loadId == "up_next_series",
                          )
                        : RenderListItems(
                            isWide: widget.loadId == "up_next_series",
                            items: item ?? [],
                            error: snapshot.error,
                            hasError: snapshot.status == QueryStatus.error,
                            heroPrefix: "trakt_up_next${widget.loadId}",
                            service: TraktService.stremioService!,
                          ),
                  ),
                ],
              )
            ],
          ),
        );
      },
    );
  }
}
