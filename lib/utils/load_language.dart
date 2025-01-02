import 'dart:convert';

import 'package:flutter/cupertino.dart';

import '../engine/engine.dart';

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

  return PlaybackConfig(
    autoPlay: playbackConfig['autoPlay'] ?? true,
    playbackSpeed: playbackConfig['playbackSpeed']?.toDouble() ?? 1,
    defaultAudioTrack: playbackConfig['defaultAudioTrack'] ?? 'eng',
    defaultSubtitleTrack: playbackConfig['defaultSubtitleTrack'] ?? 'eng',
  );
}

class PlaybackConfig {
  final bool autoPlay;
  final double playbackSpeed;
  final String defaultAudioTrack;
  final String defaultSubtitleTrack;

  PlaybackConfig({
    required this.autoPlay,
    required this.playbackSpeed,
    required this.defaultAudioTrack,
    required this.defaultSubtitleTrack,
  });
}
