import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/video_settings.dart';

class DelayControls extends StatelessWidget {
  const DelayControls({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<VideoSettingsProvider>(
      builder: (context, settings, _) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Text('Subtitle Delay: '),
                  Expanded(
                    child: Slider(
                      value: settings.subtitleDelay,
                      min: -50.0,
                      max: 50.0,
                      onChanged: (value) {
                        settings.setSubtitleDelay(value);
                      },
                    ),
                  ),
                  Text('${settings.subtitleDelay.toStringAsFixed(1)}s'),
                ],
              ),
              Row(
                children: [
                  const Text('Audio Delay: '),
                  Expanded(
                    child: Slider(
                      value: settings.audioDelay,
                      min: -50.0,
                      max: 50.0,
                      onChanged: (value) {
                        settings.setAudioDelay(value);
                      },
                    ),
                  ),
                  Text('${settings.audioDelay.toStringAsFixed(1)}s'),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
