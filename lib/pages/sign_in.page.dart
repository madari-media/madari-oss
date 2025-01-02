import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:madari_client/engine/engine.dart';
import 'package:madari_client/pages/home.page.dart';
import 'package:madari_client/pages/sign_up.page.dart';
import 'package:pocketbase/pocketbase.dart';

class SignInPage extends StatefulWidget {
  static String get routeName => "/signin";

  const SignInPage({
    super.key,
  });

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> with TickerProviderStateMixin {
  final PocketBase pb = AppEngine.engine.pb;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  late AnimationController _backgroundAnimationController;
  late Animation<double> _backgroundAnimation;

  final List<List<Color>> _gradients = [
    [Colors.purple.shade800, Colors.blue.shade900],
    [Colors.blue.shade900, Colors.teal.shade800],
  ];

  bool _isLoading = false;
  String _errorMessage = '';
  bool _obscurePassword = true;

  late StreamSubscription<AuthStoreEvent> _subscription;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _subscription.cancel();
    _backgroundAnimationController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    _subscription = pb.authStore.onChange.listen((data) {
      if (data.record != null) {
        if (mounted) {
          context.go(HomePage.routeName);
        }
      }
    });

    _backgroundAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);

    _backgroundAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(_backgroundAnimationController);
  }

  Future<void> signIn() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      try {
        await pb.collection("users").authWithPassword(
              _usernameController.text.trim(),
              _passwordController.text.trim(),
            );
      } catch (e) {
        setState(() {
          _errorMessage = 'Invalid username or password';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.lerp(
                    _gradients[0][0],
                    _gradients[1][0],
                    _backgroundAnimation.value,
                  )!,
                  Color.lerp(
                    _gradients[0][1],
                    _gradients[1][1],
                    _backgroundAnimation.value,
                  )!
                ],
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  constraints: BoxConstraints(
                    minWidth: 100,
                    maxWidth: isDesktop ? 400 : double.infinity,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo
                      Text(
                        "Madari",
                        style: GoogleFonts.exo2(
                          color: Colors.white,
                          fontSize: 42,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 48),

                      // Form
                      Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Username field
                            _buildTextField(
                              controller: _usernameController,
                              hintText: 'Username',
                              prefixIcon: Icons.person_outline,
                              autofocus: true,
                            ),
                            const SizedBox(height: 16),

                            // Password field
                            _buildTextField(
                              controller: _passwordController,
                              hintText: 'Password',
                              prefixIcon: Icons.lock_outline,
                              obscureText: _obscurePassword,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: Colors.white70,
                                  size: 20,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Error message
                            if (_errorMessage.isNotEmpty)
                              Text(
                                _errorMessage,
                                style: GoogleFonts.exo2(
                                  color: Colors.red[300],
                                  fontSize: 14,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            if (_errorMessage.isNotEmpty)
                              const SizedBox(height: 24),

                            // Sign in button
                            _buildSignInButton(),
                            const SizedBox(height: 12),

                            // Additional options
                            _buildTextButton(
                              'Sign Up',
                              onPressed: () {
                                context.push(SignUpPage.routeName);
                              },
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
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
    bool obscureText = false,
    Widget? suffixIcon,
    bool autofocus = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        autofocus: autofocus,
        style: GoogleFonts.exo2(
          color: Colors.white,
          fontSize: 15,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: GoogleFonts.exo2(
            color: Colors.white38,
            fontSize: 15,
          ),
          prefixIcon: Icon(
            prefixIcon,
            color: Colors.white70,
            size: 20,
          ),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Please enter your ${hintText.toLowerCase()}';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildSignInButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : signIn,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 0,
      ),
      child: _isLoading
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
              ),
            )
          : Text(
              'Sign In',
              style: GoogleFonts.exo2(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
    );
  }

  Widget _buildTextButton(String text, {required VoidCallback onPressed}) {
    final width = MediaQuery.of(context).size.width;

    return SizedBox(
      width: width * .6,
      child: OutlinedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            vertical: 12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          text,
          style: GoogleFonts.exo2(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
