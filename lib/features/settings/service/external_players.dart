import '../model/external_media_player.dart';

final Map<String, List<ExternalMediaPlayer>> externalPlayers = {
  "android": [
    const ExternalMediaPlayer(id: "", name: "App chooser"),
    const ExternalMediaPlayer(id: "org.videolan.vlc", name: "VLC"),
    const ExternalMediaPlayer(
        id: "com.mxtech.videoplayer.ad", name: "MX Player"),
    const ExternalMediaPlayer(
      id: "com.mxtech.videoplayer.pro",
      name: "MX Player Pro",
    ),
    const ExternalMediaPlayer(
      id: "com.brouken.player",
      name: "JustPlayer",
    ),
    const ExternalMediaPlayer(
      id: "xyz.skybox.player",
      name: "Skybox",
    ),
  ],
  "ios": [
    const ExternalMediaPlayer(
      id: "open-vidhub",
      name: "VidHub",
    ),
    const ExternalMediaPlayer(
      id: "infuse",
      name: "Infuse",
    ),
    const ExternalMediaPlayer(
      id: "vlc",
      name: "VLC",
    ),
    const ExternalMediaPlayer(
      id: "outplayer",
      name: "Outplayer",
    ),
  ],
  "macos": [
    const ExternalMediaPlayer(
      id: "open-vidhub",
      name: "VidHub",
    ),
    const ExternalMediaPlayer(
      id: "infuse",
      name: "Infuse",
    ),
    const ExternalMediaPlayer(
      id: "iina",
      name: "IINA",
    ),
    const ExternalMediaPlayer(
      id: "omniplayer",
      name: "OmniPlayer",
    ),
    const ExternalMediaPlayer(
      id: "nplayer-mac",
      name: "nPlayer",
    ),
  ]
};
