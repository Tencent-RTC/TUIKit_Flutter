/// 普通礼物胶囊：最多两条独立通道，合并键固定为 `senderID + giftID`。
/// 同一送礼人连送同一礼物时在原槽位累加件数，槽位满则排队等待。
library;

import '../../theme/live_theme.dart';
import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../live_image_loader.dart';
import '../../live_kit_resources.dart';
import 'gift_display_view.dart';

/// 视图层只读取本控制器的槽位快照，不自行编排队列。
class GiftNoticeController extends ChangeNotifier {
  static const int maximumChannelCount = 2;
  static const double itemHeight = 44;
  static const double channelSpacing = 4;
  static const Duration holdDuration = Duration(seconds: 2);
  static const Duration enterDuration = Duration(milliseconds: 520);
  static const Duration exitDuration = Duration(milliseconds: 320);
  static const Duration fadeInDuration = Duration(milliseconds: 260);

  final List<GiftNoticeSlot> _activeEntries = <GiftNoticeSlot>[];
  final List<_PendingNotice> _queue = <_PendingNotice>[];

  /// reset 之后忽略上一轮的延时回调。
  int _generation = 0;
  bool _disposed = false;

  /// 当前占用的槽位，按加入顺序排列。
  List<GiftNoticeSlot> get activeEntries =>
      List<GiftNoticeSlot>.unmodifiable(_activeEntries);

  void enqueue(GiftDisplayItem gift) {
    if (_disposed || gift.count <= 0) {
      return;
    }

    // 已在展示且未开始退场：原槽位累加件数并重新计时。
    for (final GiftNoticeSlot active in _activeEntries) {
      if (active.key == gift.comboKey && !active.isLeaving) {
        active._gift = gift;
        active._count = _addingWithoutOverflow(active.count, gift.count);
        active._bumpToken += 1;
        _scheduleExpiration(active);
        notifyListeners();
        return;
      }
    }

    // 同键槽位正在退场：立即收尾，让新的一条重新入场。
    for (final GiftNoticeSlot leaving in List<GiftNoticeSlot>.from(
      _activeEntries,
    )) {
      if (leaving.key == gift.comboKey && leaving.isLeaving) {
        _finish(leaving);
      }
    }

    for (final _PendingNotice pending in _queue) {
      if (pending.key == gift.comboKey) {
        pending.gift = gift;
        pending.count = _addingWithoutOverflow(pending.count, gift.count);
        return;
      }
    }

    final _PendingNotice pending = _PendingNotice(
      key: gift.comboKey,
      gift: gift,
      count: gift.count,
    );
    if (_activeEntries.length < maximumChannelCount) {
      _activate(pending);
    } else {
      _queue.add(pending);
    }
  }

  void reset() {
    if (_disposed) return;
    _generation += 1;
    for (final GiftNoticeSlot entry in _activeEntries) {
      entry._cancelScheduledWork();
    }
    _activeEntries.clear();
    _queue.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _generation += 1;
    for (final GiftNoticeSlot entry in _activeEntries) {
      entry._cancelScheduledWork();
    }
    _activeEntries.clear();
    _queue.clear();
    super.dispose();
  }

  void _activate(_PendingNotice pending) {
    final GiftNoticeSlot entry = GiftNoticeSlot._(
      gift: pending.gift,
      count: pending.count,
    );
    _activeEntries.add(entry);
    _scheduleExpiration(entry);
    notifyListeners();
  }

  void _scheduleExpiration(GiftNoticeSlot entry) {
    entry._expiration?.cancel();
    final int generation = _generation;
    entry._expiration = Timer(holdDuration, () {
      if (_generation != generation) {
        return;
      }
      _dismiss(entry);
    });
  }

  void _dismiss(GiftNoticeSlot entry) {
    if (!_activeEntries.contains(entry) || entry.isLeaving) {
      return;
    }
    entry._isLeaving = true;
    entry._expiration = null;
    notifyListeners();

    final int generation = _generation;
    entry._removal = Timer(exitDuration, () {
      if (_generation != generation) {
        return;
      }
      _finish(entry);
    });
  }

  void _finish(GiftNoticeSlot entry) {
    if (!_activeEntries.remove(entry)) {
      return;
    }
    entry._cancelScheduledWork();

    if (_queue.isNotEmpty) {
      _activate(_queue.removeAt(0));
      return;
    }
    notifyListeners();
  }

  static int _addingWithoutOverflow(int lhs, int rhs) {
    final int value = lhs + rhs;
    if (lhs > 0 && rhs > 0 && value < 0) {
      return 0x7FFFFFFFFFFFFFFF;
    }
    return value;
  }
}

class GiftNoticeSlot {
  GiftNoticeSlot._({required GiftDisplayItem gift, required int count})
      : key = gift.comboKey,
        _gift = gift,
        _count = count;

  final String key;

  GiftDisplayItem get gift => _gift;
  GiftDisplayItem _gift;

  int get count => _count;
  int _count;

  bool get isLeaving => _isLeaving;
  bool _isLeaving = false;

