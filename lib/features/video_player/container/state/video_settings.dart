import 'package:flutter/material.dart';

class VideoSettingsProvider extends ChangeNotifier {
  double _subtitleSize = 1.0;
  double _subtitleDelay = 0.0;
  double _audioDelay = 0.0;
  bool _isLocked = false;
  Color _subtitleBackgroundColor = Colors.black;
  double _subtitleOpacity = 0.6;
  bool _isFilled = false;

  double get subtitleSize => _subtitleSize;
  double get subtitleDelay => _subtitleDelay;
  double get audioDelay => _audioDelay;
  bool get isLocked => _isLocked;
  Color get subtitleBackgroundColor => _subtitleBackgroundColor;
  double get subtitleOpacity => _subtitleOpacity;
  bool get isFilled => _isFilled;

  void setSubtitleSize(double size) {
    _subtitleSize = size;
    notifyListeners();
  }

  void setIsFilled(bool isFilled) {
    _isFilled = isFilled;
    notifyListeners();
  }

  void toggleFilled() {
    _isFilled = !_isFilled;
    notifyListeners();
  }

  void setSubtitleDelay(double delay) {
    _subtitleDelay = delay;
    notifyListeners();
  }

  void setAudioDelay(double delay) {
    _audioDelay = delay;
    notifyListeners();
  }

  void setIsLocked(bool locked) {
    _isLocked = locked;
    notifyListeners();
  }

  void toggleLock() {
    _isLocked = !_isLocked;
    notifyListeners();
  }

  void setSubtitleBackgroundColor(Color color) {
    _subtitleBackgroundColor = color;
    notifyListeners();
  }

  void setSubtitleOpacity(double opacity) {
    _subtitleOpacity = opacity;
    notifyListeners();
  }
}
