import 'package:flutter/material.dart' hide AlertDialog;
import 'package:flutter/material.dart' as material show AlertDialog;
import '../base_component.dart';
import '../localizations/atomic_localizations.dart';
import '../theme/theme_state.dart';

enum TextColorPreset { primary, grey, blue, red }

class ButtonConfig {
  final String text;
  final TextColorPreset type;
  final bool isBold;
  final VoidCallback? onClick;

  const ButtonConfig({
    required this.text,
    this.type = TextColorPreset.grey,
    this.isBold = false,
    this.onClick,
  });
}

class AlertDialogConfig {
  final String title;
  final String? content;
  final Widget? iconWidget;
  final bool autoDismiss;
  final int countdownDuration;
  final ButtonConfig? confirmConfig;
  final ButtonConfig? cancelConfig;
  final List<ButtonConfig> itemList;

  @Deprecated('Use cancelConfig instead')
  final String? cancelText;

  @Deprecated('Use confirmConfig instead')
  final String? defaultText;

  @Deprecated('Use confirmConfig with type = TextColorPreset.red instead')
  final bool isDestructive;

  @Deprecated('Use confirmConfig.onClick instead')
  final VoidCallback? defaultCallback;

  const AlertDialogConfig({
    this.title = '',
    this.content,
    this.iconWidget,
    this.autoDismiss = false,
    this.countdownDuration = 0,
    this.confirmConfig,
    this.cancelConfig,
    this.itemList = const [],
    @Deprecated('Use cancelConfig instead')
    this.cancelText,
    @Deprecated('Use confirmConfig instead')
    this.defaultText,
    @Deprecated('Use confirmConfig with type = TextColorPreset.red instead')
    this.isDestructive = false,
    @Deprecated('Use confirmConfig.onClick instead')
    this.defaultCallback,
  });
}

class AlertDialog extends StatelessWidget {
  final AlertDialogConfig config;

  const AlertDialog({
    super.key,
    required this.config,
  });