  /// 每次连击累加自增，驱动件数的放大回弹动画重放。
  int get bumpToken => _bumpToken;
  int _bumpToken = 0;

  Timer? _expiration;
  Timer? _removal;

  void _cancelScheduledWork() {
    _expiration?.cancel();
    _expiration = null;
    _removal?.cancel();
    _removal = null;
  }
}

class _PendingNotice {
  _PendingNotice({required this.key, required this.gift, required this.count});

  final String key;
  GiftDisplayItem gift;
  int count;
}

class GiftNoticeView extends StatelessWidget {
  const GiftNoticeView({super.key, required this.controller});

  final GiftNoticeController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (BuildContext context, _) {
        final List<GiftNoticeSlot> entries = controller.activeEntries;
        if (entries.isEmpty) {
          return const SizedBox.shrink();
        }
        // 底部对齐、通道间距 4。
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            for (int index = 0; index < entries.length; index++) ...<Widget>[
              if (index > 0)
                const SizedBox(height: GiftNoticeController.channelSpacing),
              SizedBox(
                height: GiftNoticeController.itemHeight,
                child: _GiftNoticeItemView(
                  key: ObjectKey(entries[index]),
                  slot: entries[index],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _GiftNoticeItemView extends StatefulWidget {
  const _GiftNoticeItemView({super.key, required this.slot});

  final GiftNoticeSlot slot;

  @override
  State<_GiftNoticeItemView> createState() => _GiftNoticeItemViewState();
}

class _GiftNoticeItemViewState extends State<_GiftNoticeItemView>
    with SingleTickerProviderStateMixin {
  static const double _slideInFraction = -1.2;

  static const double _slideOutOffset = -24;

  static const Curve _enterCurve = Cubic(0.16, 0.82, 0.22, 1);

  late final AnimationController _bumpController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  );

  double _opacity = 0;
  double _slideFraction = _slideInFraction;
  Duration _opacityDuration = Duration.zero;
  Duration _slideDuration = Duration.zero;
  Curve _slideCurve = _enterCurve;
  int _renderedBumpToken = 0;

  @override
  void initState() {
    super.initState();
    _renderedBumpToken = widget.slot.bumpToken;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _opacityDuration = GiftNoticeController.fadeInDuration;
        _slideDuration = GiftNoticeController.enterDuration;
        _slideCurve = _enterCurve;
        _opacity = 1;
        _slideFraction = 0;
      });
    });
  }

