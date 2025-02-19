import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:madari_client/features/pocketbase/service/pocketbase.service.dart';
import 'package:madari_engine/madari_engine.dart';

class FullProfileSelectorPage extends StatefulWidget {
  const FullProfileSelectorPage({super.key});

  @override
  State<FullProfileSelectorPage> createState() =>
      _FullProfileSelectorPageState();
}

class _FullProfileSelectorPageState extends State<FullProfileSelectorPage> {
  late Future<List<UserProfile>> _future;
  final profileService = AppPocketBaseService.instance.engine.profileService;
  String? selectedProfileId;

  @override
  void initState() {
    super.initState();

    _future =
        AppPocketBaseService.instance.engine.profileService.getAllProfiles();

    AppPocketBaseService.instance.engine.profileService
        .getCurrentProfile()
        .then((item) {
      if (item != null) selectedProfileId = item.id;
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  int _getCrossAxisCount(double width) {
    if (width > 1200) return 6;
    if (width > 900) return 5;
    if (width > 600) return 4;
    if (width > 400) return 3;
    return 2;
  }

  double _getAvatarSize(double width) {
    if (width > 1200) return 64;
    if (width > 900) return 56;
    if (width > 600) return 48;
    return 40;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isDesktop = width > 600;
        final padding = isDesktop ? 32.0 : 16.0;
        final spacing = isDesktop ? 24.0 : 16.0;
        final avatarSize = _getAvatarSize(width);
        final crossAxisCount = _getCrossAxisCount(width);

        return Scaffold(
          appBar: AppBar(
            title: Text(
              'Select Profile',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: isDesktop,
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isDesktop ? 1400 : double.infinity,
              ),
              child: Column(
                children: [
                  if (isDesktop) const SizedBox(height: 32),
                  Expanded(
                    child: FutureBuilder(
                      future: _future,
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  size: 48,
                                  color: colorScheme.error,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Error loading profiles',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: colorScheme.error,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${snapshot.error}',
                                  style: theme.textTheme.bodyMedium,
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          );
                        }

                        if (!snapshot.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        final profiles = snapshot.data;

                        return GridView.builder(
                          padding: EdgeInsets.all(padding),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            mainAxisSpacing: spacing,
                            crossAxisSpacing: spacing,
                            mainAxisExtent: isDesktop ? 200 : 160,
                          ),
                          itemCount: profiles!.length,
                          itemBuilder: (context, index) {
                            final profile = profiles[index];

                            final isSelected = snapshot.data == profile.id;

                            return InkWell(
                              onTap: () async {
                                profileService.setCurrentProfile(profile.id);

                                if (context.mounted) context.push("/");
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: isSelected
                                      ? colorScheme.primaryContainer
                                          .withOpacity(0.3)
                                      : Colors.transparent,
                                  border: Border.all(
                                    color: isSelected
                                        ? colorScheme.primary
                                        : colorScheme.outlineVariant,
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        if (profile.profileImage != null)
                                          CircleAvatar(
                                            radius: avatarSize,
                                            backgroundImage: NetworkImage(
                                              profile.profileImage!,
                                            ),
                                          )
                                        else
                                          CircleAvatar(
                                            radius: avatarSize,
                                            backgroundColor: isSelected
                                                ? colorScheme.primary
                                                : colorScheme
                                                    .surfaceContainerHighest,
                                            child: Text(
                                              profile.name[0].toUpperCase(),
                                              style: TextStyle(
                                                color: isSelected
                                                    ? colorScheme.onPrimary
                                                    : colorScheme
                                                        .onSurfaceVariant,
                                                fontSize: avatarSize * 0.75,
                                                fontWeight: isSelected
                                                    ? FontWeight.bold
                                                    : FontWeight.normal,
                                              ),
                                            ),
                                          ),
                                        if (isSelected)
                                          Positioned(
                                            right: 0,
                                            bottom: 0,
                                            child: Container(
                                              padding: EdgeInsets.all(
                                                  isDesktop ? 6 : 4),
                                              decoration: BoxDecoration(
                                                color: colorScheme.primary,
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: colorScheme.surface,
                                                  width: 2,
                                                ),
                                              ),
                                              child: Icon(
                                                Icons.check,
                                                color: colorScheme.onPrimary,
                                                size: isDesktop ? 24 : 20,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: isDesktop ? 16 : 8,
                                      ),
                                      child: Text(
                                        profile.name,
                                        style: (isDesktop
                                                ? theme.textTheme.titleLarge
                                                : theme.textTheme.titleMedium)
                                            ?.copyWith(
                                          color: isSelected
                                              ? colorScheme.primary
                                              : null,
                                          fontWeight: isSelected
                                              ? FontWeight.bold
                                              : null,
                                        ),
                                        textAlign: TextAlign.center,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(padding),
                    child: SizedBox(
                      width: isDesktop ? 400 : double.infinity,
                      child: FilledButton.icon(
                        onPressed: () {
                          context.push("/profile/manage");
                        },
                        style: FilledButton.styleFrom(
                          minimumSize: Size.fromHeight(isDesktop ? 64 : 56),
                        ),
                        icon: Icon(
                          Icons.manage_accounts,
                          size: isDesktop ? 28 : 24,
                        ),
                        label: Text(
                          'Manage Profiles',
                          style: (isDesktop
                                  ? theme.textTheme.titleLarge
                                  : theme.textTheme.titleMedium)
                              ?.copyWith(
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
