import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:madari_client/features/connections/service/base_connection_service.dart';
import 'package:madari_client/features/doc_viewer/container/video_viewer/season_source.dart';
import 'package:madari_client/features/doc_viewer/container/video_viewer/torrent_stat.dart';
import 'package:madari_client/features/doc_viewer/types/doc_source.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:window_manager/window_manager.dart';

import '../../../connections/types/stremio/stremio_base.types.dart';

MaterialDesktopVideoControlsThemeData getDesktopControls(
  BuildContext context, {
  required DocSource source,
  required Player player,
  Widget? library,
  required Function() onSubtitleSelect,
  required Function() onAudioSelect,
  LibraryItem? meta,
  required Function(int index) onVideoChange,
}) {
  return MaterialDesktopVideoControlsThemeData(
    toggleFullscreenOnDoublePress: true,
    displaySeekBar: true,
    topButtonBar: [
      SafeArea(
        child: MaterialDesktopCustomButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      SafeArea(
        child: Center(
          child: SizedBox(
            width: MediaQuery.of(context).size.width - 120,
            child: Text(
              (meta is Meta && meta.currentVideo != null)
                  ? "${meta.name ?? ""}  S${meta.currentVideo?.season} E${meta.currentVideo?.episode}"
                  : source.title.endsWith(".mp4")
                      ? source.title.substring(0, source.title.length - 4)
                      : source.title,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ),
      ),
      const Spacer(),
      if (meta is Meta)
        if (meta.type == "series")
          SeasonSource(
            meta: meta,
            isMobile: false,
            player: player,
            onVideoChange: onVideoChange,
          ),
    ],
    bufferingIndicatorBuilder: source is TorrentSource
        ? (ctx) {
            return TorrentStats(
              torrentHash: source.infoHash,
            );
          }
        : null,
    playAndPauseOnTap: true,
    bottomButtonBar: [
      const MaterialDesktopSkipPreviousButton(),
      const MaterialDesktopPlayOrPauseButton(),
      const MaterialDesktopSkipNextButton(),
      const MaterialDesktopVolumeButton(),
      const MaterialDesktopPositionIndicator(),
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
            2.5,
            3.0,
            3.5,
            4.0,
            4.5,
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
      MaterialDesktopCustomButton(
        onPressed: onSubtitleSelect,
        icon: const Icon(Icons.subtitles),
      ),
      const SizedBox(
        width: 12,
      ),
      MaterialDesktopCustomButton(
        onPressed: onAudioSelect,
        icon: const Icon(Icons.audiotrack),
      ),
      if (!kIsWeb &&
          (Platform.isLinux || Platform.isWindows || Platform.isMacOS))
        const AlwaysOnTopButton(),
      const MaterialDesktopFullscreenButton(),
    ],
  );
}

class AlwaysOnTopButton extends StatefulWidget {
  const AlwaysOnTopButton({super.key});

  @override
  State<AlwaysOnTopButton> createState() => _AlwaysOnTopButtonState();
}

class _AlwaysOnTopButtonState extends State<AlwaysOnTopButton> {
  bool alwaysOnTop = false;

  @override
  void initState() {
    super.initState();

    windowManager.isAlwaysOnTop().then((value) {
      if (mounted) {
        setState(() {
          alwaysOnTop = value;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: "Always on top",
      child: MaterialDesktopCustomButton(
        onPressed: () async {
          if (await windowManager.isAlwaysOnTop()) {
            windowManager.setAlwaysOnTop(false);
            windowManager.setTitleBarStyle(TitleBarStyle.normal);
            setState(() {
              alwaysOnTop = false;
            });
            windowManager.setVisibleOnAllWorkspaces(false);
          } else {
            windowManager.setAlwaysOnTop(true);
            windowManager.setVisibleOnAllWorkspaces(true);
            windowManager.setTitleBarStyle(TitleBarStyle.hidden);
            setState(() {
              alwaysOnTop = true;
            });
          }
        },
        icon: Icon(
          alwaysOnTop ? Icons.push_pin : Icons.push_pin_outlined,
        ),
        iconSize: 22,
      ),
    );
  }
}