  static Future<bool?> show(
    BuildContext context, {
    required String title,
    required String content,
    String? cancelText,
    String? confirmText,
    bool isDestructive = false,
    VoidCallback? onConfirm,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          config: AlertDialogConfig(
            title: title,
            content: content,
            cancelConfig: cancelText != null ? ButtonConfig(text: cancelText) : null,
            confirmConfig: confirmText != null
                ? ButtonConfig(
                    text: confirmText,
                    type: isDestructive ? TextColorPreset.red : TextColorPreset.blue,
                    onClick: onConfirm,
                  )
                : null,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorsTheme = BaseThemeProvider.colorsOf(context);
    final appLocale = AtomicLocalizations.of(context);

    final effectiveCancelConfig = config.cancelConfig ??
        (config.cancelText != null ? ButtonConfig(text: config.cancelText!) : null);
    final effectiveConfirmConfig = config.confirmConfig ??
        (config.defaultText != null
            ? ButtonConfig(
                text: config.defaultText!,
                type: config.isDestructive ? TextColorPreset.red : TextColorPreset.blue,
                onClick: config.defaultCallback,
              )
            : null);

    return material.AlertDialog(
      backgroundColor: colorsTheme.bgColorDialog,
      title: config.title.isNotEmpty
          ? Text(
              config.title,
              style: TextStyle(
                color: colorsTheme.textColorPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            )
          : null,
      content: (config.content?.isNotEmpty ?? false)
          ? Text(
              config.content!,
              style: TextStyle(
                color: colorsTheme.textColorSecondary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            )
          : null,
      actions: [
        if (effectiveCancelConfig != null)
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(false);
              effectiveCancelConfig.onClick?.call();
            },
            child: Text(
              effectiveCancelConfig.text.isNotEmpty ? effectiveCancelConfig.text : appLocale.cancel,
              style: TextStyle(
                color: colorsTheme.textColorPrimary,
                fontSize: 16,
              ),
            ),
          ),
        if (effectiveConfirmConfig != null)
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(true);
              effectiveConfirmConfig.onClick?.call();
            },
            child: Text(
              effectiveConfirmConfig.text.isNotEmpty ? effectiveConfirmConfig.text : appLocale.confirm,
              style: TextStyle(
                color: _resolveButtonTextColor(effectiveConfirmConfig.type, colorsTheme),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  Color _resolveButtonTextColor(TextColorPreset type, SemanticColorScheme colorsTheme) {
    switch (type) {
      case TextColorPreset.red:
        return colorsTheme.textColorError;
      case TextColorPreset.blue:
        return colorsTheme.textColorLink;
      case TextColorPreset.primary:
        return colorsTheme.textColorPrimary;
      case TextColorPreset.grey:
        return colorsTheme.textColorSecondary;
    }
  }
}

class AtomicAlertDialog extends StatefulWidget {
  final AlertDialogConfig config;

  static const double designWidth = 375.0;

  const AtomicAlertDialog({
    super.key,
    required this.config,
  });

  @Deprecated('Use showWithConfig instead')
  static String show(
    BuildContext context, {
    String title = '',
    String content = '',
    String cancelText = '',
    String confirmText = '',
    bool isDestructive = false,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
    bool barrierDismissible = false,
    bool rootOverlay = true,
    bool enableHide = false,
  }) {
    return showWithConfig(
      context,
      config: AlertDialogConfig(
        title: title,
        content: content,
        cancelConfig: cancelText.isNotEmpty
            ? ButtonConfig(
                text: cancelText,
                onClick: onCancel,
              )
            : null,
        confirmConfig: confirmText.isNotEmpty
            ? ButtonConfig(
                text: confirmText,
                type: isDestructive ? TextColorPreset.red : TextColorPreset.blue,
                onClick: onConfirm,
              )
            : null,
      ),
      barrierDismissible: barrierDismissible,
      rootOverlay: rootOverlay,
      enableHide: enableHide,
    );
  }

  static String showWithConfig(
    BuildContext context, {
    required AlertDialogConfig config,
    bool barrierDismissible = false,
    bool rootOverlay = true,
    bool enableHide = false,
  }) {
    final dialogId = 'alert_dialog_${DateTime.now().millisecondsSinceEpoch}';

    final effectiveCancelConfig = config.cancelConfig ??
        (config.cancelText?.isNotEmpty == true ? ButtonConfig(text: config.cancelText!) : null);
    final effectiveConfirmConfig = config.confirmConfig ??
        (config.defaultText?.isNotEmpty == true
            ? ButtonConfig(
                text: config.defaultText!,
                type: config.isDestructive ? TextColorPreset.red : TextColorPreset.blue,
                isBold: true,
                onClick: config.defaultCallback,
              )
            : null);

    DialogOverlayManager.show(
      context: context,
      dialogId: dialogId,
      barrierDismissible: barrierDismissible,
      enableHide: enableHide,
      rootOverlay: rootOverlay,
      dialog: AtomicAlertDialog(
        config: AlertDialogConfig(
          title: config.title,
          content: config.content,
          iconWidget: config.iconWidget,
          autoDismiss: config.autoDismiss,
          countdownDuration: config.countdownDuration,
          itemList: config.itemList,
          confirmConfig: effectiveConfirmConfig != null
              ? ButtonConfig(
                  text: effectiveConfirmConfig.text,
                  type: effectiveConfirmConfig.type,
                  isBold: effectiveConfirmConfig.isBold,
                  onClick: () {
                    DialogOverlayManager.dismiss(dialogId);
                    effectiveConfirmConfig.onClick?.call();
                  },
                )
              : null,
          cancelConfig: effectiveCancelConfig != null
              ? ButtonConfig(
                  text: effectiveCancelConfig.text,
                  type: effectiveCancelConfig.type,
                  isBold: effectiveCancelConfig.isBold,
                  onClick: () {
                    DialogOverlayManager.dismiss(dialogId);
                    effectiveCancelConfig.onClick?.call();
                  },
                )
              : null,
        ),
      ),
    );

    return dialogId;
  }

  static void setVisable(String dialogId, bool visiable) {
    DialogOverlayManager.setVisable(dialogId, visiable);
  }

  static void dismiss(String dialogId) {
    DialogOverlayManager.dismiss(dialogId);
  }

  static void dismissAll() {
    DialogOverlayManager.dismissAll();
  }

  static bool exists(String dialogId) {
    return DialogOverlayManager.exists(dialogId);
  }

  @override
  State<AtomicAlertDialog> createState() => _AtomicAlertDialogState();
}

class _AtomicAlertDialogState extends State<AtomicAlertDialog> {
  late int _remainingSeconds;
  String _cancelDisplayText = '';

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.config.countdownDuration;
    _cancelDisplayText = widget.config.cancelConfig?.text ?? '';
    if (widget.config.countdownDuration > 0) {
      _startCountdown();
    }
  }

  void _startCountdown() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() {
        _remainingSeconds--;
        _cancelDisplayText = '${widget.config.cancelConfig?.text ?? ''} ($_remainingSeconds)';
      });
      if (_remainingSeconds <= 0) {
        widget.config.cancelConfig?.onClick?.call();
        return false;
      }
      return true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorsTheme = BaseThemeProvider.colorsOf(context);
    final widthScale = MediaQuery.sizeOf(context).width / AtomicAlertDialog.designWidth;

    return Container(
      width: 259 * widthScale,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: colorsTheme.bgColorDialog,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 24),
          _buildTitle(colorsTheme),
          _buildContent(colorsTheme),
          const SizedBox(height: 20),
          Divider(height: 0.0, color: colorsTheme.strokeColorSecondary),
          _buildActionButtons(colorsTheme),
        ],
      ),
    );
  }

