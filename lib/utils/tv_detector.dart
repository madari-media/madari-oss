class DeviceDetector {
  static bool isTV() {
    return const String.fromEnvironment('is_tv') == 'true';
  }
}
