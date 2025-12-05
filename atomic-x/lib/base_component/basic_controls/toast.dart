import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/font.dart';
import '../theme/theme_state.dart';

enum ToastType {
  loading,
  info,
  success,
  warning,
  error,
  help,
}

class ToastTypeHelper {
  static String getIconName(ToastType type) {
    switch (type) {
      case ToastType.loading:
        return 'chat_assets/icon/loading-blue.png';
      case ToastType.info:
        return 'chat_assets/icon/info-circle-filled.svg';
      case ToastType.success:
        return 'chat_assets/icon/check-circle-filled.svg';
      case ToastType.warning:
        return 'chat_assets/icon/error-circle-filled.svg';
      case ToastType.error:
        return 'chat_assets/icon/error-circle-filled.svg';
      case ToastType.help:
        return 'chat_assets/icon/help-circle-filled.svg';
      default:
        return 'chat_assets/icon/info-circle-filled.svg';
    }
  }

  static Color getIconColor(ToastType type, colors) {
    switch (type) {
      case ToastType.loading:
        return colors.textColorLink;
      case ToastType.info:
        return colors.textColorLink;
      case ToastType.success:
        return colors.textColorSuccess;
      case ToastType.warning:
        return colors.textColorWarning;
      case ToastType.error:
        return colors.textColorError;
      case ToastType.help:
        return colors.textColorLink;
    }
  }
}

class IconToast extends StatefulWidget {
  final ToastType type;
  final String message;
  final String? customIcon;
  final bool isVisible;
  final VoidCallback onDismiss;

  const IconToast({
    super.key,
    this.type = ToastType.info,
    required this.message,
    this.customIcon,
    required this.isVisible,
    required this.onDismiss,
  });

  @override
  State<IconToast> createState() => _IconToastState();
}

