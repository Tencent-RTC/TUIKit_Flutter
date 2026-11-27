import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../live_kit_resources.dart';
import '../theme/live_text_input_view.dart';
import '../theme/live_theme.dart';
import '../theme/live_toast_view.dart';
import 'emoji/barrage_emoji_converter.dart';
import 'emoji/barrage_emoji_panel_view.dart';

enum BarrageInputMode { keyboard, emoji }

class BarrageInputView extends StatefulWidget {
  const BarrageInputView({
    super.key,
    required this.onDismiss,
    this.onSend,
    this.isPresented = true,
    this.initialInputMode = BarrageInputMode.keyboard,
    this.onInputBarHeightChanged,
    this.onInputBarBottomChanged,
  });

  static const double inputBarHeight = 32;
  static const int characterLimit = 200;
  static const double keyboardGap = 0;
  static const double emojiPanelHeight = 274;

  final bool isPresented;
  final BarrageInputMode initialInputMode;
  final ValueChanged<double>? onInputBarHeightChanged;
  final ValueChanged<double>? onInputBarBottomChanged;
  final VoidCallback onDismiss;
  final void Function(String text)? onSend;

  @override
  State<BarrageInputView> createState() => _BarrageInputViewState();
}

class _BarrageInputViewState extends State<BarrageInputView> {
  final _BarrageEmojiEditingController _controller = _BarrageEmojiEditingController();
  final FocusNode _focusNode = FocusNode();
  final GlobalKey _inputBarKey = GlobalKey();
  final LiveToastController _toast = LiveToastController();
  BarrageInputMode _inputMode = BarrageInputMode.keyboard;
  double _placeholderOpacity = 0;
  bool _geometryReportScheduled = false;
  double? _lastReportedHeight;
  double? _lastReportedBottom;
  double _resolvedInputBarBottom = 0;
  bool _dismissNotified = false;
  bool _isAwaitingKeyboard = false;
  double? _emojiToKeyboardBottom;
  double? _lastKeyboardHeight;
  Timer? _keyboardSettleTimer;

