import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:universal_platform/universal_platform.dart';

import '../../../../streamio_addons/models/stremio_base_types.dart';

class CatalogFeatured extends StatefulWidget {
  final List<Meta> meta;
  final VoidCallback? onTap;

  const CatalogFeatured({
    super.key,
    required this.meta,
    this.onTap,
  });

  @override
  State<CatalogFeatured> createState() => _CatalogFeaturedState();
}

class _CatalogFeaturedState extends State<CatalogFeatured> {
  bool _isImageLoaded = false;
  int _selectedIndex = 0;
  final PageController _pageController = PageController();

  Meta get selectedMeta {
    return widget.meta[_selectedIndex];
  }

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _loadImage() {
    final imageProvider = NetworkImage(selectedMeta.background!);

    imageProvider.resolve(const ImageConfiguration()).addListener(
      ImageStreamListener((info, _) {
        if (mounted) {
          setState(() {
            _isImageLoaded = true;
          });
        }
      }),
    );
  }

  void _onPageChanged(int index) {
    setState(() {
      _selectedIndex = index;
      _isImageLoaded = false;
    });
    _loadImage();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final theme = Theme.of(context);
    final isMobile = screenSize.width <= 600;

    final containerWidth = screenSize.width.clamp(300.0, 1900.0);
    final aspectRatio = isMobile ? 16 / 9 : 21 / 9;
    final containerHeight = math
        .min(
          screenSize.height * (isMobile ? 0.7 : 0.65),
          containerWidth / aspectRatio,
        )
        .clamp(
          300.0 * 1.6,
          800.0 * 1.6,
        );

    final horizontalPadding =
        (screenSize.width - containerWidth).clamp(16.0, 120.0) / 2;

    const textColor = Colors.white;
    const secondaryTextColor = Color(0xB3FFFFFF);
    final darkSurfaceColor = Colors.black.withOpacity(0.8);

    return Padding(
      padding: const EdgeInsets.only(
        top: 18.0,
        left: 6,
        right: 6,
      ),
      child: Center(
        child: Container(
          constraints: BoxConstraints(
            maxWidth: containerWidth,
            maxHeight: containerHeight + 40,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: widget.meta.length,
                    onPageChanged: _onPageChanged,
                    itemBuilder: (context, index) {
                      final meta = widget.meta[index];

                      final image = UniversalPlatform.isMobile
                          ? meta.poster
                          : meta.background;

                      return AnimatedOpacity(
                        duration: const Duration(milliseconds: 300),
                        opacity: _selectedIndex == index ? 1.0 : 0.0,
                        child: GestureDetector(
                          onTap: () {
                            context.push(
                              "/meta/${selectedMeta.type}/${selectedMeta.id}",
                              extra: {
                                "meta": selectedMeta,
                              },
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  if (image != null)
                                    AnimatedOpacity(
                                      opacity: _isImageLoaded &&
                                              _selectedIndex == index
                                          ? 1.0
                                          : 0.0,
                                      duration:
                                          const Duration(milliseconds: 300),
                                      child: Image.network(
                                        "https://proxy-image.syncws.com/insecure/plain/${Uri.encodeQueryComponent(image)}@webp",
                                        fit: BoxFit.cover,
                                        frameBuilder: (context, child, frame,
                                            wasSynchronouslyLoaded) {
                                          if (wasSynchronouslyLoaded) {
                                            return child;
                                          }
                                          return Container(
                                            color: Colors.black,
                                            child: child,
                                          );
                                        },
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                Container(
                                          color: Colors.black,
                                          child: const Icon(
                                            Icons.error_outline,
                                            size: 32,
                                            color: Colors.red,
                                          ),
                                        ),
                                      ),
                                    ),
                                  // Dark overlay gradient
                                  Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.transparent,
                                          darkSurfaceColor.withOpacity(0.2),
                                          darkSurfaceColor.withOpacity(0.85),
                                          darkSurfaceColor,
                                        ],
                                        stops: const [0.3, 0.5, 0.8, 1.0],
                                      ),
                                    ),
                                  ),
                                  // Dim overlay for consistent text readability
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.2),
                                    ),
                                  ),
                                  Positioned.fill(
                                    child: Center(
                                      child: IconButton(
                                        onPressed: () {
                                          context.push(
                                            "/meta/${selectedMeta.type}/${selectedMeta.id}",
                                            extra: {
                                              "meta": selectedMeta,
                                            },
                                          );
                                        },
                                        icon: const Icon(
                                          Icons.play_arrow,
                                          size: 54,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    left: 0,
                                    right: 0,
                                    child: Padding(
                                      padding: EdgeInsets.all(
                                        isMobile ? 16.0 : 24.0,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            meta.name ?? '',
                                            style: theme
                                                .textTheme.headlineMedium
                                                ?.copyWith(
                                              color: textColor,
                                              fontWeight: FontWeight.bold,
                                              fontSize: isMobile ? 24 : 32,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 8),
                                          Wrap(
                                            spacing: 16,
                                            runSpacing: 8,
                                            children: [
                                              if (meta.imdbRating.isNotEmpty)
                                                _buildMetaItem(
                                                  Icons.star_rounded,
                                                  meta.imdbRating,
                                                  theme,
                                                ),
                                              if (meta.year != null)
                                                Text(
                                                  meta.year.toString(),
                                                  style:
                                                      _metadataTextStyle(theme),
                                                ),
                                              if (meta.runtime != null)
                                                Text(
                                                  meta.runtime!,
                                                  style:
                                                      _metadataTextStyle(theme),
                                                ),
                                            ],
                                          ),
                                          if (meta.genres?.isNotEmpty ??
                                              false) ...[
                                            const SizedBox(height: 12),
                                            Text(
                                              meta.genres!.take(3).join(' • '),
                                              style: theme.textTheme.titleMedium
                                                  ?.copyWith(
                                                color: secondaryTextColor,
                                                fontSize: isMobile ? 14 : 16,
                                              ),
                                            ),
                                          ],
                                          const SizedBox(
                                            height: 8,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.meta.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    height: 8,
                    width: _selectedIndex == index ? 24 : 8,
                    decoration: BoxDecoration(
                      color: _selectedIndex == index
                          ? theme.colorScheme.primary
                          : theme.colorScheme.primary.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetaItem(IconData icon, String text, ThemeData theme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 20,
          color: Colors.amberAccent,
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: _metadataTextStyle(theme),
        ),
      ],
    );
  }

  TextStyle _metadataTextStyle(ThemeData theme) {
    return theme.textTheme.titleMedium!.copyWith(
      color: Colors.white,
      fontSize: 16,
      fontWeight: FontWeight.w500,
    );
  }
}
