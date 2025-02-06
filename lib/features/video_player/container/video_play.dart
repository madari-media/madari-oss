import 'dart:async';

import 'package:flutter/material.dart';
import 'package:madari_client/features/settings/model/playback_settings_model.dart';
import 'package:madari_client/features/video_player/container/native.dart';
import 'package:madari_client/features/video_player/container/state/video_settings.dart';
import 'package:madari_client/features/video_player/container/video_desktop.dart';
import 'package:madari_client/features/video_player/container/video_mobile.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/src/subjects/behavior_subject.dart';
import 'package:universal_platform/universal_platform.dart';

import '../../streamio_addons/models/stremio_base_types.dart';
import '../service/video_eventer_default_track.dart';

typedef OnVideoChangeCallback = Future<bool> Function(
  int selectedIndex,
);

class VideoPlay extends StatefulWidget {
  final bool enabledHardwareAcceleration;
  final String? poster;
  final PlaybackSettings? settings;
  final Meta? meta;
  final int index;
  final String stream;
  final int bufferSize;
  final OnVideoChangeCallback onVideoChange;
  final BehaviorSubject<int> updateSubject;
  final PlaybackSettings data;

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
    required this.onVideoChange,
    required this.updateSubject,
    required this.data,
  });

  @override
  State<VideoPlay> createState() => _VideoPlayState();
}

class _VideoPlayState extends State<VideoPlay> {
  late String stream = widget.stream;
  late int index = widget.index;

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
  late VideoSettingsProvider _settings;
  late Debouncer _debouncer;
  late VideoEventerDefaultTrackSetter setter;

  @override
  void initState() {
    super.initState();

    _settings = context.read<VideoSettingsProvider>();
    _debouncer = Debouncer(
      duration: const Duration(milliseconds: 500),
    );
    _settings.addListener(_onSettingsChanged);

    setter = VideoEventerDefaultTrackSetter(
      player,
      widget.data,
    );

    player.open(
      Media(
        widget.stream,
        httpHeaders: {},
        extras: {},
      ),
    );

    player.play();
  }

  void _onSettingsChanged() {
    final platform = player.platform;
    if (platform is NativePlayer) {
      _debouncer.run(() {
        if (!UniversalPlatform.isWeb) {
          setDelay(platform, _settings);
        }
      });
    }
  }

  @override
  void didUpdateWidget(covariant VideoPlay oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.stream != stream) {
      stream = widget.stream;
      player.open(
        Media(
          stream,
        ),
      );
    }

    index = widget.index;
  }

  @override
  void dispose() {
    super.dispose();
    _settings.removeListener(_onSettingsChanged);
    setter.dispose();
    player.dispose();
  }

  late int selectedVideo = widget.index;

  @override
  Widget build(BuildContext context) {
    if (UniversalPlatform.isMobile) {
      return VideoMobile(
        controller: controller,
        meta: widget.meta,
        onVideoChange: widget.onVideoChange,
        index: index,
        updateSubject: widget.updateSubject,
      );
    }

    return VideoDesktop(
      controller: controller,
      meta: widget.meta,
      onVideoChange: widget.onVideoChange,
      updateSubject: widget.updateSubject,
    );
  }
}

class Debouncer {
  final Duration duration;
  Timer? _timer;

  Debouncer({
    this.duration = const Duration(milliseconds: 500),
  });

  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(duration, action);
  }

  void dispose() {
    _timer?.cancel();
  }
}
