import 'package:flutter/material.dart';

import '../../live_kit_resources.dart';

class BarrageEmoji {
  const BarrageEmoji(this.token, this.assetName, this.markerCodePoint);

  final String token;
  final String assetName;
  final int markerCodePoint;

  String get marker => String.fromCharCode(markerCodePoint);

  static const List<BarrageEmoji> all = <BarrageEmoji>[
    BarrageEmoji('[TUIEmoji_Smile]', 'live_barrage_emoji_0', 0xE000),
    BarrageEmoji('[TUIEmoji_Expect]', 'live_barrage_emoji_1', 0xE001),
    BarrageEmoji('[TUIEmoji_Blink]', 'live_barrage_emoji_2', 0xE002),
    BarrageEmoji('[TUIEmoji_Guffaw]', 'live_barrage_emoji_3', 0xE003),
    BarrageEmoji('[TUIEmoji_KindSmile]', 'live_barrage_emoji_4', 0xE004),
    BarrageEmoji('[TUIEmoji_Haha]', 'live_barrage_emoji_5', 0xE005),
    BarrageEmoji('[TUIEmoji_Cheerful]', 'live_barrage_emoji_6', 0xE006),
    BarrageEmoji('[TUIEmoji_Speechless]', 'live_barrage_emoji_7', 0xE007),
    BarrageEmoji('[TUIEmoji_Amazed]', 'live_barrage_emoji_8', 0xE008),
    BarrageEmoji('[TUIEmoji_Sorrow]', 'live_barrage_emoji_9', 0xE009),
    BarrageEmoji('[TUIEmoji_Complacent]', 'live_barrage_emoji_10', 0xE00A),
    BarrageEmoji('[TUIEmoji_Silly]', 'live_barrage_emoji_11', 0xE00B),
    BarrageEmoji('[TUIEmoji_Lustful]', 'live_barrage_emoji_12', 0xE00C),
    BarrageEmoji('[TUIEmoji_Giggle]', 'live_barrage_emoji_13', 0xE00D),
    BarrageEmoji('[TUIEmoji_Kiss]', 'live_barrage_emoji_14', 0xE00E),
    BarrageEmoji('[TUIEmoji_Wail]', 'live_barrage_emoji_15', 0xE00F),
    BarrageEmoji('[TUIEmoji_TearsLaugh]', 'live_barrage_emoji_16', 0xE010),
    BarrageEmoji('[TUIEmoji_Trapped]', 'live_barrage_emoji_17', 0xE011),
    BarrageEmoji('[TUIEmoji_Mask]', 'live_barrage_emoji_18', 0xE012),
    BarrageEmoji('[TUIEmoji_Fear]', 'live_barrage_emoji_19', 0xE013),
    BarrageEmoji('[TUIEmoji_BareTeeth]', 'live_barrage_emoji_20', 0xE014),
    BarrageEmoji('[TUIEmoji_FlareUp]', 'live_barrage_emoji_21', 0xE015),
    BarrageEmoji('[TUIEmoji_Yawn]', 'live_barrage_emoji_22', 0xE016),
    BarrageEmoji('[TUIEmoji_Tact]', 'live_barrage_emoji_23', 0xE017),
    BarrageEmoji('[TUIEmoji_Stareyes]', 'live_barrage_emoji_24', 0xE018),
    BarrageEmoji('[TUIEmoji_ShutUp]', 'live_barrage_emoji_25', 0xE019),
    BarrageEmoji('[TUIEmoji_Sigh]', 'live_barrage_emoji_26', 0xE01A),
    BarrageEmoji('[TUIEmoji_Hehe]', 'live_barrage_emoji_27', 0xE01B),
    BarrageEmoji('[TUIEmoji_Silent]', 'live_barrage_emoji_28', 0xE01C),
    BarrageEmoji('[TUIEmoji_Surprised]', 'live_barrage_emoji_29', 0xE01D),
    BarrageEmoji('[TUIEmoji_Askance]', 'live_barrage_emoji_30', 0xE01E),
    BarrageEmoji('[TUIEmoji_Ok]', 'live_barrage_emoji_31', 0xE01F),
    BarrageEmoji('[TUIEmoji_Shit]', 'live_barrage_emoji_32', 0xE020),
    BarrageEmoji('[TUIEmoji_Monster]', 'live_barrage_emoji_33', 0xE021),
    BarrageEmoji('[TUIEmoji_Daemon]', 'live_barrage_emoji_34', 0xE022),
    BarrageEmoji('[TUIEmoji_Rage]', 'live_barrage_emoji_35', 0xE023),
    BarrageEmoji('[TUIEmoji_Fool]', 'live_barrage_emoji_36', 0xE024),
    BarrageEmoji('[TUIEmoji_Pig]', 'live_barrage_emoji_37', 0xE025),
    BarrageEmoji('[TUIEmoji_Cow]', 'live_barrage_emoji_38', 0xE026),
    BarrageEmoji('[TUIEmoji_Ai]', 'live_barrage_emoji_39', 0xE027),
    BarrageEmoji('[TUIEmoji_Skull]', 'live_barrage_emoji_40', 0xE028),
    BarrageEmoji('[TUIEmoji_Bombs]', 'live_barrage_emoji_41', 0xE029),
    BarrageEmoji('[TUIEmoji_Coffee]', 'live_barrage_emoji_42', 0xE02A),
    BarrageEmoji('[TUIEmoji_Cake]', 'live_barrage_emoji_43', 0xE02B),
    BarrageEmoji('[TUIEmoji_Beer]', 'live_barrage_emoji_44', 0xE02C),
    BarrageEmoji('[TUIEmoji_Flower]', 'live_barrage_emoji_45', 0xE02D),
    BarrageEmoji('[TUIEmoji_Watermelon]', 'live_barrage_emoji_46', 0xE02E),
    BarrageEmoji('[TUIEmoji_Rich]', 'live_barrage_emoji_47', 0xE02F),
    BarrageEmoji('[TUIEmoji_Heart]', 'live_barrage_emoji_48', 0xE030),
    BarrageEmoji('[TUIEmoji_Moon]', 'live_barrage_emoji_49', 0xE031),
    BarrageEmoji('[TUIEmoji_Sun]', 'live_barrage_emoji_50', 0xE032),
    BarrageEmoji('[TUIEmoji_Star]', 'live_barrage_emoji_51', 0xE033),
    BarrageEmoji('[TUIEmoji_RedPacket]', 'live_barrage_emoji_52', 0xE034),
    BarrageEmoji('[TUIEmoji_Celebrate]', 'live_barrage_emoji_53', 0xE035),
    BarrageEmoji('[TUIEmoji_Bless]', 'live_barrage_emoji_54', 0xE036),
    BarrageEmoji('[TUIEmoji_Fortune]', 'live_barrage_emoji_55', 0xE037),
    BarrageEmoji('[TUIEmoji_Convinced]', 'live_barrage_emoji_56', 0xE038),
    BarrageEmoji('[TUIEmoji_Prohibit]', 'live_barrage_emoji_57', 0xE039),
    BarrageEmoji('[TUIEmoji_666]', 'live_barrage_emoji_58', 0xE03A),
    BarrageEmoji('[TUIEmoji_857]', 'live_barrage_emoji_59', 0xE03B),
    BarrageEmoji('[TUIEmoji_Knife]', 'live_barrage_emoji_60', 0xE03C),
    BarrageEmoji('[TUIEmoji_Like]', 'live_barrage_emoji_61', 0xE03D),
  ];

