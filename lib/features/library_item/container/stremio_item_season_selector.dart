import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'package:madari_client/features/connection/types/stremio.dart';

class StremioItemSeasonSelector extends StatefulWidget {
  final Meta meta;
  final int? season;
  final bool needToPopBeforeSelection;

  const StremioItemSeasonSelector({
    super.key,
    required this.meta,
    this.season,
    this.needToPopBeforeSelection = false,
  });

  @override
  State<StremioItemSeasonSelector> createState() =>
      _StremioItemSeasonSelectorState();
}

class _StremioItemSeasonSelectorState extends State<StremioItemSeasonSelector>
    with SingleTickerProviderStateMixin {
  int? selectedSeason;
  late TabController _tabController;
  late final Map<int, List<Video>> seasonMap;

  @override
  void initState() {
    super.initState();
    seasonMap = _organizeEpisodes();
    selectedSeason = widget.season;

    _tabController = TabController(
      length: seasonMap.keys.length,
      vsync: this,
      initialIndex: selectedSeason ?? (seasonMap.keys.first == 0 ? 1 : 0),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Map<int, List<Video>> _organizeEpisodes() {
    final episodes = widget.meta.videos ?? [];
    return groupBy(episodes, (Video video) => video.season);
  }

  @override
  Widget build(BuildContext context) {
    final seasons = seasonMap.keys.toList()..sort();

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            splashBorderRadius: BorderRadius.circular(50),
            automaticIndicatorColorAdjustment: true,
            dividerColor: Colors.transparent,
            tabs: seasons.map((season) {
              if (season == 0) {
                return const Tab(text: "Specials");
              }
              return Tab(text: 'Season $season');
            }).toList(),
          ),
        ),
        const SliverToBoxAdapter(
          child: SizedBox(height: 16),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final season = seasons[_tabController.index];
              final episodes = seasonMap[season]!;
              if (index >= episodes.length) return null;

              final episode = episodes[index];
              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    if (widget.needToPopBeforeSelection) {
                      Navigator.of(context).pop();
                    }
                  },
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Episode number
                      SizedBox(
                        width: 30,
                        child: Text(
                          '${episode.episode}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      // Thumbnail
                      if (episode.thumbnail != null &&
                          episode.thumbnail!.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            episode.thumbnail!,
                            width: 160,
                            height: 90,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 160,
                                height: 90,
                                color: Colors.grey[800],
                              );
                            },
                          ),
                        )
                      else
                        Container(
                          width: 160,
                          height: 90,
                          decoration: BoxDecoration(
                            color: Colors.grey[800],
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      const SizedBox(width: 16),
                      // Episode details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              episode.name ?? 'Episode ${episode.episode}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (episode.released != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                intl.DateFormat('MMMM dd yyyy')
                                    .format(episode.released!),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[400],
                                ),
                              ),
                            ],
                            if (episode.overview != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                episode.overview!,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[300],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
            childCount: seasonMap[seasons[_tabController.index]]?.length ?? 0,
          ),
        ),
      ],
    );
  }
}

Map<T, List<E>> groupBy<E, T>(Iterable<E> items, T Function(E) key) {
  final map = <T, List<E>>{};

  for (final item in items) {
    final keyValue = key(item);
    if (!map.containsKey(keyValue)) {
      map[keyValue] = [];
    }
    map[keyValue]!.add(item);
  }

  return map;
}
