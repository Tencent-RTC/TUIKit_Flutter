import 'dart:io';

import 'package:flutter/material.dart';

import 'package:tencent_live_kit_desktop/tencent_live_kit_desktop.dart';

import 'window_control.dart';

/// remixicon has no window-control icons, so the glyphs are hand-drawn.
class WindowControlsBar extends StatefulWidget {
  const WindowControlsBar({super.key});

  @override
  State<WindowControlsBar> createState() => _WindowControlsBarState();
}

class _WindowControlsBarState extends State<WindowControlsBar> {
  @override
  void initState() {
    super.initState();
    WindowControl.ensureInitialized();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _WindowButton(
          icon: const _MinimizeIcon(),
          onTap: WindowControl.minimize,
        ),
        ValueListenableBuilder<bool>(
          valueListenable: WindowControl.isMaximized,
          builder:
              (context, maximized, _) => _WindowButton(
                icon: maximized ? const _RestoreIcon() : const _MaximizeIcon(),
                onTap: WindowControl.toggleMaximize,
              ),
        ),
        _WindowButton(
          icon: const _CloseIcon(),
          onTap: WindowControl.close,
          danger: true,
        ),
      ],
    );
  }
}

class _WindowButton extends StatefulWidget {
  const _WindowButton({
    required this.icon,
    required this.onTap,
    this.danger = false,
  });

  final Widget icon;
  final VoidCallback onTap;

  final bool danger;

  @override
  State<_WindowButton> createState() => _WindowButtonState();
}

class _WindowButtonState extends State<_WindowButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final danger = widget.danger;
    final color =
        danger && _hovering ? Colors.white : LiveKitStyle.textSecondary;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color:
                danger
                    ? (_hovering ? const Color(0xFFE81123) : Colors.transparent)
                    : (_hovering ? LiveKitStyle.white10 : Colors.transparent),
          ),
          child: IconTheme(
            data: IconThemeData(color: color, size: 12),
            child: widget.icon,
          ),
        ),
      ),
    );
  }
}

class _MinimizeIcon extends StatelessWidget {
  const _MinimizeIcon();

  @override
  Widget build(BuildContext context) {
    final color = IconTheme.of(context).color!;
    return SizedBox(
      width: 12,
      height: 12,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(width: 10, height: 1.5, color: color),
      ),
    );
  }
}

class _MaximizeIcon extends StatelessWidget {
  const _MaximizeIcon();

  @override
  Widget build(BuildContext context) {
    final color = IconTheme.of(context).color!;
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(border: Border.all(color: color, width: 1.2)),
    );
  }
}

class _RestoreIcon extends StatelessWidget {
  const _RestoreIcon();

  @override
  Widget build(BuildContext context) {
    final color = IconTheme.of(context).color!;
    Widget box() => Container(
      width: 7,
      height: 7,
      decoration: BoxDecoration(border: Border.all(color: color, width: 1.2)),
    );
    return SizedBox(
      width: 12,
      height: 12,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(top: 0, left: 0, child: box()),
          Positioned(right: 0, bottom: 0, child: box()),
        ],
      ),
    );
  }
}

class _CloseIcon extends StatelessWidget {
  const _CloseIcon();

  @override
  Widget build(BuildContext context) {
    final color = IconTheme.of(context).color!;
    return SizedBox(
      width: 12,
      height: 12,
      child: CustomPaint(painter: _CloseIconPainter(color)),
    );
  }
}

class _CloseIconPainter extends CustomPainter {
  _CloseIconPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color
          ..strokeWidth = 1.2
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke;
    const inset = 1.5;
    canvas.drawLine(
      const Offset(inset, inset),
      Offset(size.width - inset, size.height - inset),
      paint,
    );
    canvas.drawLine(
      Offset(size.width - inset, inset),
      Offset(inset, size.height - inset),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _CloseIconPainter oldDelegate) =>
      oldDelegate.color != color;
}

class WindowDragArea extends StatelessWidget {
  const WindowDragArea({super.key, this.height = 44});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: height,
      child: MouseRegion(
        cursor: SystemMouseCursors.move,
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onPanStart: (_) => WindowControl.startDragging(),
          onDoubleTap: () => WindowControl.toggleMaximize(),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

bool showWindowControls() => Platform.isWindows;
