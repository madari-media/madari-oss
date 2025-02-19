import 'dart:typed_data';

import 'package:http/http.dart';
import 'package:logging/logging.dart';
import 'package:pocketbase/pocketbase.dart';

import '../../pocketbase/service/pocketbase.service.dart';

class AccountProfileService {
  static final AccountProfileService instance =
      AccountProfileService._internal();
  final _logger = Logger('AccountProfileService');
  final profileService = AppPocketBaseService.instance.engine.profileService;

  AccountProfileService._internal();

  Future<RecordModel> createProfile({
    required String name,
    required bool canSearch,
    Uint8List? profileImage,
  }) async {
    try {
      final formData = {
        'name': name,
        'can_search': canSearch,
        'user': AppPocketBaseService.instance.pb.authStore.record!.id,
      };

      final record = await AppPocketBaseService.instance.pb
          .collection('account_profile')
          .create(
        body: formData,
        files: [
          if (profileImage != null)
            MultipartFile.fromBytes(
              'profile_image',
              profileImage,
              filename: 'profile_image.jpg',
            )
        ],
      );

      _logger.info('Profile created successfully: ${record.id}');
      return record;
    } catch (e, stack) {
      _logger.warning('Error creating profile: $e', e, stack);
      rethrow;
    }
  }

  Future<RecordModel> updateProfile({
    required String id,
    String? name,
    bool? canSearch,
    Uint8List? profileImage,
  }) async {
    try {
      final formData = <String, dynamic>{};

      if (name != null) formData['name'] = name;
      if (canSearch != null) formData['can_search'] = canSearch;

      final record = await AppPocketBaseService.instance.pb
          .collection('account_profile')
          .update(
        id,
        body: formData,
        files: [
          if (profileImage != null)
            MultipartFile.fromBytes(
              'profile_image',
              profileImage,
              filename: 'profile_image.jpg',
            ),
        ],
      );

      _logger.info('Profile updated successfully: ${record.id}');
      return record;
    } catch (e) {
      _logger.warning('Error updating profile: $e');
      rethrow;
    }
  }

  Future<List<RecordModel>> getProfiles() async {
    try {
      final records = await AppPocketBaseService.instance.pb
          .collection('account_profile')
          .getFullList();

      _logger.info('Retrieved ${records.length} profiles');
      return records;
    } catch (e) {
      _logger.warning('Error fetching profiles: $e');
      rethrow;
    }
  }

  Future<void> deleteProfile(String id) async {
    try {
      await AppPocketBaseService.instance.pb
          .collection('account_profile')
          .delete(id);

      _logger.info('Profile deleted successfully: $id');
    } catch (e) {
      _logger.warning('Error deleting profile: $e');
      rethrow;
    }
  }
}
