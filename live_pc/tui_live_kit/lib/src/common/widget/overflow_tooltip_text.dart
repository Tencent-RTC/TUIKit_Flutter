import 'package:flutter/material.dart';

/// Overflow is re-evaluated on every layout, so a hover animation that narrows the text still shows it.
class OverflowTooltipText extends StatefulWidget {
  const OverflowTooltipText(
    this.text, {
    super.key,
    required this.style,
    this.textAlign,
    this.maxLines = 1,
    this.showDuration = const Duration(seconds: 10),
  });

  final String text;
  final TextStyle style;
  final TextAlign? textAlign;
  final int maxLines;

  final Duration showDuration;

  @override
  State<OverflowTooltipText> createState() => _OverflowTooltipTextState();
}

class _OverflowTooltipTextState extends State<OverflowTooltipText> {
  final GlobalKey<TooltipState> _tooltipKey = GlobalKey<TooltipState>();

  bool _hovering = false;
  bool _overflowing = false;

  void _updateTooltipVisibility() {
    if (_hovering && _overflowing) {
      _tooltipKey.currentState?.ensureTooltipVisible();
    } else {
      Tooltip.dismissAllToolTips();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        _hovering = true;
        _updateTooltipVisibility();
      },
      onExit: (_) {
        _hovering = false;
        _updateTooltipVisibility();
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final painter = TextPainter(
            text: TextSpan(
              text: widget.text,
              style: DefaultTextStyle.of(context).style.merge(widget.style),
            ),
            maxLines: widget.maxLines,
            textDirection: TextDirection.ltr,
            textAlign: widget.textAlign ?? TextAlign.start,
          )..layout(maxWidth: constraints.maxWidth);
          final overflowing = painter.didExceedMaxLines;
          if (overflowing != _overflowing) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              _overflowing = overflowing;
              _updateTooltipVisibility();
            });
          }
          final text = Text(
            widget.text,
            maxLines: widget.maxLines,
            overflow: TextOverflow.ellipsis,
            textAlign: widget.textAlign,
            style: widget.style,
          );
          if (!overflowing) {
            return text;
          }
          return Tooltip(
            key: _tooltipKey,
            message: widget.text,
            triggerMode: TooltipTriggerMode.manual,
            showDuration: widget.showDuration,
            child: text,
          );
        },
      ),
    );
  }
}
