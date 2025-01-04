import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:madari_client/utils/external_player.dart';

import '../engine/engine.dart';

part 'load_language.g.dart';

Future<Map<String, String>> loadLanguages(BuildContext context) async {
  final data = await DefaultAssetBundle.of(context)
      .loadString("assets/data/languages.json");

  final result = jsonDecode(data);

  final Map<String, String> availableLanguages = {};

  for (final entry in result.entries) {
    availableLanguages[(entry as MapEntry).key as String] =
        entry.value as String;
  }

  return availableLanguages;
}

PlaybackConfig getPlaybackConfig() {
  final user = AppEngine.engine.pb.authStore.record;
  if (user == null) {
    throw Exception('User not authenticated');
  }

  final config = user.data['config'] as Map<String, dynamic>? ?? {};
  final playbackConfig = config['playback'] as Map<String, dynamic>? ?? {};

  return PlaybackConfig.fromJson(playbackConfig);
}

@JsonSerializable()
class PlaybackConfig {
  @JsonKey(defaultValue: true)
  final bool autoPlay;
  @JsonKey(defaultValue: 1.0)
  final double playbackSpeed;
  @JsonKey(defaultValue: "eng")
  final String defaultAudioTrack;
  @JsonKey(defaultValue: "eng")
  final String defaultSubtitleTrack;

  @JsonKey(defaultValue: false)
  final bool externalPlayer;
  final Map<String, String?>? externalPlayerId;

  PlaybackConfig({
    required this.autoPlay,
    required this.playbackSpeed,
    required this.defaultAudioTrack,
    required this.defaultSubtitleTrack,
    required this.externalPlayer,
    this.externalPlayerId,
  });

  String? get currentPlayerPackage {
    return externalPlayerId?.containsKey(getPlatformInString()) == true
        ? externalPlayerId![getPlatformInString()]
        : null;
  }

  factory PlaybackConfig.fromJson(Map<String, dynamic> config) =>
      _$PlaybackConfigFromJson(config);
}
