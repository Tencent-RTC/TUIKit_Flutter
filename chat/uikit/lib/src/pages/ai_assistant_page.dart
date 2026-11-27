import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide IconButton;
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:tuikit_atomic_x/atomicx.dart';
import 'package:tuikit_atomic_x/base_component/utils/tui_event_bus.dart';

import '../aiassistant/agent_welcome_inserter.dart';
import '../aiassistant/ai_assistant_agent.dart';
import '../aiassistant/ai_assistant_control_messages.dart';
import '../aiassistant/ai_assistant_usage_reporter.dart';
import '../aiassistant/ai_constants.dart';
import '../aiassistant/call/ai_call_controller.dart';
import '../aiassistant/call/ai_call_page.dart';
import '../aiassistant/call/ai_call_ui_options.dart';
import '../common/language/gen/chat_localizations.dart';
import '../common/utils/uikit_util.dart';
import '../message_input/message_input.dart';
import '../message_list/listen/listen_playback_bar.dart';
import '../message_list/message_list.dart';

/// Optional first-run hint for the experience demo. Omitted hosts see no prompt
/// and no extra red dots.
class AIAssistantTrialPrompt {
  const AIAssistantTrialPrompt({
    this.initialInputText,
    this.shouldShowSendRedDot,
    this.onSendRedDotTap,
    this.shouldShowCallRedDot,
    this.onCallRedDotTap,
    this.backLabel,
    this.onBack,
    this.quickQuestions = const [],
    this.quickQuestionsForAgent,
    this.headerBanner,
    this.callUiOptions,
    this.callUiOptionsForAgent,
    this.showCallButton = true,
    this.onTitleTap,
  });

  final String? initialInputText;
  final bool Function()? shouldShowSendRedDot;
  final VoidCallback? onSendRedDotTap;
  final bool Function()? shouldShowCallRedDot;
  final VoidCallback? onCallRedDotTap;

  /// Back entry on the left of the header; shown only when both are given.
  final String? backLabel;
  final VoidCallback? onBack;

  /// Tappable questions beside the transfer button; a tap sends directly.
  final List<String> quickQuestions;

  /// Questions for the current assistant, refreshed on every switch. Null
  /// falls back to [quickQuestions].
  final List<String>? Function(AIAssistantAgent agent)? quickQuestionsForAgent;

  /// Inserted under the header; the host controls its own visibility.
  final Widget? headerBanner;

  /// Look and guidance of the call page. Null keeps the page as it was.
  final AICallUiOptions? callUiOptions;

  /// Call page options for the current assistant, e.g. its sample hints. Null
  /// falls back to [callUiOptions].
  final AICallUiOptions? Function(AIAssistantAgent agent)?
      callUiOptionsForAgent;
  final bool showCallButton;
  final void Function(Rect anchor)? onTitleTap;
}

/// Lets a host drive the page, e.g. start a call from its own landing view.
///
/// Notifies when voice support is known or the selected assistant changes.
class AIAssistantPageController extends ChangeNotifier {
  _AIAssistantPageState? _state;

  /// Whether the device can run AI voice calls. False until checked.
  bool get isVoiceCallSupported => _state?._isVoiceCallSupported ?? false;

  /// Whether [isVoiceCallSupported] has been determined.
  bool get isVoiceSupportChecked => _state?._voiceSupportChecked ?? false;

  AIAssistantAgent? get selectedAgent => _state?._selectedAgent;

  /// An assistant is loaded and the device supports voice calls.
  bool get canStartVoiceCall => selectedAgent != null && isVoiceCallSupported;

  /// Same as the header call button, including the human handoff check.
  /// Completes with true after an AI call page was shown and closed.
  Future<bool> startVoiceCall() async {
    final state = _state;
    if (state == null) return false;
    state._consumeCallRedDot();
    return state._onCallTap();
  }

  /// Fetches the directory again, e.g. after the host changed the selection.
  Future<void> reload() async => _state?._reloadAgents();

  void _notify() => notifyListeners();
}

@visibleForTesting
SystemUiOverlayStyle aiAssistantSystemUiOverlayStyle({
  required Color backgroundColor,
  required Brightness brightness,
}) {
  final isDark = brightness == Brightness.dark;
  return SystemUiOverlayStyle(
    statusBarColor: backgroundColor,
    statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
    statusBarBrightness: brightness,
    systemStatusBarContrastEnforced: false,
  );
}

