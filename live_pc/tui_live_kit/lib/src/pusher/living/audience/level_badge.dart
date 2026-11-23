import 'package:flutter/material.dart';

import '../../../common/style/live_kit_style.dart';

const String _packageName = 'tencent_live_kit_desktop';

class LevelBadge extends StatelessWidget {
  const LevelBadge({super.key, required this.level});

  final int level;

  static const double height = 14;
  static const double _minimumWidth = 32;
  static const double _iconSize = 9.5;
  static const double _iconLeading = 4;
  static const double _valueLeading = 13;
  static const double _trailingInset = 4;

  static const TextStyle _valueStyle = TextStyle(
    inherit: false,
    fontSize: 8,
    fontWeight: FontWeight.w700,
    decoration: TextDecoration.none,
    shadows: <Shadow>[
      Shadow(color: LiveKitStyle.shadowBlack34, offset: Offset(0, 1), blurRadius: 2),
    ],
  );

  static Size sizeForLevel(int level) {
    final painter = TextPainter(
      text: TextSpan(text: '${level < 0 ? 0 : level}', style: _valueStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    final width = (_valueLeading + painter.width.ceilToDouble() + _trailingInset)
        .clamp(_minimumWidth, double.infinity);
    painter.dispose();
    return Size(width, height);
  }

  @override
  Widget build(BuildContext context) {
    final int normalizedLevel = level < 0 ? 0 : level;
    final _LevelTier tier = _LevelTier.fromLevel(normalizedLevel);

    return ClipRRect(
      borderRadius: BorderRadius.circular(height / 2),
      child: Container(
        width: sizeForLevel(normalizedLevel).width,
        height: height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: tier.colors,
          ),
          borderRadius: BorderRadius.circular(height / 2),
        ),
        foregroundDecoration: BoxDecoration(
          borderRadius: BorderRadius.circular(height / 2),
          border: tier.borderWidth > 0
              ? Border.all(color: tier.borderColor, width: tier.borderWidth)
              : null,
        ),
        child: Stack(
          children: <Widget>[
            Positioned(
              left: _iconLeading,
              top: (height - _iconSize) / 2,
              child: Image(
                image: AssetImage(
                  'assets/${tier.assetName}.png',
                  package: _packageName,
                ),
                width: _iconSize,
                height: _iconSize,
                fit: BoxFit.contain,
              ),
            ),
            Positioned(
              left: _valueLeading,
              top: 1,
              right: _trailingInset,
              height: 11,
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
      ),
    );
  }
}

class _LevelTier {
  const _LevelTier._({
    required this.colors,
    required this.assetName,
    required this.borderWidth,
    required this.borderColor,
    required this.textColor,
  });

  factory _LevelTier.fromLevel(int level) {
    if (level >= 40) return _elite;
    if (level >= 25) return _premium;
    if (level >= 10) return _advanced;
    return _basic;
  }

  final List<Color> colors;
  final String assetName;
  final double borderWidth;
  final Color borderColor;
  final Color textColor;

  static const _LevelTier _basic = _LevelTier._(
    colors: <Color>[Color(0xFF53637F), Color(0xFF7186AD)],
    assetName: 'livekit_level_basic',
    borderWidth: 0,
    borderColor: Color(0x00000000),
    textColor: Color(0xFFDBE7FF),
  );

  static const _LevelTier _advanced = _LevelTier._(
    colors: <Color>[Color(0xFF397BD8), Color(0xFF55B9DC)],
    assetName: 'livekit_level_advanced',
    borderWidth: 0.5,
    borderColor: Color(0x4DD2F6FF),
    textColor: Color(0xFFE9FBFF),
  );

  static const _LevelTier _premium = _LevelTier._(
    colors: <Color>[Color(0xFF6655E8), Color(0xFFA35DF0), Color(0xFFE76DBD)],
    assetName: 'livekit_level_premium',
    borderWidth: 0.5,
    borderColor: Color(0x6BFFFFFF),
    textColor: Color(0xFFFFF3FF),
  );

  static const _LevelTier _elite = _LevelTier._(
    colors: <Color>[Color(0xFFE58743), Color(0xFFF1C853), Color(0xFF7568F0)],
    assetName: 'livekit_level_elite',
    borderWidth: 0.5,
    borderColor: Color(0xFFFFFACF),
    textColor: Color(0xFFFFF9DD),
  );
}
