import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';

import '../../../engine/engine.dart';
import '../../../utils/load_language.dart';

class PlaybackSettingsScreen extends StatefulWidget {
  const PlaybackSettingsScreen({super.key});

  @override
  State<PlaybackSettingsScreen> createState() => _PlaybackSettingsScreenState();
}

class _PlaybackSettingsScreenState extends State<PlaybackSettingsScreen> {
  String? _error;
  Timer? _saveDebouncer;

  // Playback settings
  bool _autoPlay = true;
  double _playbackSpeed = 1.0;
  String _defaultAudioTrack = 'eng';
  String _defaultSubtitleTrack = 'eng';

  Map<String, String> _availableLanguages = {};

  List<DropdownMenuItem<String>> get dropdown =>
      _availableLanguages.entries.map((item) {
        return DropdownMenuItem<String>(
          value: item.key,
          child: Text(item.value),
        );
      }).toList();

  final PocketBase _engine = AppEngine.engine.pb;

  @override
  void initState() {
    super.initState();

    loadLanguages(context).then((data) {
      setState(() {
        _availableLanguages = data;
      });
    });
    _loadPlaybackSettings();
  }

  void _loadPlaybackSettings() {
    final playbackConfig = getPlaybackConfig();

    _autoPlay = playbackConfig.autoPlay ?? true;
    _playbackSpeed = playbackConfig.playbackSpeed.toDouble() ?? 1.0;
    _defaultAudioTrack = playbackConfig.defaultAudioTrack ?? 'eng';
    _defaultSubtitleTrack = playbackConfig.defaultSubtitleTrack ?? 'eng';
  }

  @override
  void dispose() {
    _saveDebouncer?.cancel();
    super.dispose();
  }

  void _debouncedSave() {
    _saveDebouncer?.cancel();
    _saveDebouncer =
        Timer(const Duration(milliseconds: 500), _savePlaybackSettings);
  }

  Future<void> _savePlaybackSettings() async {
    try {
      final user = _engine.authStore.record;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final currentConfig = user.data['config'] as Map<String, dynamic>? ?? {};

      final updatedConfig = {
        ...currentConfig,
        'playback': {
          'autoPlay': _autoPlay,
          'playbackSpeed': _playbackSpeed,
          'defaultAudioTrack': _defaultAudioTrack,
          'defaultSubtitleTrack': _defaultSubtitleTrack,
        },
      };

      await _engine.collection('users').update(
        user.id,
        body: {'config': updatedConfig},
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Settings saved'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save settings: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_error!, style: const TextStyle(color: Colors.red)),
              ElevatedButton(
                onPressed: _loadPlaybackSettings,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Playback Settings'),
      ),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Auto-play'),
            subtitle: const Text('Automatically play next content'),
            value: _autoPlay,
            onChanged: (value) {
              setState(() => _autoPlay = value);
              _debouncedSave();
            },
          ),
          ListTile(
            title: const Text('Playback Speed'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Slider(
                  value: _playbackSpeed,
                  min: 0.5,
                  max: 5.0,
                  divisions: 18,
                  label: '${_playbackSpeed.toStringAsFixed(2)}x',
                  onChanged: (value) {
                    setState(() => _playbackSpeed =
                        double.parse(value.toStringAsFixed(2)));
                    _debouncedSave();
                  },
                ),
                Text('Current: ${_playbackSpeed.toStringAsFixed(2)}x'),
              ],
            ),
          ),
          ListTile(
            title: const Text('Default Audio Track'),
            trailing: DropdownButton<String>(
              value: _defaultAudioTrack,
              items: dropdown,
              onChanged: (value) {
                if (value != null) {
                  setState(() => _defaultAudioTrack = value);
                  _debouncedSave();
                }
              },
            ),
          ),
          ListTile(
            title: const Text('Default Subtitle Track'),
            trailing: DropdownButton<String>(
              value: _defaultSubtitleTrack,
              items: dropdown,
              onChanged: (value) {
                if (value != null) {
                  setState(() => _defaultSubtitleTrack = value);
                  _debouncedSave();
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
