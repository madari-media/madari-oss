import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';

final _logger = Logger('StreamioKeyboardHandler');

class StreamioKeyboardHandler extends StatelessWidget {
  final Widget child;
  final FocusNode focusNode;
  final VoidCallback? onPlay;
  final VoidCallback? onBack;
  final VoidCallback? onNextEpisode;
  final VoidCallback? onPreviousEpisode;

  const StreamioKeyboardHandler({
    super.key,
    required this.child,
    required this.focusNode,
    this.onPlay,
    this.onBack,
    this.onNextEpisode,
    this.onPreviousEpisode,
  });

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: focusNode,
      onKeyEvent: (KeyEvent event) {
        if (event is! KeyDownEvent) return;

        _logger.fine('Key event: ${event.logicalKey}');

        switch (event.logicalKey) {
          case LogicalKeyboardKey.space:
          case LogicalKeyboardKey.enter:
            if (onPlay != null) {
              onPlay!();
              return;
            }
            break;
          case LogicalKeyboardKey.escape:
          case LogicalKeyboardKey.backspace:
            if (onBack != null) {
              onBack!();
              return;
            }
            break;
          case LogicalKeyboardKey.arrowRight:
            if (onNextEpisode != null) {
              onNextEpisode!();
              return;
            }
            break;
          case LogicalKeyboardKey.arrowLeft:
            if (onPreviousEpisode != null) {
              onPreviousEpisode!();
              return;
            }
            break;
        }
      },
      child: child,
    );
  }
}
