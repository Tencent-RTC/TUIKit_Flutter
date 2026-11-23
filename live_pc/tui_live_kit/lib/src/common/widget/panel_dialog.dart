import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:remixicon/remixicon.dart';

import '../style/constants.dart';
import '../style/live_kit_style.dart';
import 'hover_clickable.dart';

Future<T?> showPanelDialog<T>(BuildContext context, {required Widget child, String? barrierLabel}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierLabel: barrierLabel,
    // The backdrop is drawn by PanelDialog itself (with blur); skip the
    // default solid barrier color.
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 150),
    pageBuilder: (context, animation, secondaryAnimation) => child,
    transitionBuilder:
        (context, animation, secondaryAnimation, child) => FadeTransition(opacity: animation, child: child),
  );
}

class PanelDialog extends StatelessWidget {
  const PanelDialog({super.key, required this.width, this.height, this.dismissible = true, required this.child});

  final double width;

  final double? height;

  final bool dismissible;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: dismissible ? () => Navigator.pop(context) : null,
            behavior: HitTestBehavior.opaque,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
              child: ColoredBox(color: Colors.black.withValues(alpha: 0.6)),
            ),
          ),
        ),
        Center(
          child: Container(
            width: width,
            height: height,
            decoration: LiveKitStyle.dialogPanel(),
            clipBehavior: Clip.antiAlias,
            child: Material(
              type: MaterialType.transparency,
              child: DefaultTextStyle.merge(
                style: TextStyle(fontFamilyFallback: getTargetPlatformTextFont),
                child: child,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class PanelDialogHeader extends StatelessWidget {
  const PanelDialogHeader({
    super.key,
    required this.icon,
    required this.title,
    this.padded = true,
    this.iconSize = 14,
    this.closeSize = 14,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  });

  final IconData icon;

  final String title;

  final bool padded;

  final EdgeInsetsGeometry padding;

  final double iconSize;

  final double closeSize;

  @override
  Widget build(BuildContext context) {
    final header = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: iconSize, color: LiveKitStyle.textTertiary),
            const SizedBox(width: 6),
            Text(
              title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: LiveKitStyle.textEmphasis),
            ),
          ],
        ),
        _DialogCloseButton(onTap: () => Navigator.pop(context), iconSize: closeSize),
      ],
    );
    return padded ? Padding(padding: padding, child: header) : header;
  }
}

class _DialogCloseButton extends StatefulWidget {
  const _DialogCloseButton({required this.onTap, this.iconSize = 14});

  final VoidCallback? onTap;

  final double iconSize;

  @override
  State<_DialogCloseButton> createState() => _DialogCloseButtonState();
}

class _DialogCloseButtonState extends State<_DialogCloseButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return HoverClickable(
      onTap: widget.onTap,
      onHover: (hovering) => setState(() => _hovering = hovering),
      child: Container(
        width: 24,
        height: 24,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: _hovering ? LiveKitStyle.white10 : LiveKitStyle.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          RemixIcons.close_line,
          size: widget.iconSize,
          color: _hovering ? LiveKitStyle.textSecondary : LiveKitStyle.textTertiary,
        ),
      ),
    );
  }
}
