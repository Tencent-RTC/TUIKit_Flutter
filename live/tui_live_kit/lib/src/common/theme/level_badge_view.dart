library;

import 'package:flutter/widgets.dart';

import '../live_kit_resources.dart';

class LevelBadgeView extends StatelessWidget {
  const LevelBadgeView({super.key, required this.level, this.isInline = false});

  final int level;
  final bool isInline;

  static const Size badgeSize = Size(34, 15);

  static Size sizeForLevel(int level) {
    final painter = TextPainter(
      text: TextSpan(text: '${level < 0 ? 0 : level}', style: _valueStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    final width =
        (14 + painter.width.ceilToDouble() + 4).clamp(34.0, double.infinity);
    painter.dispose();
    return Size(width, badgeSize.height);
  }

  static const _valueStyle = TextStyle(
    fontSize: 8.5,
    fontWeight: FontWeight.w700,
    decoration: TextDecoration.none,
    shadows: [
      Shadow(color: Color(0x57000000), offset: Offset(0, 1), blurRadius: 2)
    ],
  );

  @override
  Widget build(BuildContext context) {
    final int normalizedLevel = level < 0 ? 0 : level;
    final _LiveLevelTier tier = _LiveLevelTier.fromLevel(normalizedLevel);

    final badge = Container(
      width: sizeForLevel(normalizedLevel).width,
      height: badgeSize.height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: tier.colors,
        ),
        borderRadius: const BorderRadius.all(Radius.circular(7.5)),
        boxShadow: !isInline && tier.shadowRadius > 0
            ? <BoxShadow>[
                BoxShadow(
                  color: const Color(0x70EDAB4A),
                  blurRadius: tier.shadowRadius,
                ),
              ]
            : null,
      ),
      foregroundDecoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(7.5)),
        border: tier.borderWidth > 0
            ? Border.all(color: tier.borderColor, width: tier.borderWidth)
            : null,
      ),
      child: Stack(
        children: <Widget>[
          // leading 4、垂直居中、10×10。
          Positioned(
            left: 4,
            top: (badgeSize.height - 10) / 2,
            child: Image(
              image: LiveKitResources.image(tier.assetName),
              width: 10,
              height: 10,
              fit: BoxFit.contain,
            ),
          ),
          // The value expands the badge while keeping its icon and trailing inset.
          Positioned(
            left: 14,
            top: 1,
            right: 4,
            height: 12,
            child: Center(
              child: Text(
                '$normalizedLevel',
                textAlign: TextAlign.center,
                textScaler: TextScaler.noScaling,
                style: _valueStyle.copyWith(color: tier.textColor),
              ),
            ),
          ),
        ],
      ),
    );
    return isInline
        ? ClipRRect(borderRadius: BorderRadius.circular(7.5), child: badge)
        : badge;
  }
}

class _LiveLevelTier {
  const _LiveLevelTier._({
    required this.colors,
    required this.assetName,
    required this.borderWidth,
    required this.borderColor,
    required this.textColor,
    required this.shadowRadius,
  });

  factory _LiveLevelTier.fromLevel(int level) {
    if (level >= 40) {
      return _elite;
    }
    if (level >= 25) {
      return _premium;
    }
    if (level >= 10) {
      return _advanced;
    }
    return _basic;
  }

  final List<Color> colors;
  final String assetName;
  final double borderWidth;
  final Color borderColor;
  final Color textColor;
  final double shadowRadius;

  static const _LiveLevelTier _basic = _LiveLevelTier._(
    colors: <Color>[Color(0xFF53637F), Color(0xFF7186AD)],
    assetName: 'livekit_level_basic',
    borderWidth: 0,
    borderColor: Color(0x00000000),
    textColor: Color(0xFFDBE7FF),
    shadowRadius: 0,
  );

  static const _LiveLevelTier _advanced = _LiveLevelTier._(
    colors: <Color>[Color(0xFF397BD8), Color(0xFF55B9DC)],
    assetName: 'livekit_level_advanced',
    borderWidth: 0.5,
    borderColor: Color(0x4DD2F6FF),
    textColor: Color(0xFFE9FBFF),
    shadowRadius: 0,
  );

  static const _LiveLevelTier _premium = _LiveLevelTier._(
    colors: <Color>[Color(0xFF6655E8), Color(0xFFA35DF0), Color(0xFFE76DBD)],
    assetName: 'livekit_level_premium',
    borderWidth: 0.5,
    borderColor: Color(0x6BFFFFFF),
    textColor: Color(0xFFFFF3FF),
    shadowRadius: 0,
  );

  static const _LiveLevelTier _elite = _LiveLevelTier._(
    colors: <Color>[Color(0xFFE58743), Color(0xFFF1C853), Color(0xFF7568F0)],
    assetName: 'livekit_level_elite',
    borderWidth: 0.5,
    borderColor: Color(0xFFFFFACF),
    textColor: Color(0xFFFFF9DD),
    shadowRadius: 6,
  );
}
