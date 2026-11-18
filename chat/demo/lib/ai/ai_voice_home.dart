import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:tencent_chat_uikit/tencent_chat_uikit.dart';

import '../common/language/gen/demo_localizations.dart';
import 'ai_agent_picker.dart';
import 'ai_agent_profile.dart';
import 'custom_bot_dialog.dart';
import 'pulse_rings.dart';
import 'quick_start_guide_dialog.dart';
import 'support_agent_catalog.dart';

/// The experience demo's AI tab: a call-style landing by default, where only
/// a tap starts the AI voice call. "Ask by text" / "History" switch to the
/// text conversation page, and hanging up lands there too. Devices without
/// voice support go straight to the text page.
class AIVoiceHome extends StatefulWidget {
  const AIVoiceHome({super.key, required this.visible});

  /// Whether the AI tab is the current tab. Forwarded to the text page and
  /// used to pause animations and the back-key interception.
  final ValueListenable<bool> visible;

  @override
  State<AIVoiceHome> createState() => _AIVoiceHomeState();
}

class _AIVoiceHomeState extends State<AIVoiceHome>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  static const Duration _sampleInterval = Duration(milliseconds: 2600);
  static const Color _callGreenLight = Color(0xFF34E89E);
  static const Color _callGreenDark = Color(0xFF0FB57A);

  final AIAssistantPageController _pageController = AIAssistantPageController();
  late final AnimationController _callBreath = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1100));

  bool _showLanding = true;
  AIAssistantAgent? _agent;
  int _sampleIndex = 0;
  Timer? _sampleTimer;

  /// Went to system settings to turn the microphone on; a call starts when
  /// the user comes back with it granted.
  bool _pendingSettingsReturn = false;
  bool _leftForSettings = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.visible.addListener(_updateLandingAnimations);
    _pageController.addListener(_onPageChanged);
    SupportAgentCatalog.load();
    _updateLandingAnimations();
  }

  @override
  void didUpdateWidget(covariant AIVoiceHome oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.visible != widget.visible) {
      oldWidget.visible.removeListener(_updateLandingAnimations);
      widget.visible.addListener(_updateLandingAnimations);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.visible.removeListener(_updateLandingAnimations);
    _pageController
      ..removeListener(_onPageChanged)
      ..dispose();
    _sampleTimer?.cancel();
    _callBreath.dispose();
    super.dispose();
  }

  /// The text page only ever gets the assistant chosen in the picker.
  Future<List<AIAssistantAgent>> _loadAgents() async {
    final agents = await SupportAgentCatalog.fetch();
    final agent = agents.isEmpty ? null : agents.first;
    if (mounted && agent?.imUserId != _agent?.imUserId) {
      setState(() {
        _agent = agent;
        _sampleIndex = 0;
      });
    }
    return agents;
  }

  void _onPageChanged() {
    final controller = _pageController;
    // Without voice support there is nothing to call from the landing.
    if (controller.isVoiceSupportChecked &&
        !controller.isVoiceCallSupported &&
        _showLanding) {
      _showText();
    }
  }

  bool get _voiceSupported =>
      !_pageController.isVoiceSupportChecked ||
      _pageController.isVoiceCallSupported;

  // region mode switch

  void _showVoice() {
    if (!_voiceSupported) return;
    setState(() => _showLanding = true);
    _updateLandingAnimations();
  }

  void _showText() {
    setState(() => _showLanding = false);
    _updateLandingAnimations();
  }

  void _updateLandingAnimations() {
    final active = mounted && _showLanding && widget.visible.value;
    if (active) {
      _sampleTimer ??= Timer.periodic(_sampleInterval, (_) {
        if (mounted) setState(() => _sampleIndex++);
      });
      if (!_callBreath.isAnimating) _callBreath.repeat(reverse: true);
    } else {
      _sampleTimer?.cancel();
      _sampleTimer = null;
      _callBreath
        ..stop()
        ..value = 0;
    }
  }

  void _onPopInvoked(bool didPop, Object? _) {
    // In text mode the back key returns to the voice landing instead of
    // doing nothing.
    if (didPop || _showLanding || !widget.visible.value || !_voiceSupported) {
      return;
    }
    _showVoice();
  }

  // endregion

  // region call

  /// The landing's "History" and "Ask by text".
  void _onShowTextTap() {
    if (QuickStartGuideDialog.showIfNeeded(context)) return;
    _showText();
  }

  Future<void> _onStartCallTap() async {
    if (QuickStartGuideDialog.showIfNeeded(context)) return;
    if (!_pageController.canStartVoiceCall) {
      Toast.simple(context, DemoLocalizations.of(context).aiVoiceUnavailable);
      return;
    }
    final status = await Permission.check(PermissionType.microphone);
    if (!mounted) return;
    if (status == PermissionStatus.granted) {
      await _startCall();
    } else {
      // Permission.check only reports permanentlyDenied once it was asked,
      // then the system dialog no longer shows and only settings help.
      _showMicSheet(
          permanentlyDenied: status == PermissionStatus.permanentlyDenied);
    }
  }

  Future<void> _startCall() async {
    final callShown = await _pageController.startVoiceCall();
    // Back from hanging up: carry on by text.
    if (callShown && mounted) _showText();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_pendingSettingsReturn) return;
    if (state == AppLifecycleState.paused) {
      _leftForSettings = true;
      return;
    }
    // Closing the sheet resumes the window once before settings opens; only a
    // return after really leaving counts.
    if (state == AppLifecycleState.resumed && _leftForSettings) {
      _pendingSettingsReturn = false;
      _leftForSettings = false;
      Permission.check(PermissionType.microphone).then((status) {
        if (mounted &&
            status == PermissionStatus.granted &&
            _pageController.canStartVoiceCall) {
          _startCall();
        }
      });
    }
  }

  Future<void> _openAppSettings() async {
    _pendingSettingsReturn = true;
    _leftForSettings = false;
    if (!await Permission.openAppSettings()) _pendingSettingsReturn = false;
  }

  /// Explains why the microphone is needed before the system dialog, with a
  /// way out that does not use it.
  void _showMicSheet({required bool permanentlyDenied}) {
    final l10n = DemoLocalizations.of(context);
    final colors = BaseThemeProvider.colorsOf(context);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: colors.bgColorDialog,
      barrierColor: Colors.black54,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 18),
                  decoration: BoxDecoration(
                    color: colors.strokeColorPrimary,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                        shape: BoxShape.circle, color: Color(0x337B5CFF)),
                    child: SvgPicture.asset(
                      'chat_assets/icon/aiassistant/ai_call_mic.svg',
                      package: 'tencent_chat_uikit',
                      width: 24,
                      height: 24,
                      colorFilter: const ColorFilter.mode(
                          AIAgentPicker.brandPurple, BlendMode.srcIn),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    l10n.aiMicTitle,
                    style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        color: colors.textColorPrimary),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                permanentlyDenied ? l10n.aiMicDeniedDesc : l10n.aiMicDesc,
                style: TextStyle(
                    fontSize: 14,
                    height: 1.3,
                    color: colors.textColorSecondary),
              ),
              const SizedBox(height: 8),
              Text(l10n.aiMicTip,
                  style: TextStyle(
                      fontSize: 13, color: colors.textColorSecondary)),
              const SizedBox(height: 22),
              GestureDetector(
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  if (permanentlyDenied) {
                    _openAppSettings();
                  } else {
                    _startCall();
                  }
                },
                child: Container(
                  height: 50,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [_callGreenLight, _callGreenDark]),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    permanentlyDenied
                        ? l10n.aiMicOpenSettings
                        : l10n.aiMicAllow,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _showText();
                },
                child: Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 4),
                  child: Text(
                    l10n.aiMicText,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: colors.textColorLink),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // endregion

  AICallUiOptions _callUiOptions(List<String> hints) => AICallUiOptions(
        auroraStyle: true,
        plainTranscript: true,
        sampleHints: hints,
        showButtonLabels: true,
        showCallTimer: true,
      );

  @override
  Widget build(BuildContext context) {
    final l10n = DemoLocalizations.of(context);
    final profile = AIAgentProfile.of(l10n, _agent);
    final voiceSupported = _voiceSupported;
    final page = AIAssistantPage(
      visible: widget.visible,
      controller: _pageController,
      agentLoader: _loadAgents,
      handoffStatusLoader: SupportAgentCatalog.fetchHandoffStatus,
      trialPrompt: AIAssistantTrialPrompt(
        backLabel: voiceSupported ? l10n.aiVoiceBack : null,
        onBack: voiceSupported ? _showVoice : null,
        quickQuestions: AIAgentProfile.of(l10n, null).quickQuestions,
        quickQuestionsForAgent: (agent) =>
            AIAgentProfile.of(l10n, agent).quickQuestions,
        headerBanner: const _CtaBanner(),
        callUiOptions: _callUiOptions(profile.samples),
        callUiOptionsForAgent: (agent) =>
            _callUiOptions(AIAgentProfile.of(l10n, agent).samples),
      ),
    );
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: _onPopInvoked,
      child: Stack(
        children: [
          Positioned.fill(
            child: Offstage(
              offstage: _showLanding,
              child: TickerMode(enabled: !_showLanding, child: page),
            ),
          ),
          if (_showLanding)
            Positioned.fill(
              child: ValueListenableBuilder<bool>(
                valueListenable: widget.visible,
                builder: (_, visible, child) =>
                    TickerMode(enabled: visible, child: child!),
                child: _buildLanding(l10n, profile),
              ),
            ),
        ],
      ),
    );
  }

  // region landing

  Widget _buildLanding(DemoLocalizations l10n, AIAgentProfile profile) {
    final colors = BaseThemeProvider.colorsOf(context);
    final samples = profile.samples;
    final sample =
        samples.isEmpty ? '' : samples[_sampleIndex % samples.length];
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: colors.bgColorOperate,
        statusBarIconBrightness: Theme.of(context).brightness == Brightness.dark
            ? Brightness.light
            : Brightness.dark,
      ),
      child: ColoredBox(
        color: colors.bgColorOperate,
        child: SafeArea(
          bottom: false,
          child: LayoutBuilder(builder: (context, constraints) {
            // Leave room for everything else on short screens.
            final orbBox =
                math.min(264.0, math.max(160.0, constraints.maxHeight - 470));
            return Column(
              children: [
                SizedBox(
                  height: 56,
                  child: Padding(
                    padding:
                        const EdgeInsetsDirectional.only(start: 16, end: 16),
                    child: Row(
                      children: [
                        Flexible(
                          child: Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: AIAgentPicker(
                              agent: _agent,
                              onSelectionChanged: _pageController.reload,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: _onShowTextTap,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border:
                                  Border.all(color: colors.strokeColorPrimary),
                            ),
                            child: Text(l10n.aiVoiceHistory,
                                style: TextStyle(
                                    fontSize: 13,
                                    color: colors.textColorPrimary)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(flex: 8),
                GestureDetector(
                  onTap: _onStartCallTap,
                  child: SizedBox.square(
                    dimension: orbBox,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        const Positioned.fill(
                          child: PulseRings(
                            color: Color(0xFF8B7BFF),
                            count: 3,
                            period: Duration(milliseconds: 3600),
                            startFraction: 0.6,
                            maxAlpha: 0.5,
                          ),
                        ),
                        SizedBox.square(
                          dimension: orbBox * 250 / 264,
                          child: VoiceOrb(
                            state: AICallState.idle,
                            level: const AlwaysStoppedAnimation<double>(0),
                            colorLight: colors.buttonColorPrimaryHover,
                            colorCore: colors.buttonColorPrimaryDefault,
                            colorDark: colors.buttonColorPrimaryActive,
                            auroraStyle: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.aiVoiceHeadline,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: colors.textColorPrimary),
                ),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    profile.subtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 14, color: colors.textColorSecondary),
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 28),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: colors.bgColorDefault,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: colors.strokeColorSecondary),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.aiVoiceTryLabel,
                          style: TextStyle(
                              fontSize: 12, color: colors.textColorSecondary)),
                      const SizedBox(height: 2),
                      ClipRect(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 380),
                          layoutBuilder: (current, previous) => Stack(
                            alignment: AlignmentDirectional.centerStart,
                            children: [
                              ...previous,
                              if (current != null) current
                            ],
                          ),
                          transitionBuilder: _slideUp,
                          child: Text(
                            sample,
                            key: ValueKey<int>(_sampleIndex),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 16, color: colors.textColorPrimary),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(flex: 10),
                SizedBox.square(
                  dimension: 116,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const Positioned.fill(
                        child: PulseRings(
                          color: Color(0xFF1DC98A),
                          count: 2,
                          period: Duration(milliseconds: 2000),
                          startFraction: 0.64,
                          maxAlpha: 0.7,
                        ),
                      ),
                      ScaleTransition(
                        scale: Tween<double>(begin: 1, end: 1.05).animate(
                            CurvedAnimation(
                                parent: _callBreath, curve: Curves.easeInOut)),
                        child: Semantics(
                          button: true,
                          label: l10n.aiVoiceStart,
                          child: GestureDetector(
                            onTap: _onStartCallTap,
                            child: Container(
                              width: 76,
                              height: 76,
                              alignment: Alignment.center,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [_callGreenLight, _callGreenDark],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                      color: Color(0x400FB57A),
                                      blurRadius: 12,
                                      offset: Offset(0, 4)),
                                ],
                              ),
                              child: SvgPicture.asset(
                                'chat_assets/icon/aiassistant/ai_call.svg',
                                package: 'tencent_chat_uikit',
                                width: 32,
                                height: 32,
                                colorFilter: const ColorFilter.mode(
                                    Colors.white, BlendMode.srcIn),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  l10n.aiVoiceStart,
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: colors.textColorPrimary),
                ),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _onShowTextTap,
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Text(l10n.aiVoiceUseText,
                        style: TextStyle(
                            fontSize: 13, color: colors.textColorLink)),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            );
          }),
        ),
      ),
    );
  }

  /// The new sample slides up in from below while the old one leaves upward.
  /// The outgoing child runs the animation in reverse (1 to 0).
  Widget _slideUp(Widget child, Animation<double> animation) {
    final incoming = child.key == ValueKey<int>(_sampleIndex);
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: incoming ? const Offset(0, 1) : const Offset(0, -1),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
    );
  }

  // endregion
}

/// Closable "bring this AI agent to your app" banner over the text page,
/// opening the official knowledge-base document in an in-app browser.
class _CtaBanner extends StatefulWidget {
  const _CtaBanner();

  /// Closed once, it stays away for this process and comes back on restart.
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
