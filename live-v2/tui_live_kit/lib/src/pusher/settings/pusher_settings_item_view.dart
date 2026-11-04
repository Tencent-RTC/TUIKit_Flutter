import 'package:flutter/widgets.dart';

import '../../common/live_kit_resources.dart';
import '../../common/theme/live_text.dart';
import '../../common/theme/live_theme.dart';

enum PusherSettingsItemStyle { prepare, panel, soundOption }

class PusherSettingsItemView extends StatelessWidget {
  const PusherSettingsItemView({
    super.key,
    required this.title,
    required this.assetName,
    this.iconSize = const Size(22, 22),
    this.showsIconBackground = true,
    this.style = PusherSettingsItemStyle.panel,
    this.isSelected = false,
    this.onPressed,
  });

  final String title;
  final String assetName;
  final Size iconSize;
  final bool showsIconBackground;
  final PusherSettingsItemStyle style;
  final bool isSelected;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final bool prepare = style == PusherSettingsItemStyle.prepare;
    final bool sound = style == PusherSettingsItemStyle.soundOption;
    final bool selected = sound && isSelected;
    final double side = prepare || sound ? 48 : 44;
    final double top = prepare || sound ? 0 : 4;
    final Size imageSize = prepare
        ? const Size.square(24)
        : sound
            ? const Size.square(25)
            : iconSize;
    return Semantics(
      button: true,
      selected: sound ? isSelected : null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        child: SizedBox(
          width: prepare ? 68 : null,
          height: prepare
              ? 71
              : sound
                  ? 64
                  : null,
          child: Stack(
            children: <Widget>[
              Positioned(
                left: 0,
                right: 0,
                top: top,
                height: side,
                child: Center(
                  child: Container(
                    width: side,
                    height: side,
                    decoration: BoxDecoration(
                      color: prepare
                          ? const Color(0x80141417)
                          // A transparent color also zeros the gradient
                          // paint's alpha in Flutter's BoxDecoration.
                          : selected || !showsIconBackground
                              ? null
                              : sound
                                  ? PusherSettingsSelectionStyle.idleBackground
                                  : const Color(0x14FFFFFF),
                      borderRadius: BorderRadius.circular(sound ? 14 : side / 2),
                      border: prepare || sound
                          ? Border.all(
                              color: selected
                                  ? PusherSettingsSelectionStyle.border
                                  : sound
                                      ? PusherSettingsSelectionStyle.idleBorder
                                      : const Color(0x1AFFFFFF),
                            )
                          : null,
                      gradient: selected
                          ? const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: <Color>[
                                PusherSettingsSelectionStyle.gradientTop,
                                PusherSettingsSelectionStyle.gradientBottom
                              ],
                            )
                          : null,
                    ),
                    child: Center(
                        child: Image(
                      image: LiveKitResources.image(assetName),
                      width: imageSize.width,
                      height: imageSize.height,
                      fit: BoxFit.contain,
                    )),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                top: top +
                    side +
                    (sound
                        ? 2
                        : prepare
                            ? 7
                            : 8),
                height: prepare
                    ? 16
                    : sound
                        ? 14
                        : 28,
                child: LayoutBuilder(builder: (context, constraints) {
                  final TextScaler scaler = MediaQuery.textScalerOf(context);
                  final int lines = style == PusherSettingsItemStyle.panel ? 2 : 1;
                  // UILabel fits within one/two lines down to 75%; Flutter
                  // needs an explicit measured scale to preserve the same slot.
                  double factor = 1;
                  final painter = TextPainter(
                    text: TextSpan(
                      text: title,
                      style: LiveTheme.textStyle(
                        LiveTextRole.control,
                        isEmphasized: prepare || selected,
                        lineHeight: prepare ? 16 : 14,
                      ),
                    ),
                    textDirection: Directionality.of(context),
                    maxLines: lines,
                  );
                  while (true) {
                    painter.textScaler = TextScaler.linear(scaler.scale(11) / 11 * factor);
                    painter.layout(maxWidth: constraints.maxWidth);
                    if ((!painter.didExceedMaxLines && painter.height <= constraints.maxHeight) || factor <= .75) break;
                    factor = (factor - .05).clamp(.75, 1);
                  }
                  painter.dispose();
                  return Center(
                    child: MediaQuery(
                      data: MediaQuery.of(context).copyWith(
                        textScaler: TextScaler.linear(scaler.scale(11) / 11 * factor),
                      ),
                      child: LiveText(
                        LiveTextRole.control,
                        text: title,
                        tone: prepare || selected ? LiveTextTone.primary : LiveTextTone.secondary,
                        isEmphasized: prepare || selected,
                        alignment: TextAlign.center,
                        maxLines: lines,
                        lineHeight: prepare ? 16 : 14,
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

abstract final class PusherSettingsSelectionStyle {
  static const gradientTop = Color(0x6B4A9EFF);
  static const gradientBottom = Color(0x420052D9);
  static const border = LiveTheme.brandBlue;
  static const idleBackground = Color(0x0BFFFFFF);
  static const idleBorder = Color(0x24FFFFFF);
}
