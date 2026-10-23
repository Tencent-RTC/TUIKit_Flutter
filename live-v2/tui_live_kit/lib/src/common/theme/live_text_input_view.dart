import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../live_kit_resources.dart';
import 'live_toast_view.dart';

enum LiveTextLengthUnit { characters, utf8Bytes }

class LiveTextInputView extends StatefulWidget {
  const LiveTextInputView({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.characterLimit,
    required this.maximumLines,
    required this.minimumHeight,
    required this.limitMessageKey,
    required this.style,
    required this.textInputAction,
    required this.onSubmitted,
    this.textAlign = TextAlign.start,
    this.placeholder,
    this.lengthUnit = LiveTextLengthUnit.characters,
    this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final int characterLimit;
  final int maximumLines;
  final double minimumHeight;
  final String limitMessageKey;
  final TextStyle style;
  final TextInputAction textInputAction;
  final VoidCallback onSubmitted;
  final TextAlign textAlign;
  final String? placeholder;
  final LiveTextLengthUnit lengthUnit;
  final ValueChanged<String>? onChanged;

  @override
  State<LiveTextInputView> createState() => _LiveTextInputViewState();
}

class _LiveTextInputViewState extends State<LiveTextInputView> {
  final _toast = LiveToastController();
  late _LiveTextLengthFormatter _formatter;

  @override
  void initState() {
    super.initState();
    _formatter = _LiveTextLengthFormatter(
        widget.characterLimit, widget.lengthUnit, _showLimitToast);
  }

  @override
  void didUpdateWidget(LiveTextInputView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.characterLimit != widget.characterLimit ||
        oldWidget.lengthUnit != widget.lengthUnit) {
      _formatter = _LiveTextLengthFormatter(
          widget.characterLimit, widget.lengthUnit, _showLimitToast);
    }
  }

  void _showLimitToast() {
    if (!mounted) return;
    _toast.show(LiveKitResources.localizedFormat(
        widget.limitMessageKey, widget.characterLimit));
  }

  @override
  void dispose() {
    _toast.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: widget.minimumHeight),
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          Material(
            type: MaterialType.transparency,
            child: TextField(
              controller: widget.controller,
              focusNode: widget.focusNode,
              inputFormatters: [_formatter],
              minLines: 1,
              maxLines: widget.maximumLines,
              keyboardType: TextInputType.multiline,
              textInputAction: widget.textInputAction,
              onSubmitted: (_) => widget.onSubmitted(),
              onChanged: widget.onChanged,
              textAlign: widget.textAlign,
              cursorColor: Colors.white,
              style: widget.style,
              decoration: InputDecoration(
                isCollapsed: true,
                contentPadding: EdgeInsets.zero,
                border: InputBorder.none,
                hintText: widget.placeholder,
                hintMaxLines: 1,
                hintStyle:
                    widget.style.copyWith(color: const Color(0x66FFFFFF)),
              ),
            ),
          ),
          Positioned.fill(child: LiveToastView(controller: _toast)),
        ],
      ),
    );
  }
}

class _LiveTextLengthFormatter extends TextInputFormatter {
  _LiveTextLengthFormatter(this.limit, this.unit, this.onLimitExceeded);

  final int limit;
  final LiveTextLengthUnit unit;
  final VoidCallback onLimitExceeded;
  String _committedText = '';

  int _length(String text) => unit == LiveTextLengthUnit.utf8Bytes
      ? utf8.encode(text).length
      : text.characters.length;

  String _limitedPrefix(String text, int budget) {
    final accepted = StringBuffer();
    var remaining = budget;
    for (final character in text.characters) {
      final length = _length(character);
      if (length > remaining) break;
      accepted.write(character);
      remaining -= length;
    }
    return accepted.toString();
  }

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (oldValue.composing.isCollapsed && _length(oldValue.text) <= limit) {
      _committedText = oldValue.text;
    }
    if (!newValue.composing.isCollapsed) return newValue;
    if (_length(newValue.text) <= limit) {
      _committedText = newValue.text;
      return newValue;
    }
    onLimitExceeded();
    if (oldValue.composing.isCollapsed &&
        oldValue.selection.isValid &&
        _length(oldValue.text) <= limit) {
      final start = oldValue.selection.start;
      final prefix = oldValue.text.substring(0, start);
      final suffix = oldValue.text.substring(oldValue.selection.end);
      final insertionEnd = newValue.text.length - suffix.length;
      if (insertionEnd >= start &&
          newValue.text.startsWith(prefix) &&
          newValue.text.endsWith(suffix)) {
        return _limited(
            prefix, newValue.text.substring(start, insertionEnd), suffix);
      }
    }
    final previous = _committedText.characters.toList();
    final updated = newValue.text.characters.toList();
    var prefixCount = 0;
    while (prefixCount < previous.length &&
        prefixCount < updated.length &&
        previous[prefixCount] == updated[prefixCount]) {
      prefixCount++;
    }
    var suffixCount = 0;
    while (suffixCount < previous.length - prefixCount &&
        suffixCount < updated.length - prefixCount &&
        previous[previous.length - 1 - suffixCount] ==
            updated[updated.length - 1 - suffixCount]) {
      suffixCount++;
    }
    return _limited(
        updated.take(prefixCount).join(),
        updated.sublist(prefixCount, updated.length - suffixCount).join(),
        updated.skip(updated.length - suffixCount).join());
  }

  TextEditingValue _limited(String prefix, String insertion, String suffix) {
    final available =
        (limit - _length(prefix) - _length(suffix)).clamp(0, limit);
    final accepted = _limitedPrefix(insertion, available);
    _committedText = prefix + accepted + suffix;
    return TextEditingValue(
        text: _committedText,
        selection:
            TextSelection.collapsed(offset: prefix.length + accepted.length));
  }
}
