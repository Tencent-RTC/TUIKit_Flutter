import 'dart:async';

import 'package:flutter/material.dart';
import 'package:remixicon/remixicon.dart';

import '../style/constants.dart';
import '../style/live_kit_style.dart';

/// Errors linger longer so error codes can be noted down.
enum ToastLevel { info, warn, error }

const Duration errorToastDuration = Duration(seconds: 6);

const Duration _defaultToastDuration = Duration(seconds: 4);

/// Overlay-based, so hosts need no Scaffold.
void showToast(
  BuildContext context,
  String message, {
  ToastLevel level = ToastLevel.info,
  Duration? duration,
}) {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) {
    return;
  }
  _ToastHub.show(
    overlay,
    message,
    level,
    duration ??
        (level == ToastLevel.error
            ? errorToastDuration
            : _defaultToastDuration),
  );
}

void showToastOnOverlay(
  OverlayState overlay,
  String message, {
  ToastLevel level = ToastLevel.info,
  Duration? duration,
}) {
  _ToastHub.show(
    overlay,
    message,
    level,
    duration ??
        (level == ToastLevel.error
            ? errorToastDuration
            : _defaultToastDuration),
  );
}

IconData _iconFor(ToastLevel level) => switch (level) {
  ToastLevel.info => RemixIcons.information_line,
  ToastLevel.warn => RemixIcons.error_warning_line,
  ToastLevel.error => RemixIcons.close_circle_line,
};

Color _iconColorFor(ToastLevel level) => switch (level) {
  ToastLevel.info => LiveKitStyle.info, // --c-info
  ToastLevel.warn => LiveKitStyle.gold, // --c-gold (warning amber)
  ToastLevel.error => LiveKitStyle.danger, // --c-danger
};

class _ToastHub {
  static final List<_ToastData> _items = <_ToastData>[];
  static OverlayEntry? _entry;
  static final ValueNotifier<int> _revision = ValueNotifier<int>(0);

  static void show(
    OverlayState overlay,
    String message,
    ToastLevel level,
    Duration duration,
  ) {
    final data = _ToastData(message, level);
    _items.insert(0, data);
    if (_entry == null) {
      _entry = OverlayEntry(builder: (_) => const _ToastStackView());
      overlay.insert(_entry!);
    }
    _revision.value++;
    Timer(duration, () {
      data.dismissing = true;
      _revision.value++;
      // Wait for the fade-out animation to finish before actually removing.
      Timer(const Duration(milliseconds: 220), () {
        _items.remove(data);
        _revision.value++;
        if (_items.isEmpty) {
          _entry?.remove();
          _entry = null;
        }
      });
    });
  }
}

class _ToastData {
  _ToastData(this.message, this.level);

  final String message;
  final ToastLevel level;
  final int key = Object().hashCode;
  bool dismissing = false;
}

class _ToastStackView extends StatelessWidget {
  const _ToastStackView();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: _ToastHub._revision,
      builder:
          (context, _, __) => Positioned(
            top: 120,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Material(
                type: MaterialType.transparency,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    for (final data in _ToastHub._items)
                      _ToastView(key: ValueKey(data.key), data: data),
                  ],
                ),
              ),
            ),
          ),
    );
  }
}

class _ToastView extends StatelessWidget {
  const _ToastView({super.key, required this.data});

  final _ToastData data;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: data.dismissing ? 0 : 1),
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      builder:
          (context, value, child) => Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, (1 - value) * 8),
              child: child,
            ),
          ),
      child: Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        constraints: const BoxConstraints(maxWidth: 520),
        decoration: BoxDecoration(
          color: const Color(0xFF232130),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              _iconFor(data.level),
              size: 14,
              color: _iconColorFor(data.level),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                data.message,
                style: TextStyle(
                  fontSize: 12,
                  color: const Color(0xFFF0F0F0),
                  height: 1.5,
                  decoration: TextDecoration.none,
                  fontFamilyFallback: getTargetPlatformTextFont,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
