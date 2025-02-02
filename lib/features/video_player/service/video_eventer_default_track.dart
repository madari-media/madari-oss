import 'dart:async';

import 'package:logging/logging.dart';
import 'package:madari_client/features/settings/model/playback_settings_model.dart';
import 'package:media_kit/media_kit.dart';

class VideoEventerDefaultTrackSetter {
  final _logger = Logger("VideoEventerDefaultTrackSetter");

  final Player player;
  final PlaybackSettings data;
  final List<StreamSubscription> _listeners = [];
  bool defaultConfigSelected = false;
  bool audioSelectionHandled = false;
  bool subtitleSelectionHandled = false;

  VideoEventerDefaultTrackSetter(
    this.player,
    this.data,
  ) {
    _logger.info("VideoEventerDefaultTrackSetter");
    _listeners.add(
      player.stream.tracks.listen(
        (tracks) {
          if (defaultConfigSelected == true &&
              (tracks.audio.length <= 1 || tracks.audio.length <= 1)) {
            return;
          }

          defaultConfigSelected = true;

          player.setRate(data.playbackSpeed);

          final defaultSubtitle = data.defaultSubtitleTrack;
          final defaultAudio = data.defaultAudioTrack;

          for (final item in tracks.audio) {
            if ((defaultAudio == item.id ||
                    defaultAudio == item.language ||
                    defaultAudio == item.title) &&
                audioSelectionHandled == false) {
              player.setAudioTrack(item);
              _logger.info("message player.setAudioTrack(item) = $item");
              audioSelectionHandled = true;
              break;
            }
          }

          if (data.disableSubtitles) {
            for (final item in tracks.subtitle) {
              if ((item.id == "no" ||
                      item.language == "no" ||
                      item.title == "no") &&
                  subtitleSelectionHandled == false) {
                player.setSubtitleTrack(item);
                _logger.info("message player.setSubtitleTrack(item) = $item");
                subtitleSelectionHandled = true;
              }
            }
          } else {
            for (final item in tracks.subtitle) {
              if ((defaultSubtitle == item.id ||
                      defaultSubtitle == item.language ||
                      defaultSubtitle == item.title) &&
                  subtitleSelectionHandled == false) {
                subtitleSelectionHandled = true;
                player.setSubtitleTrack(item);
                _logger.info("message player.setSubtitleTrack(item) = $item");
                break;
              }
            }
          }
        },
      ),
    );
  }

  dispose() {
    _logger.info("VideoEventerDefaultTrackSetter.dispose()");
    for (final item in _listeners) {
      item.cancel();
    }
  }
}
