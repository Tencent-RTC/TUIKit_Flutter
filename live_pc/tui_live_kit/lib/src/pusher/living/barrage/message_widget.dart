import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../common/widget/toast.dart';
import '../../../common/style/live_kit_style.dart';
import 'new_items_button.dart';
import 'message_input.dart';
import 'message_item.dart';
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
  bool _isFollowingLatest = true;
  int _unreadCount = 0;
  int _lastMessageCount = 0;
  bool _focused = false;
  static const int _maxMessageCount = 2000;
  static const double _bottomThreshold = 24;

  @override
  void initState() {
    super.initState();
    _store = BarrageStore.create(widget.liveID);
    _lastMessageCount = _store!.barrageState.messageList.value.length;
    _store!.barrageState.messageList.addListener(_onMessagesChanged);
    _scrollController.addListener(_onScroll);
    _focusNode.addListener(_onFocusChange);
    widget.isLiveStarted?.addListener(_onLiveStartedChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
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
    final list = _store!.barrageState.messageList.value;
    final added = list.length - _lastMessageCount;
    _lastMessageCount = list.length;
    if (_isFollowingLatest) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (_trimIfNeeded()) return;
        _scrollToBottom();
      });
      return;
    }
    if (added > 0) {
      setState(() => _unreadCount += added);
    }
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
    final atBottom = _isAtBottom();
    if (atBottom == _isFollowingLatest && !(atBottom && _unreadCount > 0)) {
      return;
    }
    setState(() {
      _isFollowingLatest = atBottom;
      if (atBottom) _unreadCount = 0;
    });
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
    _lastMessageCount = _store!.barrageState.messageList.value.length;
    _store!.barrageState.messageList.addListener(_onMessagesChanged);
    _isFollowingLatest = true;
    _unreadCount = 0;
  }

  bool get _isLiveStarted => widget.isLiveStarted?.value ?? true;

  bool _isHostMessage(Barrage barrage) {
    final hostUserID = LoginStore.shared.loginState.loginUserInfo?.userID;
    if (hostUserID == null || hostUserID.isEmpty) return false;
    return barrage.sender.userID == hostUserID;
  }

  bool _isAtBottom() {
    if (!_scrollController.hasClients) return true;
    return _scrollController.position.extentAfter <= _bottomThreshold;
  }

  void _followLatest() {
    if (!_isFollowingLatest || _unreadCount != 0) {
      setState(() {
        _isFollowingLatest = true;
        _unreadCount = 0;
      });
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_trimIfNeeded()) return;
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    final distance = position.maxScrollExtent - position.pixels;
    if (distance <= 0) return;
    if (distance > position.viewportDimension) {
      _scrollController.jumpTo(position.maxScrollExtent);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_isFollowingLatest) return;
        if (!_scrollController.hasClients) return;
        final next = _scrollController.position;
        if (next.pixels < next.maxScrollExtent) {
          _scrollController.jumpTo(next.maxScrollExtent);
        }
      });
    } else {
      _scrollController.animateTo(
        position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  final Set<String> _pendingTexts = <String>{};

  Future<void> _sendTextMessage() async {
    if (!_isLiveStarted) return;
    final text = _controller.text.trim();
    if (text.isEmpty || _pendingTexts.contains(text)) return;
    final store = _store;
    if (store == null) return;

    _pendingTexts.add(text);
    int? errorCode;
    try {
      final result = await store.sendTextMessage(text: text);
      if (!result.isSuccess) errorCode = result.errorCode;
    } on Object {
      errorCode = -1;
    }
    if (!mounted) return;
    _pendingTexts.remove(text);
    if (errorCode != null) {
      showToast(
        context,
        _sendErrorMessage(LiveKitLocalizations.of(context), errorCode),
        level: ToastLevel.warn,
      );
      return;
    }
    _controller.clear();
    _followLatest();
    _focusNode.requestFocus();
  }

  // IM / TRTC 发送错误码（腾讯云服务端定义，见 V2TIMError / TXLiteAVError）
  static const _errMuted = [10017, -2381]; // 被禁言
  static const _errAllMuted = [-2380]; // 全员禁言
  static const _errTooFrequent = [10023, 10006, 7008, 9506, -2]; // 发送太频繁
  static const _errContentRejected = [7015, 80001]; // 内容审核拒绝
  static const _errTooLong = [8001, 80002]; // 内容超长
  static const _errLoginExpired = [6014, 6206, -1002]; // 登录态过期
  static const _errLoginElsewhere = [6208]; // 异地登录被踢
  static const _errNotJoined = [-2101]; // 未加入房间
  static const _errRoomUnavailable = [10010]; // 房间不可用
  static const _errNoPermission = [10007]; // 无权限
  static const _errNetwork = [9508, 9512]; // 网络错误
  static const _errTimeout = [9510, 9518, 9519, 9520, 9521, 9523, 9524, 9525];
  static const _errSendRejected = [10016]; // 发送被拒绝

  String _sendErrorMessage(LiveKitLocalizations strings, int code) {
    if (_errMuted.contains(code)) return strings.barrageErrorMuted;
    if (_errAllMuted.contains(code)) return strings.barrageErrorAllMuted;
    if (_errTooFrequent.contains(code)) return strings.barrageErrorTooFrequent;
    if (_errContentRejected.contains(code)) {
      return strings.barrageErrorContentRejected;
    }
    if (_errTooLong.contains(code)) return strings.barrageErrorTooLong;
    if (_errLoginExpired.contains(code)) return strings.barrageErrorLoginExpired;
    if (_errLoginElsewhere.contains(code)) {
      return strings.barrageErrorLoginElsewhere;
    }
    if (_errNotJoined.contains(code)) return strings.barrageErrorNotJoined;
    if (_errRoomUnavailable.contains(code)) {
      return strings.barrageErrorRoomUnavailable;
    }
    if (_errNoPermission.contains(code)) return strings.barrageErrorNoPermission;
    if (_errNetwork.contains(code)) return strings.barrageErrorNetwork;
    if (_errTimeout.contains(code)) return strings.barrageErrorTimeout;
    if (_errSendRejected.contains(code)) return strings.barrageErrorSendRejected;
    return strings.barrageErrorSendFailed;
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
                        color: LiveKitStyle.textHint, fontSize: 13),
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
                      itemBuilder: (_, i) => MessageItem(
                        barrage: messages[i],
                        isHost: _isHostMessage(messages[i]),
                      ),
                    ),
                  ),
                  if (_unreadCount > 0)
                    NewItemsButton(
                      label: LiveKitLocalizations.of(context)
                          .barrageNewMessages(_unreadCount),
                      onTap: _followLatest,
                    ),
                ],
              );
            },
          ),
        ),
        Container(height: 1, color: LiveKitStyle.white5),
        MessageInput(
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