  Widget _buildTitle(SemanticColorScheme colorsTheme) {
    return Visibility(
      visible: widget.config.title.isNotEmpty,
      child: Padding(
        padding: const EdgeInsets.only(left: 16.0, right: 16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.config.iconWidget != null) ...[
              widget.config.iconWidget!,
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Text(
                widget.config.title,
                style: TextStyle(
                  fontSize: 18,
                  color: colorsTheme.textColorPrimary,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(SemanticColorScheme colorsTheme) {
    final content = widget.config.content;
    return Visibility(
      visible: content != null && content.isNotEmpty,
      child: Column(
        children: [
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.only(left: 16.0, right: 16.0),
            child: Text(
              content ?? '',
              style: TextStyle(
                fontSize: 16,
                color: colorsTheme.textColorPrimary,
                fontWeight: FontWeight.normal,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(SemanticColorScheme colorsTheme) {
    if (widget.config.itemList.isNotEmpty) {
      return _buildItemListButtons(colorsTheme);
    }
    return IntrinsicHeight(
      child: Row(
        children: [
          _buildCancelButton(colorsTheme),
          _buildButtonDivider(colorsTheme),
          _buildConfirmButton(colorsTheme),
        ],
      ),
    );
  }

  Widget _buildItemListButtons(SemanticColorScheme colorsTheme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: widget.config.itemList.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (index > 0) Divider(height: 0.0, color: colorsTheme.strokeColorSecondary),
            SizedBox(
              height: 56,
              width: double.infinity,
              child: TextButton(
                style: ButtonStyle(
                  overlayColor: WidgetStateProperty.all<Color>(Colors.transparent),
                ),
                onPressed: item.onClick,
                child: Text(
                  item.text,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: item.isBold ? FontWeight.bold : FontWeight.normal,
                    color: _resolveButtonTextColor(item.type, colorsTheme),
                  ),
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildCancelButton(SemanticColorScheme colorsTheme) {
    final cancelConfig = widget.config.cancelConfig;
    return Visibility(
      visible: cancelConfig != null,
      child: Expanded(
        child: TextButton(
          style: ButtonStyle(
            overlayColor: WidgetStateProperty.all<Color>(Colors.transparent),
          ),
          onPressed: cancelConfig?.onClick,
          child: Text(
            widget.config.countdownDuration > 0 ? _cancelDisplayText : (cancelConfig?.text ?? ''),
            style: TextStyle(
              fontSize: 16,
              fontWeight: (cancelConfig?.isBold ?? false) ? FontWeight.bold : FontWeight.normal,
              color: _resolveButtonTextColor(cancelConfig?.type ?? TextColorPreset.grey, colorsTheme),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildButtonDivider(SemanticColorScheme colorsTheme) {
    return Visibility(
      visible: widget.config.confirmConfig != null && widget.config.cancelConfig != null,
      child: VerticalDivider(width: 1, color: colorsTheme.strokeColorSecondary),
    );
  }

  Widget _buildConfirmButton(SemanticColorScheme colorsTheme) {
    final confirmConfig = widget.config.confirmConfig;
    return Visibility(
      visible: confirmConfig != null,
      child: Expanded(
        child: TextButton(
          style: ButtonStyle(
            overlayColor: WidgetStateProperty.all<Color>(Colors.transparent),
          ),
          onPressed: confirmConfig?.onClick,
          child: Text(
            confirmConfig?.text ?? '',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: (confirmConfig?.isBold ?? false) ? FontWeight.bold : FontWeight.normal,
              color: _resolveButtonTextColor(confirmConfig?.type ?? TextColorPreset.blue, colorsTheme),
            ),
          ),
        ),
      ),
    );
  }

  Color _resolveButtonTextColor(TextColorPreset type, SemanticColorScheme colorsTheme) {
    switch (type) {
      case TextColorPreset.red:
        return colorsTheme.textColorError;
      case TextColorPreset.blue:
        return colorsTheme.textColorLink;
      case TextColorPreset.primary:
        return colorsTheme.textColorPrimary;
      case TextColorPreset.grey:
        return colorsTheme.textColorSecondary;
    }
  }
}

class OverlayEntryWrapper {
  final OverlayEntry overlayEntry;
  final ValueNotifier<bool> isVisable;

  OverlayEntryWrapper({required this.overlayEntry, required this.isVisable});
}

class DialogOverlayManager {
  static final Map<String, OverlayEntryWrapper> _overlays = {};

  static void show({
    required BuildContext context,
    required String dialogId,
    required Widget dialog,
    bool barrierDismissible = true,
    Color barrierColor = Colors.black54,
    bool rootOverlay = true,
    bool enableHide = false,
  }) {
    dismiss(dialogId);

    final overlay = Overlay.of(context, rootOverlay: rootOverlay);
    late OverlayEntry overlayEntry;
    final WidgetBuilder widgetBuilder = (builderContext) {
      return Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: barrierDismissible ? () => dismiss(dialogId) : null,
              child: Container(
                color: barrierColor,
              ),
            ),
          ),
          Center(
            child: Material(
              color: Colors.transparent,
              child: dialog,
            ),
          ),
        ],
      );
    };
    ValueNotifier<bool> isVisable = ValueNotifier(true);
    if (enableHide) {
      overlayEntry = OverlayEntry(
        builder: (context) {
          return ValueListenableBuilder<bool>(
            valueListenable: isVisable,
            builder: (_, visible, __) {
              return Offstage(
                offstage: !visible,
                child: widgetBuilder.call(context),
              );
            },
          );
        },
      );
    } else {
      overlayEntry = OverlayEntry(
        builder: (context) => widgetBuilder.call(context),
      );
    }

    overlay.insert(overlayEntry);
    _overlays[dialogId] = OverlayEntryWrapper(overlayEntry: overlayEntry, isVisable: isVisable);
  }

  static void setVisable(String dialogId, bool visiable) {
    final entryWrapper = _overlays[dialogId];
    entryWrapper?.isVisable.value = visiable;
  }

  static void dismiss(String dialogId) {
    final OverlayEntryWrapper? entryWrapper = _overlays[dialogId];
    if (entryWrapper != null) {
      entryWrapper.overlayEntry.remove();
      entryWrapper.isVisable.dispose();
      _overlays.remove(dialogId);
    }
  }

  static void dismissAll() {
    for (var entryWrapper in _overlays.values) {
      entryWrapper.overlayEntry.remove();
      entryWrapper.isVisable.dispose();
    }
    _overlays.clear();
  }

  static bool exists(String dialogId) {
    return _overlays.containsKey(dialogId);
  }
}
