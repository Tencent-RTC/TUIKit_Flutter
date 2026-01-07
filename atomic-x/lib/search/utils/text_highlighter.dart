import 'package:flutter/material.dart';

class TextHighlighter {
  static Widget buildHighlightedText(String text, String keyword, TextStyle? style, Color highlightColor) {
    if (keyword.isEmpty || !text.toLowerCase().contains(keyword.toLowerCase())) {
      return Text(text, style: style);
    }
    final spans = <TextSpan>[];
    int start = 0;
    int index;
    while ((index = text.toLowerCase().indexOf(keyword.toLowerCase(), start)) != -1) {
      if (index > start) {
        spans.add(TextSpan(text: text.substring(start, index), style: style));
      }
      spans.add(TextSpan(
        text: text.substring(index, index + keyword.length),
        style: style?.copyWith(color: highlightColor),
      ));
      start = index + keyword.length;
    }
    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start), style: style));
    }
    return RichText(text: TextSpan(children: spans));
  }
} 