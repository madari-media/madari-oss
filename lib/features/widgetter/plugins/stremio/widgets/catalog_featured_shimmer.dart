import 'package:flutter/material.dart';

class CatalogFeaturedShimmer extends StatefulWidget {
  const CatalogFeaturedShimmer({super.key});

  @override
  State<CatalogFeaturedShimmer> createState() => _CatalogFeaturedShimmerState();
}

class _CatalogFeaturedShimmerState extends State<CatalogFeaturedShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _animation = Tween<double>(
      begin: 0.0,
      end: 0.5,
    ).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final theme = Theme.of(context);
    final isMobile = screenSize.width <= 600;
    final containerHeight = screenSize.height * (isMobile ? 0.6 : 0.65);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Container(
            height: containerHeight,
            decoration: BoxDecoration(
              color: Color.lerp(
                theme.colorScheme.surface,
                theme.colorScheme.primary.withOpacity(0.1),
                _animation.value,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: theme.shadowColor.withOpacity(0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
