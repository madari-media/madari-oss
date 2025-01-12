import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:madari_client/features/doc_viewer/types/doc_source.dart';
import 'package:madari_client/utils/load_language.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import 'mobile_video_player.dart';

class VideoViewerMobile extends StatefulWidget {
  final VoidCallback onSubtitleSelect;
  final VoidCallback onLibrarySelect;
  final Player player;
  final DocSource source;
  final VideoController controller;
  final VoidCallback onAudioSelect;
  final PlaybackConfig config;
  final GlobalKey<VideoState> videoKey;

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
  });

  @override
  State<VideoViewerMobile> createState() => _VideoViewerMobileState();
}

class _VideoViewerMobileState extends State<VideoViewerMobile> {
  final Logger _logger = Logger('_VideoViewerMobileState');
  bool isScaled = false;

  @override
  build(BuildContext context) {
    final mobile = getMobileVideoPlayer(
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
}
