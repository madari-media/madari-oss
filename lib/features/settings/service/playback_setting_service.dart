import 'dart:convert';

import 'package:cached_query_flutter/cached_query_flutter.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../pocketbase/service/pocketbase.service.dart';
import '../model/playback_settings_model.dart';

class PlaybackSettingsService {
  static const _localSettingsKey = 'playback_settings_local';
  static final PlaybackSettingsService instance = PlaybackSettingsService._();

  PlaybackSettingsService._();

  PlaybackSettings? _cachedSettings;
  Map<String, String>? _cachedLanguages;

  Future<Map<String, String>> getLanguages() async {
    if (_cachedLanguages != null) return _cachedLanguages!;

    final String jsonString =
        await rootBundle.loadString('assets/data/languages.json');
    _cachedLanguages = Map<String, String>.from(json.decode(jsonString));
    return _cachedLanguages!;
  }

  Future<void> saveSettings(PlaybackSettings settings) async {
    final result = Query(
      key: "video_settings",
      queryFn: () {
        return getSettings();
      },
    );

    result.invalidateQuery();

    final prefs = await SharedPreferences.getInstance();
    final localSettings = {
      'disableHardwareAcceleration': settings.disableHardwareAcceleration,
      'externalPlayer': settings.externalPlayer,
      'selectedExternalPlayer': settings.selectedExternalPlayer,
      'bufferSize': settings.bufferSize,
      'fontSize': settings.fontSize,
    };

    await prefs.setString(_localSettingsKey, json.encode(localSettings));
    await AppPocketBaseService.instance.pb.collection('users').update(
      AppPocketBaseService.instance.pb.authStore.record!.id,
      body: {'config': settings.toJson()},
    );

    _cachedSettings = settings;
  }

  Future<PlaybackSettings> getSettings() async {
    if (_cachedSettings != null) return _cachedSettings!;

    final prefs = await SharedPreferences.getInstance();
    final localSettingsStr = prefs.getString(_localSettingsKey);
    final localSettings =
        localSettingsStr != null ? json.decode(localSettingsStr) : {};

    final record =
        await AppPocketBaseService.instance.pb.collection('users').getOne(
              AppPocketBaseService.instance.pb.authStore.record!.id,
            );

    final serverSettings = PlaybackSettings.fromJson(
      record.data['config'] ?? {},
    );

    _cachedSettings = PlaybackSettings(
      autoPlay: serverSettings.autoPlay,
      playbackSpeed: serverSettings.playbackSpeed,
      defaultAudioTrack: serverSettings.defaultAudioTrack,
      defaultSubtitleTrack: serverSettings.defaultSubtitleTrack,
      subtitleColor: serverSettings.subtitleColor,
      fontSize: (localSettings['fontSize'] ?? 16).toDouble(),
      disableHardwareAcceleration:
          localSettings['disableHardwareAcceleration'] ?? false,
      externalPlayer: localSettings['externalPlayer'] ?? false,
      selectedExternalPlayer: localSettings['selectedExternalPlayer'],
      disableSubtitles: serverSettings.disableSubtitles,
      bufferSize: (localSettings['bufferSize'] ?? 32),
    );

    return _cachedSettings!;
  }
}
