import 'package:cached_query_flutter/cached_query_flutter.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:madari_client/features/streamio_addons/service/stremio_addon_service.dart';
import 'package:madari_client/features/widgetter/plugins/stremio/containers/cast_info_shimmer.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../models/cast_info.dart';

class CastInfoLoader extends StatelessWidget {
  final String id;

  CastInfoLoader({
    super.key,
    required this.id,
  });

  late final Query<CastMember?> query = Query(
    key: "cast$id",
    config: QueryConfig(
      cacheDuration: const Duration(days: 30),
      refetchDuration: const Duration(days: 7),
    ),
    queryFn: () {
      return StremioAddonService.instance.getPerson(id);
    },
  );

  @override
  Widget build(BuildContext context) {
    return QueryBuilder(
      query: query,
      builder: (context, state) {
        if (state.status == QueryStatus.error) {
          return const Center(
            child: Text("Something went wrong"),
          );
        }

        if (state.status == QueryStatus.loading || state.data == null) {
          return const CastInfoShimmer();
        }

        return CastInfo(
          castMember: state.data!,
        );
      },
    );
  }
}

class CastInfo extends StatelessWidget {
  final CastMember castMember;

  const CastInfo({
    super.key,
    required this.castMember,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            floating: false,
            pinned: true,
            backgroundColor: theme.colorScheme.surface,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          theme.colorScheme.primaryContainer.withValues(
                            alpha: 0.8,
                          ),
                          theme.colorScheme.surface,
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: theme.shadowColor.withValues(alpha: 0.2),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: castMember.profilePath != null
                                ? Image.network(
                                    castMember.profilePath!,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            _buildProfilePlaceholder(theme),
                                  )
                                : _buildProfilePlaceholder(theme),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          castMember.name,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (castMember.department != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            castMember.department!,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                        if (_hasSocialLinks(castMember.socialLinks)) ...[
                          const SizedBox(height: 16),
                          _buildSocialMediaRow(theme),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                if (castMember.character != null) _buildCharacterCard(theme),
                if (castMember.birthDate != null ||
                    castMember.birthPlace != null)
                  _buildPersonalInfo(theme),
                if (castMember.knownFor.isNotEmpty) _buildKnownFor(theme),
                if (castMember.biography != null) _buildBiography(theme),
                const SizedBox(height: 24),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfilePlaceholder(ThemeData theme) {
    return Container(
      color: theme.colorScheme.primary.withValues(alpha: 0.1),
      child: Icon(
        Icons.person,
        size: 48,
        color: theme.colorScheme.primary,
      ),
    );
  }

  Widget _buildSocialMediaRow(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (castMember.socialLinks.instagram != null)
          _buildSocialIcon(
            Icons.photo_camera,
            'Instagram',
            theme,
            castMember.socialLinks.instagram,
          ),
        if (castMember.socialLinks.twitter != null)
          _buildSocialIcon(
            Icons.chat,
            'Twitter',
            theme,
            castMember.socialLinks.twitter,
          ),
        if (castMember.socialLinks.facebook != null)
          _buildSocialIcon(
            Icons.facebook,
            'Facebook',
            theme,
            castMember.socialLinks.facebook,
          ),
        if (castMember.socialLinks.website != null)
          _buildSocialIcon(
            Icons.language,
            'Website',
            theme,
            castMember.socialLinks.website,
          ),
      ],
    );
  }

  Widget _buildSocialIcon(
      IconData icon, String label, ThemeData theme, String? url) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: InkWell(
        onTap: () {
          if (url != null) launchUrlString(url);
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: theme.shadowColor.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            icon,
            size: 24,
            color: theme.colorScheme.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildCharacterCard(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              Icons.theater_comedy,
              color: theme.colorScheme.primary,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                castMember.character!,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalInfo(ThemeData theme) {
    return _buildSection(
      title: 'Personal Information',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (castMember.birthDate != null)
            _buildInfoRow(Icons.cake_outlined, castMember.birthDate!, theme),
          if (castMember.birthPlace != null)
            _buildInfoRow(
                Icons.location_on_outlined, castMember.birthPlace!, theme),
        ],
      ),
      theme: theme,
    );
  }

  Widget _buildBiography(ThemeData theme) {
    return _buildSection(
      title: 'Biography',
      content: Text(
        castMember.biography!,
        style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
      ),
      theme: theme,
    );
  }

  Widget _buildKnownFor(ThemeData theme) {
    return _buildSection(
      title: 'Known For',
      content: SizedBox(
        height: 190,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: castMember.knownFor.length,
          itemBuilder: (context, index) {
            final movie = castMember.knownFor[index];

            return Container(
              width: 100,
              margin: const EdgeInsets.only(right: 12),
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () {
                  context.push(
                    "/meta/${movie.type}/${movie.id}",
                    extra: {
                      "meta": movie,
                    },
                  );
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: AspectRatio(
                        aspectRatio: 2 / 3,
                        child: movie.poster != null
                            ? Image.network(
                                movie.poster!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    _buildMoviePlaceholder(theme),
                              )
                            : _buildMoviePlaceholder(theme),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      movie.name ?? "",
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      theme: theme,
    );
  }

  Widget _buildMoviePlaceholder(ThemeData theme) {
    return Container(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          Icons.movie_outlined,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required Widget content,
    required ThemeData theme,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 12),
          content,
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String value, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  bool _hasSocialLinks(SocialLinks links) {
    return links.instagram != null ||
        links.twitter != null ||
        links.facebook != null ||
        links.website != null;
  }
}
