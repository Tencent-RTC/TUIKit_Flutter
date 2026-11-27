import 'package:flutter/cupertino.dart';
import '../theme/live_slider.dart';
import '../theme/live_text.dart';
import '../theme/live_theme.dart';

import '../live_kit_resources.dart';

enum BeautyKind { smooth, whiteness, ruddy }

extension _BeautyKindTitle on BeautyKind {
  String get title {
    switch (this) {
      case BeautyKind.smooth:
        return LiveKitResources.localizedString('tuilivekit.pusher.beauty.smooth');
      case BeautyKind.whiteness:
        return LiveKitResources.localizedString('tuilivekit.pusher.beauty.whiteness');
      case BeautyKind.ruddy:
        return LiveKitResources.localizedString('tuilivekit.pusher.beauty.ruddy');
    }
  }

  String get assetName {
    switch (this) {
      case BeautyKind.smooth:
        return 'livekit_beauty_smooth';
      case BeautyKind.whiteness:
        return 'livekit_beauty_whiteness';
      case BeautyKind.ruddy:
        return 'livekit_beauty_ruddy';
    }
  }
}

class BeautyViewState {
  const BeautyViewState(
      {this.isBeautyEnabled = true, this.smoothLevel = 0, this.whitenessLevel = 0, this.ruddyLevel = 0});
  final bool isBeautyEnabled;
  final double smoothLevel;
  final double whitenessLevel;
  final double ruddyLevel;
}

class BeautyView extends StatefulWidget {
  const BeautyView({
    super.key,
    required this.settings,
    this.onSetEnabled,
    this.onSetSmoothLevel,
    this.onSetWhitenessLevel,
    this.onSetRuddyLevel,
  });

  final BeautyViewState settings;
  final ValueChanged<bool>? onSetEnabled;
  final void Function(double level)? onSetSmoothLevel;
  final void Function(double level)? onSetWhitenessLevel;
  final void Function(double level)? onSetRuddyLevel;

  @override
  State<BeautyView> createState() => BeautyViewWidgetState();
}

class BeautyViewWidgetState extends State<BeautyView> {
  static const Color _activeColor = BeautyStyle.accent;

  static const Color _selectedBackgroundColor = BeautyStyle.selectedFill;

  static const Color _normalBackgroundColor = BeautyStyle.idleFill;

  static const Color _normalBorderColor = BeautyStyle.idleBorder;

  static const Color _normalTitleColor = Color(0xBFFFFFFF);

  static const Color _normalIconColor = BeautyStyle.idleForeground;

  BeautyKind _selectedKind = BeautyKind.smooth;

  double? get _currentValue {
    switch (_selectedKind) {
      case BeautyKind.smooth:
        return widget.settings.smoothLevel;
      case BeautyKind.whiteness:
        return widget.settings.whitenessLevel;
      case BeautyKind.ruddy:
        return widget.settings.ruddyLevel;
    }
  }

  void resetSelection() => _select(BeautyKind.smooth);

  void _select(BeautyKind kind) {
    setState(() {
      _selectedKind = kind;
    });
  }