  static const _animationDuration = Duration(milliseconds: 250);

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
    _inputMode = widget.initialInputMode;
    _placeholderOpacity = _inputMode == BarrageInputMode.keyboard ? 0 : 0;
    if (widget.isPresented) _beginPresentation();
    _scheduleGeometryReport();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!widget.isPresented) return;
    final keyboardHeight = MediaQuery.viewInsetsOf(context).bottom;
    if (_inputMode != BarrageInputMode.keyboard) return;
    final transitionBottom = _emojiToKeyboardBottom;
    if (transitionBottom != null && keyboardHeight > 0 && keyboardHeight < transitionBottom) {
      _scheduleKeyboardSettle();
    } else {
      _keyboardSettleTimer?.cancel();
    }
    final reachedTransitionBottom = transitionBottom == null || keyboardHeight >= transitionBottom;
    if (keyboardHeight > 0 && reachedTransitionBottom) _lastKeyboardHeight = keyboardHeight;
    if (keyboardHeight > 0) {
      if (reachedTransitionBottom) _emojiToKeyboardBottom = null;
      _isAwaitingKeyboard = false;
      return;
    }
    if (_isAwaitingKeyboard) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.isPresented && _inputMode == BarrageInputMode.keyboard && !_isAwaitingKeyboard) {
        _dismiss();
      }
    });
  }

  void _scheduleKeyboardSettle() {
    _keyboardSettleTimer?.cancel();
    _keyboardSettleTimer = Timer(_animationDuration, () {
      _keyboardSettleTimer = null;
      if (!mounted || !widget.isPresented || _inputMode != BarrageInputMode.keyboard) return;
      final keyboardHeight = MediaQuery.viewInsetsOf(context).bottom;
      if (keyboardHeight <= 0 || _emojiToKeyboardBottom == null) return;
      setState(() {
        _lastKeyboardHeight = keyboardHeight;
        _emojiToKeyboardBottom = null;
      });
    });
  }

  @override
  void didUpdateWidget(BarrageInputView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isPresented && widget.isPresented) {
      _dismissNotified = false;
      _lastReportedBottom = null;
      _inputMode = widget.initialInputMode;
      _beginPresentation();
    }
    if (oldWidget.isPresented && !widget.isPresented) {
      _keyboardSettleTimer?.cancel();
      _emojiToKeyboardBottom = null;
      _isAwaitingKeyboard = false;
      _focusNode.unfocus();
    }
    _scheduleGeometryReport();
  }

  @override
  void dispose() {
    _keyboardSettleTimer?.cancel();
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.dispose();
    _toast.dispose();
    super.dispose();
  }

  void _beginPresentation() {
    _keyboardSettleTimer?.cancel();
    _emojiToKeyboardBottom = null;
    if (_inputMode == BarrageInputMode.keyboard) {
      _placeholderOpacity = 0;
      _isAwaitingKeyboard = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !widget.isPresented || _inputMode != BarrageInputMode.keyboard) return;
        setState(() => _placeholderOpacity = 1);
        _focusNode.requestFocus();
      });
    } else {
      _placeholderOpacity = 0;
      _isAwaitingKeyboard = false;
      _focusNode.unfocus();
    }
  }

  void _notifyDismiss() {
    if (_dismissNotified || !mounted || !widget.isPresented) return;
    _dismissNotified = true;
    widget.onDismiss();
  }

  void _onTextChanged() {
    if (mounted) setState(() {});
  }

  bool get _hasText => BarrageEmojiConverter.serialize(_controller.text).trim().isNotEmpty;

  double _keyboardBottom(BuildContext context) {
    final inset = MediaQuery.viewInsetsOf(context).bottom;
    final transitionBottom = _emojiToKeyboardBottom;
    if (transitionBottom != null && inset < transitionBottom) return transitionBottom;
    if (inset > 0) return inset;
    return MediaQuery.viewPaddingOf(context).bottom;
  }

  double _panelHeight(BuildContext context) {
    if (_inputMode == BarrageInputMode.emoji) {
      return _lastKeyboardHeight ?? BarrageInputView.emojiPanelHeight + MediaQuery.viewPaddingOf(context).bottom;
    }
    return math.max(_keyboardBottom(context), MediaQuery.viewPaddingOf(context).bottom);
  }

  double _inputBarBottom(BuildContext context) {
    if (_inputMode == BarrageInputMode.emoji) {
      return _lastKeyboardHeight ?? BarrageInputView.emojiPanelHeight + MediaQuery.viewPaddingOf(context).bottom;
    }
    return _keyboardBottom(context) + BarrageInputView.keyboardGap;
  }

  void _setMode(BarrageInputMode mode) {
    final modeChanged = _inputMode != mode;
    if (modeChanged) _keyboardSettleTimer?.cancel();
    if (modeChanged && _inputMode == BarrageInputMode.emoji && mode == BarrageInputMode.keyboard) {
      _emojiToKeyboardBottom = _inputBarBottom(context);
    } else if (modeChanged) {
      _emojiToKeyboardBottom = null;
    }
    if (modeChanged) {
      setState(() {
        _inputMode = mode;
        _placeholderOpacity = mode == BarrageInputMode.keyboard ? 1 : 0;
      });
    }
    if (mode == BarrageInputMode.keyboard) {
      if (modeChanged || MediaQuery.viewInsetsOf(context).bottom <= 0 || !_focusNode.hasFocus) {
        _isAwaitingKeyboard = true;
        _focusNode.requestFocus();
      } else {
        _isAwaitingKeyboard = false;
      }
    } else {
      _isAwaitingKeyboard = false;
      _focusNode.unfocus();
    }
    _scheduleGeometryReport();
  }

  void _showLimitToast() {
    if (!mounted) return;
    _toast
        .show(LiveKitResources.localizedFormat('tuilivekit.comment.character_limit', BarrageInputView.characterLimit));
  }

  void _insertEmoji(BarrageEmoji emoji) {
    final value = _controller.value;
    if (!value.composing.isCollapsed) return;
    final text = BarrageEmojiConverter.normalize(value.text);
    final selection = value.selection.isValid ? value.selection : TextSelection.collapsed(offset: text.length);
    final start = selection.start.clamp(0, text.length);
    final end = selection.end.clamp(0, text.length);
    final selectedLength = BarrageEmojiConverter.visibleLength(text.substring(start, end));
    final available = BarrageInputView.characterLimit - BarrageEmojiConverter.visibleLength(text) + selectedLength;
    if (available < 1) {
      _showLimitToast();
      return;
    }
    final updated = text.replaceRange(start, end, emoji.marker);
    _controller.value = TextEditingValue(
      text: updated,
      selection: TextSelection.collapsed(offset: start + emoji.marker.length),
    );
  }

  void _delete() {
    final value = _controller.value;
    if (!value.composing.isCollapsed) return;
    final text = value.text;
    if (text.isEmpty) return;
    final selection = value.selection.isValid ? value.selection : TextSelection.collapsed(offset: text.length);
    var start = selection.start.clamp(0, text.length);
    final end = selection.end.clamp(0, text.length);
    if (selection.isCollapsed) {
      if (start == 0) return;
      final prefix = text.substring(0, start);
      start -= prefix.characters.last.length;
    }
    _controller.value = TextEditingValue(
      text: text.replaceRange(start, end, ''),
      selection: TextSelection.collapsed(offset: start),
    );
  }

  void _send() {
    if (!_controller.value.composing.isCollapsed) return;
    final text = BarrageEmojiConverter.serialize(_controller.text).trim();
    if (text.isEmpty) {
      _setMode(BarrageInputMode.keyboard);
      return;
    }
    final limited = BarrageEmojiConverter.visiblePrefix(text, BarrageInputView.characterLimit);
    widget.onSend?.call(BarrageEmojiConverter.serialize(limited));
    _controller.clear();
    _dismiss();
  }

  void _dismiss() {
    _keyboardSettleTimer?.cancel();
    _emojiToKeyboardBottom = null;
    _isAwaitingKeyboard = false;
    _focusNode.unfocus();
    _notifyDismiss();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final inputBarHeight = _lastReportedHeight ?? BarrageInputView.inputBarHeight + 20;
      final maximumBottom = math.max(0.0, constraints.maxHeight - inputBarHeight);
      final panelHeight = math.min(_panelHeight(context), maximumBottom);
      final inputBarBottom = math.min(_inputBarBottom(context), maximumBottom);
      _resolvedInputBarBottom = inputBarBottom;
      _scheduleGeometryReport();
      return Offstage(
        offstage: !widget.isPresented,
        child: Focus(
          onKeyEvent: (node, event) {
            if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.escape) {
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
                left: 0,
                right: 0,
                bottom: 0,
                height: panelHeight,
                child: Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    BarrageEmojiPanelView(
                      isPresented: widget.isPresented,
                      onSelect: _insertEmoji,
                      onDelete: _delete,
                      onSend: _send,
                      isDeleteEnabled: _controller.text.isNotEmpty,
                      isSendEnabled: _hasText,
                    ),
                    IgnorePointer(
                      ignoring: _inputMode == BarrageInputMode.emoji,
                      child: AnimatedOpacity(
                        duration: _animationDuration,
                        opacity: _placeholderOpacity,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {},
                          child: const ColoredBox(color: _CommentComposerStyle.containerBackground),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: inputBarBottom,
                child: NotificationListener<SizeChangedLayoutNotification>(
                  onNotification: (_) {
                    _scheduleGeometryReport();
                    return false;
                  },
                  child: SizeChangedLayoutNotifier(child: _buildInputBar()),
                ),
              ),
              Positioned.fill(child: IgnorePointer(child: LiveToastView(controller: _toast))),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildInputBar() {
    return ColoredBox(
      key: _inputBarKey,
      color: _CommentComposerStyle.containerBackground,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Container(
          key: const ValueKey('barrageInputBar'),
          constraints: const BoxConstraints(minHeight: BarrageInputView.inputBarHeight),
          decoration: BoxDecoration(
            color: _CommentComposerStyle.inputBackground,
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.only(left: 12, right: 10, top: 4, bottom: 4),
          child: Row(
            children: <Widget>[
              Expanded(child: _buildTextField()),
              const SizedBox(width: 8),
              Semantics(
                button: true,
                label: LiveKitResources.localizedString(_inputMode == BarrageInputMode.keyboard
                    ? 'tuilivekit.comment.emoji_input'
                    : 'tuilivekit.comment.keyboard_input'),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _setMode(
                      _inputMode == BarrageInputMode.keyboard ? BarrageInputMode.emoji : BarrageInputMode.keyboard),
                  child: Image(
                    image: LiveKitResources.image(
                        _inputMode == BarrageInputMode.keyboard ? 'livekit_comment_emoji' : 'livekit_comment_keyboard'),
                    width: 24,
                    height: 24,
                    errorBuilder: (context, error, stackTrace) =>
                        Container(width: 20, height: 20, color: _CommentComposerStyle.placeholderForeground),
                  ),
                ),
              ),
            ],
          ),
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
          color: _CommentComposerStyle.textForeground,
          fontSize: 14,
          height: 1.2,
          fontWeight: FontWeight.w400,
          decoration: TextDecoration.none),
      placeholder: LiveKitResources.localizedString('tuilivekit.comment.friendly_placeholder'),
      placeholderColor: _CommentComposerStyle.placeholderForeground,
      cursorColor: LiveTheme.brandBlue,
      textInputAction: TextInputAction.send,
      onSubmitted: _send,
      onTap: () {
        if (_inputMode == BarrageInputMode.emoji) _setMode(BarrageInputMode.keyboard);
      },
      characterLength: BarrageEmojiConverter.visibleLength,
      characterPrefix: BarrageEmojiConverter.visiblePrefix,
      normalizeText: BarrageEmojiConverter.normalize,
    );
  }

  void _scheduleGeometryReport() {
    if (_geometryReportScheduled) return;
    _geometryReportScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _geometryReportScheduled = false;
      if (!mounted) return;
      final height = _inputBarKey.currentContext?.size?.height;
      if (height != null && height != _lastReportedHeight) {
        _lastReportedHeight = height;
        setState(() {});
        widget.onInputBarHeightChanged?.call(height);
      }
      final bottom = _resolvedInputBarBottom;
      if (bottom != _lastReportedBottom) {
        _lastReportedBottom = bottom;
        widget.onInputBarBottomChanged?.call(bottom);
      }
    });
  }
}

class _BarrageEmojiEditingController extends TextEditingController {
  @override
  TextSpan buildTextSpan({required BuildContext context, TextStyle? style, required bool withComposing}) {
    final composing = value.composing;
    if (!composing.isValid || composing.isCollapsed || composing.end > value.text.length) {
      return TextSpan(style: style, children: BarrageEmojiConverter.buildSpans(value.text));
    }
    return TextSpan(
      style: style,
      children: <InlineSpan>[
        ...BarrageEmojiConverter.buildSpans(value.text.substring(0, composing.start)),
        TextSpan(
          text: value.text.substring(composing.start, composing.end),
          style: withComposing ? const TextStyle(decoration: TextDecoration.underline) : null,
        ),
        ...BarrageEmojiConverter.buildSpans(value.text.substring(composing.end)),
      ],
    );
  }
}

class _CommentComposerStyle {
  static const containerBackground = Color(0xFFF6F6F8);
  static const inputBackground = Color(0xFFF0F0F2);
  static const textForeground = Color(0xE6000000);
  static const placeholderForeground = Color(0x66000000);
}
