import 'package:flutter/material.dart';
import 'package:tencent_live_uikit/common/index.dart';
import 'package:tuikit_atomic_x/base_component/basic_controls/action_sheet.dart';
import 'package:tuikit_atomic_x/base_component/theme/color_scheme.dart';
import 'package:tuikit_atomic_x/base_component/theme/theme_state.dart';

class ActionSheetItem {
  final String title;
  final bool isDestructive;
  final VoidCallback onTap;

  const ActionSheetItem({
    required this.title,
    required this.onTap,
    this.isDestructive = false,
  });
}

/// Guards against "tap-through" events that occur during a modal sheet's
/// reverse dismiss animation.
///
/// How it works:
/// - [BaseBottomSheet] calls [trackRoute] right after pushing a sheet. The
///   guard listens for the route's animation status.
/// - When the animation enters [AnimationStatus.reverse] (i.e. the sheet
///   has just begun closing), [isCovered] becomes true and a timestamp is
///   refreshed.
/// - [isCovered] returns false as soon as either of the following happens
///   (whichever comes first):
///     1. The animation reaches [AnimationStatus.dismissed] (normal path).
///     2. More than [_maxCoverDuration] has elapsed since the last reverse
///        timestamp (safety fallback in case the dismissed callback never
///        arrives, e.g. the route is disposed externally).
/// - Forward / completed states are intentionally ignored: while the sheet
///   is fully open it is modal and blocks taps on its own, so no guarding
///   is needed.
///
/// Note: this guard only tracks modal sheets opened via [BaseBottomSheet];
/// it has no effect on `OverlayEntry`-based floating widgets and will not
/// interfere with them.
class BottomSheetGuard {
  BottomSheetGuard._();

  static final BottomSheetGuard instance = BottomSheetGuard._();

  /// Upper bound of the cover window measured from the moment the reverse
  /// animation starts. Slightly larger than the platform's default modal
  /// bottom sheet reverse animation duration (~250ms) to leave a small
  /// margin. Acts purely as a safety fallback — the normal path relies on
  /// [AnimationStatus.dismissed] and usually clears the flag earlier.
  static const Duration _maxCoverDuration = Duration(milliseconds: 350);

  bool _isClosing = false;
  DateTime? _closingStartedAt;

  /// Whether a modal sheet is currently inside its reverse dismiss
  /// animation window. Returns false once the animation finishes
  /// (`dismissed`) or once [_maxCoverDuration] has elapsed since the
  /// reverse animation started, whichever comes first.
  bool get isCovered {
    if (!_isClosing) return false;
    final startedAt = _closingStartedAt;
    if (startedAt == null) return false;
    if (DateTime.now().difference(startedAt) > _maxCoverDuration) {
      // Safety fallback: dismissed callback never arrived (e.g. route was
      // disposed externally). Auto-clear so we cannot get stuck.
      _isClosing = false;
      _closingStartedAt = null;
      return false;
    }
    return true;
  }

  /// Registers a modal route that is being shown. Only the reverse and
  /// dismissed transitions are observed.
  void trackRoute(ModalRoute<dynamic> route) {
    final animation = route.animation;
    if (animation == null) return;

    void listener(AnimationStatus status) {
      if (status == AnimationStatus.reverse) {
        _isClosing = true;
        _closingStartedAt = DateTime.now();
      } else if (status == AnimationStatus.dismissed) {
        animation.removeStatusListener(listener);
        _isClosing = false;
        _closingStartedAt = null;
      }
    }

    animation.addStatusListener(listener);
  }
}

class BottomSheetHandler {
  NavigatorState? _navigatorState;
  Route? _route;

  BottomSheetHandler();

  bool isShowing() {
    return _route?.isActive ?? false;
  }

  void close() {
    if (_navigatorState != null && _navigatorState!.mounted && _route != null && _route!.isActive) {
      _navigatorState!.removeRoute(_route!);
      _route = null;
    }
  }
}

