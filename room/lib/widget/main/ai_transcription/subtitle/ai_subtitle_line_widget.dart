import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../config/ai_transcription_config.dart';

/// Single subtitle line widget with streaming text animation and clip-from-top overflow.
///
/// When text exceeds [maxLines], the oldest (top) content is clipped and the newest (bottom)
/// content remains visible — matching the Android `AISubtitleLineView` behaviour where the
/// container height is fixed to `maxLines × lineHeight`, the inner [Text] has no `maxLines`
/// limit, and `clipBehavior = Clip.hardEdge` trims the overflow from the top.
class AISubtitleLineWidget extends StatefulWidget {
  final AITextStyle textStyle;
  final double streamAnimationDuration;
  final int maxLines;
  final String initialText;

  const AISubtitleLineWidget({
    super.key,
    required this.textStyle,
    this.streamAnimationDuration = 0.03,
    this.maxLines = 0,
    this.initialText = '',
  });

  @override
  State<AISubtitleLineWidget> createState() => AISubtitleLineWidgetState();
}

class AISubtitleLineWidgetState extends State<AISubtitleLineWidget> {
  String _fullText = '';
  String _displayText = '';
  int _currentCharIndex = 0;
  Timer? _streamTimer;

  /// Cached single-line height in logical pixels, calculated from the current [textStyle].
  double? _lineHeight;

  @override
  void initState() {
    super.initState();
    if (widget.initialText.isNotEmpty) {
      _fullText = widget.initialText;
      _displayText = widget.initialText;
      _currentCharIndex = widget.initialText.length;
    }
  }

  @override
  void dispose() {
    _streamTimer?.cancel();
    super.dispose();
  }

  /// Update the full text, optionally with streaming animation.
  void updateText(String text, {bool animated = true}) {
    _streamTimer?.cancel();
    _streamTimer = null;

    final previousText = _fullText;
    _fullText = text;

    if (animated && text.isNotEmpty) {
      if (text.startsWith(previousText) && text.length > previousText.length) {
        _currentCharIndex = previousText.length;
        _startStreamAnimation();
      } else {
        _currentCharIndex = 0;
        setState(() => _displayText = '');
        _startStreamAnimation();
      }
    } else {
      setState(() => _displayText = text);
    }
  }

  void clearText() {
    _streamTimer?.cancel();
    _streamTimer = null;
    _fullText = '';
    _currentCharIndex = 0;
    setState(() => _displayText = '');
  }

  String get currentText => _fullText;

  void _startStreamAnimation() {
    final duration = Duration(
      milliseconds: (widget.streamAnimationDuration * 1000).round(),
    );
    _streamTimer = Timer.periodic(duration, (timer) {
      if (_currentCharIndex < _fullText.length) {
        _currentCharIndex++;
        setState(() {
          _displayText = _fullText.substring(0, _currentCharIndex);
        });
      } else {
        timer.cancel();
        _streamTimer = null;
      }
    });
  }

  /// Compute the height of a single line of text using the current [textStyle].
  ///
  /// Uses [TextPainter.preferredLineHeight] which is computed from the font
  /// metrics (ascent + descent + leading), matching Android's
  /// `fontMetrics.descent - fontMetrics.ascent + fontMetrics.leading`.
  /// A `strutStyle` is applied to the [Text] widget so that the actual
  /// rendered line height is consistent with this measurement.
  double _computeLineHeight() {
    if (_lineHeight != null) return _lineHeight!;
    final style = widget.textStyle.toTextStyle();
    // '你好Ag' covers CJK glyphs (tallest ascent) + uppercase latin (ascender)
    // + lowercase descender ('g'), ensuring the measured line height accounts
    // for the maximum extent in both directions across mixed-language content.
    final painter = TextPainter(
      text: TextSpan(text: '你好Ag', style: style),
      maxLines: 1,
      textDirection: TextDirection.ltr,
      strutStyle: StrutStyle.fromTextStyle(style, forceStrutHeight: true),
    )..layout();
    _lineHeight = painter.preferredLineHeight;
    painter.dispose();
    return _lineHeight!;
  }

  @override
  void didUpdateWidget(covariant AISubtitleLineWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.textStyle != widget.textStyle) {
      _lineHeight = null; // Invalidate cache when style changes.
    }
  }

  @override
  Widget build(BuildContext context) {
    final style = widget.textStyle.toTextStyle();

    // Force consistent line height via strutStyle so that every line has the
    // exact same height as our _computeLineHeight() measurement.
    final strutStyle = StrutStyle.fromTextStyle(style, forceStrutHeight: true);

    final textWidget = Text(
      _displayText,
      style: style,
      strutStyle: strutStyle,
      overflow: TextOverflow.visible,
    );

    // When maxLines is not set, render text without height constraint.
    if (widget.maxLines <= 0) {
      return textWidget;
    }

    // Adaptive-height container that clips overflow from the top.
    // The inner Text has no maxLines limit; it grows naturally.
    // By aligning to the bottom, the newest (bottom) text is always visible
    // while the oldest (top) text is clipped away — no ellipsis.
    //
    // Uses ConstrainedBox with minHeight=lineHeight and maxHeight=maxLines*lineHeight
    // so that when text is short (e.g. 1 line), the container shrinks to fit,
    // keeping spacing consistent regardless of maxLines setting.
    final lineHeight = _computeLineHeight();
    final maxHeight = (lineHeight * widget.maxLines).ceilToDouble();

    return ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: lineHeight,
        maxHeight: maxHeight,
      ),
      child: ClipRect(
        child: _BottomAlignedOverflow(
          child: textWidget,
        ),
      ),
    );
  }
}

/// A single-child layout that positions its child aligned to the bottom,
/// allowing it to overflow upward. Combined with [ClipRect], this creates
/// the "clip from top" effect.
class _BottomAlignedOverflow extends SingleChildRenderObjectWidget {
  const _BottomAlignedOverflow({required super.child});

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderBottomAlignedOverflow();
  }
}

class _RenderBottomAlignedOverflow extends RenderShiftedBox {
  _RenderBottomAlignedOverflow() : super(null);

  @override
  void performLayout() {
    final child = this.child!;
    // Let the child use the full available width so line-wrapping is correct,
    // but unconstrained height so it can grow as many lines as needed.
    child.layout(
      BoxConstraints(
        minWidth: constraints.maxWidth,
        maxWidth: constraints.maxWidth,
        minHeight: 0,
        maxHeight: double.infinity,
      ),
      parentUsesSize: true,
    );
    // Container size: full width from parent, height capped by SizedBox.
    // Use constraints.constrain() to ensure the size always satisfies
    // the parent's min/max constraints (avoids "does not meet its
    // constraints" errors when the child is shorter than minHeight or
    // the parent passes an unbounded width).
    size = constraints.constrain(
      Size(constraints.maxWidth, child.size.height),
    );
    // Shift the child so its bottom edge aligns with the container's bottom.
    // When the child is shorter than the container, offset is ≥ 0 (top-aligned
    // effectively, since child fits). When taller, offset is negative, pushing
    // the top of the child above the container — ClipRect trims it.
    final childParentData = child.parentData! as BoxParentData;
    childParentData.offset = Offset(0, size.height - child.size.height);
  }
}
