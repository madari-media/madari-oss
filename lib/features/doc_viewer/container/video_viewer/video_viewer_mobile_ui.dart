import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:madari_client/features/connections/service/base_connection_service.dart';
import 'package:madari_client/features/doc_viewer/container/video_viewer/season_source.dart';
import 'package:madari_client/features/doc_viewer/container/video_viewer/torrent_stat.dart';
import 'package:madari_client/features/doc_viewer/types/doc_source.dart';
import 'package:madari_client/utils/load_language.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../../../connections/types/stremio/stremio_base.types.dart' as types;

class VideoViewerMobile extends StatefulWidget {
  final VoidCallback onSubtitleSelect;
  final VoidCallback onLibrarySelect;
  final Player player;
  final DocSource source;
  final VideoController controller;
  final VoidCallback onAudioSelect;
  final PlaybackConfig config;
  final GlobalKey<VideoState> videoKey;
  final LibraryItem? meta;
  final Future<void> Function(int index) onVideoChange;

  const VideoViewerMobile({
    super.key,
    required this.onLibrarySelect,
    required this.onSubtitleSelect,
    required this.player,
    required this.source,
    required this.controller,
    required this.onAudioSelect,
    required this.config,
    required this.videoKey,
    required this.meta,
    required this.onVideoChange,
  });

  @override
  State<VideoViewerMobile> createState() => _VideoViewerMobileState();
}

class _VideoViewerMobileState extends State<VideoViewerMobile> {
  final Logger _logger = Logger('_VideoViewerMobileState');
  bool isScaled = false;

  @override
  build(BuildContext context) {
    final mobile = _getMobileControls(
      context,
      onLibrarySelect: widget.onLibrarySelect,
      player: widget.player,
      source: widget.source,
      onSubtitleClick: widget.onSubtitleSelect,
      onAudioClick: widget.onAudioSelect,
      toggleScale: () {
        setState(() {
          isScaled = !isScaled;
        });
      },
    );

    String subtitleStyleName = widget.config.subtitleStyle ?? 'Normal';
    String subtitleStyleColor = widget.config.subtitleColor ?? 'white';
    double subtitleSize = widget.config.subtitleSize;

    Color hexToColor(String hexColor) {
      final hexCode = hexColor.replaceAll('#', '');
      try {
        return Color(int.parse('0x$hexCode'));
      } catch (e) {
        return Colors.white;
      }
    }

    FontStyle getFontStyleFromString(String styleName) {
      switch (styleName.toLowerCase()) {
        case 'italic':
          return FontStyle.italic;
        case 'normal':
        default:
          return FontStyle.normal;
      }
    }

    FontStyle currentFontStyle = getFontStyleFromString(subtitleStyleName);
    return MaterialVideoControlsTheme(
      fullscreen: mobile,
      normal: mobile,
      child: Video(
        subtitleViewConfiguration: SubtitleViewConfiguration(
          style: TextStyle(
            color: hexToColor(subtitleStyleColor),
            fontSize: subtitleSize,
            fontStyle: currentFontStyle,
            fontWeight: FontWeight.bold,
          ),
        ),
        fit: isScaled ? BoxFit.fitWidth : BoxFit.fitHeight,
        pauseUponEnteringBackgroundMode: true,
        key: widget.videoKey,
        onExitFullscreen: () async {
          await defaultExitNativeFullscreen();
          if (context.mounted) Navigator.of(context).pop();
        },
        controller: widget.controller,
        controls: MaterialVideoControls,
      ),
    );
  }

  _getMobileControls(
    BuildContext context, {
    required DocSource source,
    required Player player,
    required VoidCallback onSubtitleClick,
    required VoidCallback onAudioClick,
    required VoidCallback toggleScale,
    required VoidCallback onLibrarySelect,
  }) {
    final mediaQuery = MediaQuery.of(context);
    final meta = widget.meta;

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
          meta.toString(),
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const Spacer(),
        if (meta is types.Meta)
          if (meta.type == "series")
            SeasonSource(
              meta: meta,
              isMobile: true,
              player: player,
              onVideoChange: (index) async {
                await widget.onVideoChange(index);
                setState(() {});
              },
            ),
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
}
