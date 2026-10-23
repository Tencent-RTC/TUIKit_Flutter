/// 评论列表：等级徽章、主播徽章、气泡行、顶部渐隐、跟随最新与未读提示。
///
/// 视图只消费消息模型，不持有房间 Store。
library;

import '../theme/live_theme.dart';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../gift/gift_barrage_store.dart';
import '../live_image_loader.dart';
import '../live_kit_resources.dart';
import '../theme/level_badge_view.dart';

/// All coordinates use the interaction host's local coordinate system.
class LiveInteractionLayout {
  LiveInteractionLayout(
      {required double? topBoundary,
      required double bottom,
      double defaultCommentHeight = 184,
      required double contentHeight,
      required bool isWelcomeVisible,
      required double giftNoticeHeight,
      required double safeBottom}) {
    commentHeight = topBoundary == null ? defaultCommentHeight : math.max(0, bottom - topBoundary);
    final welcomeReservation = isWelcomeVisible ? 32.0 : 0.0;
    final giftReservation = giftNoticeHeight > 0 ? giftNoticeHeight + 4 : 0.0;
    visibleCommentHeight =
        topBoundary == null ? null : math.max(0, bottom - topBoundary - welcomeReservation - giftReservation);
    final used = math.min(contentHeight, visibleCommentHeight ?? commentHeight);
    welcomeTop = bottom - used - 4 - 28;
    giftNoticeBottom = math.min(safeBottom, bottom - 4) - used - welcomeReservation;
  }
  late final double commentHeight;
  late final double? visibleCommentHeight;
  late final double welcomeTop;
  late final double giftNoticeBottom;
}

class LiveMessage {
  const LiveMessage({
    required this.id,
    required this.userName,
    required this.content,
    required this.level,
    this.isHost = false,
    this.gift,
    this.isSystemAnnouncement = false,
  });

  final String id;
  final String userName;
  final String content;
  final int? level;
  final bool isHost;
  final bool isSystemAnnouncement;

  /// 非空表示这一条渲染为礼物评论行。
  final LiveGiftBarrage? gift;

  @override
  bool operator ==(Object other) {
    return other is LiveMessage &&
        other.id == id &&
        other.userName == userName &&
        other.content == content &&
        other.level == level &&
        other.isHost == isHost &&
        other.isSystemAnnouncement == isSystemAnnouncement &&
        other.gift == gift;
  }

  @override
  int get hashCode => Object.hash(id, userName, content, level, isHost, gift, isSystemAnnouncement);
}

class BarrageStreamView extends StatefulWidget {
  const BarrageStreamView({
    super.key,
    required this.messages,
    this.onVisibleContentHeightChanged,
    this.onContentHeightChanged,
    this.maximumVisibleHeight,
  });

  final List<LiveMessage> messages;
  final double? maximumVisibleHeight;
  final ValueChanged<double>? onContentHeightChanged;

  /// 上报当前可见评论内容高度，供入场横幅避让。
  final void Function(double height)? onVisibleContentHeightChanged;

  static const double defaultWidthRatio = 0.8;

  static const int maximumMessageCount = 100;
  static const int contentCharacterLimit = 200;
  static const double bottomThreshold = 8;
  static const double topFadeHeight = 22;

  static const double messageRowSpacing = 2;

  @override
  State<BarrageStreamView> createState() => _BarrageStreamViewState();
}

class _BarrageStreamViewState extends State<BarrageStreamView> {
  final ScrollController _scrollController = ScrollController();

  /// 用于按行做可见锚点定位。
  final Map<String, GlobalKey> _rowKeys = <String, GlobalKey>{};
  final GlobalKey _contentKey = GlobalKey();

  List<LiveMessage> _messages = <LiveMessage>[];
  int _unreadCount = 0;
  bool _isFollowingLatest = true;
  bool _isUserScrolling = false;
  int _scrollRequest = 0;
  _VisibleAnchor? _readingAnchor;
  double _lastContentHeight = -1;
  double _clipTop = 0;
  Size _lastViewportSize = Size.zero;

  double _lastVisibleContentHeight = -1;
  bool _contentSizeRefreshScheduled = false;

  @override
  void initState() {
    super.initState();
    _messages = widget.messages.length > BarrageStreamView.maximumMessageCount
        ? widget.messages.sublist(widget.messages.length - BarrageStreamView.maximumMessageCount)
        : List<LiveMessage>.of(widget.messages);
    _scheduleScrollToLatest(animated: false);
  }

