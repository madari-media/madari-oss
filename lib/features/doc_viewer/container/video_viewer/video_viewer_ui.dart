import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:madari_client/features/connections/service/base_connection_service.dart';
import 'package:madari_client/features/doc_viewer/container/video_viewer/audio_track_selector.dart';
import 'package:madari_client/features/doc_viewer/container/video_viewer/subtitle_selector.dart';
import 'package:madari_client/features/doc_viewer/container/video_viewer/tv_controls.dart';
import 'package:madari_client/features/doc_viewer/container/video_viewer/video_viewer_mobile_ui.dart';
import 'package:madari_client/features/doc_viewer/types/doc_source.dart';
import 'package:madari_client/utils/load_language.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../../../../utils/tv_detector.dart';
import '../../../connections/widget/base/render_stream_list.dart';
import 'desktop_video_player.dart';

class VideoViewerUi extends StatefulWidget {
  final VideoController controller;
  final Player player;
  final PlaybackConfig config;
  final DocSource source;
  final VoidCallback onLibrarySelect;
  final String title;
  final BaseConnectionService? service;
  final LibraryItem? meta;

  const VideoViewerUi({
    super.key,
    required this.controller,
    required this.player,
    required this.config,
    required this.source,
    required this.onLibrarySelect,
    required this.title,
    required this.service,
    this.meta,
  });

  @override
  State<VideoViewerUi> createState() => _VideoViewerUiState();
}

class _VideoViewerUiState extends State<VideoViewerUi> {
  late final GlobalKey<VideoState> key = GlobalKey<VideoState>();
  final Logger _logger = Logger('_VideoViewerUiState');

  final List<StreamSubscription> listeners = [];

  bool defaultConfigSelected = false;

  bool subtitleSelectionHandled = false;
  bool audioSelectionHandled = false;

  void setDefaultAudioTracks(Tracks tracks) {
    if (defaultConfigSelected == true &&
        (tracks.audio.length <= 1 || tracks.audio.length <= 1)) {
      return;
    }

    defaultConfigSelected = true;

    widget.controller.player.setRate(widget.config.playbackSpeed);

    final defaultSubtitle = widget.config.defaultSubtitleTrack;
    final defaultAudio = widget.config.defaultAudioTrack;

    for (final item in tracks.audio) {
      if ((defaultAudio == item.id ||
              defaultAudio == item.language ||
              defaultAudio == item.title) &&
          audioSelectionHandled == false) {
        widget.controller.player.setAudioTrack(item);
        audioSelectionHandled = true;
        break;
      }
    }

    if (widget.config.disableSubtitle) {
      for (final item in tracks.subtitle) {
        if ((item.id == "no" || item.language == "no" || item.title == "no") &&
            subtitleSelectionHandled == false) {
          widget.controller.player.setSubtitleTrack(item);
          subtitleSelectionHandled = true;
        }
      }
    } else {
      for (final item in tracks.subtitle) {
        if ((defaultSubtitle == item.id ||
                defaultSubtitle == item.language ||
                defaultSubtitle == item.title) &&
            subtitleSelectionHandled == false) {
          subtitleSelectionHandled = true;
          widget.controller.player.setSubtitleTrack(item);
          break;
        }
      }
    }
  }

  @override
  void initState() {
    super.initState();

    final listenerComplete = widget.player.stream.completed.listen((completed) {
      if (completed) {
        widget.onLibrarySelect();
        key.currentState?.exitFullscreen();
      }
    });

    listeners.add(listenerComplete);

    if (!kIsWeb) {
      if (Platform.isAndroid || Platform.isIOS) {
        WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
          key.currentState?.enterFullscreen();
        });
      }
    }

    final listener = widget.player.stream.tracks.listen((tracks) {
      if (mounted) {
        setDefaultAudioTracks(tracks);
      }
    });

    listeners.add(listener);
  }

  @override
  void dispose() {
    super.dispose();

    for (final listener in listeners) {
      listener.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    return _buildBody(context);
  }

  _buildBody(BuildContext context) {
    if (DeviceDetector.isTV()) {
      return MaterialTvVideoControlsTheme(
        fullscreen: const MaterialTvVideoControlsThemeData(),
        normal: const MaterialTvVideoControlsThemeData(),
        child: Video(
          width: MediaQuery.of(context).size.width,
          fit: BoxFit.fitWidth,
          controller: widget.controller,
          controls: MaterialTvVideoControls,
        ),
      );
    }

    switch (Theme.of(context).platform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
        return VideoViewerMobile(
          onLibrarySelect: widget.onLibrarySelect,
          onSubtitleSelect: onSubtitleSelect,
          player: widget.player,
          source: widget.source,
          controller: widget.controller,
          onAudioSelect: onAudioSelect,
          config: widget.config,
          videoKey: key,
        );
      default:
        return _buildDesktop(context);
    }
  }

  _buildDesktop(BuildContext context) {
    final desktop = getDesktopControls(
      context,
      player: widget.player,
      source: widget.source,
      onAudioSelect: onAudioSelect,
      onSubtitleSelect: onSubtitleSelect,
    );

    return MaterialDesktopVideoControlsTheme(
      normal: desktop,
      fullscreen: desktop,
      child: Video(
        key: key,
        width: MediaQuery.of(context).size.width,
        fit: BoxFit.fitWidth,
        controller: widget.controller,
        controls: MaterialDesktopVideoControls,
      ),
    );
  }

  onAudioSelect() {
    _logger.info('Audio track selection triggered.');

    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => AudioTrackSelector(
        player: widget.player,
        config: widget.config,
      ),
    );
  }

  onSubtitleSelect() {
    _logger.info('Subtitle selection triggered.');

    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => SubtitleSelector(
        player: widget.player,
        config: widget.config,
        service: widget.service,
        meta: widget.meta,
      ),
    );
  }
}
