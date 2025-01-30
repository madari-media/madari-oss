import 'package:flutter/material.dart';

class SettingWrapper extends StatelessWidget {
  final Widget child;

  const SettingWrapper({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = switch (screenWidth) {
      > 1024 => screenWidth * 0.2,
      > 600 => 48.0,
      _ => 16.0,
    };
    final isSmallScreen = screenWidth <= 600;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: isSmallScreen ? 16.0 : 24.0,
      ),
      child: child,
    );
  }
}
