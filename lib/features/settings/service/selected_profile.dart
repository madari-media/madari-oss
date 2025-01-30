import 'package:logging/logging.dart';
import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SelectedProfileService {
  static final SelectedProfileService instance =
      SelectedProfileService._internal();
  final _logger = Logger('SelectedProfileService');

  static const String _selectedProfileKey = 'selected_profile_id';
  final _selectedProfileSubject = BehaviorSubject<String?>();

  SharedPreferences? _prefs;

  SelectedProfileService._internal();

  Future<void> initialize() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      final storedId = _prefs?.getString(_selectedProfileKey);
      _selectedProfileSubject.add(storedId);
      _logger.info('Initialized with stored profile ID: $storedId');
    } catch (e, stack) {
      _logger.severe('Error initializing SelectedProfileService', e, stack);
      rethrow;
    }
  }

  String? get selectedProfileId => _selectedProfileSubject.valueOrNull;

  Stream<String?> get selectedProfileStream => _selectedProfileSubject.stream;

  Future<void> setSelectedProfile(String? profileId) async {
    try {
      if (profileId != null) {
        await _prefs?.setString(_selectedProfileKey, profileId);
      } else {
        await _prefs?.remove(_selectedProfileKey);
      }
      _selectedProfileSubject.add(profileId);
      _logger.info('Selected profile updated: $profileId');
    } catch (e, stack) {
      _logger.severe('Error setting selected profile', e, stack);
      rethrow;
    }
  }

  void dispose() {
    _selectedProfileSubject.close();
  }
}
