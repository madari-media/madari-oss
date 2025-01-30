import 'dart:async';

import 'package:flutter/material.dart';
import 'package:madari_client/features/pocketbase/service/pocketbase.service.dart';
import 'package:pocketbase/src/dtos/record_model.dart';
import 'package:pocketbase/src/dtos/result_list.dart';
import 'package:shimmer/shimmer.dart';

import '../../service/selected_profile.dart';

class ProfileSelector extends StatefulWidget {
  const ProfileSelector({super.key});

  @override
  State<ProfileSelector> createState() => _ProfileSelectorState();
}

class _ProfileSelectorState extends State<ProfileSelector> {
  final _selectedProfileService = SelectedProfileService.instance;

  late Future<ResultList<RecordModel>> _future;

  late StreamSubscription<String?> _listener;

  @override
  void initState() {
    super.initState();

    _future = AppPocketBaseService.instance.pb
        .collection('account_profile')
        .getList();

    _listener = _selectedProfileService.selectedProfileStream.listen(
      (item) {
        if (mounted) {
          setState(() {
            _future = AppPocketBaseService.instance.pb
                .collection('account_profile')
                .getList();
          });
        }
      },
    );
  }

  @override
  void dispose() {
    super.dispose();
    _listener.cancel();
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

        final profiles = snapshot.data!.items;

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

            return StreamBuilder<String?>(
              stream: _selectedProfileService.selectedProfileStream,
              builder: (context, snapshot) {
                final isSelected = snapshot.data == profile.id;

                return InkWell(
                  onTap: () async {
                    final currentSelectedId =
                        _selectedProfileService.selectedProfileId;
                    final newSelectedId = currentSelectedId == profile.id
                        ? profile.id
                        : profile.id;
                    await _selectedProfileService
                        .setSelectedProfile(newSelectedId);
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
                            if (profile.data['profile_image'] != null &&
                                profile.data['profile_image'] != "")
                              CircleAvatar(
                                radius: 24,
                                backgroundImage: NetworkImage(
                                  AppPocketBaseService.instance.pb.files
                                      .getUrl(
                                        profile,
                                        profile.data['profile_image'],
                                      )
                                      .toString(),
                                ),
                              )
                            else
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: isSelected
                                    ? colorScheme.primary
                                    : colorScheme.surfaceVariant,
                                child: Text(
                                  profile.data['name'][0].toUpperCase(),
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
                            profile.data['name'],
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
      },
    );
  }
}
