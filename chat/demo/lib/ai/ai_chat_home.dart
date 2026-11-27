import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:tencent_chat_uikit/tencent_chat_uikit.dart';

import '../common/language/gen/demo_localizations.dart';
import 'ai_agent_picker.dart';
import 'ai_agent_profile.dart';
import 'custom_bot_dialog.dart';
import 'quick_start_guide_dialog.dart';
import 'support_agent_catalog.dart';

class AIChatHome extends StatefulWidget {
  const AIChatHome({super.key, required this.visible});

  final ValueListenable<bool> visible;

  @override
  State<AIChatHome> createState() => _AIChatHomeState();
}

class _AIChatHomeState extends State<AIChatHome> {
  static bool _quickStartGuideShown = false;

  final AIAssistantPageController _pageController = AIAssistantPageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<List<AIAssistantAgent>> _loadAgents() async {
    final agents = await SupportAgentCatalog.fetch();
    if (mounted && widget.visible.value && !_quickStartGuideShown) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_quickStartGuideShown) {
          _quickStartGuideShown = QuickStartGuideDialog.showIfNeeded(context);
        }
      });
    }
    return agents;
  }

  Future<void> _onTitleTap(Rect anchor) async {
    if (await AIAgentPicker.show(context, anchor)) {
      await _pageController.reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = DemoLocalizations.of(context);
    return AIAssistantPage(
      visible: widget.visible,
      controller: _pageController,
      agentLoader: _loadAgents,
      handoffStatusLoader: SupportAgentCatalog.fetchHandoffStatus,
      trialPrompt: AIAssistantTrialPrompt(
        quickQuestions: AIAgentProfile.of(l10n, null).quickQuestions,
        quickQuestionsForAgent: (agent) =>
            AIAgentProfile.of(l10n, agent).quickQuestions,
        headerBanner: const _CtaBanner(),
        showCallButton: false,
        onTitleTap: _onTitleTap,
      ),
    );
  }
}

class _CtaBanner extends StatefulWidget {
  const _CtaBanner();

  static bool dismissed = false;

  @override
  State<_CtaBanner> createState() => _CtaBannerState();
}

class _CtaBannerState extends State<_CtaBanner> {
  static const Color _pink = Color(0xFFFF6FD8);

  @override
  Widget build(BuildContext context) {
    if (_CtaBanner.dismissed) return const SizedBox.shrink();
    final l10n = DemoLocalizations.of(context);
    final colors = BaseThemeProvider.colorsOf(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 2),
      child: GestureDetector(
        onTap: CustomBotDialog.openDoc,
        child: Container(
          padding: const EdgeInsets.all(1.5),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [
              AIAgentPicker.brandPurple,
              AIAgentPicker.brandBlue,
              _pink,
            ]),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Container(
            padding: const EdgeInsetsDirectional.fromSTEB(14, 9, 8, 9),
            decoration: BoxDecoration(
              color: colors.bgColorOperate,
              borderRadius: BorderRadius.circular(12.5),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.aiCtaTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: colors.textColorPrimary)),
                      Text(l10n.aiCtaDesc,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 12, color: colors.textColorSecondary)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [
                      AIAgentPicker.brandPurple,
                      AIAgentPicker.brandBlue,
                    ]),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(l10n.aiCtaAction,
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                ),
                Semantics(
                  button: true,
                  label: l10n.aiCtaClose,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => setState(() => _CtaBanner.dismissed = true),
                    child: SizedBox.square(
                      dimension: 32,
                      child: Center(
                        child: Text('✕',
                            style: TextStyle(
                                fontSize: 13,
                                color: colors.textColorSecondary)),
                      ),
                    ),
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
