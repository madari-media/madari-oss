import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';
import 'package:madari_client/consts/data.dart';
import 'package:madari_client/features/settings/service/selected_profile.dart';
import 'package:madari_client/features/streamio_addons/extension/query_extension.dart';
import 'package:madari_client/features/streamio_addons/service/stremio_addon_service.dart';
import 'package:pocketbase/pocketbase.dart';

import '../../common/utils/error_handler.dart';
import '../../pocketbase/service/pocketbase.service.dart';
import '../../theme/theme/app_theme.dart';
import '../service/layout_service.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage>
    with SingleTickerProviderStateMixin {
  final _logger = Logger("SignUpPage");
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameFocusNode = FocusNode();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  final pocketbase = AppPocketBaseService.instance.pb;

  void _setupKeyboardListeners() {
    _nameFocusNode.addListener(() {
      if (!_nameFocusNode.hasFocus && _nameController.text.isNotEmpty) {
        _formKey.currentState?.validate();
      }
    });

    _emailFocusNode.addListener(() {
      if (!_emailFocusNode.hasFocus && _emailController.text.isNotEmpty) {
        _formKey.currentState?.validate();
      }
    });

    _passwordFocusNode.addListener(() {
      if (!_passwordFocusNode.hasFocus && _passwordController.text.isNotEmpty) {
        _formKey.currentState?.validate();
      }
    });

    _confirmPasswordFocusNode.addListener(() {
      if (!_confirmPasswordFocusNode.hasFocus &&
          _confirmPasswordController.text.isNotEmpty) {
        _formKey.currentState?.validate();
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _setupKeyboardListeners();
    _animationController.forward();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
  }

  Widget _buildAnimatedTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required IconData icon,
    required String? Function(String?) validator,
    bool isPassword = false,
    required TextInputType keyboardType,
    required TextInputAction textInputAction,
    required List<String> autofillHints,
    required VoidCallback? onEditingComplete,
    bool isConfirmPassword = false,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 500),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        obscureText: isPassword
            ? (isConfirmPassword ? _obscureConfirmPassword : _obscurePassword)
            : false,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        autofillHints: autofillHints,
        onEditingComplete: onEditingComplete,
        style: Theme.of(context).textTheme.bodyLarge,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    (isConfirmPassword
                            ? _obscureConfirmPassword
                            : _obscurePassword)
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                  onPressed: () {
                    setState(() {
                      if (isConfirmPassword) {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      } else {
                        _obscurePassword = !_obscurePassword;
                      }
                    });
                  },
                  tooltip: (isConfirmPassword
                          ? _obscureConfirmPassword
                          : _obscurePassword)
                      ? 'Show password'
                      : 'Hide password',
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color:
                  Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
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
          fillColor: Theme.of(context).colorScheme.surface,
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildThemeToggle() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(24),
      ),
      child: IconButton(
        icon: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return RotationTransition(
              turns: animation,
              child: FadeTransition(
                opacity: animation,
                child: child,
              ),
            );
          },
          child: Icon(
            isDark ? Icons.light_mode : Icons.dark_mode,
            key: ValueKey<bool>(isDark),
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        onPressed: () {
          AppTheme().toggleTheme();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Stack(
        children: [
          Positioned(
            top: 16,
            right: 16,
            child: _buildThemeToggle(),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: AutofillGroup(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Hero(
                            tag: 'app_logo',
                            child: Image.asset(
                              'assets/icon/icon_mini.png',
                              height: 80,
                              width: 80,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Madari',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Create your account',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: colorScheme.onSurface.withValues(
                                alpha: 0.7,
                              ),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 32),
                          Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildAnimatedTextField(
                                  controller: _nameController,
                                  focusNode: _nameFocusNode,
                                  label: 'Name',
                                  icon: Icons.person_outline,
                                  keyboardType: TextInputType.name,
                                  textInputAction: TextInputAction.next,
                                  autofillHints: const [AutofillHints.name],
                                  onEditingComplete: () {
                                    _emailFocusNode.requestFocus();
                                  },
                                  validator: (value) {
                                    if (value?.isEmpty ?? true) {
                                      return 'Please enter your name';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                _buildAnimatedTextField(
                                  controller: _emailController,
                                  focusNode: _emailFocusNode,
                                  label: 'Email',
                                  icon: Icons.email_outlined,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  autofillHints: const [AutofillHints.email],
                                  onEditingComplete: () {
                                    _passwordFocusNode.requestFocus();
                                  },
                                  validator: (value) {
                                    if (value?.isEmpty ?? true) {
                                      return 'Please enter your email';
                                    }
                                    if (!RegExp(
                                            r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
                                        .hasMatch(value!)) {
                                      return 'Please enter a valid email';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                _buildAnimatedTextField(
                                  controller: _passwordController,
                                  focusNode: _passwordFocusNode,
                                  label: 'Password',
                                  icon: Icons.lock_outline,
                                  isPassword: true,
                                  keyboardType: TextInputType.visiblePassword,
                                  textInputAction: TextInputAction.next,
                                  autofillHints: const [
                                    AutofillHints.newPassword
                                  ],
                                  onEditingComplete: () {
                                    _confirmPasswordFocusNode.requestFocus();
                                  },
                                  validator: (value) {
                                    if (value?.isEmpty ?? true) {
                                      return 'Please enter your password';
                                    }
                                    if (value!.length < 6) {
                                      return 'Password must be at least 6 characters';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                _buildAnimatedTextField(
                                  controller: _confirmPasswordController,
                                  focusNode: _confirmPasswordFocusNode,
                                  label: 'Confirm Password',
                                  icon: Icons.lock_outline,
                                  isPassword: true,
                                  isConfirmPassword: true,
                                  keyboardType: TextInputType.visiblePassword,
                                  textInputAction: TextInputAction.done,
                                  autofillHints: const [
                                    AutofillHints.newPassword
                                  ],
                                  onEditingComplete: _signUp,
                                  validator: (value) {
                                    if (value?.isEmpty ?? true) {
                                      return 'Please confirm your password';
                                    }
                                    if (value != _passwordController.text) {
                                      return 'Passwords do not match';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 24),
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  height: 50,
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : _signUp,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: colorScheme.primary,
                                      foregroundColor: colorScheme.onPrimary,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: _isLoading
                                        ? const SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                            ),
                                          )
                                        : const Text(
                                            'Sign Up',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Already have an account? ',
                                      style: TextStyle(
                                        color: colorScheme.onSurface
                                            .withValues(alpha: 0.7),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        context.go('/signin');
                                      },
                                      style: TextButton.styleFrom(
                                        foregroundColor: colorScheme.primary,
                                      ),
                                      child: const Text(
                                        'Sign In',
                                        style: TextStyle(
                                            fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
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
        ],
      ),
    );
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final userData = {
        "email": _emailController.text.trim(),
        "password": _passwordController.text,
        "passwordConfirm": _confirmPasswordController.text,
        "name": _nameController.text.trim(),
      };

      await pocketbase.collection('users').create(body: userData);

      await pocketbase.collection('users').authWithPassword(
            _emailController.text.trim(),
            _passwordController.text,
          );

      final profile = await pocketbase.collection('account_profile').create(
        body: {
          "name": _nameController.text.trim(),
          "can_search": true,
          'user': pocketbase.authStore.record!.id,
        },
      );

      await SelectedProfileService.instance.setSelectedProfile(profile.id);

      for (final defaultAddon in defaultAppAddons) {
        final manifest = await StremioAddonService.instance
            .validateManifest(defaultAddon.url, noCache: true)
            .queryFn();
        await StremioAddonService.instance.saveAddon(manifest);
      }

      await LayoutService.instance.addAllHomeWidgets();

      final addons = StremioAddonService.instance.getInstalledAddons();
      await addons.refetch();

      if (mounted) {
        context.go('/profile');
      }
    } on ClientException catch (e, stack) {
      _logger.warning("Unable to sign up", e, stack);
      if (mounted) {
        String errorMessage = getErrorMessage(e);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'OK',
              textColor: Theme.of(context).colorScheme.onError,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameFocusNode.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }
}
