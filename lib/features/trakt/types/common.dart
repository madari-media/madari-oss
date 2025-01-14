class TraktProgress {
  final String id;
  final int? episode;
  final int? season;
  final double progress;
  final int? traktId;

  TraktProgress({
    required this.id,
    this.episode,
    this.season,
    required this.progress,
    this.traktId,
  });
}

class TraktShowWatched {
  final String title;
  final List<dynamic> seasons;
  final TraktIds ids;
  final DateTime? lastWatchedAt;
  final int plays;
  List<TraktEpisodeWatched>? episodes; // Add episodes list

  TraktShowWatched({
    required this.title,
    required this.seasons,
    required this.ids,
    this.lastWatchedAt,
    required this.plays,
    this.episodes,
  });
}

class TraktIds {
  final int? trakt;
  final String? slug;
  final String? imdb;
  final int? tmdb;

  TraktIds({
    this.trakt,
    this.slug,
    this.imdb,
    this.tmdb,
  });

  factory TraktIds.fromJson(Map<String, dynamic> json) => TraktIds(
    trakt: json['trakt'],
    slug: json['slug'],
    imdb: json['imdb'],
    tmdb: json['tmdb'],
  );
}

class TraktEpisodeWatched {
  final int season;
  final int episode;
  final DateTime watchedAt;

  TraktEpisodeWatched({
    required this.season,
    required this.episode,
    required this.watchedAt,
  });
}