class _IconToastState extends State<IconToast> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );

    if (widget.type == ToastType.loading) {
      _animationController.repeat();
    }
  }

  @override
  void didUpdateWidget(IconToast oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.type == ToastType.loading && oldWidget.type != ToastType.loading) {
      _animationController.repeat();
    } else if (widget.type != ToastType.loading && oldWidget.type == ToastType.loading) {
      _animationController.stop();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible) {
      return const SizedBox.shrink();
    }

    final colorsTheme = BaseThemeProvider.colorsOf(context);

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      bottom: 0,
      child: IgnorePointer(
        ignoring: true,
        child: Container(
          color: Colors.transparent,
          child: Center(
            child: IgnorePointer(
              ignoring: false,
              child: GestureDetector(
                onTap: widget.onDismiss,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: colorsTheme.floatingColorDefault,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: colorsTheme.strokeColorSecondary,
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: colorsTheme.shadowColor,
                        blurRadius: 8,
                        offset: const Offset(0, 6),
                      ),
                      BoxShadow(
                        color: colorsTheme.shadowColor,
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.type == ToastType.loading)
                        RotationTransition(
                          turns: _animationController,
                          child: Image.asset(
                            ToastTypeHelper.getIconName(widget.type),
                            width: 16,
                            height: 16,
                            package: 'tuikit_atomic_x',
                          ),
                        )
                      else
                        SvgPicture.asset(
                          ToastTypeHelper.getIconName(widget.type),
                          width: 16,
                          height: 16,
                          package: 'tuikit_atomic_x',
                          colorFilter: ColorFilter.mode(
                            ToastTypeHelper.getIconColor(widget.type, colorsTheme),
                            BlendMode.srcIn,
                          ),
                        ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          widget.message,
                          style: FontScheme.caption2Medium.copyWith(
                            color: colorsTheme.textColorPrimary,
                          ),
                          textAlign: TextAlign.left,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SimpleToast extends StatelessWidget {
  final String message;
  final bool isVisible;
  final VoidCallback onDismiss;

  const SimpleToast({
    super.key,
    required this.message,
    required this.isVisible,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    if (!isVisible) {
      return const SizedBox.shrink();
    }

    final colorsTheme = BaseThemeProvider.colorsOf(context);

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      bottom: 0,
      child: IgnorePointer(
        ignoring: true,
        child: Container(
          color: Colors.transparent,
          child: Center(
            child: IgnorePointer(
              ignoring: false,
              child: GestureDetector(
                onTap: onDismiss,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: colorsTheme.floatingColorDefault,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: colorsTheme.strokeColorSecondary,
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: colorsTheme.shadowColor,
                        blurRadius: 8,
                        offset: const Offset(0, 6),
                      ),
                      BoxShadow(
                        color: colorsTheme.shadowColor,
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Text(
                    message,
                    style: FontScheme.caption2Medium.copyWith(
                      color: colorsTheme.textColorPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class Toast {
  static Toast? _instance;
  static Toast get instance => _instance ??= Toast._();
  
  Toast._();

  OverlayEntry? _overlayEntry;
  Timer? _hideTimer;

  static void success(BuildContext context, String message, {Duration duration = const Duration(seconds: 2)}) {
    instance._showToast(context, message, ToastType.success, duration);
  }

  static void info(BuildContext context, String message, {Duration duration = const Duration(seconds: 2)}) {
    instance._showToast(context, message, ToastType.info, duration);
  }

  static void warning(BuildContext context, String message, {Duration duration = const Duration(seconds: 2)}) {
    instance._showToast(context, message, ToastType.warning, duration);
  }

  static void error(BuildContext context, String message, {Duration duration = const Duration(seconds: 2)}) {
    instance._showToast(context, message, ToastType.error, duration);
  }

  static void loading(BuildContext context, String message, {Duration duration = const Duration(seconds: 3)}) {
    instance._showToast(context, message, ToastType.loading, duration);
  }

  static void simple(BuildContext context, String message, {Duration duration = const Duration(seconds: 2)}) {
    instance._showSimpleToast(context, message, duration);
  }

  static void show(
    BuildContext context,
    String message, {
    ToastType type = ToastType.info,
    Duration duration = const Duration(seconds: 2),
  }) {
    instance._showToast(context, message, type, duration);
  }

  static void hide() {
    instance._hide();
  }

  void _showToast(BuildContext context, String message, ToastType type, Duration duration) {
    _hide();

    _overlayEntry = OverlayEntry(
      builder: (context) => IconToast(
        type: type,
        message: message,
        isVisible: true,
        onDismiss: _hide,
      ),
    );

    try {
      final overlay = Overlay.of(context);
      overlay.insert(_overlayEntry!);
      
      _hideTimer?.cancel();
      _hideTimer = Timer(duration, _hide);
    } catch (e) {
      print('Toast: Failed to show toast - $e');
      _overlayEntry = null;
    }
  }

  void _showSimpleToast(BuildContext context, String message, Duration duration) {
    _hide();

    _overlayEntry = OverlayEntry(
      builder: (context) => SimpleToast(
        message: message,
        isVisible: true,
        onDismiss: _hide,
      ),
    );

    try {
      final overlay = Overlay.of(context);
      overlay.insert(_overlayEntry!);
      
      _hideTimer?.cancel();
      _hideTimer = Timer(duration, _hide);
    } catch (e) {
      print('Toast: Failed to show toast - $e');
      _overlayEntry = null;
      
      _showToastFallback(context, message, duration);
    }
  }

  void _showToastFallback(BuildContext context, String message, Duration duration) {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: duration,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      );
    } catch (e) {
      print('Toast: Failed to show SnackBar - $e');
    }
  }

  void _hide() {
    _hideTimer?.cancel();
    _hideTimer = null;
    
    if (_overlayEntry != null) {
      try {
        _overlayEntry!.remove();
      } catch (e) {
        print('Toast remove overlay entry failed: $e');
      }
      _overlayEntry = null;
    }
  }
}
