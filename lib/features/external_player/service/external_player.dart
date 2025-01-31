import 'dart:io';

import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:universal_platform/universal_platform.dart';
import 'package:url_launcher/url_launcher.dart';

final _logger = Logger("ExternalPlayerService");

class ExternalPlayerService {
  static Future<void> openInExternalPlayer({
    required String videoUrl,
    String? playerPackage,
  }) async {
    switch (UniversalPlatform.value) {
      case UniversalPlatformType.Android:
        await _openAndroid(videoUrl, playerPackage);
        break;
      case UniversalPlatformType.IOS:
        await _openIOS(videoUrl, playerPackage);
        break;
      case UniversalPlatformType.MacOS:
        await _openMacOS(videoUrl, playerPackage);
        break;
      case UniversalPlatformType.Windows:
        await _openWindows(videoUrl);
        break;
      case UniversalPlatformType.Linux:
        await _openLinux(videoUrl);
        break;
      default:
        throw PlatformException(
          code: 'UNSUPPORTED_PLATFORM',
          message: 'Platform ${UniversalPlatform.value} is not supported',
        );
    }
  }

  static Future<void> _openAndroid(
      String videoUrl, String? playerPackage) async {
    final AndroidIntent intent = AndroidIntent(
      action: 'action_view',
      type: "video/*",
      package: playerPackage,
      data: videoUrl,
      flags: const <int>[268435456],
      arguments: {},
    );

    await intent.launch();
  }

  static Future<void> _openIOS(String videoUrl, String? customScheme) async {
    if (customScheme != null) {
      final encodedUrl = Uri.encodeComponent(videoUrl);
      String customUrl = '$customScheme://$encodedUrl';

      switch (customScheme) {
        case "infuse":
          customUrl = "infuse://x-callback-url/play?url=$encodedUrl";
          break;
        case "open-vidhub":
          customUrl = "open-vidhub://x-callback-url/open?url=$encodedUrl";
          break;
        case "vlc":
          customUrl = "vlc://$encodedUrl";
          break;
        case "outplayer":
          customUrl = "outplayer://$encodedUrl";
          break;
      }

      _logger.info("External player $customUrl");

      if (await canLaunchUrl(Uri.parse(customUrl))) {
        await launchUrl(Uri.parse(customUrl));
        return;
      }
    }

    await launchUrl(Uri.parse(videoUrl));
  }

  static Future<void> _openMacOS(String videoUrl, String? customScheme) async {
    if (customScheme != null) {
      final encodedUrl = Uri.encodeComponent(videoUrl);

      String customUrl = '$customScheme://$encodedUrl';

      switch (customScheme) {
        case "infuse":
          customUrl = "infuse://x-callback-url/play?url=$encodedUrl";
          break;
        case "open-vidhub":
          customUrl = "open-vidhub://x-callback-url/open?url=$encodedUrl";
          break;
        case "iina":
          customUrl = "iina://weblink?url=$encodedUrl";
          break;
        case "omniplayer":
          customUrl = "omniplayer://$encodedUrl";
          break;
        case "nplayer-mac":
          customUrl = "nplayer-mac://$encodedUrl";
          break;
      }

      _logger.info("External player $customUrl for $customScheme");

      if (await canLaunchUrl(Uri.parse(customUrl))) {
        await launchUrl(Uri.parse(customUrl));
        return;
      }
    }

    await Process.run('open', [videoUrl]);
  }

  static Future<void> _openWindows(String videoUrl) async {
    await Process.run('cmd', ['/c', 'start', videoUrl]);
  }

  static Future<void> _openLinux(String videoUrl) async {
    try {
      await Process.run('xdg-open', [videoUrl]);
    } catch (e) {
      final players = ['vlc', 'mpv', 'mplayer'];
      bool launched = false;

      for (final player in players) {
        try {
          final result = await Process.run('which', [player]);
          if (result.exitCode == 0) {
            await Process.run(player, [videoUrl]);
            launched = true;
            break;
          }
        } catch (e) {
          continue;
        }
      }

      if (!launched) {
        throw PlatformException(
          code: 'NO_PLAYER_FOUND',
          message: 'No suitable video player found on Linux',
        );
      }
    }
  }
}
