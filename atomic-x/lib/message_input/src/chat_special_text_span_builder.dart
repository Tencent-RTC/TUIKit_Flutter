import 'package:tuikit_atomic_x/base_component/base_component.dart';
import 'package:extended_text/extended_text.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../emoji_picker/emoji_picker_data.dart';

class ChatSpecialTextSpanBuilder extends SpecialTextSpanBuilder {
  final ValueChanged<String> onTapUrl;
  SemanticColorScheme colorScheme;

  ChatSpecialTextSpanBuilder({
    this.showAtBackground = false,
    required this.onTapUrl,
    required this.colorScheme,
  });

  /// whether show background for @somebody
  final bool showAtBackground;

  @override
  SpecialText? createSpecialText(String flag,
      {TextStyle? textStyle, SpecialTextGestureTapCallback? onTap, int? index}) {
    if (flag == '') {
      return null;
    }

    ///index is end index of start flag, so text start index should be index-(flag.length-1)
    if (isStart(flag, HttpText.flag)) {
      return HttpText(
          colorScheme: colorScheme, textStyle, onTap, onTapUrl: onTapUrl, start: index! - (HttpText.flag.length - 1));
    } else if (isStart(flag, EmojiText.flag)) {
      return EmojiText(
        colorScheme: colorScheme,
        textStyle,
        start: index! - (EmojiText.flag.length - 1),
      );
    }
    return null;
  }
}

class EmojiText extends SpecialText {
  static const String flag = '[TUIEmoji_';
  final int? start;
  SemanticColorScheme colorScheme;

  EmojiText(
    TextStyle? textStyle, {
    this.start,
    required this.colorScheme,
  }) : super(EmojiText.flag, ']', textStyle);

  @override
  InlineSpan finishText() {
    final String key = toString();
    String res = "";
    if (emojiPickerDataDefault.containsValue(key)) {
      emojiPickerDataDefault.forEach((emojiAssets, value) {
        if (value == key) {
          res = emojiAssets;
        }
      });
    }

    return ImageSpan(
      AssetImage(res, package: "tuikit_atomic_x"),
      actualText: key,
      imageWidth: 22,
      imageHeight: 22,
      start: start!,
      // fit: BoxFit.cover,
      margin: const EdgeInsets.all(0),
    );
  }
}

class HttpText extends SpecialText {
  static const String flag = '!@TURL#*&\$';
  final int? start;
  SemanticColorScheme colorScheme;

  HttpText(TextStyle? textStyle, SpecialTextGestureTapCallback? onTap,
      {required this.colorScheme, required this.onTapUrl, this.start})
      : super(flag, flag, textStyle, onTap: onTap);
  final ValueChanged<String> onTapUrl;

  @override
  InlineSpan finishText() {
    final String text = getContent();
    final isValidUrl = ChatUtils.urlReg.hasMatch(text);
    return isValidUrl
        ? SpecialTextSpan(
            text: text,
            actualText: toString(),
            start: start!,

            ///caret can move into special text
            deleteAll: true,
            style: TextStyle(color: colorScheme.textColorLink),
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                onTapUrl(text);
              },
          )
        : TextSpan(text: toString(), style: textStyle);
  }
}

String getMarkDownStringData({
  String? text,
}) {
  String formattedText = _addSpaceAfterLeftBracket(_addSpaceBeforeHttp(_replaceSingleNewlineWithTwo(text ?? "")));
  RegExp emojiExp = RegExp(r"\[TUIEmoji_(\w{2,})\]");
  formattedText = formattedText.replaceAllMapped(emojiExp, (match) {
    String emojiName = match.group(0) ?? "";
    if (emojiName.isNotEmpty) {
      if (emojiPickerDataDefault.containsValue(emojiName)) {
        emojiPickerDataDefault.forEach((emojiAssets, value) {
          if (value == emojiName) {
            emojiName = '![$value](resource:$emojiAssets#30x30)';
          }
        });
      }
    }

    return emojiName;
  });

  return formattedText;
}

String _addSpaceAfterLeftBracket(String inputText) {
  return inputText.splitMapJoin(
    RegExp(r'<\w+[^<>]*>'),
    onMatch: (match) {
      return match.group(0)!.replaceFirst('<', '< ');
    },
    onNonMatch: (text) => text,
  );
}

String _replaceSingleNewlineWithTwo(String inputText) {
  return inputText.split('\n').join('\n\n');
}

String _addSpaceBeforeHttp(String inputText) {
  return inputText.splitMapJoin(
    RegExp(r'http'),
    onMatch: (match) {
      return ' http';
    },
    onNonMatch: (text) => text,
  );
}
