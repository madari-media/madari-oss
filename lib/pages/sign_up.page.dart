import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:madari_client/engine/engine.dart';
import 'package:pocketbase/pocketbase.dart';

class SignUpPage extends StatefulWidget {
  static String get routeName => "/signup";

  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> with TickerProviderStateMixin {
  final PocketBase pb = AppEngine.engine.pb;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  late AnimationController _backgroundAnimationController;
  late Animation<double> _backgroundAnimation;

  final List<List<Color>> _gradients = [
    [Colors.purple.shade800, Colors.blue.shade900],
    [Colors.blue.shade900, Colors.teal.shade800],
  ];

  @override
  void initState() {
    super.initState();

    // Initialize background animation
    _backgroundAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);

    _backgroundAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(_backgroundAnimationController);
  }

  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void dispose() {
    _backgroundAnimationController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> signUp() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      try {
        final body = <String, dynamic>{
          "name": _usernameController.text.trim(),
          "email": _emailController.text.trim(),
          "password": _passwordController.text.trim(),
          "passwordConfirm": _confirmPasswordController.text.trim(),
        };

        await pb.collection("users").create(body: body);
        await pb
            .collection("users")
            .authWithPassword(_emailController.text, _passwordController.text);

        if (mounted) {
          context.go("/getting-started");
        }
      } catch (e) {
        setState(() {
          _errorMessage = e.toString().contains('email')
              ? 'Email already exists'
              : e.toString().contains('username')
                  ? 'Username already taken'
                  : 'Failed to create account';
          _isLoading = false;
        });

        print(e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AnimatedBuilder(
          animation: _backgroundAnimation,
          builder: (context, child) {
            return Container(
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
            );
          },
        ),
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        "Create Account",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 48),

                      // Username TextField
                      _buildTextField(
                        autofocus: true,
                        controller: _usernameController,
                        hintText: "Name",
                        autoFillHints: [
                          AutofillHints.name,
                        ],
                        prefixIcon: Icons.drive_file_rename_outline,
                      ),
                      const SizedBox(height: 16),

                      // Email TextField
                      _buildTextField(
                        autofocus: true,
                        controller: _emailController,
                        hintText: "Email",
                        prefixIcon: Icons.email_outlined,
                        autoFillHints: [
                          AutofillHints.email,
                        ],
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your email';
                          }
                          if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$')
                              .hasMatch(value)) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      _buildTextField(
                          autofocus: true,
                          obscureText: true,
                          controller: _passwordController,
                          hintText: "Password",
                          prefixIcon: Icons.password,
                          autoFillHints: [
                            AutofillHints.password,
                          ]),

                      const SizedBox(height: 16),

                      _buildTextField(
                        autofocus: true,
                        obscureText: true,
                        controller: _confirmPasswordController,
                        hintText: "Confirm Password",
                        autoFillHints: [
                          AutofillHints.password,
                        ],
                        prefixIcon: Icons.password,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please confirm your password';
                          }
                          if (value != _passwordController.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      if (_errorMessage.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Text(
                            _errorMessage,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),

                      // Sign Up Button
                      _buildSignInButton(),
                      const SizedBox(height: 24),

                      // Sign In Link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Already have an account?',
                            style: TextStyle(color: Colors.grey),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: Text(
                              'Sign In',
                              style: TextStyle(
                                color: Theme.of(context).primaryIconTheme.color,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
    bool obscureText = false,
    Widget? suffixIcon,
    bool autofocus = false,
    final FormFieldValidator? validator,
    List<String> autoFillHints = const [],
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
        textInputAction: TextInputAction.next,
        onEditingComplete: () => FocusScope.of(context).nextFocus(),
        style: GoogleFonts.exo2(
          color: Colors.white,
          fontSize: 15,
        ),
        autofillHints: autoFillHints,
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
        validator: validator ??
            (value) {
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
      onPressed: _isLoading ? null : signUp,
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
              'Sign Up',
              style: GoogleFonts.exo2(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
    );
  }

  InputDecoration _buildInputDecoration(String hint,
      {bool showVisibilityToggle = false,
      bool obscureText = false,
      VoidCallback? onVisibilityToggle}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.grey),
      filled: true,
      fillColor: Colors.grey[900],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      suffixIcon: showVisibilityToggle
          ? IconButton(
              icon: Icon(
                obscureText ? Icons.visibility_off : Icons.visibility,
                color: Colors.grey,
              ),
              onPressed: onVisibilityToggle,
            )
          : null,
    );
  }
}
