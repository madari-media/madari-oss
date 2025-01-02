import 'package:json_annotation/json_annotation.dart';

part 'base_watch_history.g.dart';

abstract class BaseWatchHistory {
  Future<List<WatchHistory>> getItemWatchHistory({
    required List<WatchHistoryGetRequest> ids,
  });
  Future<void> saveWatchHistory({
    required WatchHistory history,
  });
}

class WatchHistoryGetRequest {
  final String id;
  final String? season;
  final String? episode;

  WatchHistoryGetRequest({
    required this.id,
    this.season,
    this.episode,
  });
}

@JsonSerializable()
class WatchHistory {
  String id;
  final String? season;
  final String? episode;
  final int progress;
  final double duration;

  WatchHistory({
    required this.id,
    this.season,
    this.episode,
    required this.progress,
    required this.duration,
  });

  Map<String, dynamic>? toJson() => _$WatchHistoryToJson(this);

  factory WatchHistory.fromJson(Map<String, dynamic> json) =>
      _$WatchHistoryFromJson(json);
}
