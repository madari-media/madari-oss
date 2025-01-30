import 'package:flutter/foundation.dart';

class StateProvider extends ChangeNotifier {
  final Map<String, dynamic> _state = {};
  String _search = "";

  Map<String, dynamic> get state => _state;
  String get search => _search;

  dynamic getValue(String key) {
    return _state[key];
  }

  void setSearch(String search) {
    _search = search;
    notifyListeners();
  }

  void setValue(String key, dynamic value) {
    _state[key] = value;
    notifyListeners();
  }

  void removeValue(String key) {
    _state.remove(key);
    notifyListeners();
  }

  void clearAll() {
    _state.clear();
    notifyListeners();
  }

  bool hasKey(String key) {
    return _state.containsKey(key);
  }
}
