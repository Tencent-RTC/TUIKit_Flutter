/// 评论输入：透明拦截层 + 跟随键盘的圆角输入条 + 渐变发送按钮。
/// 视觉依据 Ardot `126:1844 hostCommentInputBar`，交互依据说明节点 `126:1907`。
library;

import '../theme/live_theme.dart';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../live_kit_resources.dart';
import '../theme/live_text_input_view.dart';

class BarrageInputView extends StatefulWidget {
  const BarrageInputView({
    super.key,
    required this.onDismiss,
    this.onSend,
    this.isPresented = true,
    this.onInputBarHeightChanged,
  });

  /// 输入条高度，对应 Ardot 36pt 与 iOS `Constants.inputHeight`。
  static const double inputBarHeight = 36;
  static const int characterLimit = 200;
  final bool isPresented;
  final ValueChanged<double>? onInputBarHeightChanged;

  /// 输入条与键盘顶部的间距。
  static const double keyboardGap = 4;

  /// 输入层关闭。
  final VoidCallback onDismiss;

  final void Function(String text)? onSend;

  @override
  State<BarrageInputView> createState() =>
      _BarrageInputViewState();
}

class _BarrageInputViewState extends State<BarrageInputView> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final GlobalKey _inputBarKey = GlobalKey();
  bool _heightReportScheduled = false;
  double? _lastReportedHeight;
  bool _dismissNotified = false;

  /// 对齐 Android `isAwaitingKeyboard`：展示后到键盘首次真正弹出之间，
  /// 键盘 inset 仍为 0，此时不能误判成「用户收起了键盘」。
  bool _isAwaitingKeyboard = false;

  /// Ardot `#0C0D12` 88%。
  static const Color _inputBarColor = Color(0xE00C0D12);

  /// Ardot 输入条描边，白色 8%。
  static const Color _inputBarBorderColor = Color(0x14FFFFFF);

  /// Ardot 发送按钮 45° 渐变。
  static const List<Color> _sendGradientColors = <Color>[
    LiveTheme.brandBlue,
    Color(0xFF596BFF),
  ];

  static const Size _sendButtonSize = Size(60, 28);

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
    if (widget.isPresented) {
      _isAwaitingKeyboard = true;
      _requestFocus();
    }
    _reportHeight();
  }

  /// 对齐 Android `handleKeyboardVisibility`：系统键盘收起（如 Android 导航栏
  /// 收起键）不会让 Flutter 输入框失焦，只能通过键盘 inset 归零来判定。
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!widget.isPresented) return;
    if (MediaQuery.viewInsetsOf(context).bottom > 0) {
      _isAwaitingKeyboard = false;
      return;
    }
    if (_isAwaitingKeyboard) return;
    // onDismiss 会触发宿主 setState，不能在依赖变更阶段同步调用。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.isPresented && !_isAwaitingKeyboard) _dismiss();
    });
  }

  void _notifyDismiss() {
    if (_dismissNotified || !mounted || !widget.isPresented) return;
    _dismissNotified = true;
    widget.onDismiss();
  }

  void _requestFocus() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.isPresented) _focusNode.requestFocus();
    });
  }

  @override
  void didUpdateWidget(BarrageInputView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isPresented && widget.isPresented) {
      _dismissNotified = false;
      _isAwaitingKeyboard = true;
      _requestFocus();
    }
    if (oldWidget.isPresented && !widget.isPresented) {
      _isAwaitingKeyboard = false;
      _focusNode.unfocus();
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {});
  }

  bool get _hasText => _controller.text.trim().isNotEmpty;

  void _send() {
    if (!_controller.value.composing.isCollapsed) return;
    final String text = _controller.text
        .trim()
        .characters
        .take(BarrageInputView.characterLimit)
        .toString();
    if (text.isEmpty) {
      return;
    }
    widget.onSend?.call(text);
    _controller.clear();
    _dismiss();
  }

  void _dismiss() {
    _isAwaitingKeyboard = false;
    _focusNode.unfocus();
    _notifyDismiss();
  }

  @override
  Widget build(BuildContext context) {
    return Offstage(
        offstage: !widget.isPresented,
        child: Focus(
            onKeyEvent: (node, event) {
              if (event is KeyDownEvent &&
                  event.logicalKey == LogicalKeyboardKey.escape) {
                _dismiss();
                return KeyEventResult.handled;
              }
              return KeyEventResult.ignored;
            },
            child: Stack(
              children: <Widget>[
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _dismiss,
                    child: const SizedBox.expand(),
                  ),
                ),
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: math.max(MediaQuery.viewInsetsOf(context).bottom,
                          MediaQuery.viewPaddingOf(context).bottom) +
                      BarrageInputView.keyboardGap,
                  child: NotificationListener<SizeChangedLayoutNotification>(
                      onNotification: (_) {
                        _reportHeight();
                        return false;
                      },
                      child: SizeChangedLayoutNotifier(
                          child: DecoratedBox(
                        key: _inputBarKey,
                        decoration: BoxDecoration(
                          color: _inputBarColor,
                          borderRadius: BorderRadius.circular(
                            BarrageInputView.inputBarHeight / 2,
                          ),
                          border: Border.all(color: _inputBarBorderColor),
                          boxShadow: const <BoxShadow>[
                            BoxShadow(
                              color: Color(0x4D000000),
                              offset: Offset(0, 9),
                              blurRadius: 14,
                            ),
                          ],
                        ),
                        child: Row(
                          children: <Widget>[
                            _buildCancelButton(),
                            Expanded(
                                child: Padding(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 8),
                                    child: _buildTextField())),
                            const SizedBox(width: 8),
                            _buildSendButton(),
                            const SizedBox(width: 6),
                          ],
                        ),
                      ))),
                ),
              ],
            )));
  }

  /// 视觉中心距输入条左边 19pt，命中区放大。
  Widget _buildCancelButton() {
    return Semantics(
      label: LiveKitResources.localizedString('tuilivekit.comment.cancel'),
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _dismiss,
        child: const SizedBox(
          width: 36,
          height: BarrageInputView.inputBarHeight,
          child: Padding(
              padding: EdgeInsets.only(left: 2),
              child: Center(
                child: Text(
                  '\u00D7',
                  style: TextStyle(
                    color: Color(0x94FFFFFF),
                    fontSize: 18,
                    height: 1,
                    decoration: TextDecoration.none,
                  ),
                ),
              )),
        ),
      ),
    );
  }

  Widget _buildTextField() {
    return LiveTextInputView(
      controller: _controller,
      focusNode: _focusNode,
      characterLimit: BarrageInputView.characterLimit,
      maximumLines: 4,
      minimumHeight: 20,
      limitMessageKey: 'tuilivekit.comment.character_limit',
      style: const TextStyle(
          color: Colors.white, fontSize: 14, height: 1.2, fontWeight: FontWeight.w600),
      placeholder: LiveKitResources.localizedString(
          'tuilivekit.comment.friendly_placeholder'),
      textInputAction: TextInputAction.send,
      onSubmitted: _send,
    );
  }

  void _reportHeight() {
    if (_heightReportScheduled) return;
    _heightReportScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _heightReportScheduled = false;
      if (!mounted) return;
      final height = _inputBarKey.currentContext?.size?.height;
      if (height == null || height == _lastReportedHeight) return;
      _lastReportedHeight = height;
      widget.onInputBarHeightChanged?.call(height);
    });
  }

  Widget _buildSendButton() {
    return Opacity(
      opacity: _hasText ? 1 : 0.45,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _hasText ? _send : null,
        child: Container(
          width: _sendButtonSize.width,
          height: _sendButtonSize.height,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.bottomLeft,
              end: Alignment.topRight,
              colors: _sendGradientColors,
            ),
            borderRadius: BorderRadius.circular(_sendButtonSize.height / 2),
          ),
          child: Center(
            child: Text(
              LiveKitResources.localizedString('tuilivekit.common.send'),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.none,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