class BaseBottomSheet {
  static BottomSheetHandler showWithHandler(
    BuildContext context, {
    bool useRootNavigator = false,
    String? title,
    String? message,
    required List<ActionSheetItem> actions,
    String? cancelText,
    bool showCancel = true,
  }) {
    final handler = BottomSheetHandler();
    final route = ActionSheet.showModalBottomSheetBySystem(
      context: context,
      useRootNavigator: useRootNavigator,
      backgroundColor: Colors.transparent,
      builder: (buildContext) {
        return _createWidget(buildContext,
            title: title, message: message, actions: actions, showCancel: showCancel, cancelText: cancelText);
      },
    );
    final navigator = Navigator.of(context, rootNavigator: useRootNavigator);
    handler._navigatorState = navigator;
    handler._route = route;
    BottomSheetGuard.instance.trackRoute(route);
    return handler;
  }

  static BottomSheetHandler showModalSheet({
    required WidgetBuilder builder,
    required BuildContext context,
    RouteSettings? routeSettings,
    VoidCallback? onDismiss,
    bool useRootNavigator = false,
    bool isDismissible = true,
    bool isScrollControlled = false,
    Color? barrierColor,
    Color? backgroundColor,
  }) {
    final handler = BottomSheetHandler();
    final route = ActionSheet.showModalBottomSheetBySystem(
      context: context,
      routeSettings: routeSettings,
      useRootNavigator: useRootNavigator,
      isDismissible: isDismissible,
      isScrollControlled: isScrollControlled,
      barrierColor: barrierColor,
      backgroundColor: backgroundColor,
      onDismiss: onDismiss,
      builder: (builderContext) => builder.call(builderContext),
    );
    final navigator = Navigator.of(context, rootNavigator: useRootNavigator);
    handler._navigatorState = navigator;
    handler._route = route;
    BottomSheetGuard.instance.trackRoute(route);
    return handler;
  }

  static Widget _createWidget(
    BuildContext context, {
    String? title,
    String? message,
    required List<ActionSheetItem> actions,
    String? cancelText,
    bool showCancel = true,
  }) {
    // Calculate max height: 60% of screen height
    final maxHeight = MediaQuery.of(context).size.height * 0.6;
    final colors = BaseThemeProvider.colorsOf(context);
    return Container(
      decoration: BoxDecoration(
        color: colors.bgColorDialog,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(14), topRight: Radius.circular(14)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            constraints: BoxConstraints(maxHeight: maxHeight),
            decoration: BoxDecoration(
              color: colors.bgColorDialog,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (title != null || message != null)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                    child: Column(
                      children: [
                        if (title != null)
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 13,
                              color: colors.textColorSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        if (title != null && message != null) const SizedBox(height: 4),
                        if (message != null)
                          Text(
                            message,
                            style: TextStyle(
                              fontSize: 13,
                              color: colors.textColorSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                      ],
                    ),
                  ),
                if (title != null || message != null) _buildDivider(colors),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: actions.asMap().entries.map((entry) {
                        final index = entry.key;
                        final action = entry.value;
                        final isFirst = index == 0 && title == null && message == null;
                        final isLast = index == actions.length - 1;

                        return Column(
                          children: [
                            _buildActionButton(
                              context: context,
                              colors: colors,
                              item: action,
                              isFirst: isFirst,
                              isLast: isLast,
                            ),
                            if (!isLast) _buildDivider(colors),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (showCancel) ...[
            _buildDivider(colors, height: 6.0, padding: 0.0),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: colors.bgColorDialog,
                borderRadius: BorderRadius.circular(14),
              ),
              child: _buildCancelButton(
                context: context,
                colors: colors,
                text: LiveKitLocalizations.of(context)!.common_cancel,
              ),
            ),
          ],
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  static Widget _buildActionButton({
    required BuildContext context,
    required SemanticColorScheme colors,
    required ActionSheetItem item,
    bool isFirst = false,
    bool isLast = false,
  }) {
    Color textColor = item.isDestructive ? colors.textColorError : Colors.white;
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        onPressed: () {
          Navigator.of(context).pop();
          item.onTap();
        },
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              top: isFirst ? const Radius.circular(14) : Radius.zero,
              bottom: isLast ? const Radius.circular(14) : Radius.zero,
            ),
          ),
        ),
        child: Text(
          item.title,
          style: TextStyle(
            color: textColor,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  static Widget _buildCancelButton({
    required BuildContext context,
    required SemanticColorScheme colors,
    required String text,
  }) {
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        onPressed: () => Navigator.of(context).pop(),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  static Widget _buildDivider(SemanticColorScheme colors, {height = 0.5, padding = 20.0}) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: padding),
      child: Container(
        height: height,
        color: colors.strokeColorPrimary,
      ),
    );
  }
}
