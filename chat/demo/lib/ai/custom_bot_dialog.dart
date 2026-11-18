import 'package:flutter/material.dart' hide AlertDialog;
import 'package:tencent_chat_uikit/tencent_chat_uikit.dart';
import 'package:url_launcher/url_launcher.dart';

import '../common/language/gen/demo_localizations.dart';
import 'ai_agent_picker.dart';
import 'quick_start_guide_dialog.dart';
import 'support_agent_catalog.dart';

/// Takes the ID of the assistant the user created in the experience workbench.
///
/// The bot is checked on the server before saving; only then is it stored and
/// selected. Resolves true when the custom assistant was saved and selected.
class CustomBotDialog extends StatefulWidget {
  const CustomBotDialog({super.key});

  /// Official "Knowledge Base AI Assistant" document; the AI page banner opens
  /// it too.
  static const String docUrl =
      'https://cloud.tencent.com/document/product/269/139511';

  static Future<bool> show(BuildContext context) async {
    await SupportAgentCatalog.load();
    if (!context.mounted) return false;
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => const CustomBotDialog(),
    );
    return saved ?? false;
  }

  /// Opens [docUrl] in an in-app browser, so the user does not leave the app.
  static Future<void> openDoc() async {
    final uri = Uri.parse(docUrl);
    if (!await launchUrl(uri, mode: LaunchMode.inAppBrowserView)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  State<CustomBotDialog> createState() => _CustomBotDialogState();
}

class _CustomBotDialogState extends State<CustomBotDialog> {
  late final TextEditingController _controller;
  String? _error;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
        text: _stripPrefix(SupportAgentCatalog.customBotUserID));
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // The prefix is shown in front of the field, so only the part after it is
  // edited. A pasted full ID is accepted too.
  static String _stripPrefix(String value) {
    final text = value.trim();
    const prefix = SupportAgentCatalog.botUserIDPrefix;
    return text.startsWith(prefix)
        ? text.substring(prefix.length).trim()
        : text;
  }

  Future<void> _submit() async {
    final l10n = DemoLocalizations.of(context);
    final suffix = _stripPrefix(_controller.text);
    if (suffix.isEmpty) return;
    final userID = '${SupportAgentCatalog.botUserIDPrefix}$suffix';
    setState(() {
      _submitting = true;
      _error = null;
    });
    final result = await SupportAgentCatalog.checkBot(userID);
    if (!mounted) return;
    switch (result) {
      case CustomBotCheckResult.found:
        await SupportAgentCatalog.setCustomBotUserID(userID);
        await SupportAgentCatalog.setSelectedBotUserID(userID);
        if (!mounted) return;
        Navigator.of(context).pop(true);
        return;
      case CustomBotCheckResult.notFound:
        setState(() {
          _submitting = false;
          _error = l10n.customBotNotFound;
        });
        return;
      case CustomBotCheckResult.networkError:
        setState(() {
          _submitting = false;
          _error = l10n.customBotNetworkError;
        });
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = DemoLocalizations.of(context);
    final colors = BaseThemeProvider.colorsOf(context);
    final canSubmit = !_submitting && _stripPrefix(_controller.text).isNotEmpty;
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
                const GradientBadge(text: '+', fontSize: 28),
                const SizedBox(height: 14),
                Text(
                  l10n.customBotDialogTitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                      color: colors.textColorPrimary),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.customBotDialogDesc,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color: colors.textColorSecondary),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _controller,
                  enabled: !_submitting,
                  autofocus: true,
                  autocorrect: false,
                  enableSuggestions: false,
                  style:
                      TextStyle(fontSize: 16, color: colors.textColorPrimary),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: colors.bgColorDefault,
                    contentPadding: const EdgeInsets.symmetric(vertical: 15),
                    // prefixText only shows once focused; the prefix must
                    // always be visible so the user knows to type only the rest.
                    prefixIcon: const Padding(
                      padding: EdgeInsetsDirectional.only(start: 14, end: 6),
                      child: Text(SupportAgentCatalog.botUserIDPrefix,
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AIAgentPicker.brandPurple)),
                    ),
                    prefixIconConstraints:
                        const BoxConstraints(minWidth: 0, minHeight: 0),
                    hintText: l10n.customBotInputHint,
                    hintStyle: TextStyle(
                        fontSize: 16, color: colors.textColorTertiary),
                    enabledBorder: _border(colors.strokeColorSecondary, 1),
                    disabledBorder: _border(colors.strokeColorSecondary, 1),
                    focusedBorder: _border(AIAgentPicker.brandPurple, 2),
                  ),
                  onChanged: (_) {
                    if (_error != null) setState(() => _error = null);
                  },
                  onSubmitted: (_) {
                    if (canSubmit) _submit();
                  },
                ),
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: Text(_error!,
                        style: TextStyle(
                            fontSize: 12,
                            height: 1.35,
                            color: colors.textColorError)),
                  ),
                ],
                const SizedBox(height: 20),
                GradientButton(
                  label: l10n.customBotConfirm,
                  onTap: canSubmit ? _submit : null,
                  child: _submitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : null,
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _FooterAction(
                      label: l10n.customBotCancel,
                      color: colors.textColorSecondary,
                      onTap: _submitting
                          ? null
                          : () => Navigator.of(context).pop(false),
                    ),
                    Container(
                        width: 1,
                        height: 14,
                        color: colors.strokeColorSecondary),
                    _FooterAction(
                      label: l10n.customBotDialogDocLink,
                      color: colors.textColorLink,
                      onTap: CustomBotDialog.openDoc,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static OutlineInputBorder _border(Color color, double width) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: color, width: width),
      );
}

class _FooterAction extends StatelessWidget {
  const _FooterAction(
      {required this.label, required this.color, required this.onTap});

  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Text(label, style: TextStyle(fontSize: 14, color: color)),
      ),
    );
  }
}
