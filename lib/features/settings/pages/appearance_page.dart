import 'package:flutter/material.dart';

import '../../theme/theme/app_theme.dart';

class AppearancePage extends StatefulWidget {
  const AppearancePage({super.key});

  @override
  State<AppearancePage> createState() => _AppearancePageState();
}

class _AppearancePageState extends State<AppearancePage> {
  final List<Color> _presetColors = [
    Colors.red,
    Colors.pink,
    Colors.purple,
    Colors.deepPurple,
    Colors.indigo,
    Colors.blue,
    Colors.lightBlue,
    Colors.cyan,
    Colors.teal,
    Colors.green,
    Colors.lightGreen,
    Colors.lime,
    Colors.yellow,
    Colors.amber,
    Colors.orange,
    Colors.deepOrange,
    Colors.brown,
    Colors.blueGrey,
    Colors.grey,
    Colors.indigoAccent,
    Colors.black,
  ];

  void _updateThemeColor(Color color) {
    final appTheme = AppTheme();
    appTheme.setPrimaryColorFromRGB(
      color.red,
      color.green,
      color.blue,
    );
  }

  Widget _buildColorButton(Color color, ThemeData theme) {
    return Semantics(
      button: true,
      label: 'Select color',
      child: InkWell(
        onTap: () => _updateThemeColor(color),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.outline.withOpacity(0.5),
              width: 2,
            ),
          ),
          child: color == theme.colorScheme.primary
              ? Center(
                  child: Icon(
                    Icons.check_circle,
                    color: ThemeData.estimateBrightnessForColor(color) ==
                            Brightness.dark
                        ? Colors.white
                        : Colors.black,
                  ),
                )
              : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth > 1024
        ? screenWidth * 0.2
        : screenWidth > 600
            ? 48.0
            : 24.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Appearance',
          style: theme.textTheme.titleLarge,
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: 24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 80,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppTheme().getCurrentTheme().brightness ==
                                  Brightness.light
                              ? theme.colorScheme.primary
                              : theme.colorScheme.outline.withOpacity(0.5),
                        ),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          if (AppTheme().getCurrentTheme().brightness ==
                              Brightness.dark) {
                            setState(() => AppTheme().toggleTheme());
                          }
                        },
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.light_mode,
                              color: theme.colorScheme.onSurface,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Light',
                              style: theme.textTheme.bodyLarge,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Container(
                      height: 80,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppTheme().getCurrentTheme().brightness ==
                                  Brightness.dark
                              ? theme.colorScheme.primary
                              : theme.colorScheme.outline.withOpacity(0.5),
                        ),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          if (AppTheme().getCurrentTheme().brightness ==
                              Brightness.light) {
                            setState(() => AppTheme().toggleTheme());
                          }
                        },
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.dark_mode,
                              color: theme.colorScheme.onSurface,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Dark',
                              style: theme.textTheme.bodyLarge,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Text(
                'Accent Color',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1,
                ),
                itemCount: _presetColors.length,
                itemBuilder: (context, index) {
                  return _buildColorButton(_presetColors[index], theme);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
