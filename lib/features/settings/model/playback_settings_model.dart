import 'package:flutter/material.dart';

class PlaybackSettings {
  bool autoPlay;
  double playbackSpeed;
  String defaultAudioTrack;
  bool disableHardwareAcceleration;
  bool disableSubtitles;
  String defaultSubtitleTrack;
  Color subtitleColor;
  double fontSize;
  bool externalPlayer;
  String? selectedExternalPlayer;
  int bufferSize;

  PlaybackSettings({
    this.autoPlay = true,
    this.playbackSpeed = 1.0,
    this.defaultAudioTrack = 'eng',
    this.disableHardwareAcceleration = false,
    this.disableSubtitles = false,
    this.defaultSubtitleTrack = 'eng',
    this.subtitleColor = Colors.white,
    this.fontSize = 16,
    this.externalPlayer = false,
    this.selectedExternalPlayer,
    this.bufferSize = 32,
  });

  Map<String, dynamic> toJson() => {
        'autoPlay': autoPlay,
        'playbackSpeed': playbackSpeed,
        'defaultAudioTrack': defaultAudioTrack,
        'defaultSubtitleTrack': defaultSubtitleTrack,
        'subtitleColor': subtitleColor.value,
        'fontSize': fontSize,
        'disableSubtitles': disableSubtitles,
      };

  factory PlaybackSettings.fromJson(Map<String, dynamic> json) {
    return PlaybackSettings(
      autoPlay: json['autoPlay'] ?? true,
      playbackSpeed: (json['playbackSpeed'] ?? 1.0).toDouble(),
      defaultAudioTrack: json['defaultAudioTrack'] ?? 'eng',
      defaultSubtitleTrack: json['defaultSubtitleTrack'] ?? 'eng',
      subtitleColor: Color(json['subtitleColor'] ?? Colors.white.value),
      fontSize: (json['fontSize'] ?? 16).toDouble(),
      disableSubtitles: json['disableSubtitles'] ?? false,
    );
  }
}
