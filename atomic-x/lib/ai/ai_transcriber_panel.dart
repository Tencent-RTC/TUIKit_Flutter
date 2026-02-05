import 'package:flutter/material.dart';
import 'package:atomic_x_core/atomicxcore.dart';

import '../base_component/base_component.dart';
import 'ai_transcriber_manager.dart';
import 'ai_transcriber_display_widget.dart';
import 'ai_transcriber_settings_page.dart';

class AITranscriberPanel extends StatefulWidget {
  final double bottomOffset;
  
  final double leftOffset;
  
  final double rightOffset;
  
  final Duration animationDuration;
  
  final Curve animationCurve;

  const AITranscriberPanel({
    super.key,
    this.bottomOffset = 0,
    this.leftOffset = 0,
    this.rightOffset = 0,
    this.animationDuration = const Duration(milliseconds: 300),
    this.animationCurve = Curves.easeInOut,
  });

  @override
  State<AITranscriberPanel> createState() => _AITranscriberPanelState();
}

class _AITranscriberPanelState extends State<AITranscriberPanel> {
  OverlayEntry? _settingsOverlay;
  final GlobalKey<AITranscriberDisplayWidgetState> _displayWidgetKey = GlobalKey();

  @override
  void dispose() {
    _hideSettings();
    super.dispose();
  }

  void _showSettings() {
    var selfId = CallStore.shared.state.selfInfo.value.id;
    var inviterId = CallStore.shared.state.activeCall.value.inviterId;
    if (selfId != inviterId) return;
    if (_settingsOverlay != null) return;

    final locale = Localizations.localeOf(context);
    _settingsOverlay = OverlayEntry(
      builder: (overlayContext) => Localizations(
        locale: locale,
        delegates: AtomicLocalizations.localizationsDelegates,
        child: ComponentTheme(
          child: AITranscriberSettingsPage(
            onClose: _hideSettings,
          ),
        ),
      ),
    );
    Overlay.of(context).insert(_settingsOverlay!);
  }

  void _hideSettings() {
    _settingsOverlay?.remove();
    _settingsOverlay = null;
    _displayWidgetKey.currentState?.scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: aiTranscriberConfigManager.isPanelVisible,
      builder: (context, isPanelVisible, child) {
        if (!isPanelVisible) return const SizedBox.shrink();
        return AnimatedPositioned(
          duration: widget.animationDuration,
          curve: widget.animationCurve,
          left: widget.leftOffset,
          right: widget.rightOffset,
          bottom: widget.bottomOffset,
          child: ValueListenableBuilder(
            valueListenable: aiTranscriberConfigManager.currentSettings,
            builder: (context, settings, child) {
              return AITranscriberDisplayWidget(
                key: _displayWidgetKey,
                showBilingual: settings.showBilingual,
                displayTranslationLanguage: settings.translationLanguage,
                onArrowTap: _showSettings,
              );
            },
          ),
        );
      },
    );
  }
}
