import 'package:flutter/material.dart' hide AlertDialog;
import 'package:flutter/material.dart' as material show AlertDialog;
import '../base_component.dart';
import '../localizations/atomic_localizations.dart';
import '../theme/theme_state.dart';

class AlertDialogConfig {
  final String title;
  final String content;
  final String? cancelText;
  final String? confirmText;
  final bool isDestructive;
  final VoidCallback? onConfirm;

  const AlertDialogConfig({
    required this.title,
    required this.content,
    this.cancelText,
    this.confirmText,
    this.isDestructive = false,
    this.onConfirm,
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
            cancelText: cancelText,
            confirmText: confirmText,
            isDestructive: isDestructive,
            onConfirm: onConfirm,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorsTheme = BaseThemeProvider.colorsOf(context);
    final appLocale = AtomicLocalizations.of(context);

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
      content: config.content.isNotEmpty
          ? Text(
              config.content,
              style: TextStyle(
                color: colorsTheme.textColorPrimary,
                fontSize: 16,
              ),
            )
          : null,
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            config.cancelText ?? appLocale.cancel,
            style: TextStyle(
              color: colorsTheme.textColorPrimary,
              fontSize: 16,
            ),
          ),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(true);
            config.onConfirm?.call();
          },
          child: Text(
            config.confirmText ?? appLocale.confirm,
            style: TextStyle(
              color: config.isDestructive ? colorsTheme.textColorError : colorsTheme.buttonColorPrimaryDefault,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class AtomicAlertDialog extends StatelessWidget {
  final String title;
  final String content;
  final String cancelText;
  final String confirmText;
  final bool isDestructive;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;

  static const double designWidth = 375.0;

  const AtomicAlertDialog({
    super.key,
    this.title = '',
    this.content = '',
    this.cancelText = '',
    this.confirmText = '',
    this.isDestructive = false,
    this.onConfirm,
    this.onCancel,
  });

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
  }) {
    final dialogId = 'alert_dialog_${DateTime.now().millisecondsSinceEpoch}';

    DialogOverlayManager.show(
      context: context,
      dialogId: dialogId,
      barrierDismissible: barrierDismissible,
      dialog: AtomicAlertDialog(
        title: title,
        content: content,
        cancelText: cancelText,
        confirmText: confirmText,
        isDestructive: isDestructive,
        onConfirm: () {
          DialogOverlayManager.dismiss(dialogId);
          onConfirm?.call();
        },
        onCancel: () {
          DialogOverlayManager.dismiss(dialogId);
          onCancel?.call();
        },
      ),
    );

    return dialogId;
  }

  static void dismiss(String dialogId) {
    DialogOverlayManager.dismiss(dialogId);
  }

  static void dismissAll() {
    DialogOverlayManager.dismissAll();
  }

  @override
  Widget build(BuildContext context) {
    final colorsTheme = BaseThemeProvider.colorsOf(context);
    final widthScale = MediaQuery.sizeOf(context).width / designWidth;

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
      visible: title.isNotEmpty,
      child: Padding(
        padding: const EdgeInsets.only(left: 16.0, right: 16.0),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 18,
            color: colorsTheme.textColorPrimary,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildContent(SemanticColorScheme colorsTheme) {
    return Visibility(
      visible: content.isNotEmpty,
      child: Column(
        children: [
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.only(left: 16.0, right: 16.0),
            child: Text(
              content,
              style: TextStyle(
                fontSize: 14,
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

  Widget _buildCancelButton(SemanticColorScheme colorsTheme) {
    return Visibility(
      visible: cancelText.isNotEmpty,
      child: Expanded(
        child: TextButton(
          style: ButtonStyle(
            overlayColor: WidgetStateProperty.all<Color>(Colors.transparent),
          ),
          onPressed: onCancel,
          child: Text(
            cancelText,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: colorsTheme.textColorPrimary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildButtonDivider(SemanticColorScheme colorsTheme) {
    return Visibility(
      visible: confirmText.isNotEmpty && cancelText.isNotEmpty,
      child: VerticalDivider(width: 1, color: colorsTheme.strokeColorSecondary),
    );
  }

  Widget _buildConfirmButton(SemanticColorScheme colorsTheme) {
    return Visibility(
      visible: confirmText.isNotEmpty,
      child: Expanded(
        child: TextButton(
          style: ButtonStyle(
            overlayColor: WidgetStateProperty.all<Color>(Colors.transparent),
          ),
          onPressed: onConfirm,
          child: Text(
            confirmText,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDestructive ? colorsTheme.textColorError : colorsTheme.buttonColorPrimaryDefault,
            ),
          ),
        ),
      ),
    );
  }
}

class DialogOverlayManager {
  static final Map<String, OverlayEntry> _overlays = {};

  static void show({
    required BuildContext context,
    required String dialogId,
    required Widget dialog,
    bool barrierDismissible = true,
    Color barrierColor = Colors.black54,
  }) {
    dismiss(dialogId);

    final overlay = Overlay.of(context, rootOverlay: true);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Stack(
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
      ),
    );

    overlay.insert(overlayEntry);
    _overlays[dialogId] = overlayEntry;
  }

  static void dismiss(String dialogId) {
    final entry = _overlays[dialogId];
    if (entry != null) {
      entry.remove();
      _overlays.remove(dialogId);
    }
  }

  static void dismissAll() {
    for (var entry in _overlays.values) {
      entry.remove();
    }
    _overlays.clear();
  }

  static bool exists(String dialogId) {
    return _overlays.containsKey(dialogId);
  }
}
