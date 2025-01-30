import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:madari_client/features/video_player/container/options/settings_sheet.dart';
import 'package:madari_client/features/video_player/container/state/video_settings.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:provider/provider.dart';

import '../../streamio_addons/models/stremio_base_types.dart' as types;
import 'options/audio_track_selector.dart';
import 'options/scale_option.dart';
import 'options/subtitle_selector.dart';

class VideoMobile extends StatefulWidget {
  final VideoController controller;
  final types.Meta? meta;

  const VideoMobile({
    super.key,
    required this.controller,
    required this.meta,
  });

  @override
  State<VideoMobile> createState() => _VideoMobileState();
}

class _VideoMobileState extends State<VideoMobile> {
  late final GlobalKey<VideoState> key = GlobalKey<VideoState>();
  bool isLocked = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      key.currentState?.enterFullscreen();
    });
  }

  void _toggleLock(BuildContext context) {
    final settings = context.read<VideoSettingsProvider>();
    settings.toggleLock();
  }

  Future<void> _showCustomBottomSheet({
    required BuildContext context,
    required String title,
    required Widget child,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black87,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Divider(color: Colors.white24),
          Flexible(child: child),
        ],
      ),
    );
  }

  void _showSubtitleSelector(BuildContext context) {
    _showCustomBottomSheet(
      title: "Subtitles",
      context: context,
      child: SubtitleSelector(
        controller: widget.controller,
      ),
    );
  }

  void _showSettingsSheet(BuildContext context) {
    if (isLocked) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black87,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SettingsSheet(
        controller: widget.controller,
      ),
    );
  }

  void _showAudioTrackSelector(BuildContext context) {
    _showCustomBottomSheet(
      context: context,
      title: "Audio Tracks",
      child: AudioTrackSelector(
        controller: widget.controller,
      ),
    );
  }

  MaterialVideoControlsThemeData getFullscreenControl() {
    return kDefaultMaterialVideoControlsThemeDataFullscreen.copyWith(
      volumeGesture: !isLocked,
      brightnessGesture: !isLocked,
      seekGesture: !isLocked,
      gesturesEnabledWhileControlsVisible: false,
      speedUpOnLongPress: !isLocked,
      speedUpFactor: 2,
      controlsHoverDuration: const Duration(seconds: 3),
      controlsTransitionDuration: const Duration(milliseconds: 300),
      seekBarMargin: const EdgeInsets.only(
        bottom: 34,
        left: 34,
        right: 24,
      ),
      topButtonBar: [
        MaterialCustomButton(
          onPressed: isLocked
              ? () {}
              : () {
                  Navigator.of(context, rootNavigator: true).pop();
                },
          icon: Icon(
            Icons.arrow_back,
            color: isLocked ? Colors.grey : Colors.white,
          ),
        ),
        if (widget.meta?.currentVideo != null)
          Expanded(
            child: Text(
              "${widget.meta?.name} - ${widget.meta?.currentVideo?.name ?? widget.meta?.currentVideo?.title} - S${widget.meta!.currentVideo?.season} E${widget.meta?.currentVideo?.episode}",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        if (widget.meta?.currentVideo == null)
          Expanded(
            child: Text(
              widget.meta?.name ?? "",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        MaterialCustomButton(
          onPressed: () => _toggleLock(context),
          icon: Icon(
            isLocked ? Icons.lock : Icons.lock_open,
            color: Colors.white,
          ),
        ),
      ],
      seekBarThumbColor: Theme.of(context).primaryColorLight,
      seekBarColor: Theme.of(context).primaryColor,
      seekBarPositionColor: Theme.of(context).focusColor,
      bottomButtonBar: [
        const MaterialPlayOrPauseButton(),
        const MaterialSkipNextButton(),
        const SizedBox(width: 12),
        const MaterialPositionIndicator(),
        const Spacer(),
        MaterialCustomButton(
          onPressed: () => _showSubtitleSelector(context),
          icon: const Icon(Icons.subtitles, color: Colors.white),
        ),
        MaterialCustomButton(
          onPressed: () => _showAudioTrackSelector(context),
          icon: const Icon(Icons.audiotrack, color: Colors.white),
        ),
        const ScaleOption(),
        MaterialCustomButton(
          onPressed: () => _showSettingsSheet(context),
          icon: const Icon(Icons.settings, color: Colors.white),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<VideoSettingsProvider>(
      builder: (context, data, _) {
        return MaterialVideoControlsTheme(
          fullscreen: getFullscreenControl(),
          normal: const MaterialVideoControlsThemeData(),
          child: Video(
            key: key,
            onEnterFullscreen: () async {
              await defaultEnterNativeFullscreen();
            },
            onExitFullscreen: () async {
              await defaultExitNativeFullscreen();
              context.pop();
            },
            controller: widget.controller,
            fit: data.isFilled ? BoxFit.fitWidth : BoxFit.fitHeight,
          ),
        );
      },
    );
  }
}
