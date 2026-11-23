import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// All desktop clickables should use this instead of a bare GestureDetector.
class HoverClickable extends StatefulWidget {
  const HoverClickable({
    super.key,
    required this.child,
    this.onTap,
    this.onTapDown,
    this.onTapUp,
    this.onTapCancel,
    this.enabled = true,
    this.onHover,
    this.opaque = true,
  });

  final Widget child;

  final VoidCallback? onTap;

  final GestureTapDownCallback? onTapDown;
  final GestureTapUpCallback? onTapUp;

  /// Tap cancellation (pointer moved off / gesture lost the arena while
  /// pressed); consumers holding a pressed visual state must reset it here,
  /// since [onTapUp] will never fire in that case.
  final GestureTapCancelCallback? onTapCancel;

  final bool enabled;

  final ValueChanged<bool>? onHover;

  final bool opaque;

  @override
  State<HoverClickable> createState() => _MouseRegionClickableState();
}

class _MouseRegionClickableState extends State<HoverClickable> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.enabled;
    return MouseRegion(
      cursor:
          enabled ? SystemMouseCursors.click : SystemMouseCursors.forbidden,
      onEnter: (_) {
        if (_hovering) return;
        _hovering = true;
        widget.onHover?.call(true);
      },
      onExit: (_) {
        if (!_hovering) return;
        _hovering = false;
        widget.onHover?.call(false);
      },
      child: GestureDetector(
        onTap: enabled ? widget.onTap : null,
        onTapDown: enabled ? widget.onTapDown : null,
        onTapUp: enabled ? widget.onTapUp : null,
        onTapCancel: enabled ? widget.onTapCancel : null,
        behavior:
            widget.opaque ? HitTestBehavior.opaque : HitTestBehavior.deferToChild,
        child: widget.child,
      ),
    );
  }
}