/// Reusable AI assistant page. Its directory is provided by [agentLoader].
class AIAssistantPage extends StatefulWidget {
  const AIAssistantPage({
    super.key,
    required this.visible,
    required this.agentLoader,
    this.handoffStatusLoader,
    this.trialPrompt,
    this.controller,
  });

  /// Whether the tab is currently shown. The directory is fetched again every
  /// time this turns true, since the page itself stays alive across tab switches.
  final ValueListenable<bool> visible;

  /// Supplies a fresh assistant snapshot whenever this page becomes visible.
  final AIAssistantAgentLoader agentLoader;

  /// Supplies the latest human-agent handoff state before starting a call.
  ///
  /// When omitted, the call button keeps its original AI voice-call behavior.
  final AIAssistantHandoffStatusLoader? handoffStatusLoader;

  /// Demo-only composer prompt and the two entry red dots. Null keeps the page unchanged.
  final AIAssistantTrialPrompt? trialPrompt;

  /// Optional handle for hosts that start calls or reload from outside.
  final AIAssistantPageController? controller;

  @override
  State<AIAssistantPage> createState() => _AIAssistantPageState();
}

class _AIAssistantPageState extends State<AIAssistantPage> {
  static const double _headerHeight = 48;
  static const double _titleMaxWidth = 180;

  final GlobalKey _titleAnchorKey = GlobalKey();

  final AIAssistantUsageReporter _usageReporter = AIAssistantUsageReporter();

  List<AIAssistantAgent> _agents = const [];
  AIAssistantAgent? _selectedAgent;
  String? _boundConversationID;
  bool _loaded = false;
  int _fetchGeneration = 0;
  bool _isVoiceCallSupported = false;
  bool _voiceSupportChecked = false;
  int _callCheckGeneration = 0;
  bool _isCheckingHandoffStatus = false;

  GlobalKey<MessageInputState> _messageInputKey = GlobalKey();
  MultiSelectState? _multiSelectState;

  @override
  void initState() {
    super.initState();
    widget.visible.addListener(_onVisibilityChanged);
    widget.controller?._state = this;
    _checkVoiceCallSupport();
    if (widget.visible.value) {
      _reloadAgents();
    }
  }

  @override
  void didUpdateWidget(covariant AIAssistantPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final becameVisible = oldWidget.visible != widget.visible &&
        !oldWidget.visible.value &&
        widget.visible.value;
    if (oldWidget.visible != widget.visible) {
      oldWidget.visible.removeListener(_onVisibilityChanged);
      widget.visible.addListener(_onVisibilityChanged);
    }
    if (widget.visible.value &&
        (becameVisible || oldWidget.agentLoader != widget.agentLoader)) {
      _reloadAgents();
    }
    if (oldWidget.controller != widget.controller) {
      if (oldWidget.controller?._state == this)
        oldWidget.controller?._state = null;
      widget.controller?._state = this;
    }
    if (oldWidget.handoffStatusLoader != widget.handoffStatusLoader) {
      _callCheckGeneration++;
      _isCheckingHandoffStatus = false;
    }
  }

  @override
  void dispose() {
    widget.visible.removeListener(_onVisibilityChanged);
    if (widget.controller?._state == this) widget.controller?._state = null;
    _fetchGeneration++;
    _callCheckGeneration++;
    _isCheckingHandoffStatus = false;
    super.dispose();
  }

  void _onVisibilityChanged() {
    if (widget.visible.value) {
      _reloadAgents();
    }
  }

  Future<void> _checkVoiceCallSupport() async {
    final supported = await AICallController.isSupported();
    if (!mounted) return;
    setState(() {
      _isVoiceCallSupported = supported;
      _voiceSupportChecked = true;
    });
    widget.controller?._notify();
  }

  Future<void> _reloadAgents() async {
    final generation = ++_fetchGeneration;
    late final List<AIAssistantAgent> agents;
    try {
      agents = await widget.agentLoader();
    } catch (error) {
      if (mounted && generation == _fetchGeneration) {
        debugPrint('AIAssistantPage: load agents failed: $error');
      }
      return;
    }
    if (!mounted || generation != _fetchGeneration) return;
    _onAgentsLoaded(agents);
  }

