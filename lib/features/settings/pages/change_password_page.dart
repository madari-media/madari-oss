import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../pocketbase/service/pocketbase.service.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    _loadUserEmail();
  }

  Future<void> _loadUserEmail() async {
    try {
      final user = AppPocketBaseService.instance.pb.authStore.record;
      if (user != null) {
        _emailController.text = user.data['email'] ?? '';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load user data: $e')),
        );
      }
    }
  }

  Future<void> _updatePassword() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      setState(() => _isLoading = true);
      final user = AppPocketBaseService.instance.pb.authStore.record;

      if (user != null) {
        await AppPocketBaseService.instance.pb.collection('users').update(
          user.id,
          body: {
            'oldPassword': _currentPasswordController.text,
            'password': _newPasswordController.text,
            'passwordConfirm': _confirmPasswordController.text,
          },
        );

        final email = _emailController.text;
        final newPassword = _newPasswordController.text;

        await AppPocketBaseService.instance.pb
            .collection('users')
            .authWithPassword(
              email,
              newPassword,
            );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Password updated successfully')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update password: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required bool obscureText,
    required VoidCallback onToggleVisibility,
    required String? Function(String?) validator,
    String? tooltip,
  }) {
    return Semantics(
      textField: true,
      label: tooltip ?? label,
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        style: Theme.of(context).textTheme.bodyLarge,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.lock_outline),
          suffixIcon: IconButton(
            tooltip: 'Toggle password visibility',
            icon: Icon(obscureText ? Icons.visibility_off : Icons.visibility),
            onPressed: onToggleVisibility,
          ),
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
          fillColor:
              Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
          hoverColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.08),
          focusColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.12),
        ),
        validator: validator,
        onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
        keyboardType: TextInputType.visiblePassword,
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
        title: const Text('Change Password'),
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
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
                          LogicalKeyboardKey.shift, LogicalKeyboardKey.tab):
                      const PreviousFocusIntent(),
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
                                'Change Password',
                                style: theme.textTheme.titleLarge,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Enter your current password and choose a new one.',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              SizedBox(height: isSmallScreen ? 16.0 : 24.0),
                              _buildPasswordField(
                                label: 'Current Password',
                                controller: _currentPasswordController,
                                obscureText: _obscureCurrentPassword,
                                onToggleVisibility: () => setState(() =>
                                    _obscureCurrentPassword =
                                        !_obscureCurrentPassword),
                                validator: (value) => value?.isEmpty ?? true
                                    ? 'Please enter current password'
                                    : null,
                                tooltip: 'Enter your current password',
                              ),
                              SizedBox(height: isSmallScreen ? 12.0 : 16.0),
                              _buildPasswordField(
                                label: 'New Password',
                                controller: _newPasswordController,
                                obscureText: _obscureNewPassword,
                                onToggleVisibility: () => setState(() =>
                                    _obscureNewPassword = !_obscureNewPassword),
                                validator: (value) => value?.isEmpty ?? true
                                    ? 'Please enter new password'
                                    : null,
                                tooltip: 'Enter your new password',
                              ),
                              SizedBox(height: isSmallScreen ? 12.0 : 16.0),
                              _buildPasswordField(
                                label: 'Confirm New Password',
                                controller: _confirmPasswordController,
                                obscureText: _obscureConfirmPassword,
                                onToggleVisibility: () => setState(() =>
                                    _obscureConfirmPassword =
                                        !_obscureConfirmPassword),
                                validator: (value) {
                                  if (value?.isEmpty ?? true) {
                                    return 'Please confirm new password';
                                  }
                                  if (value != _newPasswordController.text) {
                                    return 'Passwords do not match';
                                  }
                                  return null;
                                },
                                tooltip: 'Confirm your new password',
                              ),
                              SizedBox(height: isSmallScreen ? 16.0 : 24.0),
                              Center(
                                child: FilledButton.icon(
                                  onPressed: _updatePassword,
                                  icon: const Icon(Icons.lock),
                                  label: const Text('Update Password'),
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
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _emailController.dispose();
    super.dispose();
  }
}
