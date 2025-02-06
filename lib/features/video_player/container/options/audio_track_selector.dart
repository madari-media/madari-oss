import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../../../settings/service/playback_setting_service.dart';

class AudioTrackSelector extends StatefulWidget {
  final VideoController controller;
  const AudioTrackSelector({
    super.key,
    required this.controller,
  });

  @override
  State<AudioTrackSelector> createState() => _AudioTrackSelectorState();
}

class _AudioTrackSelectorState extends State<AudioTrackSelector> {
  final languages = PlaybackSettingsService.instance.getLanguages();

  String getTitle(AudioTrack trakt, Map<String, String>? data) {
    if (trakt.id == "auto") {
      return "Automatic";
    }

    if (trakt.id == "no") {
      return "No audio";
    }

    final result = trakt.language ?? trakt.id;

    return data?.containsKey(result) == true ? data![result]! : result;
  }

  @override
  Widget build(BuildContext context) {
    final tracks = widget.controller.player.state.tracks.audio;

    return FutureBuilder(
      future: languages,
      builder: (context, state) {
        if (state.connectionState != ConnectionState.done) {
          return const CircularProgressIndicator();
        }

        return ListView.builder(
          shrinkWrap: true,
          itemCount: tracks.length,
          itemBuilder: (context, index) {
            final track = tracks[index];

            String trackTitle = "";

            if (track.codec != null) {
              trackTitle += " codec: ${track.codec}";
            }

            if (track.channels != null) {
              trackTitle += " channels: ${track.channels}";
            }

            if (track.bitrate != null) {
              trackTitle += " bitrate: ${track.bitrate}";
            }

            return ListTile(
              title: Text(getTitle(track, state.data)),
              subtitle:
                  trackTitle.trim() != "" ? Text(trackTitle.trim()) : null,
              selected:
                  widget.controller.player.state.track.audio.id == track.id,
              onTap: () {
                widget.controller.player.setAudioTrack(track);
                Navigator.pop(context);
              },
            );
          },
        );
      },
    );
  }
}
