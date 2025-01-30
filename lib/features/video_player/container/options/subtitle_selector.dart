import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../../../settings/service/playback_setting_service.dart';

class SubtitleSelector extends StatefulWidget {
  final VideoController controller;

  const SubtitleSelector({
    super.key,
    required this.controller,
  });

  @override
  State<SubtitleSelector> createState() => _SubtitleSelectorState();
}

class _SubtitleSelectorState extends State<SubtitleSelector> {
  final languages = PlaybackSettingsService.instance.getLanguages();

  String getTitle(SubtitleTrack trakt, Map<String, String>? data) {
    if (trakt.id == "auto") {
      return "Automatic";
    }

    if (trakt.id == "no") {
      return "No subtitles";
    }

    final result = trakt.language ?? trakt.id;

    final returnValue =
        data?.containsKey(result) == true ? data![result]! : result;

    return "$returnValue ${(trakt.title ?? "").trim() == "" ? "" : "(${trakt.title?.trim()})"}"
        .trim();
  }

  @override
  Widget build(BuildContext context) {
    final tracks = widget.controller.player.state.tracks.subtitle;

    return FutureBuilder(
      future: languages,
      builder: (context, state) {
        return ListView.builder(
          shrinkWrap: true,
          itemCount: tracks.length,
          itemBuilder: (context, index) {
            final track = tracks[index];

            return ListTile(
              title: Text(getTitle(track, state.data)),
              selected:
                  widget.controller.player.state.track.subtitle.id == track.id,
              onTap: () {
                widget.controller.player.setSubtitleTrack(track);
                Navigator.pop(context);
              },
            );
          },
        );
      },
    );
  }
}
