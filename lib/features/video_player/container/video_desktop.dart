import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:madari_client/features/video_player/container/options/settings_sheet.dart';
import 'package:madari_client/features/video_player/container/state/video_settings.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:provider/provider.dart';
import 'package:universal_platform/universal_platform.dart';

import '../../streamio_addons/models/stremio_base_types.dart' as types;
import 'options/always_on_top.dart';
import 'options/audio_track_selector.dart';
import 'options/scale_option.dart';
import 'options/subtitle_selector.dart';

class VideoDesktop extends StatefulWidget {
  final VideoController controller;
  final types.Meta? meta;

  const VideoDesktop({
    super.key,
    required this.controller,
    required this.meta,
  });

  @override
  State<VideoDesktop> createState() => _VideoDesktopState();
}

class _VideoDesktopState extends State<VideoDesktop> {
  bool isLocked = false;

  @override
  void initState() {
    super.initState();
  }

  void _toggleLock(BuildContext context) {
    final settings = context.read<VideoSettingsProvider>();
    settings.toggleLock();
  }

  Future<void> _showPopupMenu({
    required BuildContext context,
    required String title,
    required Widget child,
  }) {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: 400, // Fixed width for desktop
          child: child,
        ),
        backgroundColor: Colors.black87,
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showSubtitleSelector(BuildContext context) {
    _showPopupMenu(
      title: "Subtitles",
      context: context,
      child: SubtitleSelector(
        controller: widget.controller,
      ),
    );
  }

  void _showSettingsDialog(BuildContext context) {
    if (isLocked) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Settings"),
        content: SizedBox(
          width: 400,
          child: SettingsSheet(
            controller: widget.controller,
          ),
        ),
        backgroundColor: Colors.black87,
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showAudioTrackSelector(BuildContext context) {
    _showPopupMenu(
      context: context,
      title: "Audio Tracks",
      child: AudioTrackSelector(
        controller: widget.controller,
      ),
    );
  }

  MaterialDesktopVideoControlsThemeData getDesktopControls() {
    return MaterialDesktopVideoControlsThemeData(
      displaySeekBar: true,
      hideMouseOnControlsRemoval: true,
      toggleFullscreenOnDoublePress: true,
      modifyVolumeOnScroll: false,
      controlsHoverDuration: const Duration(seconds: 3),
      controlsTransitionDuration: const Duration(milliseconds: 300),
      seekBarMargin: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 0,
      ),
      topButtonBar: [
        MaterialCustomButton(
          onPressed: isLocked ? () {} : () => context.pop(),
          icon: Icon(
            Icons.arrow_back,
            color: isLocked ? Colors.grey : Colors.white,
          ),
        ),
        const SizedBox(
          width: 6,
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
      ],
      seekBarThumbColor: Theme.of(context).primaryColorLight,
      seekBarColor: Theme.of(context).primaryColor,
      seekBarPositionColor: Theme.of(context).focusColor,
      bottomButtonBar: [
        const MaterialPlayOrPauseButton(),
        const MaterialDesktopVolumeButton(),
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
        if (UniversalPlatform.isDesktop) const AlwaysOnTopButton(),
        const ScaleOption(),
        MaterialCustomButton(
          onPressed: () => _showSettingsDialog(context),
          icon: const Icon(Icons.settings, color: Colors.white),
        ),
        const MaterialFullscreenButton(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<VideoSettingsProvider>(
      builder: (context, data, _) {
        return MaterialDesktopVideoControlsTheme(
          normal: getDesktopControls(),
          fullscreen: getDesktopControls(),
          child: Video(
            controller: widget.controller,
            fit: data.isFilled ? BoxFit.fitWidth : BoxFit.fitHeight,
          ),
        );
      },
    );
  }
}
