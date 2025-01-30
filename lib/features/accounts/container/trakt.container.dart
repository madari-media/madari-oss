import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../common/utils/refresh_auth.dart';
import '../../pocketbase/service/pocketbase.service.dart';

class TraktContainer extends StatefulWidget {
  const TraktContainer({super.key});

  @override
  State<TraktContainer> createState() => _TraktContainerState();
}

class _TraktContainerState extends State<TraktContainer> {
  final pb = AppPocketBaseService.instance.pb;
  bool isLoggedIn = false;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    checkIsLoggedIn();
  }

  void checkIsLoggedIn() {
    final traktToken = pb.authStore.record!.getStringValue("trakt_token");
    setState(() {
      isLoggedIn = traktToken != "";
    });
  }

  Future<void> removeAccount() async {
    setState(() => isLoading = true);
    try {
      final record = pb.authStore.record!;
      record.set("trakt_token", "");

      await pb.collection('users').update(
            record.id,
            body: record.toJson(),
          );

      await refreshAuth();
      setState(() {
        isLoggedIn = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> loginWithTrakt() async {
    setState(() => isLoading = true);
    try {
      await pb.collection("users").authWithOAuth2(
        "oidc",
        (url) async {
          final newUrl = Uri.parse(
            url.toString().replaceFirst(
                  "scope=openid&",
                  "",
                ),
          );
          await launchUrl(newUrl);
        },
        scopes: ["openid"],
      );

      await refreshAuth();
      checkIsLoggedIn();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;

    final isDesktopOrTV = screenWidth > 1024;
    final isTablet = screenWidth > 600 && screenWidth <= 1024;
    final horizontalPadding = isDesktopOrTV
        ? screenWidth * 0.2
        : isTablet
            ? 48.0
            : 24.0;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: 24,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              isLoggedIn ? 'Connected to Trakt' : 'Connect with Trakt',
              style: theme.textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              isLoggedIn
                  ? 'Your Trakt account is connected'
                  : 'Sign in to track your movies and shows',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              height: 50,
              child: FilledButton(
                onPressed: isLoading
                    ? null
                    : (isLoggedIn ? removeAccount : loginWithTrakt),
                style: FilledButton.styleFrom(
                  backgroundColor:
                      isLoggedIn ? colorScheme.error : colorScheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ).copyWith(
                  overlayColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.hovered)) {
                      return colorScheme.onPrimary.withValues(alpha: 0.08);
                    }
                    if (states.contains(WidgetState.pressed)) {
                      return colorScheme.onPrimary.withValues(alpha: 0.12);
                    }
                    return null;
                  }),
                ),
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        isLoggedIn
                            ? 'Disconnect Account'
                            : 'Connect with Trakt',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
