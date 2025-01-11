class TraktProgress {
  final String id;
  final int? episode;
  final int? season;
  final double progress;

  TraktProgress({
    required this.id,
    this.episode,
    this.season,
    required this.progress,
  });
}
