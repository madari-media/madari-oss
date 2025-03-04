import 'package:madari_client/features/video_player/container/state/video_settings.dart';
import 'package:media_kit/media_kit.dart';

void setDelay(NativePlayer platform, VideoSettingsProvider settings) {
  platform.setProperty('sub-delay', "${-settings.subtitleDelay}");
  platform.setProperty('audio-delay', "${-settings.audioDelay}");
}
