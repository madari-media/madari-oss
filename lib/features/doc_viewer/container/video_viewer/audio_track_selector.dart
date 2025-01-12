import 'package:flutter/material.dart';
import 'package:madari_client/utils/load_language.dart';
import 'package:media_kit/media_kit.dart';

class AudioTrackSelector extends StatefulWidget {
  final Player player;
  final PlaybackConfig config;

  const AudioTrackSelector({
    super.key,
    required this.player,
    required this.config,
  });

  @override
  State<AudioTrackSelector> createState() => _AudioTrackSelectorState();
}

class _AudioTrackSelectorState extends State<AudioTrackSelector> {
  List<AudioTrack> audioTracks = [];
  Map<String, String> languages = {};

  @override
  void initState() {
    super.initState();

    audioTracks = widget.player.state.tracks.audio.where((item) {
      return item.id != "auto" && item.id != "no";
    }).toList();

    loadLanguages(context).then((language) {
      if (mounted) {
        setState(() {
          languages = language;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
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
                      languages.containsKey(title) ? languages[title]! : title,
                    ),
                    selected:
                        widget.player.state.track.audio.id == currentItem.id,
                    onTap: () {
                      widget.player.setAudioTrack(currentItem);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
