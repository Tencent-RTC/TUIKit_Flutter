import 'dart:ui';
import 'package:flutter/material.dart';
import '../../common/app_strings.dart';

enum LiveHomeMode { grid, preview }

class LiveHomeHeaderView extends StatelessWidget {
  const LiveHomeHeaderView({
    super.key,
    required this.mode,
    required this.onModeChanged,
    required this.onStartLive,
    this.enabled = true,
  });
  final LiveHomeMode mode;
  final ValueChanged<LiveHomeMode> onModeChanged;
  final VoidCallback onStartLive;
  final bool enabled;
  @override
  Widget build(BuildContext context) {
    final preview = mode == LiveHomeMode.preview;
    return ColoredBox(
      color: preview ? Colors.transparent : const Color(0xff101116),
      child: SizedBox(
        height: 57,
        child: LayoutBuilder(
          builder: (context, bounds) {
            final startLabel = AppStrings.of(context, 'broadcast');
            final painter = TextPainter(
              text: TextSpan(
                text: startLabel,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              textDirection: Directionality.of(context),
              textScaler: MediaQuery.textScalerOf(context),
            )..layout();
            final startWidth = (painter.width.ceilToDouble() + 52).clamp(80.0, 100.0);
            painter.dispose();
            final selectorWidth = (bounds.maxWidth - 248).clamp(100.0, 132.0);
            return Opacity(
              opacity: enabled ? 1 : .55,
              child: IgnorePointer(
                ignoring: !enabled,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 12, 7),
                  child: Row(
                    children: [
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              AppStrings.of(context, 'onlineLive'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                height: 34 / 24,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: selectorWidth,
                        height: 44,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              height: 36,
                              child: _glass(
                                preview,
                                const Color(0xff20232c),
                                .08,
                                11,
                                Padding(
                                  padding: const EdgeInsets.all(3),
                                  child: Row(
                                    children: [
                                      for (final segment in LiveHomeMode.values)
                                        Expanded(
                                          child: Container(
                                            margin: EdgeInsets.only(
                                              right: segment == LiveHomeMode.grid ? 2 : 0,
                                              left: segment == LiveHomeMode.preview ? 2 : 0,
                                            ),
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(8),
                                              color: mode == segment
                                                  ? (preview ? const Color(0x24ffffff) : const Color(0xff424754))
                                                  : Colors.transparent,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                outlined: false,
                              ),
                            ),
                            Row(
                              children: [
                                for (final segment in LiveHomeMode.values)
                                  Expanded(
                                    child: Semantics(
                                      button: true,
                                      selected: mode == segment,
                                      child: GestureDetector(
                                        behavior: HitTestBehavior.opaque,
                                        onTap: () => onModeChanged(segment),
                                        child: Center(
                                          child: FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: Text(
                                              AppStrings.of(context, segment.name),
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: mode == segment ? FontWeight.w600 : FontWeight.w500,
                                                color: mode == segment
                                                    ? Colors.white
                                                    : preview
                                                    ? const Color(0xc7ffffff)
                                                    : const Color(0xffa0a7b5),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: onStartLive,
                        child: SizedBox(
                          width: startWidth,
                          height: 44,
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: _glass(
                              preview,
                              const Color(0x0dffffff),
                              .06,
                              10,
                              Padding(
                                padding: const EdgeInsets.only(left: 10, right: 10),
                                child: Row(
                                  children: [
                                    Image.asset('assets/home_live_start.png', width: 18, height: 18),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          startLabel,
                                          style: const TextStyle(
                                            color: Color(0xe6ffffff),
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
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
        ),
      ),
    );
  }

  Widget _glass(bool preview, Color solid, double blackAlpha, double radius, Widget child, {bool outlined = true}) =>
      ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          // UIKit's fractionally scrubbed light material has no exact Flutter radius.
          // A small blur plus the same tint preserves transparency; PlatformView rendering needs device verification.
          enabled: preview,
          filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: preview ? Colors.black.withValues(alpha: blackAlpha) : solid,
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(
                color: Colors.white.withValues(
                  alpha: outlined
                      ? .1
                      : preview
                      ? .12
                      : 0,
                ),
              ),
            ),
            child: child,
          ),
        ),
      );
}