  void _onAgentsLoaded(List<AIAssistantAgent> agents) {
    if (agents.isEmpty) {
      setState(() {
        _loaded = true;
        _agents = const [];
        _selectedAgent = null;
        _boundConversationID = null;
        _multiSelectState = null;
      });
      widget.controller?._notify();
      return;
    }
    final currentID = _selectedAgent?.id;
    final next = agents.firstWhere((agent) => agent.id == currentID,
        orElse: () => agents.first);
    setState(() {
      _loaded = true;
      _agents = agents;
    });
    _bindAgent(next);
  }

  void _bindAgent(AIAssistantAgent agent) {
    if (_selectedAgent?.id != agent.id) {
      _callCheckGeneration++;
      _isCheckingHandoffStatus = false;
    }
    setState(() => _selectedAgent = agent);
    widget.controller?._notify();
    if (_boundConversationID == agent.conversationID) {
      AgentWelcomeInserter.insertIfConversationEmpty(agent);
      return;
    }
    setState(() {
      _boundConversationID = agent.conversationID;
      _messageInputKey = GlobalKey();
      _multiSelectState = null;
    });
    // The list must exist first: a history load issued right after a local
    // insert can come back without it, so the welcome reaches the list through
    // the insert notification instead.
    AgentWelcomeInserter.insertIfConversationEmpty(agent);
  }

  void _consumeCallRedDot() {
    if (widget.trialPrompt?.shouldShowCallRedDot?.call() != true) return;
    widget.trialPrompt?.onCallRedDotTap?.call();
    setState(() {});
  }

  /// Completes with true after an AI call page was shown and closed.
  Future<bool> _onCallTap() async {
    final agent = _selectedAgent;
    if (agent == null || !_isVoiceCallSupported) return false;
    final statusLoader = widget.handoffStatusLoader;
    if (statusLoader == null) {
      return _startAiVoiceCall(agent);
    }
    var aiCallShown = false;
    await _checkHandoffStatus(
      agent: agent,
      statusLoader: statusLoader,
      onResult: (status) async {
        if (status.isSeatCallable) {
          _startHumanCall(
            status.seatImUserId.trim(),
            CallMediaType.audio,
          );
        } else if (status.isWaitingForSeat) {
          Toast.simple(
            context,
            ChatLocalizations.of(context).aiCallHandoffWaiting,
          );
        } else {
          aiCallShown = await _startAiVoiceCall(agent);
        }
      },
    );
    return aiCallShown;
  }

  void _onCallMessageClick(String _, bool isVideoCall) {
    final agent = _selectedAgent;
    if (agent == null) return;
    final statusLoader = widget.handoffStatusLoader;
    if (statusLoader == null) {
      _showHandoffRequired();
      return;
    }
    _checkHandoffStatus(
      agent: agent,
      statusLoader: statusLoader,
      onResult: (status) {
        if (status.isSeatCallable) {
          _startHumanCall(
            status.seatImUserId.trim(),
            isVideoCall ? CallMediaType.video : CallMediaType.audio,
          );
        } else if (status.isWaitingForSeat) {
          Toast.simple(
            context,
            ChatLocalizations.of(context).aiCallHandoffWaiting,
          );
        } else {
          _showHandoffRequired();
        }
      },
    );
  }

  Future<void> _checkHandoffStatus({
    required AIAssistantAgent agent,
    required AIAssistantHandoffStatusLoader statusLoader,
    required FutureOr<void> Function(AIAssistantHandoffStatus status) onResult,
  }) async {
    if (_isCheckingHandoffStatus) return;
    _isCheckingHandoffStatus = true;
    final generation = ++_callCheckGeneration;
    AIAssistantHandoffStatus status;
    try {
      status = await statusLoader();
    } catch (error) {
      debugPrint('AIAssistantPage: load handoff status failed: $error');
      status = AIAssistantHandoffStatus.inactive;
    }
    if (!mounted || generation != _callCheckGeneration) return;
    _isCheckingHandoffStatus = false;
    if (_selectedAgent?.id != agent.id) return;
    await onResult(status);
  }

  void _startHumanCall(String userID, CallMediaType mediaType) {
    final params = PublishParams()
      ..isSticky = false
      ..data = {
        'participantIds': [userID],
        'mediaType': mediaType,
        'chatGroupId': null,
        'timeout': 30,
      };
    TUIEventBus.shared.publish('call.startCall', null, params);
    UIKitUtil.reportChatInvokeCall();
  }

