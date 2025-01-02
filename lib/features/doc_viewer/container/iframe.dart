import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:madari_client/features/doc_viewer/types/doc_source.dart';

class AdblockList {
  static String str = "";
}

class IframeViewer extends StatefulWidget {
  final IframeSource source;
  const IframeViewer({
    super.key,
    required this.source,
  });

  @override
  State<IframeViewer> createState() => _IframeViewerState();
}

class _IframeViewerState extends State<IframeViewer> {
  final List<ContentBlocker> contentBlockers = [];
  bool _isFullScreen = false;

  @override
  void initState() {
    super.initState();

    final url = AdblockList.str
        .split("\n")
        .where((item) => item.trim() != "")
        .map((item) {
      return ".*.$item/.*";
    }).toList();

    for (final adUrlFilter in url) {
      contentBlockers.add(
        ContentBlocker(
          trigger: ContentBlockerTrigger(
            urlFilter: adUrlFilter,
          ),
          action: ContentBlockerAction(
            type: ContentBlockerActionType.BLOCK,
          ),
        ),
      );
    }

    contentBlockers.add(
      ContentBlocker(
        trigger: ContentBlockerTrigger(
          urlFilter: ".*",
        ),
        action: ContentBlockerAction(
          type: ContentBlockerActionType.CSS_DISPLAY_NONE,
          selector: """
            .banner, .banners, .ads, .ad, .advert, .advertisement,
            [class*="ad-"], [class*="Ad"], [class*="advertisement"],
            [id*="google_ads"], [id*="ad-"],
            iframe[src*="ads"], iframe[src*="doubleclick"],
            div[aria-label*="advertisement"],
            .social-share, .newsletter-signup,
            .popup, .modal-overlay, .cookie-notice,
            [class*="cookie-banner"], [id*="cookie-consent"]
          """,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen,
              color: Colors.black,
            ),
            onPressed: () {
              setState(() {
                _isFullScreen = !_isFullScreen;
              });
              if (_isFullScreen) {
                SystemChrome.setEnabledSystemUIMode(
                    SystemUiMode.immersiveSticky);
              } else {
                SystemChrome.setEnabledSystemUIMode(
                  SystemUiMode.manual,
                  overlays: SystemUiOverlay.values,
                );
              }
            },
          ),
        ],
      ),
      body: InAppWebView(
        initialSettings: InAppWebViewSettings(
          contentBlockers: contentBlockers,
          useShouldOverrideUrlLoading: true,
          iframeAllow:
              "accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture",
          iframeCsp: "",
          iframeReferrerPolicy: ReferrerPolicy.ORIGIN,
          iframeAllowFullscreen: true,
        ),
        initialUrlRequest: URLRequest(
          url: WebUri(
            widget.source.url,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
    super.dispose();
  }
}
