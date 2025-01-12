import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:madari_client/features/doc_viewer/container/video_viewer/torrent_stat.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../../types/doc_source.dart';

MaterialVideoControlsThemeData getMobileVideoPlayer(
  BuildContext context, {
  required DocSource source,
  required Player player,
  required VoidCallback onSubtitleClick,
  required VoidCallback onAudioClick,
  required VoidCallback toggleScale,
  required VoidCallback onLibrarySelect,
}) {
  final mediaQuery = MediaQuery.of(context);

  return MaterialVideoControlsThemeData(
    topButtonBar: [
      MaterialCustomButton(
        onPressed: () {
          Navigator.of(context).pop();
        },
        icon: const Icon(
          Icons.arrow_back,
        ),
      ),
      Text(
        source.title.endsWith(".mp4")
            ? source.title.substring(0, source.title.length - 4)
            : source.title,
        style: Theme.of(context).textTheme.bodyLarge,
      ),
      const Spacer(),
    ],
    bufferingIndicatorBuilder: (source is TorrentSource)
        ? (ctx) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              child: TorrentStats(
                torrentHash: (source).infoHash,
              ),
            );
          }
        : null,
    brightnessGesture: true,
    seekGesture: true,
    seekOnDoubleTap: true,
    gesturesEnabledWhileControlsVisible: true,
    shiftSubtitlesOnControlsVisibilityChange: true,
    seekBarMargin: const EdgeInsets.only(bottom: 54),
    speedUpOnLongPress: true,
    speedUpFactor: 2,
    volumeGesture: true,
    bottomButtonBar: [
      const MaterialPlayOrPauseButton(),
      const MaterialPositionIndicator(),
      const Spacer(),
      MaterialCustomButton(
        onPressed: () {
          final speeds = [
            0.5,
            0.75,
            1.0,
            1.25,
            1.5,
            1.75,
            2.0,
            2.25,
            2.5,
            3.0,
            3.25,
            3.5,
            3.75,
            4.0,
            4.25,
            4.5,
            4.75,
            5.0
          ];
          showCupertinoModalPopup(
            context: context,
            builder: (ctx) => Card(
              child: Container(
                height: MediaQuery.of(context).size.height * 0.4,
                decoration: BoxDecoration(
                  color: Theme.of(context).dialogBackgroundColor,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        'Select Playback Speed',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: speeds.length,
                        itemBuilder: (context, index) {
                          final speed = speeds[index];
                          return ListTile(
                            title: Text('${speed}x'),
                            selected: player.state.rate == speed,
                            onTap: () {
                              player.setRate(speed);
                              Navigator.pop(context);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        icon: const Icon(Icons.speed),
      ),
      MaterialCustomButton(
        onPressed: () {
          onSubtitleClick();
        },
        icon: const Icon(Icons.subtitles),
      ),
      MaterialCustomButton(
        onPressed: () {
          onAudioClick();
        },
        icon: const Icon(Icons.audio_file),
      ),
      MaterialCustomButton(
        onPressed: () {
          toggleScale();
        },
        icon: const Icon(Icons.fit_screen_outlined),
      ),
    ],
    topButtonBarMargin: EdgeInsets.only(
      top: mediaQuery.padding.top,
    ),
    bottomButtonBarMargin: EdgeInsets.only(
      bottom: mediaQuery.viewInsets.bottom,
      left: 4.0,
      right: 4.0,
    ),
  );
}