  Future<bool> _startAiVoiceCall(AIAssistantAgent agent) async {
    if (!_isVoiceCallSupported) return false;
    _usageReporter.onVoiceEntered();
    final prompt = widget.trialPrompt;
    final options = prompt?.callUiOptionsForAgent?.call(agent) ??
        prompt?.callUiOptions ??
        const AICallUiOptions();
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
          builder: (_) =>
              AICallPage(robotUserID: agent.imUserId, uiOptions: options)),
    );
    return true;
  }

  List<String> _quickQuestions(AIAssistantAgent? agent) {
    final prompt = widget.trialPrompt;
    if (prompt == null) return const [];
    final forAgent =
        agent == null ? null : prompt.quickQuestionsForAgent?.call(agent);
    return forAgent ?? prompt.quickQuestions;
  }

  void _showHandoffRequired() {
    Toast.simple(
      context,
      ChatLocalizations.of(context).aiCallHandoffRequired,
    );
  }

  void _onTitleTap() {
    final onTitleTap = widget.trialPrompt?.onTitleTap;
    if (onTitleTap == null) {
      _showAgentPicker();
      return;
    }
    final box =
        _titleAnchorKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    onTitleTap(box.localToGlobal(Offset.zero) & box.size);
  }

  Future<void> _showAgentPicker() async {
    final agents = _agents;
    if (agents.length <= 1) return;
    final box =
        _titleAnchorKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final anchor = box.localToGlobal(Offset.zero) & box.size;
    final picked = await _AgentPicker.show(
        context: context, anchor: anchor, agents: agents);
    if (picked == null || !mounted) return;
    _bindAgent(picked);
  }

  @override
  Widget build(BuildContext context) {
    final colors = BaseThemeProvider.colorsOf(context);
    final locale = ChatLocalizations.of(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: aiAssistantSystemUiOverlayStyle(
        backgroundColor: colors.bgColorOperate,
        brightness: Theme.of(context).brightness,
      ),
      child: Scaffold(
        backgroundColor: colors.bgColorDefault,
        body: Column(
          children: [
            _buildHeader(colors, locale),
            if (widget.trialPrompt?.headerBanner != null)
              widget.trialPrompt!.headerBanner!,
            Expanded(child: _buildContent(colors, locale)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(SemanticColorScheme colors, ChatLocalizations locale) {
    final agent = _selectedAgent;
    final canSwitch = widget.trialPrompt?.onTitleTap != null ||
        (agent != null && _agents.length > 1);
    final showCall = agent != null &&
        _isVoiceCallSupported &&
        (widget.trialPrompt?.showCallButton ?? true);
    return Container(
      color: colors.bgColorOperate,
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: _headerHeight,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: _buildBackButton(colors)),
                    Expanded(
                      flex: 2,
                      child: GestureDetector(
                        key: _titleAnchorKey,
                        behavior: HitTestBehavior.opaque,
                        onTap: canSwitch ? _onTitleTap : null,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Flexible(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                    maxWidth: _titleMaxWidth),
                                child: Text(
                                  agent?.displayName ?? locale.aiPageTitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: colors.textColorPrimary,
                                  ),
                                ),
                              ),
                            ),
                            if (canSwitch) ...[
                              const SizedBox(width: 2),
                              Semantics(
                                label: locale.aiSelectAgent,
                                child: SvgPicture.asset(
                                  'chat_assets/icon/aiassistant/ai_title_dropdown.svg',
                                  package: 'tencent_chat_uikit',
                                  width: 16,
                                  height: 16,
                                  colorFilter: ColorFilter.mode(
                                      colors.textColorPrimary, BlendMode.srcIn),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: showCall
                            ? Semantics(
                                button: true,
                                label: locale.aiCallButton,
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () {
                                    _consumeCallRedDot();
                                    _onCallTap();
                                  },
                                  child: Padding(
                                    padding: const EdgeInsetsDirectional.only(
                                        start: 12, top: 14, bottom: 14),
                                    child: Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        SvgPicture.asset(
                                          'chat_assets/icon/aiassistant/ai_call.svg',
                                          package: 'tencent_chat_uikit',
                                          width: 20,
                                          height: 20,
                                          colorFilter: ColorFilter.mode(
                                              colors.textColorPrimary,
                                              BlendMode.srcIn),
                                        ),
                                        if (widget.trialPrompt
                                                ?.shouldShowCallRedDot
                                                ?.call() ==
                                            true)
                                          PositionedDirectional(
                                            top: 0,
                                            end: 0,
                                            child: Container(
                                              width: 8,
                                              height: 8,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: colors.textColorError,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(height: 0.5, color: colors.strokeColorPrimary),
          ],
        ),
      ),
    );
  }

  Widget _buildBackButton(SemanticColorScheme colors) {
    final label = widget.trialPrompt?.backLabel;
    final onBack = widget.trialPrompt?.onBack;
    if (label == null || label.isEmpty || onBack == null) {
      return const SizedBox.shrink();
    }
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onBack,
        child: Padding(
          padding: const EdgeInsetsDirectional.only(top: 8, bottom: 8, end: 8),
          child: Text(
            label,
            maxLines: 1,
            style: TextStyle(fontSize: 15, color: colors.textColorPrimary),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(SemanticColorScheme colors, ChatLocalizations locale) {
    if (_loaded && _agents.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
          child: Text(
            locale.aiAgentsEmpty,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, color: colors.textColorSecondary),
          ),
        ),
      );
    }
    final conversationID = _boundConversationID;
    if (conversationID == null) {
      return const SizedBox.shrink();
    }
    return KeyedSubtree(
      key: ValueKey(conversationID),
      child: _buildChat(conversationID),
    );
  }

  Widget _buildChat(String conversationID) {
    final multiSelectState = _multiSelectState;
    final showTransferButton =
        multiSelectState == null || !multiSelectState.isActive;
    return Stack(
      children: [
        GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
            _messageInputKey.currentState?.collapseAllPanels();
          },
          behavior: HitTestBehavior.translucent,
          child: Column(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Column(
                        children: [
                          MessageList(
                            conversationID: conversationID,
                            config: ChatMessageListConfig(
                              isShowLeftAvatar: false,
                              isShowRightAvatar: false,
                              // 回复可能来自人工客服，客户端分不清，等服务端下发「正在输入」再展示
                              enableChatbotReplyPlaceholder: false,
                              shouldHideMessage:
                                  AIAssistantControlMessages.shouldHideMessage,
                            ),
                            onCallMessageClick: _onCallMessageClick,
                            onQuoteMessage: (message) {
                              _messageInputKey.currentState
                                  ?.setQuotedMessage(message);
                            },
                            onMultiSelectStateChanged: (state) {
                              setState(() => _multiSelectState = state);
                            },
                            contentBottomInset: showTransferButton
                                ? _TransferToHumanButton.height + 8
                                : 0,
                          ),
                        ],
                      ),
                    ),
                    if (showTransferButton)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 8,
                        height: _TransferToHumanButton.height,
                        child: _buildFooterRow(conversationID),
                      ),
                  ],
                ),
              ),
              if (multiSelectState != null && multiSelectState.isActive)
                MultiSelectBottomBar(
                  selectedCount: multiSelectState.selectedCount,
                  onCancel: multiSelectState.onCancel,
                  onDelete: multiSelectState.onDelete,
                  onForward: () => multiSelectState.onForward(context),
                )
              else
                MessageInput(
                  key: _messageInputKey,
                  conversationID: conversationID,
                  config: ChatMessageInputConfig(
                    isShowAudioCall: false,
                    isShowVideoCall: false,
                    isShowMore: false,
                    isShowEmoji: false,
                    enableSendRecordedVoice: false,
                    initialInputText: widget.trialPrompt?.initialInputText,
                    shouldShowSendRedDot:
                        widget.trialPrompt?.shouldShowSendRedDot,
                    onSendRedDotTap: widget.trialPrompt?.onSendRedDotTap,
                  ),
                  onMessageSent: _usageReporter.onMessageSent,
                ),
            ],
          ),
        ),
        const Positioned.fill(child: ListenPlaybackBar()),
      ],
    );
  }

  /// Transfer button followed by the assistant's quick questions, scrolling
  /// horizontally when they do not fit.
  Widget _buildFooterRow(String conversationID) {
    final agent = _selectedAgent;
    final questions = _quickQuestions(agent);
    return SingleChildScrollView(
      // A new assistant starts from the left again.
      key: ValueKey(agent?.id),
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          _TransferToHumanButton(
              onTap: () => _sendTransferToHuman(conversationID)),
          for (final question in questions) ...[
            const SizedBox(width: 8),
            _QuickQuestionChip(
              text: question,
              onTap: () => _sendQuickQuestion(conversationID, question),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _sendQuickQuestion(String conversationID, String text) async {
    final result =
        await MessageInputStore.create(conversationID: conversationID)
            .sendMessage(payload: TextSendMessagePayload(text: text));
    if (result.isSuccess) {
      _usageReporter.onMessageSent();
    } else if (mounted) {
      Toast.simple(context, ChatLocalizations.of(context).aiCallSendFailed);
    }
  }

  Future<void> _sendTransferToHuman(String conversationID) async {
    final result =
        await MessageInputStore.create(conversationID: conversationID)
            .sendMessage(
      payload:
          const TextSendMessagePayload(text: AIConstants.transferToHumanText),
    );
    if (result.isSuccess) {
      _usageReporter.onMessageSent();
    }
    if (!result.isSuccess && mounted) {
      Toast.simple(context, ChatLocalizations.of(context).aiCallSendFailed);
    }
  }
}

class _TransferToHumanButton extends StatelessWidget {
  const _TransferToHumanButton({required this.onTap});

  static const double height = 32;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = BaseThemeProvider.colorsOf(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: colors.bgColorOperate,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.strokeColorPrimary),
        ),
        child: Text(
          ChatLocalizations.of(context).aiTransferToHuman,
          style: TextStyle(fontSize: 14, color: colors.textColorPrimary),
        ),
      ),
    );
  }
}