  @override
  void didUpdateWidget(BarrageStreamView oldWidget) {
    super.didUpdateWidget(oldWidget);
    _bind(widget.messages);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _bind(List<LiveMessage> messages) {
    final List<LiveMessage> nextMessages = messages.length > BarrageStreamView.maximumMessageCount
        ? messages.sublist(messages.length - BarrageStreamView.maximumMessageCount)
        : List<LiveMessage>.of(messages);
    if (_isSameMessages(_messages, nextMessages)) {
      return;
    }

    final bool wasEmpty = _messages.isEmpty;
    final bool wasFollowingLatest = _isFollowingLatest;
    final int addedCount = _numberOfNewMessages(_messages, nextMessages);
    final bool latestIsHost = nextMessages.isNotEmpty &&
        nextMessages.last.isHost &&
        !_messages.any((message) => message.id == nextMessages.last.id);
    // 非跟随态先记录当前可见位置，重建后再恢复。
    final _VisibleAnchor? visibleAnchor =
        wasFollowingLatest ? null : _captureVisibleAnchor(retainedIDs: nextMessages.map((m) => m.id).toSet());

    setState(() {
      _messages = nextMessages;
      if (wasEmpty || wasFollowingLatest || latestIsHost) {
        _isFollowingLatest = true;
        _unreadCount = 0;
      } else if (addedCount > 0) {
        _unreadCount += addedCount;
      }
    });

    if (wasEmpty || wasFollowingLatest || latestIsHost) {
      _scheduleScrollToLatest(animated: !wasEmpty);
    } else {
      _restoreVisibleAnchor(visibleAnchor);
    }
  }

  bool _isSameMessages(List<LiveMessage> lhs, List<LiveMessage> rhs) {
    if (lhs.length != rhs.length) {
      return false;
    }
    for (int index = 0; index < lhs.length; index++) {
      if (lhs[index] != rhs[index]) {
        return false;
      }
    }
    return true;
  }

  int _numberOfNewMessages(List<LiveMessage> previous, List<LiveMessage> next) {
    final ids = previous.map((message) => message.id).toSet();
    return next.where((message) => !ids.contains(message.id)).length;
  }

  bool get _isNearBottom {
    if (!_scrollController.hasClients) {
      return true;
    }
    return _scrollController.position.extentAfter <= BarrageStreamView.bottomThreshold;
  }

  bool _onScrollNotification(ScrollNotification notification) {
    if (notification is ScrollStartNotification) {
      if (notification.dragDetails != null) {
        _scrollRequest += 1;
        _isUserScrolling = true;
      }
      return false;
    }
    if (notification is ScrollUpdateNotification) {
      if (_isUserScrolling) {
        _updateFollowingState();
      }
      return false;
    }
    if (notification is ScrollEndNotification) {
      _updateFollowingState();
      _isUserScrolling = false;
    }
    return false;
  }

  void _updateFollowingState() {
    final bool isNearBottom = _isNearBottom;
    if (!isNearBottom) _readingAnchor = _captureVisibleAnchor();
    if (_isFollowingLatest == isNearBottom && !(isNearBottom && _unreadCount > 0)) {
      return;
    }
    setState(() {
      _isFollowingLatest = isNearBottom;
      if (isNearBottom) {
        _unreadCount = 0;
      }
    });
  }

  void _scrollToLatest({required bool animated}) {
    if (!_scrollController.hasClients || _messages.isEmpty) {
      return;
    }
    final double offset = _scrollController.position.maxScrollExtent;
    if (animated) {
      _scrollController.animateTo(
        offset,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    } else {
      _scrollController.jumpTo(offset);
    }
    if (!_isFollowingLatest || _unreadCount != 0) {
      setState(() {
        _isFollowingLatest = true;
        _unreadCount = 0;
      });
    }
  }

  /// Commit the latest scroll intent after the current native layout.
  void _scheduleScrollToLatest({required bool animated}) {
    _isUserScrolling = false;
    _scrollRequest += 1;
    final int request = _scrollRequest;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _scrollRequest != request || !_isFollowingLatest) {
        return;
      }
      _scrollToLatest(animated: animated);
    });
  }

  _VisibleAnchor? _captureVisibleAnchor({Set<String>? retainedIDs}) {
    if (!_scrollController.hasClients) {
      return null;
    }
    final RenderBox? content = _contentKey.currentContext?.findRenderObject() as RenderBox?;
    if (content == null) {
      return null;
    }
    final double visibleTop = _scrollController.position.pixels + _clipTop;
    for (final LiveMessage message in _messages) {
      if (retainedIDs != null && !retainedIDs.contains(message.id)) continue;
      final RenderBox? row = _rowKeys[message.id]?.currentContext?.findRenderObject() as RenderBox?;
      if (row == null) {
        continue;
      }
      final double rowTop = content.globalToLocal(row.localToGlobal(Offset.zero)).dy;
      if (rowTop + row.size.height >= visibleTop) {
        return _VisibleAnchor(
            id: message.id, distanceFromBottom: _lastViewportSize.height - rowTop + _scrollController.position.pixels);
      }
    }
    return null;
  }

  /// 新增或裁剪消息后浏览位置不跳。
  void _restoreVisibleAnchor(_VisibleAnchor? anchor) {
    _readingAnchor = anchor;
    final request = ++_scrollRequest;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || request != _scrollRequest || !_scrollController.hasClients) {
        return;
      }
      final RenderBox? content = _contentKey.currentContext?.findRenderObject() as RenderBox?;
      final RenderBox? row =
          anchor == null ? null : _rowKeys[anchor.id]?.currentContext?.findRenderObject() as RenderBox?;
      if (content == null) return;
      if (row == null || anchor == null) {
        _scrollController.jumpTo(_scrollController.position.minScrollExtent);
        return;
      }
      final double rowTop = content.globalToLocal(row.localToGlobal(Offset.zero)).dy;
      final double maximumOffset = _scrollController.position.maxScrollExtent;
      _scrollController.jumpTo(
        math.min(maximumOffset, math.max(0, rowTop - _lastViewportSize.height + anchor.distanceFromBottom)),
      );
    });
  }

  void _onNewMessageButton() {
    setState(() {
      _isFollowingLatest = true;
      _unreadCount = 0;
    });
    _scheduleScrollToLatest(animated: true);
  }

  /// 只保留在列的行 key，避免随消息裁剪泄漏。
  GlobalKey _rowKey(String id) => _rowKeys.putIfAbsent(id, () => GlobalKey());

  void _pruneRowKeys() {
    final Set<String> validIDs = <String>{for (final LiveMessage m in _messages) m.id};
    _rowKeys.removeWhere((String id, GlobalKey key) => !validIDs.contains(id));
  }

  /// 高度取行高加行距之和并被视口高度截断，变化小于 0.5 不上报。
  void _notifyVisibleContentHeightIfNeeded() {
    double rowsHeight = 0;
    int measuredRowCount = 0;
    for (final LiveMessage message in _messages) {
      final RenderBox? row = _rowKeys[message.id]?.currentContext?.findRenderObject() as RenderBox?;
      if (row == null || !row.hasSize) {
        continue;
      }
      rowsHeight += math.max(0, row.size.height);
      measuredRowCount += 1;
    }
    final double gapsHeight = math.max(0, measuredRowCount - 1) * BarrageStreamView.messageRowSpacing;
    final rawHeight = rowsHeight + gapsHeight;
    if ((_lastContentHeight - rawHeight).abs() > 0.5) {
      _lastContentHeight = rawHeight;
      widget.onContentHeightChanged?.call(rawHeight);
    }
    final double viewportHeight = _lastViewportSize == Size.zero ? double.infinity : _lastViewportSize.height;
    final double visibleContentHeight =
        math.min(math.min(viewportHeight, widget.maximumVisibleHeight ?? viewportHeight), rowsHeight + gapsHeight);
    if ((visibleContentHeight - _lastVisibleContentHeight).abs() <= 0.5) {
      return;
    }
    _lastVisibleContentHeight = visibleContentHeight;
    widget.onVisibleContentHeightChanged?.call(visibleContentHeight);
  }

  void _scheduleContentSizeRefresh() {
    if (_contentSizeRefreshScheduled) return;
    _contentSizeRefreshScheduled = true;
    // Remote image metadata can change the natural row height after layout.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _contentSizeRefreshScheduled = false;
      if (!mounted) return;
      _notifyVisibleContentHeightIfNeeded();
      if (_isFollowingLatest) {
        _scheduleScrollToLatest(animated: false);
      } else {
        _restoreVisibleAnchor(_readingAnchor);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_messages.isEmpty) {
      // 评论清空后同样要上报 0，避免横幅停在旧高度上。
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        _notifyVisibleContentHeightIfNeeded();
      });
      return const SizedBox.shrink();
    }
    _pruneRowKeys();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _notifyVisibleContentHeightIfNeeded();
    });

    return Stack(
      children: <Widget>[
        Positioned.fill(
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              // 键盘/连麦改变高度后重新贴底。
              final Size viewport = constraints.biggest;
              final visible =
                  math.min(viewport.height, widget.maximumVisibleHeight ?? viewport.height).clamp(0.0, viewport.height);
              final nextClipTop = viewport.height - visible;
              if (viewport != _lastViewportSize || nextClipTop != _clipTop) {
                final anchor = _isFollowingLatest ? null : _captureVisibleAnchor();
                _lastViewportSize = viewport;
                _clipTop = nextClipTop;
                _restoreVisibleAnchor(anchor);
                if (_isFollowingLatest && _messages.isNotEmpty) {
                  _scheduleScrollToLatest(animated: false);
                }
              }
              final double fadeEnd = math.min(
                0.5,
                BarrageStreamView.topFadeHeight / math.max(1, visible),
              );
              return ClipRect(
                  clipper: _CommentViewportClipper(_clipTop),
                  child: ShaderMask(
                    blendMode: BlendMode.dstIn,
                    shaderCallback: (Rect bounds) {
                      return LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: const <Color>[
                          Color(0x00000000),
                          Color(0xFF000000),
                          Color(0xFF000000),
                        ],
                        stops: <double>[0, fadeEnd, 1],
                      ).createShader(Rect.fromLTWH(0, _clipTop, bounds.width, math.max(1, visible)));
                    },
                    child: NotificationListener<ScrollNotification>(
                      onNotification: _onScrollNotification,
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        physics: const ClampingScrollPhysics(),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minHeight: viewport.height),
                          child: Column(
                            key: _contentKey,
                            // 消息始终贴容器底部。
                            mainAxisAlignment: MainAxisAlignment.end,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              SizedBox(height: BarrageStreamView.topFadeHeight + _clipTop),
                              for (int index = 0; index < _messages.length; index++) ...<Widget>[
                                if (index > 0) const SizedBox(height: BarrageStreamView.messageRowSpacing),
                                if (_messages[index].gift != null)
                                  NotificationListener<SizeChangedLayoutNotification>(
                                    onNotification: (_) {
                                      _scheduleContentSizeRefresh();
                                      return false;
                                    },
                                    child: SizeChangedLayoutNotifier(
                                      child: GiftCommentRow(
                                        key: _rowKey(_messages[index].id),
                                        comment: _messages[index].gift!,
                                      ),
                                    ),
                                  )
                                else
                                  _LiveMessageRow(
                                    key: _rowKey(_messages[index].id),
                                    message: _messages[index],
                                    maximumWidth: viewport.width,
                                  ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ));
            },
          ),
        ),
        if (_unreadCount > 0)
          Positioned(
            left: 0,
            bottom: 0,
            height: 26,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _onNewMessageButton,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  // UIColor(red: 0.039, green: 0.047, blue: 0.071, alpha: 0.96)
                  color: _MessageListStyle.unreadBackground,
                  borderRadius: BorderRadius.circular(13),
                  // UIColor(red: 0.61, green: 0.93, blue: 1, alpha: 0.34)
                  border: Border.all(color: _MessageListStyle.unreadBorder, width: 1),
                  boxShadow: const <BoxShadow>[
                    BoxShadow(
                      color: Color(0x61000000),
                      offset: Offset(0, 5),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    LiveKitResources.localizedFormat('tuilivekit.pusher.living.new_messages', _unreadCount),
                    style: const TextStyle(
                      color: Color(0xFFFFFFFF),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _VisibleAnchor {
  const _VisibleAnchor({required this.id, required this.distanceFromBottom});

  final String id;
  final double distanceFromBottom;
}

/// 行几何。
class _RowGeometry {
  const _RowGeometry({
    required this.width,
    required this.height,
    required this.verticalInset,
  });

  final double width;
  final double height;
  final double verticalInset;
}

class _LiveMessageRow extends StatelessWidget {
  const _LiveMessageRow({super.key, required this.message, required this.maximumWidth});

  final LiveMessage message;

  static const double _messageFontSize = 13;
  final double maximumWidth;
  static const double _horizontalInset = 6;
  static const double _minimumHeight = 21;
  static const double _badgeHeight = 18;
  static const double _badgeSpacing = 4;
  static const double _hostBadgeWidth = 35;
  static const TextStyle _textStyle = TextStyle(
    inherit: false,
    color: _MessageListStyle.messageForeground,
    fontSize: _messageFontSize,
    fontWeight: FontWeight.w600,
    decoration: TextDecoration.none,
  );

  @override
  Widget build(BuildContext context) {
    final textScaler = MediaQuery.textScalerOf(context);
    final direction = Directionality.of(context);
    final TextSpan span = _buildSpan(textScaler, direction);
    final _RowGeometry geometry = _measure(span, textScaler, direction);

    return SizedBox(
      width: geometry.width,
      height: geometry.height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          // UIColor(red: 0.039, green: 0.039, blue: 0.059, alpha: 0.34)
          color: LiveCommentRowStyle.background,
          borderRadius: BorderRadius.circular(LiveCommentRowStyle.cornerRadius),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: _horizontalInset,
            vertical: geometry.verticalInset,
          ),
          child: Text.rich(
            span,
            style: _textStyle,
            textDirection: direction,
            textScaler: textScaler,
            softWrap: true,
            overflow: TextOverflow.clip,
            semanticsLabel: '${message.userName}：$_displayContent',
          ),
        ),
      ),
    );
  }

  String get _displayContent =>
      !message.isSystemAnnouncement && message.content.characters.length > BarrageStreamView.contentCharacterLimit
          ? '${message.content.characters.take(BarrageStreamView.contentCharacterLimit)}...'
          : message.content;

  TextSpan _buildSpan(TextScaler textScaler, TextDirection direction) {
    if (message.isSystemAnnouncement) {
      return TextSpan(
          text: LiveCommentRowStyle.wrappableText(message.content),
          style: _textStyle.copyWith(color: LiveTheme.nickname));
    }
    return TextSpan(
      style: _textStyle,
      children: <InlineSpan>[
        if (message.level != null)
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Padding(
              padding: const EdgeInsets.only(right: _badgeSpacing),
              child: _CommentLevelBadge(level: message.level!),
            ),
          ),
        if (message.isHost)
          const WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Padding(
              padding: EdgeInsets.only(right: _badgeSpacing),
              child: _LiveHostBadgeView(),
            ),
          ),
        TextSpan(
          text: LiveCommentRowStyle.wrappableText('${LiveCommentRowStyle.displayUserName(message.userName)}：'),
          style: const TextStyle(
            // UIColor(red: 0.471, green: 0.847, blue: 1, alpha: 1)
            color: LiveTheme.nickname,
            fontSize: _messageFontSize,
            fontWeight: FontWeight.w600,
            decoration: TextDecoration.none,
          ),
        ),
        TextSpan(
          text: LiveCommentRowStyle.wrappableText(_displayContent),
          style: const TextStyle(
            // UIColor.white.withAlphaComponent(0.94)
            color: _MessageListStyle.messageForeground,
            fontSize: _messageFontSize,
            fontWeight: FontWeight.w600,
            decoration: TextDecoration.none,
          ),
        ),
      ],
    );
  }

  /// 宽度由列表容器扣除左右 8 内边距，高度不小于 21，
  /// 单行上下内边距 2、多行 1。
  _RowGeometry _measure(TextSpan span, TextScaler textScaler, TextDirection direction) {
    final TextPainter painter = TextPainter(
      text: span,
      textDirection: direction,
      textScaler: textScaler,
    );
    // Text.rich scales WidgetSpan children using their inherited font size.
    // Match those rendered dimensions when measuring the inline placeholders.
    final badgeScale = textScaler.scale(_messageFontSize) / _messageFontSize;
    painter.setPlaceholderDimensions(<PlaceholderDimensions>[
      if (!message.isSystemAnnouncement && message.level != null)
        PlaceholderDimensions(
          size:
              Size(LevelBadgeView.sizeForLevel(message.level!).width * 1.2 + _badgeSpacing, _badgeHeight) * badgeScale,
          alignment: PlaceholderAlignment.middle,
        ),
      if (!message.isSystemAnnouncement && message.isHost)
        PlaceholderDimensions(
          size: const Size(_hostBadgeWidth + _badgeSpacing, _badgeHeight) * badgeScale,
          alignment: PlaceholderAlignment.middle,
        ),
    ]);
    painter.layout();
    final double textWidth = math.min(math.max(1, maximumWidth - _horizontalInset * 2), painter.width.ceilToDouble());
    painter.layout(maxWidth: textWidth);
    final double textHeight = painter.height.ceilToDouble();
    painter.dispose();

    const double verticalInset = 3;
    return _RowGeometry(
      width: textWidth + _horizontalInset * 2,
      height: math.max(_minimumHeight, textHeight + verticalInset * 2),
      verticalInset: verticalInset,
    );
  }
}

class _LiveHostBadgeView extends StatelessWidget {
  const _LiveHostBadgeView();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 35,
      height: 18,
      decoration: BoxDecoration(
        // UIColor(red: 0.196, green: 0.4, blue: 0.643, alpha: 1)
        color: _MessageListStyle.hostBadgeBackground,
        borderRadius: BorderRadius.circular(9),
        // UIColor(red: 0.61, green: 0.93, blue: 1, alpha: 0.49)
        border: Border.all(color: _MessageListStyle.hostBadgeBorder, width: 1 / MediaQuery.devicePixelRatioOf(context)),
      ),
      child: Center(
        child: Text(
          LiveKitResources.localizedString('tuilivekit.common.host'),
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFFFFFFFF),
            fontSize: 10,
            fontWeight: FontWeight.bold,
            decoration: TextDecoration.none,
          ),
        ),
      ),
    );
  }
}

