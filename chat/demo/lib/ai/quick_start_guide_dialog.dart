import 'package:flutter/material.dart' hide AlertDialog;
import 'package:tencent_chat_uikit/tencent_chat_uikit.dart';

import '../common/language/gen/demo_localizations.dart';
import 'ai_agent_picker.dart';
import 'custom_bot_dialog.dart';
import 'support_agent_catalog.dart';

/// Customers who download the source from GitHub and fill in their own
/// SDKAppID have no assistant to talk to yet. Tapping the AI home's buttons
/// first shows this card: a short intro of the AI assistant and the steps of
/// "Quick start with UIKit (no server required)" on the official site.
class QuickStartGuideDialog extends StatelessWidget {
  const QuickStartGuideDialog({super.key});

  static const Color _purpleSoft = Color(0x267B5CFF);

  /// Shows the guide when needed and returns true, so the caller stops the
  /// original action.
  static bool showIfNeeded(BuildContext context) {
    if (!SupportAgentCatalog.needsOwnAssistant) return false;
    showDialog<void>(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => const QuickStartGuideDialog(),
    );
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = DemoLocalizations.of(context);
    final colors = BaseThemeProvider.colorsOf(context);
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
          decoration: BoxDecoration(
            color: colors.bgColorDialog,
            borderRadius: BorderRadius.circular(24),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const GradientBadge(text: '✦'),
                const SizedBox(height: 14),
                Text(
                  l10n.aiQuickStartTitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                      color: colors.textColorPrimary),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.aiQuickStartIntro,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color: colors.textColorSecondary),
                ),
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: colors.bgColorDefault,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: colors.strokeColorSecondary),
                  ),
                  child: Column(
                    children: [
                      for (final (index, text) in [
                        l10n.aiQuickStartStep1,
                        l10n.aiQuickStartStep2,
                        l10n.aiQuickStartStep3,
                      ].indexed) ...[
                        if (index > 0) const SizedBox(height: 12),
                        _StepRow(number: index + 1, text: text),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.aiQuickStartDocHint,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 12,
                      height: 1.35,
                      color: colors.textColorSecondary),
                ),
                const SizedBox(height: 18),
                GradientButton(
                  label: l10n.aiQuickStartDoc,
                  onTap: () {
                    Navigator.of(context).pop();
                    CustomBotDialog.openDoc();
                  },
                ),
                const SizedBox(height: 4),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => Navigator.of(context).pop(),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
                    child: Text(l10n.aiQuickStartCancel,
                        style: TextStyle(
                            fontSize: 14, color: colors.textColorSecondary)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Number dot + step text.
class _StepRow extends StatelessWidget {
  const _StepRow({required this.number, required this.text});

  final int number;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = BaseThemeProvider.colorsOf(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
              shape: BoxShape.circle, color: QuickStartGuideDialog._purpleSoft),
          child: Text('$number',
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AIAgentPicker.brandPurple)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Text(text,
                style: TextStyle(
                    fontSize: 14,
                    height: 1.35,
                    color: colors.textColorPrimary)),
          ),
        ),
      ],
    );
  }
}

/// Purple-to-blue circle with a white glyph, shared by the AI dialogs.
class GradientBadge extends StatelessWidget {
  const GradientBadge({super.key, required this.text, this.fontSize = 24});

  final String text;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AIAgentPicker.brandPurple, AIAgentPicker.brandBlue],
        ),
      ),
      child: Text(text,
          style: TextStyle(fontSize: fontSize, height: 1, color: Colors.white)),
    );
  }
}

/// Full-width purple-to-blue primary button, shared by the AI dialogs.
class GradientButton extends StatelessWidget {
  const GradientButton(
      {super.key, required this.label, required this.onTap, this.child});

  final String label;
  final VoidCallback? onTap;

  /// Replaces [label], e.g. with a progress indicator.
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onTap == null && child == null ? 0.4 : 1,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          height: 48,
          width: double.infinity,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: const LinearGradient(
                colors: [AIAgentPicker.brandPurple, AIAgentPicker.brandBlue]),
          ),
          child: child ??
              Text(label,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
        ),
      ),
    );
  }
}