class _QuickQuestionChip extends StatelessWidget {
  const _QuickQuestionChip({required this.text, required this.onTap});

  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = BaseThemeProvider.colorsOf(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: _TransferToHumanButton.height,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: colors.bgColorOperate,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.textColorLink),
        ),
        child: Text(
          text,
          maxLines: 1,
          style: TextStyle(fontSize: 14, color: colors.textColorLink),
        ),
      ),
    );
  }
}

/// Agent menu shown below the title, horizontally centered on it.
class _AgentPicker {
  _AgentPicker._();

  static Future<AIAssistantAgent?> show({
    required BuildContext context,
    required Rect anchor,
    required List<AIAssistantAgent> agents,
  }) {
    final colors = BaseThemeProvider.colorsOf(context);
    return showGeneralDialog<AIAssistantAgent>(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 150),
      pageBuilder: (dialogContext, _, __) {
        return CustomSingleChildLayout(
          delegate: _AnchorCenteredLayout(
              anchor: anchor, padding: MediaQuery.paddingOf(dialogContext)),
          child: Material(
            color: colors.bgColorDialog,
            elevation: 8,
            shadowColor: Colors.black26,
            borderRadius: BorderRadius.circular(12),
            clipBehavior: Clip.antiAlias,
            child: IntrinsicWidth(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final agent in agents)
                    InkWell(
                      onTap: () => Navigator.of(dialogContext).pop(agent),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        child: Text(
                          agent.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 14, color: colors.textColorPrimary),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
      transitionBuilder: (_, animation, __, child) {
        return FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
            child: child);
      },
    );
  }
}

class _AnchorCenteredLayout extends SingleChildLayoutDelegate {
  _AnchorCenteredLayout({required this.anchor, required this.padding});

  static const double _screenMargin = 8;
  static const double _gap = 4;

  final Rect anchor;
  final EdgeInsets padding;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    return BoxConstraints.loose(Size(
      constraints.maxWidth - _screenMargin * 2,
      constraints.maxHeight -
          anchor.bottom -
          _gap -
          padding.bottom -
          _screenMargin,
    ));
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final maxX = (size.width - childSize.width - _screenMargin)
        .clamp(_screenMargin, double.infinity);
    final x =
        (anchor.center.dx - childSize.width / 2).clamp(_screenMargin, maxX);
    return Offset(x, anchor.bottom + _gap);
  }

  @override
  bool shouldRelayout(_AnchorCenteredLayout oldDelegate) {
    return anchor != oldDelegate.anchor || padding != oldDelegate.padding;
  }
}
