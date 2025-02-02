import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/video_settings.dart';

class SubtitleStylesheet extends StatelessWidget {
  const SubtitleStylesheet({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Consumer<VideoSettingsProvider>(
        builder: (context, settings, _) {
          return StatefulBuilder(
            builder: (context, setState) {
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Text Color',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          Colors.white,
                          Colors.grey.shade200,
                          Colors.yellowAccent,
                          Colors.blueAccent,
                          Colors.greenAccent,
                          Colors.orangeAccent,
                          Colors.redAccent,
                        ].map((color) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: InkWell(
                              onTap: () {
                                settings.setSubtitleColor(color);
                              },
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: color,
                                  border: Border.all(
                                    color: settings.subtitleColor == color
                                        ? Colors.white
                                        : Colors.transparent,
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Background Color',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          Colors.transparent,
                          Colors.black,
                          Colors.grey.shade900,
                          Colors.grey.shade800,
                          Colors.grey.shade700,
                          Colors.blue.shade900,
                          Colors.brown.shade900,
                        ].map((color) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: InkWell(
                              onTap: () {
                                settings.setSubtitleBackgroundColor(color);
                              },
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: color,
                                  border: Border.all(
                                    color: settings.subtitleBackgroundColor ==
                                            color
                                        ? Colors.white
                                        : Colors.transparent,
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Text(
                          'Background Opacity',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${(settings.subtitleOpacity * 100).round()}%',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: settings.subtitleOpacity,
                      min: 0.0,
                      max: 1.0,
                      divisions: 10,
                      onChanged: (value) {
                        settings.setSubtitleOpacity(value);
                      },
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          'Sample Subtitle Text',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            backgroundColor:
                                settings.subtitleBackgroundColor.withValues(
                              alpha: settings.subtitleOpacity,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
