import 'package:cached_query_flutter/cached_query_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:madari_client/features/settings/model/playback_settings_model.dart';
import 'package:madari_client/features/settings/service/playback_setting_service.dart';
import 'package:madari_client/features/video_player/container/video_play.dart';
import 'package:madari_client/features/widgetter/plugins/stremio/containers/streamio_background.dart';
import 'package:madari_engine/madari_engine.dart';
import 'package:rxdart/rxdart.dart';

class VideoPlayer extends StatefulWidget {
  final String stream;
  final Meta meta;
  final String id;
  final String type;
  final String? selectedIndex;
  final String? bingGroup;

  const VideoPlayer({
    super.key,
    required this.type,
    required this.id,
    required this.meta,
    required this.stream,
    this.selectedIndex,
    this.bingGroup,
  });

  @override
  State<VideoPlayer> createState() => _VideoPlayerState();

  int get index {
    if (selectedIndex == "null" || selectedIndex == "") {
      return 0;
    }

    return int.tryParse(selectedIndex ?? "0") ?? 0;
  }
}

class _VideoPlayerState extends State<VideoPlayer> with WidgetsBindingObserver {
  final _logger = Logger('VideoPlayer');
  late final Query<PlaybackSettings> _playbackSettings;
  bool _isMounted = false;
  late String stream = widget.stream;
  String? _errorMessage;
  late Meta meta = widget.meta;
  late int index = widget.index;
  late final BehaviorSubject<int> updateSubject = BehaviorSubject.seeded(
    widget.index,
  );

  @override
  void initState() {
    super.initState();
    _isMounted = true;
    WidgetsBinding.instance.addObserver(this);

    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      _playbackSettings = Query(
        key: "video_settings",
        queryFn: () => PlaybackSettingsService.instance.getSettings(),
      );

      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);

      await SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.immersiveSticky,
        overlays: [],
      );
    } catch (e, stackTrace) {
      _logger.severe('Error initializing video player', e, stackTrace);
      if (_isMounted) {
        setState(() => _errorMessage = 'Failed to initialize video player: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() => _errorMessage = null);
                  _initializePlayer();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return QueryBuilder(
      query: _playbackSettings,
      builder: (context, state) {
        switch (state.status) {
          case QueryStatus.loading:
          case QueryStatus.initial:
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );

          case QueryStatus.error:
            return Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Error loading settings: ${state.error}',
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => _playbackSettings.refetch(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );

          case QueryStatus.success:
            return PopScope(
              canPop: true,
              onPopInvokedWithResult: (didPop, data) async {
                if (didPop) {
                  _handleBackPress();
                }
              },
              child: Scaffold(
                extendBody: true,
                extendBodyBehindAppBar: true,
                body: VideoPlay(
                  updateSubject: updateSubject,
                  onVideoChange: (index) async {
                    final result = await openVideoStream(
                      context,
                      widget.meta.copyWith(
                        selectedVideoIndex: index,
                      ),
                      shouldPop: true,
                      bingGroup: widget.bingGroup,
                    );

                    if (result == null) return false;

                    setState(() {
                      this.index = index;
                      stream = result;
                    });

                    updateSubject.add(index);

                    return true;
                  },
                  stream: stream,
                  meta: meta,
                  data: state.data!,
                  bufferSize: state.data?.bufferSize ?? 32,
                  index: index,
                  enabledHardwareAcceleration:
                      state.data?.disableHardwareAcceleration != true,
                  poster: widget.meta.poster,
                  onError: _handlePlaybackError,
                  settings: state.data,
                ),
              ),
            );
        }
      },
    );
  }

  Future<bool> _handleBackPress() async {
    await SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    return true;
  }

  void _handlePlaybackError(String message) {
    _logger.warning('Playback error: $message');
    if (_isMounted) {
      setState(() => _errorMessage = message);
    }
  }

  @override
  void dispose() {
    _isMounted = false;
    WidgetsBinding.instance.removeObserver(this);

    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);

    super.dispose();
  }
}
