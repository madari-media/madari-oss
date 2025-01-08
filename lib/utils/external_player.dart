import 'dart:io';

import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';

class ExternalMediaPlayer {
  final String name;
  final String id;

  ExternalMediaPlayer({
    required this.id,
    required this.name,
  });

  DropdownMenuItem<String> toDropdownMenuItem() {
    return DropdownMenuItem<String>(
      value: id,
      child: Text(name),
    );
  }
}

final Map<String, List<ExternalMediaPlayer>> externalPlayers = {
  "android": [
    ExternalMediaPlayer(id: "", name: "App chooser"),
    ExternalMediaPlayer(id: "org.videolan.vlc", name: "VLC"),
    ExternalMediaPlayer(id: "com.mxtech.videoplayer.ad", name: "MX Player"),
    ExternalMediaPlayer(
      id: "com.mxtech.videoplayer.pro",
      name: "MX Player Pro",
    ),
    ExternalMediaPlayer(
      id: "com.brouken.player",
      name: "JustPlayer",
    ),
    ExternalMediaPlayer(
      id: "xyz.skybox.player",
      name: "Skybox",
    ),
  ],
  "ios": [
    ExternalMediaPlayer(
      id: "open-vidhub",
      name: "VidHub",
    ),
    ExternalMediaPlayer(
      id: "infuse",
      name: "Infuse",
    ),
    ExternalMediaPlayer(
      id: "vlc",
      name: "VLC",
    ),
    ExternalMediaPlayer(
      id: "outplayer",
      name: "Outplayer",
    ),
  ],
  "macos": [
    ExternalMediaPlayer(
      id: "open-vidhub",
      name: "VidHub",
    ),
    ExternalMediaPlayer(
      id: "infuse",
      name: "Infuse",
    ),
    ExternalMediaPlayer(
      id: "iina",
      name: "IINA",
    ),
    ExternalMediaPlayer(
      id: "omniplayer",
      name: "OmniPlayer",
    ),
    ExternalMediaPlayer(
      id: "nplayer-mac",
      name: "nPlayer",
    ),
  ]
};

String getPlatformInString() {
  if (isWeb) {
    return "web";
  }
  if (Platform.isAndroid) {
    return "android";
  }
  if (Platform.isIOS) {
    return "ios";
  }
  if (Platform.isMacOS) {
    return "macos";
  }
  if (Platform.isWindows) {
    return "windows";
  }
  if (Platform.isLinux) {
    return "linux";
  }

  return "unknown";
}

Future<void> openVideoUrlInExternalPlayerAndroid({
  required String videoUrl,
  String? playerPackage,
}) async {
  AndroidIntent intent = AndroidIntent(
    action: 'action_view',
    type: "video/*",
    package: playerPackage,
    data: videoUrl,
    flags: const <int>[268435456],
    arguments: {},
  );
  await intent.launch();
}
