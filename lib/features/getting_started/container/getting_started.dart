import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:madari_client/features/connection/containers/auto_import.dart';

import '../../settings/types/connection.dart';
import 'create_connection.dart';

class GettingStartedScreen extends StatefulWidget {
  final VoidCallback onCallback;
  final bool hasBackground;

  const GettingStartedScreen({
    super.key,
    required this.onCallback,
    this.hasBackground = true,
  });

  @override
  State<GettingStartedScreen> createState() => _GettingStartedScreenState();
}

class _GettingStartedScreenState extends State<GettingStartedScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late AnimationController _animationController;
  Connection? _connection;

  late final List<OnboardingStep> steps = [
    OnboardingStep(
      key: 'create_connection',
      title: 'Setup Connection',
      description: 'Configure your Stremio addons',
      icon: Icons.link_rounded,
      gradientColors: [Colors.purple.shade800, Colors.blue.shade900],
    ),
    OnboardingStep(
      key: 'create_library',
      title: 'Create Library',
      description: 'Organize your data into libraries for better management',
      icon: Icons.library_books_rounded,
      gradientColors: [Colors.blue.shade900, Colors.teal.shade800],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < steps.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 800;

    return Stack(
      children: [
        if (widget.hasBackground)
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: steps[_currentPage].gradientColors,
              ),
            ),
          ),
        // Content
        Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isDesktop ? 1200 : double.infinity,
              maxHeight: 800,
            ),
            child: Card(
              margin: EdgeInsets.symmetric(
                horizontal: isDesktop ? 48.0 : 0,
                vertical: isDesktop ? 32.0 : 0,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(32),
              ),
              color: isDesktop ? null : Colors.transparent,
              elevation: 0,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: Stack(
                  children: [
                    Stack(
                      children: [
                        PageView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          controller: _pageController,
                          onPageChanged: (index) {
                            setState(() => _currentPage = index);
                            _animationController.reset();
                            _animationController.forward();
                          },
                          itemCount: steps.length,
                          itemBuilder: (context, index) {
                            return _buildPage(steps[index], index);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPage(
    OnboardingStep step,
    int index,
  ) {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 22),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                if (index != 0)
                  IconButton(
                    onPressed: () {
                      _previousPage();
                    },
                    icon: const Icon(
                      Icons.arrow_back,
                    ),
                  ),
                const SizedBox(
                  width: 6,
                ),
                Text(
                  step.title,
                  textAlign: TextAlign.start,
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
            ),
            child: Text(
              step.description,
              textAlign: TextAlign.start,
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ),
          const SizedBox(height: 0),
          if (step.key == 'create_library')
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height *
                    0.6, // Adjust this value as needed
              ),
              child: Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: AutoImport(
                  item: _connection!,
                  onImport: () {
                    widget.onCallback();
                  },
                ),
              ),
            ),
          if (step.key == 'create_connection')
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
              ),
              child: CreateConnectionStep(
                onConnectionComplete: (Connection connection) {
                  _connection = connection;
                  _nextPage();
                },
              ),
            ),
        ],
      ),
    );
  }
}

class OnboardingStep {
  final String title;
  final String description;
  final IconData icon;
  final List<Color> gradientColors;
  final String key;

  OnboardingStep({
    required this.title,
    required this.description,
    required this.icon,
    required this.gradientColors,
    required this.key,
  });
}
