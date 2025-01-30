import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logging/logging.dart';
import 'package:madari_client/features/common/utils/error_handler.dart';
import 'package:pocketbase/pocketbase.dart';

import '../../pocketbase/service/pocketbase.service.dart';
import '../service/account_profile_service.dart';

class ProfileDialog extends StatefulWidget {
  final RecordModel? profile;

  const ProfileDialog({super.key, this.profile});

  @override
  State<ProfileDialog> createState() => _ProfileDialogState();
}

class _ProfileDialogState extends State<ProfileDialog> {
  final _formKey = GlobalKey<FormState>();
  final _logger = Logger('_ProfileDialogState');
  final _nameController = TextEditingController();
  final _profileService = AccountProfileService.instance;

  bool _canSearch = true;
  Uint8List? _selectedImage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.profile != null) {
      _nameController.text = widget.profile!.getStringValue('name');
      _canSearch = widget.profile!.getBoolValue('can_search');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedImage = await picker.pickImage(source: ImageSource.gallery);

      if (pickedImage != null) {
        final imageBytes = await pickedImage.readAsBytes();
        setState(() => _selectedImage = imageBytes);
      }
    } catch (e) {
      _logger.warning('Error picking image: $e');
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      if (widget.profile == null) {
        await _profileService.createProfile(
          name: _nameController.text,
          canSearch: _canSearch,
          profileImage: _selectedImage,
        );
      } else {
        await _profileService.updateProfile(
          id: widget.profile!.id,
          name: _nameController.text,
          canSearch: _canSearch,
          profileImage: _selectedImage,
        );
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } on ClientException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(getErrorMessage(e))),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  widget.profile == null ? 'Create Profile' : 'Edit Profile',
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: 50,
                    backgroundImage: _selectedImage != null
                        ? MemoryImage(_selectedImage!)
                        : widget.profile
                                    ?.getStringValue('profile_image')
                                    .isNotEmpty ??
                                false
                            ? NetworkImage(
                                AppPocketBaseService.instance.pb.files
                                    .getUrl(
                                      widget.profile!,
                                      widget.profile!
                                          .getStringValue('profile_image'),
                                    )
                                    .toString(),
                              )
                            : null,
                    child: _selectedImage == null &&
                            (widget.profile
                                    ?.getStringValue('profile_image')
                                    .isEmpty ??
                                true)
                        ? const Icon(Icons.camera_alt, size: 40)
                        : null,
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: _pickImage,
                  child: const Text(
                    'Change Profile Picture (Do not upload any person picture)',
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Profile Name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a profile name';
                    }
                    return null;
                  },
                  autofocus: true,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Enable Search'),
                  subtitle: const Text(
                    'Allow this profile to search and discover',
                  ),
                  value: _canSearch,
                  onChanged: (value) => setState(() => _canSearch = value),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed:
                          _isLoading ? null : () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 16),
                    FilledButton(
                      onPressed: _isLoading ? null : _saveProfile,
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(),
                            )
                          : Text(widget.profile == null ? 'Create' : 'Save'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
