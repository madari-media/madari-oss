import 'package:flutter/material.dart';
import 'package:madari_client/features/settings/model/playback_settings_model.dart';
import 'package:madari_client/features/video_player/container/video_desktop.dart';
import 'package:madari_client/features/video_player/container/video_mobile.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:universal_platform/universal_platform.dart';

import '../../streamio_addons/models/stremio_base_types.dart';

class VideoPlay extends StatefulWidget {
  final bool enabledHardwareAcceleration;
  final String? poster;
  final PlaybackSettings? settings;
  final Meta? meta;
  final int index;
  final String stream;
  final int bufferSize;

  const VideoPlay({
    super.key,
    required this.enabledHardwareAcceleration,
    required this.poster,
    this.settings,
    this.meta,
    required void Function(String message) onError,
    required this.index,
    required this.stream,
    required this.bufferSize,
  });

  @override
  State<VideoPlay> createState() => _VideoPlayState();
}

class _VideoPlayState extends State<VideoPlay> {
  late String stream = widget.stream;

  late final player = Player(
    configuration: PlayerConfiguration(
      title: "Madari",
      bufferSize: widget.bufferSize * 1024 * 1024,
    ),
  );

  late final controller = VideoController(
    player,
    configuration: VideoControllerConfiguration(
      enableHardwareAcceleration: widget.enabledHardwareAcceleration,
    ),
  );

  @override
  void initState() {
    super.initState();

    player.open(
      Media(
        widget.stream,
        httpHeaders: {},
        extras: {},
      ),
    );

    player.play();
  }

  @override
  void dispose() {
    super.dispose();

    player.dispose();
  }

  late int selectedVideo = widget.index;

  @override
  Widget build(BuildContext context) {
    if (UniversalPlatform.isMobile) {
      return VideoMobile(
        controller: controller,
        meta: widget.meta,
      );
    }

    return VideoDesktop(
      controller: controller,
      meta: widget.meta,
    );
  }
}