  @override
  void didUpdateWidget(_GiftNoticeItemView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.slot.isLeaving && _opacity != 0) {
      // 淡出并左移 24。
      setState(() {
        _opacityDuration = GiftNoticeController.exitDuration;
        _slideDuration = GiftNoticeController.exitDuration;
        _slideCurve = Curves.easeIn;
        _opacity = 0;
        _slideFraction = _slideOutOffset / 178;
      });
    }
    if (widget.slot.bumpToken != _renderedBumpToken) {
      _renderedBumpToken = widget.slot.bumpToken;
      _bumpController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _bumpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedOpacity(
        opacity: _opacity,
        duration: _opacityDuration,
        curve: widget.slot.isLeaving ? Curves.easeIn : Curves.easeOut,
        child: LayoutBuilder(builder: (context, constraints) {
          final width = constraints.maxWidth;
          return AnimatedSlide(
            offset: Offset(
                _slideFraction == 0
                    ? 0
                    : widget.slot.isLeaving
                        ? -24 / width
                        : -(width + 12) / width,
                0),
            duration: _slideDuration,
            curve: _slideCurve,
            child: _buildContent(),
          );
        }),
      ),
    );
  }

  Widget _buildContent() {
    final GiftDisplayItem gift = widget.slot.gift;
    final String senderName =
        gift.senderName.isEmpty ? gift.senderID : gift.senderName;

    return LayoutBuilder(builder: (context, constraints) {
      final capsuleWidth = (constraints.maxWidth - 56).clamp(0.0, 178.0);
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          SizedBox(width: capsuleWidth, child: _buildCapsule(gift, senderName)),
          // capsule 右侧 4。
          const SizedBox(width: 4),
          Transform.translate(
            offset: const Offset(0, 2),
            child: const Text(
              '×',
              style: TextStyle(
                color: Color(0xFFFFFFFF),
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 2),
          Flexible(
              child: Transform.translate(
                  offset: const Offset(0, 1), child: _buildCountLabel())),
        ],
      );
    });
  }

  Widget _buildCapsule(GiftDisplayItem gift, String senderName) {
    return Container(
      height: 44,
      decoration: const BoxDecoration(
        color: _GiftNoticeStyle.capsuleBackground,
        borderRadius: BorderRadius.all(Radius.circular(22)),
      ),
      child: Row(
        children: <Widget>[
          const SizedBox(width: 3),
          _buildAvatar(gift),
          const SizedBox(width: 7),
          Expanded(child: _buildTexts(gift, senderName)),
          const SizedBox(width: 2),
          _buildGiftImage(gift),
          const SizedBox(width: 5),
        ],
      ),
    );
  }

  Widget _buildAvatar(GiftDisplayItem gift) {
    final ImageProvider? provider = LiveImageLoader.provider(
      gift.senderAvatarURL,
    );
    final Widget fallback = Image(
      image: LiveKitResources.image('livekit_livelist_default_avatar'),
      fit: BoxFit.cover,
    );
    return SizedBox(
      width: 38,
      height: 38,
      child: ClipOval(
        child: DecoratedBox(
          position: DecorationPosition.foreground,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: _GiftNoticeStyle.avatarBorderAndDetail),
          ),
          child: provider == null
              ? fallback
              : Image(
                  image: provider,
                  fit: BoxFit.cover,
                  frameBuilder: (context, child, frame, synchronous) =>
                      frame != null || synchronous ? child : fallback,
                  errorBuilder: (context, error, stack) => fallback,
                ),
        ),
      ),
    );
  }

  Widget _buildTexts(GiftDisplayItem gift, String senderName) {
    // UIKit anchors each line to the capsule's middle independently. Centering
    // a column moves that split because the 12 pt and 9 pt lines differ in height.
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        Positioned(
          left: 0,
          right: 0,
          bottom: 23,
          child: Text(
            senderName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFFFFFFFF),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          top: 23,
          child: Text(
            LiveKitResources.localizedString(
              'tuilivekit.pusher.gift.sent',
            ).replaceFirst('%@', gift.name),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                color: _GiftNoticeStyle.avatarBorderAndDetail, fontSize: 9),
          ),
        ),
      ],
    );
  }

  Widget _buildGiftImage(GiftDisplayItem gift) {
    final ImageProvider? provider = LiveImageLoader.provider(gift.iconURL);
    const fallback = SizedBox(
        width: 37, height: 37, child: Center(child: _GiftFallbackView()));
    if (provider == null) return fallback;
    return Image(
      image: provider,
      width: 37,
      height: 37,
      fit: BoxFit.contain,
      frameBuilder: (context, child, frame, synchronous) =>
          frame != null || synchronous ? child : fallback,
      errorBuilder: (_, __, ___) => fallback,
    );
  }

  Widget _buildCountLabel() {
    return AnimatedBuilder(
      animation: _bumpController,
      builder: (BuildContext context, Widget? child) {
        // 前 45% 放大到 1.24 并转为高亮蓝，后 55% 回落。
        final double t = _bumpController.value;
        final double scale = t <= 0.45
            ? 1 + 0.24 * (t / 0.45)
            : 1.24 - 0.24 * ((t - 0.45) / 0.55);
        final Color color = t <= 0.45
            ? Color.lerp(
                const Color(0xFFFFFFFF),
                _GiftNoticeStyle.countHighlight,
                t / 0.45,
              )!
            : Color.lerp(
                _GiftNoticeStyle.countHighlight,
                const Color(0xFFFFFFFF),
                (t - 0.45) / 0.55,
              )!;
        return LayoutBuilder(builder: (context, constraints) {
          final text = '${widget.slot.count}';
          final style = TextStyle(
            color:
                _bumpController.isAnimating ? color : const Color(0xFFFFFFFF),
            fontSize: 26,
            fontWeight: FontWeight.w800,
            fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
            shadows: const <Shadow>[
              Shadow(
                color: Color(0x8C000000),
                offset: Offset(0, 2),
                blurRadius: 4,
              ),
            ],
          );
          final painter = TextPainter(
            text: TextSpan(
                text: text,
                style: DefaultTextStyle.of(context).style.merge(style)),
            textDirection: Directionality.of(context),
            textScaler: MediaQuery.textScalerOf(context),
            maxLines: 1,
          )..layout();
          final fontScale = painter.width > constraints.maxWidth
              ? (constraints.maxWidth / painter.width).clamp(0.6, 1.0)
              : 1.0;
          painter.dispose();
          // UILabel adjustsFontSizeToFitWidth stops at minimumScaleFactor .6;
          // an unrestricted FittedBox would make large counts illegibly small.
          return ConstrainedBox(
            constraints:
                BoxConstraints(minWidth: constraints.maxWidth.clamp(0.0, 28.0)),
            child: Transform.scale(
              scale: _bumpController.isAnimating ? scale : 1,
              child: Text(text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: style.copyWith(fontSize: 26 * fontScale)),
            ),
          );
        });
      },
    );
  }
}

class _GiftFallbackView extends StatelessWidget {
  const _GiftFallbackView();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[LiveTheme.brandBlue, Color(0xFF825AF5)],
        ),
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      child: Center(
        child: Text(
          LiveKitResources.localizedString('tuilivekit.pusher.gift.fallback'),
          style: const TextStyle(
            color: Color(0xFFFFFFFF),
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

abstract final class _GiftNoticeStyle {
  static const countHighlight = Color(0xFF78D9FF);
  static const capsuleBackground = Color(0x47080A0F);
  static const avatarBorderAndDetail = Color(0xB8FFFFFF);
}
