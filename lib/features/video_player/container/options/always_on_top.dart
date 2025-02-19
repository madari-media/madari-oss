import 'package:flutter/material.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:window_manager/window_manager.dart';

class AlwaysOnTopButton extends StatefulWidget {
  const AlwaysOnTopButton({super.key});

  @override
  State<AlwaysOnTopButton> createState() => _AlwaysOnTopButtonState();
}

class _AlwaysOnTopButtonState extends State<AlwaysOnTopButton> {
  bool alwaysOnTop = false;

  @override
  void initState() {
    super.initState();

    windowManager.isAlwaysOnTop().then((value) {
      if (mounted) {
        setState(() {
          alwaysOnTop = value;
        });
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: "Always on top",
      child: MaterialDesktopCustomButton(
        onPressed: () async {
          if (await windowManager.isAlwaysOnTop()) {
            windowManager.setAlwaysOnTop(false);
            windowManager.setTitleBarStyle(TitleBarStyle.normal);
            setState(() {
              alwaysOnTop = false;
            });
            windowManager.setVisibleOnAllWorkspaces(false);
          } else {
            windowManager.setAlwaysOnTop(true);
            windowManager.setVisibleOnAllWorkspaces(true);
            windowManager.setTitleBarStyle(TitleBarStyle.hidden);
            setState(() {
              alwaysOnTop = true;
            });
          }
        },
        icon: Icon(
          alwaysOnTop ? Icons.push_pin : Icons.push_pin_outlined,
        ),
        iconSize: 22,
      ),
    );
  }
}
