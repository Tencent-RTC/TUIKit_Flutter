import 'package:flutter/material.dart';
import 'package:tuikit_atomic_x/base_component/base_component.dart';

enum SwitchSize {
  s(26, 16, 12, 2, 10),
  m(32, 20, 15, 2.5, 12),
  l(40, 24, 18, 3, 14);

  const SwitchSize(this.width, this.height, this.thumbSize, this.padding, this.textSize);

  final double width;
  final double height;
  final double thumbSize;
  final double padding;
  final double textSize;
}

enum SwitchType {
  basic,
  withText,
  withIcon,
}

class BasicSwitch extends StatelessWidget {
  final bool checked;
  final ValueChanged<bool>? onCheckedChange;
  final bool enabled;
  final bool loading;

  const BasicSwitch({
    super.key,
    required this.checked,
    this.onCheckedChange,
    this.enabled = true,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return CustomSwitch(
      checked: checked,
      onCheckedChange: onCheckedChange,
      enabled: enabled,
      loading: loading,
      size: SwitchSize.m,
      type: SwitchType.basic,
    );
  }
}

class CustomSwitch extends StatefulWidget {
  final bool checked;
  final ValueChanged<bool>? onCheckedChange;
  final bool enabled;
  final bool loading;
  final SwitchSize size;
  final SwitchType type;

  const CustomSwitch({
    super.key,
    required this.checked,
    this.onCheckedChange,
    this.enabled = true,
    this.loading = false,
    this.size = SwitchSize.l,
    this.type = SwitchType.basic,
  });

  @override
  State<CustomSwitch> createState() => _CustomSwitchState();
}

class _CustomSwitchState extends State<CustomSwitch> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    if (widget.checked) {
      _animationController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(CustomSwitch oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.checked != oldWidget.checked) {
      if (widget.checked) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = BaseThemeProvider.colorsOf(context);
    final localizations = AtomicLocalizations.of(context);

    final width = widget.type == SwitchType.basic ? widget.size.width : widget.size.height * 2;
    final maxOffset = width - widget.size.thumbSize - widget.size.padding * 2;

    final trackColor = widget.checked ? colors.switchColorOn : colors.switchColorOff;
    final thumbColor = colors.switchColorButton;

    final effectiveTrackColor = widget.enabled ? trackColor : trackColor.withOpacity(0.6);
    final effectiveThumbColor = widget.enabled ? thumbColor : thumbColor.withOpacity(0.6);

    return GestureDetector(
      onTap: () {
        if (widget.enabled && !widget.loading) {
          widget.onCheckedChange?.call(!widget.checked);
        }
      },
      child: SizedBox(
        width: width,
        height: widget.size.height,
        child: Stack(
          children: [
            // Track背景
            Container(
              width: width,
              height: widget.size.height,
              decoration: BoxDecoration(
                color: effectiveTrackColor,
                borderRadius: BorderRadius.circular(widget.size.height / 2),
              ),
            ),
            if (widget.type == SwitchType.withText || widget.type == SwitchType.withIcon)
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _animation,
                  builder: (context, child) {
                    return Row(
                      children: [
                        if (widget.checked)
                          Expanded(
                            child: Container(
                              margin: EdgeInsets.only(left: 8, right: widget.size.thumbSize + 8),
                              alignment: Alignment.center,
                              child: widget.type == SwitchType.withIcon
                                  ? Icon(
                                      Icons.check,
                                      size: widget.size.thumbSize * 0.6,
                                      color: colors.textColorButton,
                                    )
                                  : Text(
                                      localizations.on,
                                      style: TextStyle(
                                        fontSize: widget.size.textSize,
                                        fontWeight: FontWeight.w500,
                                        color: colors.textColorButton,
                                      ),
                                      maxLines: 1,
                                    ),
                            ),
                          ),
                        if (!widget.checked)
                          Expanded(
                            child: Container(
                              margin: EdgeInsets.only(left: widget.size.thumbSize + 8, right: 8),
                              alignment: Alignment.center,
                              child: widget.type == SwitchType.withIcon
                                  ? Icon(
                                      Icons.close,
                                      size: widget.size.thumbSize * 0.6,
                                      color: colors.textColorButton,
                                    )
                                  : Text(
                                      localizations.off,
                                      style: TextStyle(
                                        fontSize: widget.size.textSize,
                                        fontWeight: FontWeight.w500,
                                        color: colors.textColorButton,
                                      ),
                                      maxLines: 1,
                                    ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            // Thumb
            AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return Positioned(
                  left: widget.size.padding + (_animation.value * maxOffset),
                  top: widget.size.padding,
                  child: Container(
                    width: widget.size.thumbSize,
                    height: widget.size.thumbSize,
                    decoration: BoxDecoration(
                      color: effectiveThumbColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.12),
                          blurRadius: widget.size == SwitchSize.s
                              ? 1.6
                              : widget.size == SwitchSize.m
                                  ? 2.0
                                  : 2.4,
                          offset: Offset.zero,
                        ),
                      ],
                    ),
                    child: widget.loading
                        ? Center(
                            child: SizedBox(
                              width: widget.size.thumbSize * 0.6,
                              height: widget.size.thumbSize * 0.6,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.5,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  colors.switchColorOn,
                                ),
                              ),
                            ),
                          )
                        : null,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
