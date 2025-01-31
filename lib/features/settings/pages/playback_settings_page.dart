import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../model/playback_settings_model.dart';
import '../service/external_players.dart';
import '../service/playback_setting_service.dart';
import '../widget/searchable_language_dropdown.dart';
import '../widget/setting_wrapper.dart';

class PlaybackSettingsPage extends StatefulWidget {
  const PlaybackSettingsPage({super.key});

  @override
  State<PlaybackSettingsPage> createState() => _PlaybackSettingsPageState();
}

class _PlaybackSettingsPageState extends State<PlaybackSettingsPage> {
  late Future<PlaybackSettings> _settingsFuture;
  late Future<Map<String, String>> _languagesFuture;

  @override
  void initState() {
    super.initState();
    _settingsFuture = PlaybackSettingsService.instance.getSettings();
    _languagesFuture = PlaybackSettingsService.instance.getLanguages();
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildSpeedSelector(PlaybackSettings settings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Playback Speed'),
        const SizedBox(height: 8),
        Row(
          children: [
            const Text('0.5x'),
            Expanded(
              child: Slider(
                value: settings.playbackSpeed,
                min: 0.5,
                max: 5.0,
                divisions: 45,
                label: '${settings.playbackSpeed.toStringAsFixed(2)}x',
                onChanged: (value) {
                  setState(() {
                    settings.playbackSpeed = value;
                    PlaybackSettingsService.instance.saveSettings(settings);
                  });
                },
              ),
            ),
            const Text('5.0x'),
          ],
        ),
      ],
    );
  }

  Widget _buildSubtitlePreview(PlaybackSettings settings) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: Center(
              child: Text(
                'Preview Subtitle Text\nSecond Line',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: settings.subtitleColor,
                  fontSize: settings.fontSize,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.8),
                      offset: const Offset(1, 1),
                      blurRadius: 2,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageSelector(
    PlaybackSettings settings,
    Map<String, String> languages,
    String label,
    bool isAudio,
  ) {
    return SearchableLanguageDropdown(
      languages: languages,
      value:
          isAudio ? settings.defaultAudioTrack : settings.defaultSubtitleTrack,
      label: label,
      onChanged: (value) {
        setState(() {
          if (isAudio) {
            settings.defaultAudioTrack = value;
          } else {
            settings.defaultSubtitleTrack = value;
          }
          PlaybackSettingsService.instance.saveSettings(settings);
        });
      },
    );
  }

  Widget _buildExternalPlayerSelector(PlaybackSettings settings) {
    final platform = defaultTargetPlatform;
    String currentPlatform;

    switch (platform) {
      case TargetPlatform.android:
        currentPlatform = 'android';
        break;
      case TargetPlatform.iOS:
        currentPlatform = 'ios';
        break;
      case TargetPlatform.macOS:
        currentPlatform = 'macos';
        break;
      default:
        return const SizedBox.shrink();
    }

    final players = externalPlayers[currentPlatform] ?? [];

    return DropdownButtonFormField<String>(
      value: settings.selectedExternalPlayer,
      decoration: const InputDecoration(
        labelText: 'External Player',
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      items: players
          .map((player) => DropdownMenuItem(
                value: player.id,
                child: Text(player.name),
              ))
          .toList(),
      onChanged: settings.externalPlayer
          ? (value) {
              if (value != null) {
                setState(() {
                  settings.selectedExternalPlayer = value;
                  PlaybackSettingsService.instance.saveSettings(settings);
                });
              }
            }
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Playback Settings'),
        centerTitle: true,
      ),
      body: SettingWrapper(
        child: FutureBuilder(
          future: Future.wait([_settingsFuture, _languagesFuture]),
          builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final settings = snapshot.data![0] as PlaybackSettings;
            final languages = snapshot.data![1] as Map<String, String>;

            return ListView(
              children: [
                _buildSection(
                  'General',
                  [
                    SwitchListTile(
                      title: const Text('Auto Play'),
                      subtitle: const Text('Automatically play next episode'),
                      value: settings.autoPlay,
                      onChanged: (value) {
                        setState(() {
                          settings.autoPlay = value;
                          PlaybackSettingsService.instance
                              .saveSettings(settings);
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildSpeedSelector(settings),
                  ],
                ),
                _buildSection(
                  'Audio',
                  [
                    _buildLanguageSelector(
                      settings,
                      languages,
                      'Default Audio Track',
                      true,
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Disable Hardware Acceleration'),
                      subtitle: const Text('May help with audio sync issues'),
                      value: settings.disableHardwareAcceleration,
                      onChanged: (value) {
                        setState(() {
                          settings.disableHardwareAcceleration = value;
                          PlaybackSettingsService.instance
                              .saveSettings(settings);
                        });
                      },
                    ),
                  ],
                ),
                _buildSection(
                  'Subtitles',
                  [
                    SwitchListTile(
                      title: const Text('Enable Subtitles'),
                      value: !settings.disableSubtitles,
                      onChanged: (value) {
                        setState(() {
                          settings.disableSubtitles = !value;
                          PlaybackSettingsService.instance
                              .saveSettings(settings);
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    if (!settings.disableSubtitles) ...[
                      _buildLanguageSelector(
                        settings,
                        languages,
                        'Default Subtitle Track',
                        false,
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        title: const Text('Subtitle Color'),
                        trailing: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: settings.subtitleColor,
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        onTap: () async {
                          final color = await showDialog<Color>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Pick a color'),
                              content: SingleChildScrollView(
                                child: ColorPicker(
                                  color: settings.subtitleColor,
                                  onColorChanged: (color) {
                                    settings.subtitleColor = color;
                                  },
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(
                                      context, settings.subtitleColor),
                                  child: const Text('Select'),
                                ),
                              ],
                            ),
                          );
                          if (color != null) {
                            setState(() {
                              settings.subtitleColor = color;
                              PlaybackSettingsService.instance
                                  .saveSettings(settings);
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Font Size'),
                          Row(
                            children: [
                              const Text('11'),
                              Expanded(
                                child: Slider(
                                  value: settings.fontSize,
                                  min: 11,
                                  max: 60,
                                  divisions: 49,
                                  label: settings.fontSize.round().toString(),
                                  onChanged: (value) {
                                    setState(() {
                                      settings.fontSize = value;
                                      PlaybackSettingsService.instance
                                          .saveSettings(settings);
                                    });
                                  },
                                ),
                              ),
                              const Text('60'),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildSubtitlePreview(settings),
                    ],
                  ],
                ),
                _buildSection(
                  'External Player',
                  [
                    SwitchListTile(
                      title: const Text('Use External Player'),
                      subtitle:
                          const Text('Open videos in your preferred player'),
                      value: settings.externalPlayer,
                      onChanged: (value) {
                        setState(() {
                          settings.externalPlayer = value;
                          PlaybackSettingsService.instance
                              .saveSettings(settings);
                        });
                      },
                    ),
                    if (settings.externalPlayer) ...[
                      const SizedBox(height: 16),
                      _buildExternalPlayerSelector(settings),
                    ],
                  ],
                ),
                _buildSection(
                  "Player buffer",
                  [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("${settings.bufferSize} MB"),
                        Row(
                          children: [
                            const Text('32 MB'),
                            Expanded(
                              child: Slider(
                                value: settings.bufferSize.toDouble(),
                                min: 32,
                                max: 2024,
                                label: settings.bufferSize.round().toString(),
                                onChanged: (value) {
                                  setState(() {
                                    settings.bufferSize = value.toInt();
                                    PlaybackSettingsService.instance
                                        .saveSettings(settings);
                                  });
                                },
                              ),
                            ),
                            const Text('2024 MB'),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
