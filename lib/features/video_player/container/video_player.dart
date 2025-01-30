import 'package:cached_query_flutter/cached_query_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:madari_client/features/settings/model/playback_settings_model.dart';
import 'package:madari_client/features/settings/service/playback_setting_service.dart';
import 'package:madari_client/features/streamio_addons/models/stremio_base_types.dart';
import 'package:madari_client/features/video_player/container/video_play.dart';

class VideoPlayer extends StatefulWidget {
  final String stream;
  final Meta meta;
  final String id;
  final String type;
  final String? selectedIndex;

  const VideoPlayer({
    super.key,
    required this.type,
    required this.id,
    required this.meta,
    required this.stream,
    this.selectedIndex,
  });

  @override
  State<VideoPlayer> createState() => _VideoPlayerState();
}

class _VideoPlayerState extends State<VideoPlayer> with WidgetsBindingObserver {
  final _logger = Logger('VideoPlayer');

  late final Query<PlaybackSettings> _playbackSettings;

  bool _isMounted = false;

  String? _errorMessage;

  int get index {
    if (widget.selectedIndex == "null" || widget.selectedIndex == "") {
      return 0;
    }

    return int.tryParse(widget.selectedIndex ?? "0") ?? 0;
  }

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
                  stream: widget.stream,
                  meta: widget.meta,
                  index: index,
                  key: ValueKey('${widget.id}_${widget.selectedIndex}'),
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
