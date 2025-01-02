import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:image_picker/image_picker.dart';
import 'package:madari_client/engine/engine.dart';
import 'package:pocketbase/pocketbase.dart';

import '../types/user_profile.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  PocketBase get pocketBase => AppEngine.engine.pb;
  late UserProfile _userProfile;
  bool _isLoading = true;
  bool _isEditing = false;

  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _initializeControllers();
  }

  void _initializeControllers() {
    _nameController = TextEditingController();
    _emailController = TextEditingController();
  }

  Future<void> _loadUserProfile() async {
    try {
      final userId = pocketBase.authStore.record!.id;
      final record = await pocketBase.collection('users').getOne(userId);
      setState(() {
        _userProfile = UserProfile.fromJson(record.toJson());
        _isLoading = false;
        _updateControllers();
      });
    } catch (e) {
      if (context.mounted && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: $e')),
        );
      }
    }
  }

  void _updateControllers() {
    _nameController.text = _userProfile.fullName;
    _emailController.text = _userProfile.email;
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final userId = pocketBase.authStore.record!.id;
      final body = {
        'name': _nameController.text,
        'email': _emailController.text,
      };

      await pocketBase.collection('users').update(userId, body: body);

      setState(() {
        _userProfile = UserProfile(
          id: userId,
          fullName: _nameController.text,
          email: _emailController.text,
          avatar: _userProfile.avatar,
        );
        _isEditing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile: $e')),
        );
      }
    }
  }

  Future<void> _uploadAvatar() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image == null) return;

    try {
      final userId = pocketBase.authStore.record!.id;
      final file = File(image.path);

      await pocketBase.collection('users').update(
        userId,
        files: [await MultipartFile.fromPath('avatar', file.path)],
      );

      await _loadUserProfile();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Avatar updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading avatar: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile Information'),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.save : Icons.edit),
            onPressed: () {
              if (_isEditing) {
                _updateProfile();
              } else {
                setState(() => _isEditing = true);
              }
            },
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            GestureDetector(
              onTap: _uploadAvatar,
              child: CircleAvatar(
                radius: 50,
                backgroundImage: _userProfile.avatar != null
                    ? NetworkImage(
                        '${pocketBase.baseURL}/api/files/users/${_userProfile.id}/${_userProfile.avatar}',
                      )
                    : null,
                child: _userProfile.avatar == null
                    ? const Icon(Icons.person, size: 50)
                    : null,
              ),
            ),
            const SizedBox(height: 24),
            _buildProfileField(
              'Full Name',
              _nameController,
              Icons.person,
              _isEditing,
            ),
            _buildProfileField(
              'Email',
              _emailController,
              Icons.email,
              _isEditing,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileField(
    String label,
    TextEditingController controller,
    IconData icon,
    bool isEditing,
  ) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      subtitle: isEditing
          ? TextFormField(
              controller: controller,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter $label';
                }
                return null;
              },
            )
          : Text(controller.text),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }
}