  static final Map<String, BarrageEmoji> byToken = Map<String, BarrageEmoji>.unmodifiable(
    <String, BarrageEmoji>{for (final emoji in all) emoji.token: emoji},
  );

  static final Map<String, BarrageEmoji> byMarker = Map<String, BarrageEmoji>.unmodifiable(
    <String, BarrageEmoji>{for (final emoji in all) emoji.marker: emoji},
  );
}

class BarrageEmojiConverter {
  BarrageEmojiConverter._();

  static final RegExp _tokenPattern = RegExp(r'\[TUIEmoji_[A-Za-z0-9]+\]');

  static String normalize(String text) {
    return text.replaceAllMapped(_tokenPattern, (match) {
      return BarrageEmoji.byToken[match.group(0)]?.marker ?? match.group(0)!;
    });
  }

  static String serialize(String text) {
    final result = StringBuffer();
    for (final rune in text.runes) {
      final character = String.fromCharCode(rune);
      result.write(BarrageEmoji.byMarker[character]?.token ?? character);
    }
    return result.toString();
  }

  static int visibleLength(String text) => normalize(text).characters.length;

  static String visiblePrefix(String text, int budget) {
    if (budget <= 0) return '';
    final normalized = normalize(text);
    if (normalized.characters.length <= budget) return normalized;
    return normalized.characters.take(budget).toString();
  }

  static List<InlineSpan> buildSpans(String text, {double size = 20}) {
    final spans = <InlineSpan>[];
    final pending = StringBuffer();

    void flushText() {
      if (pending.isEmpty) return;
      spans.add(TextSpan(text: pending.toString()));
      pending.clear();
    }

    for (final character in normalize(text).characters) {
      final emoji = BarrageEmoji.byMarker[character];
      if (emoji == null) {
        pending.write(character);
        continue;
      }
      flushText();
      spans.add(WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: buildImage(emoji, size: size),
      ));
    }
    flushText();
    return spans;
  }

  static Widget buildImage(BarrageEmoji emoji, {double size = 32, Color? color}) {
    final fallback = SizedBox(
      width: size,
      height: size,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          emoji.token,
          style: const TextStyle(fontSize: 12, color: Color(0x73000000)),
        ),
      ),
    );
    return Image(
      image: LiveKitResources.image(emoji.assetName),
      width: size,
      height: size,
      fit: BoxFit.contain,
      color: color,
      frameBuilder: (context, child, frame, synchronous) => frame != null || synchronous ? child : fallback,
      errorBuilder: (context, error, stackTrace) => fallback,
    );
  }
}
