import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart';
import 'package:image_picker/image_picker.dart';

import '../../pocketbase/service/pocketbase.service.dart';
import '../widget/language_selector.dart';
import '../widget/region_selector.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  File? _selectedImage;
  String? _selectedRegion;
  bool _isLoading = false;
  String? _selectedLanguage;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      setState(() => _isLoading = true);
      final user = AppPocketBaseService.instance.pb.authStore.record;
      if (user != null) {
        _fullNameController.text = user.data['name'] ?? '';
        _emailController.text = user.data['email'] ?? '';
        _selectedRegion = user.data['region'];
        _selectedLanguage = user.data['language'];
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load profile: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() => _selectedImage = File(image.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      setState(() => _isLoading = true);
      final user = AppPocketBaseService.instance.pb.authStore.record;

      if (user != null) {
        final data = {
          'name': _fullNameController.text,
          'region': _selectedRegion,
          'language': _selectedLanguage,
        };

        if (_selectedImage != null) {
          final multipartFile = await MultipartFile.fromPath(
            'avatar',
            _selectedImage!.path,
            filename: 'avatar${DateTime.now().millisecondsSinceEpoch}.jpg',
          );

          await AppPocketBaseService.instance.pb.collection('users').update(
            user.id,
            body: data,
            files: [multipartFile],
          );
        } else {
          await AppPocketBaseService.instance.pb
              .collection('users')
              .update(user.id, body: data);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildTextField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    String? Function(String?)? validator,
    String? tooltip,
    bool readOnly = false,
  }) {
    return Semantics(
      textField: true,
      label: tooltip ?? label,
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        style: Theme.of(context).textTheme.bodyLarge,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.primary,
              width: 2,
            ),
          ),
          filled: true,
          fillColor: Theme.of(context)
              .colorScheme
              .surfaceContainerHighest
              .withOpacity(0.3),
          hoverColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.08),
          focusColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.12),
        ),
        validator: validator,
        onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
        keyboardType: TextInputType.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = switch (screenWidth) {
      > 1024 => screenWidth * 0.2,
      > 600 => 48.0,
      _ => 16.0,
    };

    final theme = Theme.of(context);
    final isSmallScreen = screenWidth <= 600;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Profile'),
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => context.push('/settings/security'),
            icon: const Icon(Icons.security),
            label: const Text('Security'),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Focus(
              autofocus: true,
              child: Shortcuts(
                shortcuts: {
                  LogicalKeySet(LogicalKeyboardKey.tab):
                      const NextFocusIntent(),
                  LogicalKeySet(
                    LogicalKeyboardKey.shift,
                    LogicalKeyboardKey.tab,
                  ): const PreviousFocusIntent(),
                },
                child: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                      vertical: isSmallScreen ? 0.0 : 24.0,
                    ),
                    child: Form(
                      key: _formKey,
                      child: Card(
                        child: Padding(
                          padding: EdgeInsets.all(isSmallScreen ? 16.0 : 24.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Profile Information',
                                style: theme.textTheme.titleLarge,
                              ),
                              SizedBox(height: isSmallScreen ? 16.0 : 24.0),
                              Center(
                                child: Semantics(
                                  button: true,
                                  label: 'Change profile picture',
                                  child: InkWell(
                                    onTap: _pickImage,
                                    borderRadius: BorderRadius.circular(50),
                                    child: Stack(
                                      children: [
                                        CircleAvatar(
                                          radius: isSmallScreen ? 40 : 60,
                                          backgroundImage:
                                              _selectedImage != null
                                                  ? FileImage(_selectedImage!)
                                                  : null,
                                          child: _selectedImage == null
                                              ? Icon(Icons.person,
                                                  size: isSmallScreen ? 40 : 60)
                                              : null,
                                        ),
                                        Positioned(
                                          bottom: 0,
                                          right: 0,
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: BoxDecoration(
                                              color: theme.colorScheme.primary,
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              Icons.camera_alt,
                                              color: Colors.white,
                                              size: isSmallScreen ? 16 : 20,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: isSmallScreen ? 16.0 : 24.0),
                              _buildTextField(
                                label: 'Email',
                                icon: Icons.email_outlined,
                                controller: _emailController,
                                readOnly: true,
                                tooltip: 'Your email address',
                              ),
                              SizedBox(height: isSmallScreen ? 12.0 : 16.0),
                              _buildTextField(
                                label: 'Full Name',
                                icon: Icons.person_outline,
                                controller: _fullNameController,
                                validator: (value) => value?.isEmpty ?? true
                                    ? 'Please enter your name'
                                    : null,
                                tooltip: 'Enter your full name',
                              ),
                              SizedBox(height: isSmallScreen ? 16.0 : 24.0),
                              LanguageSelector(
                                initialValue: _selectedLanguage,
                                onChanged: (value) =>
                                    setState(() => _selectedLanguage = value),
                              ),
                              SizedBox(height: isSmallScreen ? 16.0 : 24.0),
                              RegionSelector(
                                initialValue: _selectedRegion,
                                onChanged: (value) =>
                                    setState(() => _selectedRegion = value),
                              ),
                              SizedBox(height: isSmallScreen ? 16.0 : 24.0),
                              Center(
                                child: FilledButton(
                                  onPressed: _updateProfile,
                                  child: const Text('Update Profile'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    super.dispose();
  }
}
