import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/video_settings.dart';

class SubtitleSize extends StatefulWidget {
  const SubtitleSize({
    super.key,
  });

  @override
  State<SubtitleSize> createState() => _SubtitleSizeState();
}

class _SubtitleSizeState extends State<SubtitleSize> {
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
                  const Text(
                    'Size: ',
                    style: TextStyle(color: Colors.white),
                  ),
                  Expanded(
                    child: Slider(
                      value: settings.subtitleSize,
                      min: 0.5,
                      max: 2.0,
                      divisions: 6,
                      onChanged: (value) {
                        setState(() {
                          settings.setSubtitleSize(value);
                        });
                      },
                    ),
                  ),
                  Text(
                    '${(settings.subtitleSize * 100).round()}%',
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Preview text
              Text(
                'Preview Text',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16.0 * settings.subtitleSize,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
