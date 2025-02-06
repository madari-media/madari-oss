import 'package:json_annotation/json_annotation.dart';

part 'zeku_player.g.dart';

class ZekuSyncer {
  ZekuSyncer();

  Future<WatchPoint> getPlayingTimestamp(PlayingTimestampRequest input) async {
    return WatchPoint(
      duration: const Duration(
        seconds: 10,
      ),
      request: input,
    );
  }

  Future<List<WatchPoint>> getPlaying(PlayingTimestampRequest input) async {
    return [];
  }
}

class WatchPoint {
  final Duration duration;
  final PlayingTimestampRequest request;

  WatchPoint({
    required this.duration,
    required this.request,
  });
}

@JsonSerializable()
class PlayingTimestampRequest {
  final String id;
  final int? episode;
  final int? season;

  PlayingTimestampRequest({
    required this.id,
    required this.episode,
    required this.season,
  });
}
