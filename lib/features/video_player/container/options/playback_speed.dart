import 'package:flutter/material.dart';
import 'package:media_kit_video/media_kit_video.dart';

class PlaybackSpeed extends StatefulWidget {
  final VideoController controller;
  const PlaybackSpeed({
    super.key,
    required this.controller,
  });

  @override
  State<PlaybackSpeed> createState() => _PlaybackSpeedState();
}

class _PlaybackSpeedState extends State<PlaybackSpeed> {
  @override
  Widget build(BuildContext context) {
    final speeds = [0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0];

    return ListView.builder(
      shrinkWrap: true,
      itemCount: speeds.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(
            '${speeds[index]}x',
            style: TextStyle(
              color: Colors.white,
              fontWeight: widget.controller.player.state.rate == speeds[index]
                  ? FontWeight.bold
                  : FontWeight.normal,
            ),
          ),
          trailing: widget.controller.player.state.rate == speeds[index]
              ? const Icon(Icons.check)
              : null,
          onTap: () {
            setState(() {
              widget.controller.player.setRate(speeds[index]);
            });
            Navigator.pop(context);
          },
        );
      },
    );
  }
}
