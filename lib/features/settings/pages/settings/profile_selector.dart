import 'dart:async';

import 'package:flutter/material.dart';
import 'package:madari_client/features/pocketbase/service/pocketbase.service.dart';
import 'package:madari_engine/madari_engine.dart';
import 'package:shimmer/shimmer.dart';

class ProfileSelector extends StatefulWidget {
  const ProfileSelector({super.key});

  @override
  State<ProfileSelector> createState() => _ProfileSelectorState();
}

class _ProfileSelectorState extends State<ProfileSelector> {
  final profileService = AppPocketBaseService.instance.engine.profileService;
  late Future<List<UserProfile>> _future;
  late String selectedProfileId;

  late StreamSubscription<bool> _listenerNew;

  @override
  void initState() {
    super.initState();

    _future = profileService.getAllProfiles();

    _listenerNew = profileService.onProfileUpdate.listen((item) {
      setState(() {
        _future = profileService.getAllProfiles();
      });
    });

    profileService.getCurrentProfile().then((item) {
      selectedProfileId = item!.id;
    });
  }

  @override
  void dispose() {
    super.dispose();
    _listenerNew.cancel();
  }

  Widget _buildShimmerLoading() {
    final colorScheme = Theme.of(context).colorScheme;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        mainAxisExtent: 80,
      ),
      itemCount: 4,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: colorScheme.surfaceContainerHighest,
          highlightColor: colorScheme.surface,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: colorScheme.surfaceContainerHighest,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: colorScheme.surfaceContainerHighest,
                ),
                const SizedBox(height: 4),
                Container(
                  height: 8,
                  width: 40,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return FutureBuilder(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text('Error loading profiles: ${snapshot.error}'),
          );
        }

        if (!snapshot.hasData) {
          return _buildShimmerLoading();
        }

        final profiles = snapshot.data!;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            mainAxisExtent: 80,
          ),
          itemCount: profiles.length,
          itemBuilder: (context, index) {
            final profile = profiles[index];

            final isSelected = selectedProfileId == profile.id;

            return InkWell(
              onTap: () async {
                profileService.setCurrentProfile(profile.id);

                setState(() {
                  selectedProfileId = profile.id;
                });
              },
              borderRadius: BorderRadius.circular(8),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: isSelected
                      ? colorScheme.primaryContainer.withOpacity(0.3)
                      : Colors.transparent,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        if (profile.profileImage != null)
                          CircleAvatar(
                            radius: 24,
                            backgroundImage: NetworkImage(
                              profile.profileImage!,
                            ),
                          )
                        else
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: isSelected
                                ? colorScheme.primary
                                : colorScheme.surfaceContainerHighest,
                            child: Text(
                              profile.name[0].toUpperCase(),
                              style: TextStyle(
                                color: isSelected
                                    ? colorScheme.onPrimary
                                    : colorScheme.onSurfaceVariant,
                                fontSize: 18,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        profile.name,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isSelected ? colorScheme.primary : null,
                          fontWeight: isSelected ? FontWeight.bold : null,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
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
    );
  }
}
