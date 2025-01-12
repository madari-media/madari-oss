import 'dart:async';

import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:madari_client/utils/external_player.dart';
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

  bool _autoPlay = true;
  double _playbackSpeed = 1.0;
  double _subtitleSize = 10.0;
  String _defaultAudioTrack = 'eng';
  String _defaultSubtitleTrack = 'eng';
  bool _enableExternalPlayer = true;
  String? _defaultPlayerId;
  bool _disabledSubtitle = false;
  Map<String, String> _availableLanguages = {};
  final List<String> _subtitleStyle = [
    'normal',
    'italic',
  ];
  bool _softwareAcceleration = false;
  String? _selectedSubtitleStyle;
  String colorToHex(Color color) {
    return '#${color.value.toRadixString(16).padLeft(8, '0').toUpperCase()}';
  }

  Color hexToColor(String hexColor) {
    final hexCode = hexColor.replaceAll('#', '');
    return Color(int.parse('0x$hexCode'));
  }

  Color _selectedSubtitleColor = Colors.white;

  _showColorPickerDialog(BuildContext context) async {
    Color? color = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Pick a Subtitle Color'),
          content: SingleChildScrollView(
            child: ColorPicker(
              padding: const EdgeInsets.all(0),
              color: _selectedSubtitleColor,
              onColorChanged: (Color color) {
                _selectedSubtitleColor = color;
              },
              // Remove pickerType
              enableShadesSelection: true,
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(_selectedSubtitleColor);
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
    if (color != null) {
      setState(() {
        _selectedSubtitleColor = color;
      });
      _debouncedSave(); // Debounced save after color change
    }
  }

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
    PlaybackConfig playbackConfig;
    try {
      playbackConfig = getPlaybackConfig();
    } catch (e) {
      playbackConfig = PlaybackConfig.fromJson({});
    }

    _autoPlay = playbackConfig.autoPlay ?? true;
    _playbackSpeed = playbackConfig.playbackSpeed.toDouble();
    _defaultAudioTrack = playbackConfig.defaultAudioTrack;
    _defaultSubtitleTrack = playbackConfig.defaultSubtitleTrack;
    _enableExternalPlayer = playbackConfig.externalPlayer;
    _softwareAcceleration = playbackConfig.softwareAcceleration;
    _defaultPlayerId =
        playbackConfig.externalPlayerId?.containsKey(currentPlatform) == true
            ? playbackConfig.externalPlayerId![currentPlatform]
            : null;
    _disabledSubtitle = playbackConfig.disableSubtitle;
    _selectedSubtitleStyle =
        (playbackConfig.subtitleStyle ?? "normal").toLowerCase();
    _selectedSubtitleColor = playbackConfig.subtitleColor != null
        ? hexToColor(playbackConfig.subtitleColor!)
        : Colors.white;
    _subtitleSize = playbackConfig.subtitleSize.toDouble();
  }

  @override
  void dispose() {
    _saveDebouncer?.cancel();
    super.dispose();
  }

  void _debouncedSave() {
    _saveDebouncer?.cancel();
    _saveDebouncer = Timer(
      const Duration(milliseconds: 500),
      _savePlaybackSettings,
    );
  }

  Future<void> _savePlaybackSettings() async {
    try {
      final user = _engine.authStore.record;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final currentConfig = user.data['config'] as Map<String, dynamic>? ?? {};

      final extranalId = currentConfig['externalPlayerId'] ?? {};

      extranalId[currentPlatform] = _defaultPlayerId;

      final updatedConfig = {
        ...currentConfig,
        'playback': {
          'autoPlay': _autoPlay,
          'playbackSpeed': _playbackSpeed,
          'defaultAudioTrack': _defaultAudioTrack,
          'defaultSubtitleTrack': _defaultSubtitleTrack,
          'externalPlayer': _enableExternalPlayer,
          'externalPlayerId': extranalId,
          'disableSubtitle': _disabledSubtitle,
          'subtitleStyle': _selectedSubtitleStyle,
          'subtitleColor': colorToHex(_selectedSubtitleColor),
          'subtitleSize': _subtitleSize,
          'softwareAcceleration': _softwareAcceleration,
        },
      };

      await _engine.collection('users').update(
        user.id,
        body: {
          'config': updatedConfig,
        },
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

  final currentPlatform = getPlatformInString();

  @override
  Widget build(BuildContext context) {
    final dropdownstyle = _subtitleStyle.map((String value) {
      return DropdownMenuItem<String>(
        value: value,
        child: Text(value.capitalize),
      );
    }).toList();
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
      body: Center(
        child: Container(
          constraints: const BoxConstraints(
            maxWidth: 600,
          ),
          child: ListView(
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
                        HapticFeedback.mediumImpact();
                        setState(() => _playbackSpeed =
                            double.parse(value.toStringAsFixed(2)));
                        _debouncedSave();
                      },
                    ),
                    Text('Current: ${_playbackSpeed.toStringAsFixed(2)}x'),
                  ],
                ),
              ),
              const Divider(),
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
              SwitchListTile(
                title: const Text('Software Acceleration'),
                value: _softwareAcceleration,
                onChanged: (value) {
                  setState(() => _softwareAcceleration = value);
                  _debouncedSave();
                },
              ),
              SwitchListTile(
                title: const Text('Disable Subtitle'),
                value: _disabledSubtitle,
                onChanged: (value) {
                  setState(() => _disabledSubtitle = value);
                  _debouncedSave();
                },
              ),
              if (!_disabledSubtitle) ...[
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
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Material(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.8,
                      ),
                      child: Text(
                        'Sample Text',
                        textAlign:
                            TextAlign.center, // Center text within its box
                        style: TextStyle(
                          fontSize: _subtitleSize / 2,
                          color: _selectedSubtitleColor,
                          fontStyle: _subtitleStyle[0].toLowerCase() == 'italic'
                              ? FontStyle.italic
                              : FontStyle.normal,
                        ),
                      ),
                    ),
                  ),
                ),
                ListTile(
                  title: const Text('Subtitle Style'),
                  trailing: DropdownButton<String>(
                    value: _selectedSubtitleStyle,
                    items: dropdownstyle,
                    onChanged: (value) {
                      HapticFeedback.mediumImpact();
                      if (value != null) {
                        setState(() {
                          _selectedSubtitleStyle = value;
                        });
                        _debouncedSave();
                      }
                    },
                  ),
                ),
                ListTile(
                  title: const Text('Subtitle Color'),
                  trailing: GestureDetector(
                    // Use GestureDetector to make the color display tappable
                    onTap: () => _showColorPickerDialog(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _selectedSubtitleColor,
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(color: Colors.grey),
                      ),
                    ),
                  ),
                ),
                ListTile(
                  title: const Text('Font Size'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Slider(
                        value: _subtitleSize,
                        min: 10.0,
                        max: 60.0,
                        divisions: 18,
                        label: '${_subtitleSize.toStringAsFixed(2)}x',
                        onChanged: (value) {
                          HapticFeedback.lightImpact();
                          setState(
                            () => _subtitleSize =
                                double.parse(value.toStringAsFixed(2)),
                          );
                          _debouncedSave();
                        },
                      ),
                      Text('Current: ${_subtitleSize.toStringAsFixed(2)}x'),
                    ],
                  ),
                ),
              ],
              const Divider(),
              if (!isWeb)
                SwitchListTile(
                  title: const Text('External Player'),
                  subtitle: const Text('Always open video in external player?'),
                  value: _enableExternalPlayer,
                  onChanged: (value) {
                    setState(() => _enableExternalPlayer = value);
                    _debouncedSave();
                  },
                ),
              if (_enableExternalPlayer &&
                  externalPlayers[currentPlatform]?.isNotEmpty == true)
                ListTile(
                  title: const Text('Default Player'),
                  trailing: DropdownButton<String>(
                    value: _defaultPlayerId == "" ? null : _defaultPlayerId,
                    items: externalPlayers[currentPlatform]!
                        .map(
                          (item) => item.toDropdownMenuItem(),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _defaultPlayerId = value);
                        _debouncedSave();
                      }
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
