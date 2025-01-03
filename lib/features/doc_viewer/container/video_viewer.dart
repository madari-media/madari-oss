import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:madari_client/features/connections/service/base_connection_service.dart';
import 'package:madari_client/features/watch_history/service/base_watch_history.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../../../utils/load_language.dart';
import '../../connections/types/stremio/stremio_base.types.dart' as types;
import '../../connections/widget/stremio/stremio_season_selector.dart';
import '../../watch_history/service/zeee_watch_history.dart';
import '../types/doc_source.dart';
import 'video_viewer/desktop_video_player.dart';
import 'video_viewer/mobile_video_player.dart';

class VideoViewer extends StatefulWidget {
  final DocSource source;
  final LibraryItem? meta;
  final BaseConnectionService? service;
  final String? currentSeason;
  final String? library;

  const VideoViewer({
    super.key,
    required this.source,
    this.meta,
    this.service,
    this.currentSeason,
    this.library,
  });

  @override
  State<VideoViewer> createState() => _VideoViewerState();
}

class _VideoViewerState extends State<VideoViewer> {
  StreamSubscription? _subTracks;
  final zeeeWatchHistory = ZeeeWatchHistoryStatic.service;
  Timer? _timer;
  late final player = Player(
    configuration: const PlayerConfiguration(
      title: "Madari",
    ),
  );
  late final GlobalKey<VideoState> key = GlobalKey<VideoState>();

  saveWatchHistory() {
    final duration = player.state.duration.inSeconds;
    final position = player.state.position.inSeconds;
    final progress = duration > 0 ? (position / duration * 100).round() : 0;

    if (progress == 0) {
      return;
    }

    zeeeWatchHistory!.saveWatchHistory(
      history: WatchHistory(
        id: _source.id,
        progress: progress,
        duration: duration.toDouble(),
        episode: _source.episode,
        season: _source.season,
      ),
    );
  }

  late final controller = VideoController(
    player,
    configuration: const VideoControllerConfiguration(
      enableHardwareAcceleration: true,
    ),
  );
  List<SubtitleTrack> subtitles = [];
  List<AudioTrack> audioTracks = [];
  Map<String, String> languages = {};

  late DocSource _source;

  void setDefaultAudioTracks(Tracks tracks) {
    if (defaultConfigSelected == true &&
        (tracks.audio.length <= 1 || tracks.audio.length <= 1)) {
      return;
    }

    defaultConfigSelected = true;

    controller.player.setRate(config.playbackSpeed);

    final defaultSubtitle = config.defaultSubtitleTrack;
    final defaultAudio = config.defaultAudioTrack;

    for (final item in tracks.audio) {
      if (defaultAudio == item.id ||
          defaultAudio == item.language ||
          defaultAudio == item.title) {
        controller.player.setAudioTrack(item);
        break;
      }
    }

    for (final item in tracks.subtitle) {
      if (defaultSubtitle == item.id ||
          defaultSubtitle == item.language ||
          defaultSubtitle == item.title) {
        controller.player.setSubtitleTrack(item);
        break;
      }
    }
  }

  void onPlaybackReady(Tracks tracks) {
    setState(() {
      audioTracks = tracks.audio.where((item) {
        return item.id != "auto" && item.id != "no";
      }).toList();

      subtitles = tracks.subtitle.where((item) {
        return item.id != "auto";
      }).toList();
    });
  }

  PlaybackConfig config = getPlaybackConfig();

  bool defaultConfigSelected = false;

  @override
  void initState() {
    super.initState();
    _source = widget.source;

    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.immersiveSticky,
      overlays: [],
    );

