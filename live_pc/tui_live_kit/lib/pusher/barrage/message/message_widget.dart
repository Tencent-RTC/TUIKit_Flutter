import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../pusher_style.dart';
import '../../../l10n/live_kit_localizations.dart';

class MessageWidget extends StatefulWidget {
  final String liveID;
  final ValueListenable<bool>? isLiveStarted;

  const MessageWidget({super.key, this.liveID = '', this.isLiveStarted});

  @override
  State<MessageWidget> createState() => _MessageWidgetState();
}

class _MessageWidgetState extends State<MessageWidget> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  BarrageStore? _store;
  bool _isUserScrolling = false;
  bool _focused = false;
  static const int _maxMessageCount = 2000;
  static const int _smoothScrollMaxCount = 100;
  int _lastMessageCount = 0;

  @override
  void initState() {
    super.initState();
    _store = BarrageStore.create(widget.liveID);
    _store!.barrageState.messageList.addListener(_onMessagesChanged);
    _scrollController.addListener(_onScroll);
    _focusNode.addListener(_onFocusChange);
    widget.isLiveStarted?.addListener(_onLiveStartedChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _jumpToBottom());
  }

  @override
  void dispose() {
    _store?.barrageState.messageList.removeListener(_onMessagesChanged);
    _scrollController.removeListener(_onScroll);
    _focusNode.removeListener(_onFocusChange);
    widget.isLiveStarted?.removeListener(_onLiveStartedChanged);
    _scrollController.dispose();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onMessagesChanged() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_trimIfNeeded()) return;
      if (!_isUserScrolling) _scrollToBottomAdaptive();
    });
  }

  bool _trimIfNeeded() {
    final notifier =
        _store!.barrageState.messageList as ValueNotifier<List<Barrage>>;
    final list = notifier.value;
    if (list.length <= _maxMessageCount) return false;
    notifier.value = list.sublist(list.length - _maxMessageCount);
    return true;
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    final canScroll = position.maxScrollExtent > 0;
    final isAtBottom = position.pixels >= position.maxScrollExtent - 200;
    final shouldShowButton = canScroll && !isAtBottom;

    if (shouldShowButton != _isUserScrolling) {
      setState(() => _isUserScrolling = shouldShowButton);
    }
  }

  void _onFocusChange() {
    if (_focused != _focusNode.hasFocus) {
      setState(() => _focused = _focusNode.hasFocus);
    }
  }

  void _onLiveStartedChanged() {
    if (widget.isLiveStarted?.value == true) {
      _rebuildBarrageStore();
    }
    setState(() {});
  }
  
  void _rebuildBarrageStore() {
    _store?.barrageState.messageList.removeListener(_onMessagesChanged);
    _store = BarrageStore.create(widget.liveID);
    _store!.barrageState.messageList.addListener(_onMessagesChanged);
    _lastMessageCount = 0;
  }

  bool get _isLiveStarted => widget.isLiveStarted?.value ?? true;

  void _scrollToBottomAdaptive() {
    if (!_scrollController.hasClients) return;
    final currentCount = _store!.barrageState.messageList.value.length;
    final delta = currentCount - _lastMessageCount;
    _lastMessageCount = currentCount;
    if (delta <= 0) return;

    final max = _scrollController.position.maxScrollExtent;
    if (delta < _smoothScrollMaxCount) {
      _scrollController.animateTo(
        max,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    } else {
      _scrollController.jumpTo(max);
    }
  }

  void _jumpToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendTextMessage() {
    if (!_isLiveStarted) return;
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    _controller.clear();
    setState(() => _isUserScrolling = false);
    _store?.sendTextMessage(text: text);
    _scrollToBottom();
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ValueListenableBuilder<List<Barrage>>(
            valueListenable: _store!.barrageState.messageList,
            builder: (context, messages, _) {
              if (messages.isEmpty) {
                return Center(
                  child: Text(
                    LiveKitLocalizations.of(context).barrageEmpty,
                    style: const TextStyle(
                        color: PusherStyle.textHint, fontSize: 13),
                  ),
                );
              }
              return Stack(
                children: [
                  RepaintBoundary(
                    child: ListView.builder(
                      controller: _scrollController,
                      addAutomaticKeepAlives: false,
                      cacheExtent: 300,
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                      itemCount: messages.length,
                      itemBuilder: (_, i) => _MessageItem(
                        barrage: messages[i],
                      ),
                    ),
                  ),
                  if (_isUserScrolling)
                    Positioned(
                      bottom: 12,
                      right: 12,
                      child: GestureDetector(
                        onTap: () {
                          setState(() => _isUserScrolling = false);
                          _scrollToBottom();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: PusherStyle.brand,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: const [
                              BoxShadow(
                                color: PusherStyle.shadowBlack,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.arrow_downward,
                                size: 12,
                                color: PusherStyle.whitePure,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                LiveKitLocalizations.of(context)
                                    .barrageBackToBottom,
                                style: const TextStyle(
                                  color: PusherStyle.whitePure,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
        Container(height: 1, color: PusherStyle.white5),
        _MessageInput(
          controller: _controller,
          focusNode: _focusNode,
          focused: _focused,
          enabled: _isLiveStarted,
          onSend: _sendTextMessage,
        ),
      ],
    );
  }

}

class _MessageItem extends StatelessWidget {
  final Barrage barrage;

  const _MessageItem({required this.barrage});

  @override
  Widget build(BuildContext context) {
    final displayName = barrage.sender.userName.isNotEmpty
        ? barrage.sender.userName
        : barrage.sender.userID;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 120),
            child: Text(
              '$displayName: ',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 12, height: 1.4, color: PusherStyle.brand),
            ),
          ),
          Expanded(
            child: Text(
              barrage.textContent,
              style: const TextStyle(
                fontSize: 12,
                height: 1.4,
                color: PusherStyle.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageInput extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool focused;
  final bool enabled;
  final VoidCallback onSend;

  const _MessageInput({
    required this.controller,
    required this.focusNode,
    required this.focused,
    required this.enabled,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    const Color accent = PusherStyle.brand;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 32,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: PusherStyle.white8,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: focused ? accent : PusherStyle.white10,
                  width: focused ? 1.2 : 0.8,
                ),
              ),
              child: Center(
                child: Theme(
                  data: Theme.of(context).copyWith(
                    focusColor: PusherStyle.transparent,
                    hoverColor: PusherStyle.transparent,
                    splashColor: PusherStyle.transparent,
                    highlightColor: PusherStyle.transparent,
                  ),
                  child: TextField(
                    controller: controller,
                    focusNode: focusNode,
                    enabled: enabled,
                    style: const TextStyle(color: PusherStyle.whitePure, fontSize: 12),
                    cursorColor: PusherStyle.brand,
                    onSubmitted: (_) => onSend(),
                    decoration: InputDecoration(
                      isCollapsed: true,
                      filled: false,
                      fillColor: PusherStyle.transparent,
                      contentPadding: EdgeInsets.zero,
                      border: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      focusedErrorBorder: InputBorder.none,
                      hintText: LiveKitLocalizations.of(context).barrageInputHint,
                      hintStyle: const TextStyle(
                        color: PusherStyle.textTertiary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          MouseRegion(
            cursor: enabled
                ? SystemMouseCursors.click
                : SystemMouseCursors.forbidden,
            child: GestureDetector(
              onTap: enabled ? onSend : null,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: PusherStyle.white10,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.send_rounded,
                  color: PusherStyle.whitePure.withAlpha(enabled ? 235 : 100),
                  size: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