  void _onSliderChanged(double next) {
    if (!widget.settings.isBeautyEnabled) return;
    final double value = next.roundToDouble();
    switch (_selectedKind) {
      case BeautyKind.smooth:
        widget.onSetSmoothLevel?.call(value);
      case BeautyKind.whiteness:
        widget.onSetWhitenessLevel?.call(value);
      case BeautyKind.ruddy:
        widget.onSetRuddyLevel?.call(value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final double? value = _currentValue;

    return Stack(
      // iOS 承载页给美颜面板的高度是 112，而选项区 top 40 + height 73 = 113，
      // UIKit 不裁剪溢出，这里同样不裁。
      clipBehavior: Clip.none,
      children: <Widget>[
        Positioned(
          left: 4,
          right: 4,
          top: 0,
          height: 32,
          child: Row(children: [
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 34),
              child: LiveText(
                LiveTextRole.caption,
                text: value == null ? '' : _selectedKind.title,
                tone: LiveTextTone.secondary,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Opacity(
                opacity: widget.settings.isBeautyEnabled ? 1 : .4,
                child: LiveSlider(
                  value: (value ?? 0).clamp(0, 9),
                  max: 9,
                  onChanged: widget.settings.isBeautyEnabled ? _onSliderChanged : null,
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 22,
              child: LiveText(
                LiveTextRole.caption,
                text: value == null ? '' : '${value.round()}',
                alignment: TextAlign.right,
                isEmphasized: true,
              ),
            ),
          ]),
        ),
        Positioned(
          left: 0,
          right: 0,
          // top 40、height 73，`fillEqually` 等分四个选项。
          top: 40,
          height: 73,
          child: Row(
            children: <Widget>[
              Expanded(
                  child: Stack(children: [
                Positioned(
                  left: 0,
                  right: 0,
                  top: 4,
                  height: 44,
                  child: Center(
                      child: Semantics(
                    label: LiveKitResources.localizedString('tuilivekit.pusher.beauty'),
                    child: Transform.scale(
                        scale: .81,
                        child: CupertinoSwitch(
                          value: widget.settings.isBeautyEnabled,
                          activeColor: const Color(0xFF2E85F2),
                          onChanged: widget.onSetEnabled,
                        )),
                  )),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  top: 56,
                  height: 14,
                  child: LiveText(LiveTextRole.control,
                      text: LiveKitResources.localizedString('tuilivekit.pusher.beauty'),
                      tone: LiveTextTone.secondary,
                      alignment: TextAlign.center),
                ),
              ])),
              for (final BeautyKind kind in BeautyKind.values)
                Expanded(
                  child: _BeautyOptionButton(
                    title: kind.title,
                    assetName: kind.assetName,
                    isSelected: kind == _selectedKind,
                    onPressed: () => _select(kind),
                    selectedBackgroundColor: _selectedBackgroundColor,
                    normalBackgroundColor: _normalBackgroundColor,
                    selectedBorderColor: _activeColor,
                    normalBorderColor: _normalBorderColor,
                    normalTitleColor: _normalTitleColor,
                    normalIconColor: _normalIconColor,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BeautyOptionButton extends StatefulWidget {
  const _BeautyOptionButton({
    required this.title,
    required this.assetName,
    required this.isSelected,
    required this.onPressed,
    required this.selectedBackgroundColor,
    required this.normalBackgroundColor,
    required this.selectedBorderColor,
    required this.normalBorderColor,
    required this.normalTitleColor,
    required this.normalIconColor,
  });

  final String title;
  final String assetName;
  final bool isSelected;
  final VoidCallback onPressed;
  final Color selectedBackgroundColor;
  final Color normalBackgroundColor;
  final Color selectedBorderColor;
  final Color normalBorderColor;
  final Color normalTitleColor;
  final Color normalIconColor;

  @override
  State<_BeautyOptionButton> createState() => _BeautyOptionButtonState();
}

class _BeautyOptionButtonState extends State<_BeautyOptionButton> {
  bool _isPressed = false;

  void _setPressed(bool isPressed) {
    if (_isPressed == isPressed) {
      return;
    }
    setState(() {
      _isPressed = isPressed;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isSelected = widget.isSelected;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onPressed,
      onTapDown: (TapDownDetails details) => _setPressed(true),
      onTapUp: (TapUpDetails details) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          Positioned(
            // top 4、centerX、44×44、cornerRadius 22。
            left: 0,
            right: 0,
            top: 4,
            height: 44,
            child: Center(
              child: AnimatedScale(
                scale: _isPressed ? 0.94 : 1,
                duration: const Duration(milliseconds: 120),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isSelected ? widget.selectedBackgroundColor : widget.normalBackgroundColor,
                    borderRadius: BorderRadius.circular(BeautyStyle.iconRadius),
                    border: Border.all(
                      color: isSelected ? widget.selectedBorderColor : widget.normalBorderColor,
                      width: 1,
                    ),
                  ),
                  child: Center(
                    //
                    // 素材为单色线稿，按 alpha 着色。
                    child: Image(
                      image: LiveKitResources.image(widget.assetName),
                      width: 24,
                      height: 24,
                      fit: BoxFit.contain,
                      color: isSelected ? const Color(0xFFFFFFFF) : widget.normalIconColor,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            // top 56、height 14、11pt 居中。
            left: 0,
            right: 0,
            top: 56,
            height: 14,
            child: Text(
              widget.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isSelected ? const Color(0xFFFFFFFF) : widget.normalTitleColor,
                fontSize: 11,
                decoration: TextDecoration.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class BeautyStyle {
  static const accent = Color(0xFF4FA3FF);
  static const selectedFill = Color(0x522E7AEB);
  static const idleFill = Color(0x14FFFFFF);
  static const idleBorder = Color(0x1FFFFFFF);
  static const idleForeground = Color(0xD1FFFFFF);
  static const iconRadius = 22.0;
}
