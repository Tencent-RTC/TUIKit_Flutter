import 'package:flutter/widgets.dart';

import 'live_theme.dart';

class LiveText extends StatelessWidget {
  const LiveText(
    this.role, {
    super.key,
    this.text,
    this.tone = LiveTextTone.primary,
    this.isEmphasized = false,
    this.alignment = TextAlign.left,
    this.lineHeight,
    this.maxLines = 1,
    this.overflow = TextOverflow.ellipsis,
    this.softWrap = true,
  });

  final LiveTextRole role;
  final String? text;
  final LiveTextTone tone;
  final bool isEmphasized;
  final TextAlign alignment;
  final double? lineHeight;
  final int? maxLines;
  final TextOverflow overflow;
  final bool softWrap;

  @override
  Widget build(BuildContext context) => Text(
        text ?? '',
        textAlign: alignment,
        maxLines: maxLines,
        overflow: overflow,
        softWrap: softWrap,
        style: LiveTheme.textStyle(
          role,
          tone: tone,
          isEmphasized: isEmphasized,
          lineHeight: lineHeight,
        ),
      );
}
