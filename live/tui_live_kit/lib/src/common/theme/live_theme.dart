import 'package:flutter/widgets.dart';

enum LiveTextRole {
  sheetTitle,
  dialogTitle,
  pageTitle,
  sectionTitle,
  itemTitle,
  listTitle,
  body,
  prominent,
  caption,
  metadata,
  control,
  action,
}

enum LiveTextTone { primary, secondary, tertiary, disabled }

abstract final class LiveTheme {
  static const brandBlue = Color(0xFF4A9EFF);
  static const brandDeepBlue = Color(0xFF0052D9);
  static const brandCyan = Color(0xFF7DE8FF);
  static const canvasBackground = Color(0xFF0F121A);
  static const overlayBase = Color(0xFF0A0C12);
  static const nickname = Color(0xFF78D8FF);
  static const audienceGiftValue = Color(0xFFFFE29A);
  static const sheetScrim = Color(0x66000000);

  static Color textColor(LiveTextTone tone) => switch (tone) {
        LiveTextTone.primary => const Color(0xFFFFFFFF),
        LiveTextTone.secondary => const Color(0xBFFFFFFF),
        LiveTextTone.tertiary => const Color(0x7AFFFFFF),
        LiveTextTone.disabled => const Color(0x61FFFFFF),
      };

  static TextStyle textStyle(
    LiveTextRole role, {
    LiveTextTone tone = LiveTextTone.primary,
    bool isEmphasized = false,
    double? lineHeight,
  }) {
    final (double size, FontWeight weight) = switch (role) {
      LiveTextRole.sheetTitle => (15, FontWeight.w600),
      LiveTextRole.dialogTitle => (16, FontWeight.w600),
      LiveTextRole.pageTitle => (21, FontWeight.w600),
      LiveTextRole.sectionTitle => (12, FontWeight.w600),
      LiveTextRole.itemTitle => (13, FontWeight.w400),
      LiveTextRole.listTitle => (15, FontWeight.w400),
      LiveTextRole.body => (14, FontWeight.w400),
      LiveTextRole.prominent => (17, FontWeight.w600),
      LiveTextRole.caption => (12, FontWeight.w400),
      LiveTextRole.metadata => (10, FontWeight.w400),
      LiveTextRole.control => (11, FontWeight.w400),
      LiveTextRole.action => (13, FontWeight.w600),
    };
    return TextStyle(
      fontSize: size,
      fontWeight: isEmphasized ? FontWeight.w600 : weight,
      color: textColor(tone),
      height: lineHeight == null ? null : lineHeight / size,
      decoration: TextDecoration.none,
    );
  }
}

abstract final class LiveVideoOverlayStyle {
  static const capsuleBackground = Color(0x380A0C12);
}

abstract final class LiveAudienceRowStyle {
  static const separator = Color(0x14FFFFFF);
  static const avatarRadius = 21.0;
  static const avatarSize = 42.0;
  static const edgeInset = 10.0;
  static const avatarLeading = 36.0;
  static const avatarTop = 11.0;
  static const nameLeading = 92.0;
  static const giftValueWidth = 38.0;
}