    if (!kIsWeb) {
      if (Platform.isAndroid || Platform.isIOS) {
        WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
          key.currentState?.enterFullscreen();
        });
      }
    }

    _streamComplete = player.stream.completed.listen((completed) {
      if (completed) {
        onLibrarySelect();
      }
    });

    _subTracks = player.stream.tracks.listen((tracks) {
      if (mounted) {
        setDefaultAudioTracks(tracks);
        onPlaybackReady(tracks);
      }
    });

    loadLanguages(context).then((language) {
      if (mounted) {
        setState(() {
          languages = language;
        });
      }
    });

    loadFile();

    if (player.platform is NativePlayer && !kIsWeb) {
      Future.microtask(() async {
        await (player.platform as dynamic).setProperty('network-timeout', '60');
      });
    }

    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      saveWatchHistory();
    });

    this._streamListen = player.stream.playing.listen((playing) {
      if (playing) {
        saveWatchHistory();
      }
    });
  }

  loadFile() async {
    final item = await zeeeWatchHistory!.getItemWatchHistory(
      ids: [
        WatchHistoryGetRequest(
          id: _source.id,
          season: _source.season,
          episode: _source.episode,
        ),
      ],
    );

    final duration = Duration(
      seconds: item.isEmpty
          ? 0
          : calculateSecondsFromProgress(
              item.first.duration,
              item.first.progress.toDouble(),
            ),
    );

    switch (_source.runtimeType) {
      case const (FileSource):
        if (kIsWeb) {
          return;
        }
        player.open(
          Media(
            (_source as FileSource).filePath,
            start: duration,
          ),
          play: true,
        );
      case const (URLSource):
      case const (MediaURLSource):
      case const (TorrentSource):
        player.open(
          Media(
            (_source as URLSource).url,
            httpHeaders: (_source as URLSource).headers,
            start: duration,
          ),
          play: true,
        );
    }
  }

  bool isScaled = false;

  late StreamSubscription<bool> _streamComplete;
  late StreamSubscription<bool> _streamListen;

  onLibrarySelect() async {
    controller.player.pause();

    final result = await showCupertinoDialog(
      context: context,
      builder: (context) {
        return Scaffold(
          appBar: AppBar(
            title: const Text("Seasons"),
          ),
          body: CustomScrollView(
            slivers: [
              StremioItemSeasonSelector(
                service: widget.service,
                library: widget.library!,
                meta: widget.meta as types.Meta,
                shouldPop: true,
                season: int.tryParse(widget.currentSeason!),
              ),
            ],
          ),
        );
      },
    );

    if (result is MediaURLSource) {
      _source = result;

      loadFile();
    }
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
      overlays: [],
    );
    _timer?.cancel();
    _subTracks?.cancel();
    _streamComplete.cancel();
    _streamListen.cancel();
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildBody(context),
    );
  }

  _buildBody(BuildContext context) {
    switch (Theme.of(context).platform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
        final mobile = getMobileVideoPlayer(
          context,
          onLibrarySelect: onLibrarySelect,
          hasLibrary: widget.service != null &&
              widget.library != null &&
              widget.meta != null,
          audioTracks: audioTracks,
          player: player,
          source: _source,
          subtitles: subtitles,
          onSubtitleClick: onSubtitleSelect,
          onAudioClick: onAudioSelect,
          toggleScale: () {
            setState(() {
              isScaled = !isScaled;
            });
          },
        );

        return MaterialVideoControlsTheme(
          fullscreen: mobile,
          normal: mobile,
          child: Video(
            fit: isScaled ? BoxFit.fitWidth : BoxFit.fitHeight,
            pauseUponEnteringBackgroundMode: true,
            key: key,
            onExitFullscreen: () async {
              await defaultExitNativeFullscreen();
              if (context.mounted) Navigator.of(context).pop();
            },
            controller: controller,
            controls: MaterialVideoControls,
          ),
        );
      default:
        final desktop = getDesktopControls(
          context,
          audioTracks: audioTracks,
          player: player,
          source: _source,
          subtitles: subtitles,
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
            controller: controller,
            controls: MaterialDesktopVideoControls,
          ),
        );
    }
  }

  onSubtitleSelect() {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => Card(
        child: Container(
          height: MediaQuery.of(context).size.height * 0.4,
          decoration: BoxDecoration(
            color: Theme.of(context).dialogBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'Select Subtitle',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: subtitles.length,
                  itemBuilder: (context, index) {
                    final currentItem = subtitles[index];

                    final title = currentItem.language ??
                        currentItem.title ??
                        currentItem.id;

                    return ListTile(
                      title: Text(
                        languages.containsKey(title)
                            ? languages[title]!
                            : title,
                      ),
                      selected:
                          player.state.track.subtitle.id == currentItem.id,
                      onTap: () {
                        player.setSubtitleTrack(currentItem);
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
  }

  onAudioSelect() {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => Card(
        child: Container(
          height: MediaQuery.of(context).size.height * 0.4,
          decoration: BoxDecoration(
            color: Theme.of(context).dialogBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'Select Audio Track',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: audioTracks.length,
                  itemBuilder: (context, index) {
                    final currentItem = audioTracks[index];
                    final title = currentItem.language ??
                        currentItem.title ??
                        currentItem.id;
                    return ListTile(
                      title: Text(
                        languages.containsKey(title)
                            ? languages[title]!
                            : title,
                      ),
                      selected: player.state.track.audio.id == currentItem.id,
                      onTap: () {
                        player.setAudioTrack(currentItem);
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
  }
}

int calculateSecondsFromProgress(
  double duration,
  double progressPercentage,
) {
  final clampedProgress = progressPercentage.clamp(0.0, 100.0);
  final currentSeconds = (duration * (clampedProgress / 100)).round();
  return currentSeconds;
}
