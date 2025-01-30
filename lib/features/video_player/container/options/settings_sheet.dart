import 'package:flutter/material.dart';
import 'package:madari_client/features/video_player/container/options/playback_speed.dart';
import 'package:madari_client/features/video_player/container/options/subtitle_selector.dart';
import 'package:madari_client/features/video_player/container/options/subtitle_size.dart';
import 'package:madari_client/features/video_player/container/options/subtitle_stylesheet.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:provider/provider.dart';

import '../state/video_settings.dart';
import 'audio_track_selector.dart';
import 'delay_controls.dart';

class SettingsSheet extends StatefulWidget {
  final VideoController controller;
  const SettingsSheet({
    super.key,
    required this.controller,
  });

  @override
  State<SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<SettingsSheet> {
  @override
  Widget build(BuildContext context) {
    return Consumer<VideoSettingsProvider>(
      builder: (context, value, _) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSettingsOption(
                  icon: Icons.speed,
                  title: 'Playback Speed',
                  subtitle: '${widget.controller.player.state.rate}x',
                  onTap: () => _showSpeedSelector(context),
                ),
                _buildSettingsOption(
                  icon: Icons.closed_caption,
                  title: 'Subtitles',
                  subtitle: 'English',
                  onTap: () => _showSubtitleSelector(context),
                ),
                _buildSettingsOption(
                  icon: Icons.format_size,
                  title: 'Subtitle Size',
                  subtitle: '${(value.subtitleSize * 100).round()}%',
                  onTap: () => _showSubtitleSizeControls(context),
                ),
                _buildSettingsOption(
                  icon: Icons.closed_caption,
                  title: 'Subtitle style',
                  subtitle: 'Change subtitles and style',
                  onTap: () => _showSubtitleStyleSheet(context),
                ),
                _buildSettingsOption(
                  icon: Icons.audiotrack,
                  title: 'Audio',
                  subtitle: 'Original',
                  onTap: () => _showAudioTrackSelector(context),
                ),
                _buildSettingsOption(
                  icon: Icons.timer,
                  title: 'Timing',
                  subtitle: 'Adjust delays',
                  onTap: () => _showDelayControls(context),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSettingsOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.white70),
      title: Text(
        title,
        style:
            const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: Colors.white70),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.white70),
      onTap: onTap,
    );
  }

  Future<void> _showCustomBottomSheet({
    required BuildContext context,
    required String title,
    required Widget child,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black87,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Divider(color: Colors.white24),
          Flexible(child: child),
        ],
      ),
    );
  }

  void _showSpeedSelector(BuildContext context) async {
    await _showCustomBottomSheet(
      context: context,
      title: 'Playback Speed',
      child: PlaybackSpeed(
        controller: widget.controller,
      ),
    );

    if (context.mounted) Navigator.of(context).pop();
  }

  void _showAudioTrackSelector(BuildContext context) {
    _showCustomBottomSheet(
      context: context,
      title: "Audio Tracks",
      child: AudioTrackSelector(
        controller: widget.controller,
      ),
    );
  }

  void _showSubtitleSizeControls(BuildContext context) async {
    Navigator.of(context).pop();

    _showCustomBottomSheet(
      context: context,
      title: "Subtitle Size",
      child: const SubtitleSize(),
    );
  }

  void _showSubtitleStyleSheet(BuildContext context) {
    _showCustomBottomSheet(
      context: context,
      title: "Subtitle Style",
      child: const SubtitleStylesheet(),
    );
  }

  void _showDelayControls(BuildContext context) async {
    Navigator.of(context).pop();

    _showCustomBottomSheet(
      context: context,
      title: "Delay Controls",
      child: const DelayControls(),
    );
  }

  void _showSubtitleSelector(BuildContext context) {
    _showCustomBottomSheet(
      title: "Subtitles",
      context: context,
      child: SubtitleSelector(
        controller: widget.controller,
      ),
    );
  }
}