abstract final class LiveCommentRowStyle {
  static const background = Color(0x570A0A0F);
  static const cornerRadius = 9.0;

  static String displayUserName(String raw) {
    final name = raw.replaceAll(RegExp(r'\r\n|[\n\r\u000B\u000C\u0085\u2028\u2029]'), ' ');
    return name.characters.length > 20 ? '${name.characters.take(20)}…' : name;
  }

  // Flutter wraps at word boundaries. Zero-width break opportunities preserve
  // grapheme clusters while allowing the inline text to wrap at any character;
  // accessibility uses the unmodified message through semanticsLabel.
  static String wrappableText(String text) => text.characters.join('\u200B');
}

abstract final class _MessageListStyle {
  static const unreadBackground = Color(0xF50A0C12);
  static const unreadBorder = Color(0x579CEDFF);
  static const messageForeground = Color(0xF0FFFFFF);
  static const hostBadgeBackground = Color(0xFF3266A4);
  static const hostBadgeBorder = Color(0x7D9CEDFF);
}

/// 礼物评论行：等级徽章、送礼人、动作词、礼物名、礼物图与件数，
/// 与普通评论行共用同一条评论历史与同样的气泡底。
class GiftCommentRow extends StatefulWidget {
  const GiftCommentRow({super.key, required this.comment});

