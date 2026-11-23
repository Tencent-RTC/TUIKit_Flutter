import 'package:flutter/material.dart';

import '../../../../../l10n/live_kit_localizations.dart';
import '../../../../../common/style/live_kit_style.dart';
import '../../../../../common/widget/panel_dialog.dart';
import '../../../../../common/widget/form_controls.dart';

const double kSourceDialogWidth = 420;

Future<T?> showSourceConfigDialog<T>(BuildContext context, {required String barrierLabel, required Widget child}) {
  return showPanelDialog<T>(context, barrierLabel: barrierLabel, child: child);
}

class SourceDialogShell extends StatelessWidget {
  const SourceDialogShell({
    super.key,
    required this.icon,
    required this.title,
    required this.confirmLabel,
    required this.onConfirm,
    required this.children,
    this.errorText,
    this.confirmEnabled = true,
    this.width = kSourceDialogWidth,
    this.height,
  });

  final IconData icon;
  final String title;
  final String confirmLabel;
  final VoidCallback onConfirm;
  final List<Widget> children;
  final String? errorText;

  final bool confirmEnabled;
  final double width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final fixedHeight = height != null;
    final content = Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: fixedHeight ? MainAxisSize.max : MainAxisSize.min,
        children: [
          ...children,
          if (errorText != null) ...[
            const SizedBox(height: 10),
            Text(errorText!, style: const TextStyle(fontSize: 12, color: LiveKitStyle.danger)),
          ],
        ],
      ),
    );
    return PanelDialog(
      width: width,
      height: height,
      child: Column(
        mainAxisSize: fixedHeight ? MainAxisSize.max : MainAxisSize.min,
        children: [
          PanelDialogHeader(icon: icon, title: title),
          Container(height: 1, color: LiveKitStyle.white6),
          if (fixedHeight) Expanded(child: content) else content,
          Container(height: 1, color: LiveKitStyle.white6),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FormButton(
                  label: LiveKitLocalizations.of(context).commonCancel,
                  onTap: () => Navigator.pop(context),
                ),
                const SizedBox(width: 8),
                FormButton(label: confirmLabel, primary: true, enabled: confirmEnabled, onTap: onConfirm),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
