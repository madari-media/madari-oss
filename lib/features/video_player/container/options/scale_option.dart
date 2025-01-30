import 'package:flutter/material.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:provider/provider.dart';

import '../state/video_settings.dart';

class ScaleOption extends StatelessWidget {
  const ScaleOption({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<VideoSettingsProvider>(
      builder: (context, data, _) {
        return MaterialCustomButton(
          onPressed: () {
            data.toggleFilled();
          },
          icon: Icon(
            data.isFilled ? Icons.fit_screen : Icons.fit_screen_outlined,
          ),
        );
      },
    );
  }
}