  final LiveGiftBarrage comment;

  @override
  State<GiftCommentRow> createState() => _GiftCommentRowState();
}

class _GiftCommentRowState extends State<GiftCommentRow> {
  static const double _horizontalInset = 6;
  static const double _giftImageSize = 22;
  static const double _fontSize = 13;
  static const TextStyle _textStyle = TextStyle(
    inherit: false,
    color: _GiftCommentStyle.giftForeground,
    fontSize: _fontSize,
    fontWeight: FontWeight.w600,
    decoration: TextDecoration.none,
  );
  ImageStream? _imageStream;
  ImageStreamListener? _imageListener;
  ImageInfo? _imageInfo;
  bool _showsImage = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolveImage();
  }

  @override
  void didUpdateWidget(GiftCommentRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.comment.giftIconURL != widget.comment.giftIconURL) {
      _resolveImage();
    }
  }

  void _resolveImage() {
    _releaseImage();
    _showsImage = widget.comment.giftIconURL.isNotEmpty;
    if (!_showsImage) return;
    final provider = LiveImageLoader.provider(widget.comment.giftIconURL);
    if (provider == null) {
      _showsImage = false;
      return;
    }
    final stream = provider.resolve(createLocalImageConfiguration(context));
    final listener = ImageStreamListener((image, _) {
      if (!mounted || _imageStream != stream) {
        image.dispose();
        return;
      }
      setState(() {
        _imageInfo?.dispose();
        _imageInfo = image;
      });
    }, onError: (Object error, StackTrace? stack) {
      if (!mounted || _imageStream != stream) return;
      setState(() => _showsImage = false);
    });
    _imageStream = stream;
    _imageListener = listener;
    stream.addListener(listener);
  }

  void _releaseImage() {
    if (_imageListener != null) _imageStream?.removeListener(_imageListener!);
    _imageStream = null;
    _imageListener = null;
    _imageInfo?.dispose();
    _imageInfo = null;
  }

  @override
  void dispose() {
    _releaseImage();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final comment = widget.comment;
    final senderName = comment.senderName.isNotEmpty
        ? comment.senderName
        : comment.senderID.isNotEmpty
            ? comment.senderID
            : LiveKitResources.localizedString('tuilivekit.common.viewer');
    final action = LiveKitResources.localizedString('tuilivekit.common.gift.sent');
    final scaler = MediaQuery.textScalerOf(context);
    final direction = Directionality.of(context);
    final span = TextSpan(style: _textStyle, children: [
      if (comment.senderLevel != null)
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Padding(
            padding: const EdgeInsets.only(right: 4),
            child: _CommentLevelBadge(level: comment.senderLevel!),
          ),
        ),
      TextSpan(
        text: LiveCommentRowStyle.wrappableText(LiveCommentRowStyle.displayUserName(senderName)),
        style: const TextStyle(color: LiveTheme.nickname),
      ),
      TextSpan(
        text: LiveCommentRowStyle.wrappableText(' $action '),
        style: const TextStyle(color: _GiftCommentStyle.actionForeground),
      ),
      TextSpan(text: LiveCommentRowStyle.wrappableText('${comment.giftName} ')),
      if (_showsImage) ...[
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: SizedBox(
            width: _giftImageSize,
            height: _giftImageSize,
            child: RawImage(image: _imageInfo?.image, fit: BoxFit.contain),
          ),
        ),
        const TextSpan(text: ' '),
      ],
      TextSpan(text: '×${comment.count}', style: const TextStyle(fontWeight: FontWeight.bold)),
    ]);
    return LayoutBuilder(builder: (context, constraints) {
      final scale = scaler.scale(_fontSize) / _fontSize;
      final painter = TextPainter(
        text: span,
        textDirection: direction,
        textScaler: scaler,
      )..setPlaceholderDimensions([
          if (comment.senderLevel != null)
            PlaceholderDimensions(
              size: Size(LevelBadgeView.sizeForLevel(comment.senderLevel!).width * 1.2 + 4, 18) * scale,
              alignment: PlaceholderAlignment.middle,
            ),
          if (_showsImage)
            PlaceholderDimensions(
              size: const Size(_giftImageSize, _giftImageSize) * scale,
              alignment: PlaceholderAlignment.middle,
            ),
        ]);
      painter.layout();
      final width = math.min(math.max(1.0, constraints.maxWidth - _horizontalInset * 2), painter.width.ceilToDouble());
      painter.layout(maxWidth: width);
      final height = painter.height.ceilToDouble() + 6;
      painter.dispose();
      return Container(
        width: width + _horizontalInset * 2,
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: _horizontalInset, vertical: 3),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: LiveCommentRowStyle.background,
          borderRadius: BorderRadius.circular(LiveCommentRowStyle.cornerRadius),
        ),
        child: Text.rich(span,
            textDirection: direction,
            textScaler: scaler,
            softWrap: true,
            overflow: TextOverflow.clip,
            semanticsLabel: '$senderName $action ${comment.giftName} ×${comment.count}'),
      );
    });
  }
}

abstract final class _GiftCommentStyle {
  static const actionForeground = Color(0xFFFFF4CF);
  static const giftForeground = Color(0xFFFFE7A3);
}

class _CommentLevelBadge extends StatelessWidget {
  const _CommentLevelBadge({required this.level});
  final int level;
  @override
  Widget build(BuildContext context) => SizedBox(
        width: LevelBadgeView.sizeForLevel(level).width * 1.2,
        height: 18,
        child: FittedBox(child: LevelBadgeView(level: level, isInline: true)),
      );
}

class _CommentViewportClipper extends CustomClipper<Rect> {
  const _CommentViewportClipper(this.top);
  final double top;
  @override
  Rect getClip(Size size) => Rect.fromLTWH(0, top, size.width, math.max(0, size.height - top));
  @override
  bool shouldReclip(_CommentViewportClipper old) => old.top != top;
}
