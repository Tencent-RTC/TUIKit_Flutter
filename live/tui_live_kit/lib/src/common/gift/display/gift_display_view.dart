/// 礼物浮层容器：统一收口普通礼物胶囊与高级礼物特效。
/// 宿主提供胶囊底边与顶部裁剪边界，动画画布保持全屏。
///
/// 收礼到展示在本文件内闭环：Controller 自己订阅 AtomicXCore `GiftStore`，
/// 宿主只注入 liveID 与展示开关，不再逐层转发收礼事件。
library;

import 'dart:math' as math;

import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/widgets.dart';

import 'gift_animation_view.dart';
import 'gift_notice_view.dart';
import '../../live_kit_resources.dart';

class GiftDisplayController extends ChangeNotifier {
  GiftDisplayController({
    required this.liveID,
    GiftNoticeController? noticeController,
    GiftAnimationController? animationController,
    GiftStore? giftStore,
  })  : notice = noticeController ?? GiftNoticeController(),
        animation = animationController ?? GiftAnimationController(),
        _injectedGiftStore = giftStore;

  static const double horizontalInset = 12;
  static const double channelHeight = 44;
  static const double channelSpacing = 4;
  static const double toolbarAndMessageOffset = 86;

  /// 展示链订阅的直播间；空串表示不订阅（例如单测里的纯 UI 用法）。
  final String liveID;

  final GiftNoticeController notice;
  final GiftAnimationController animation;

  final GiftStore? _injectedGiftStore;
  GiftStore? _giftStore;
  bool _disposed = false;
  int _viewCount = 0;
  GiftListener? _listener;
  bool _isSuspended = false;
  bool _isApplicationActive = true;
  final List<_LocalGiftReservation> _localGiftReservations = <_LocalGiftReservation>[];
  int _nextReservationID = 0;
  int _presentationGeneration = 0;

  /// 解除订阅后忽略迟到回调。
  int _activationID = 0;

  /// 由浮层挂载激活订阅，宿主只传入控制器。
  void _activate() {
    if (_disposed || liveID.isEmpty || _listener != null) {
      return;
    }
    _activationID += 1;
    final int activationID = _activationID;
    final GiftStore giftStore = _injectedGiftStore ?? GiftStore.create(liveID);
    giftStore.setLanguage(LiveKitResources.giftLanguageCode);
    _giftStore = giftStore;

    final GiftListener listener = GiftListener(
      onReceiveGift: (String eventLiveID, Gift gift, int count, LiveUserInfo sender) {
        if (_activationID != activationID) {
          return;
        }
        _receive(eventLiveID, gift, count, sender);
      },
    );
    _listener = listener;
    giftStore.addGiftListener(listener);
  }

  void _deactivate() {
    _activationID += 1;
    final GiftListener? listener = _listener;
    if (listener != null) {
      _giftStore?.removeGiftListener(listener);
    }
    _listener = null;
    _giftStore = null;
    reset();
  }

  void _receive(
    String eventLiveID,
    Gift gift,
    int count,
    LiveUserInfo sender,
  ) {
    if (eventLiveID != liveID || count <= 0) {
      return;
    }
    final GiftDisplayItem event = GiftDisplayItem(
      giftID: gift.giftID,
      name: gift.name,
      iconURL: gift.iconURL,
      resourceURL: gift.resourceURL,
      coins: gift.coins,
      count: count,
      senderID: sender.userID,
      senderName: sender.userName,
      senderAvatarURL: sender.avatarURL,
    );
    final List<int> visibleCounts = _consumeLocalGiftReservations(
      comboKey: event.comboKey,
      count: event.count,
    );
    for (final int visibleCount in visibleCounts) {
      show(_copyEvent(event, count: visibleCount));
    }
  }

  /// 中断清空当前展示；恢复后只接收新礼物。
  void setSuspended(bool isSuspended) {
    if (_isSuspended == isSuspended) {
      return;
    }
    _isSuspended = isSuspended;
    resetPresentation();
  }

  void show(GiftDisplayItem gift) {
    if (_disposed || _isSuspended || !_isApplicationActive) {
      return;
    }
    notice.enqueue(gift);
    if (gift.isAdvanced) {
      animation.enqueue(gift.resourceURL);
    }
  }

  int? reserveLocalGift(GiftDisplayItem gift) {
    if (_disposed || gift.count <= 0) {
      return null;
    }
    _nextReservationID += 1;
    final int id = _nextReservationID;
    final _LocalGiftReservation reservation = _LocalGiftReservation(
      id: id,
      comboKey: gift.comboKey,
      gift: gift,
      remainingCount: gift.count,
      presentationGeneration: !_isSuspended && _isApplicationActive ? _presentationGeneration : null,
    );
    _localGiftReservations.add(reservation);
    return id;
  }

  void confirmLocalGift(int id) {
    for (int index = 0; index < _localGiftReservations.length; index++) {
      final _LocalGiftReservation reservation = _localGiftReservations[index];
      if (reservation.id != id) continue;
      if (reservation.isDisplayed) return;
      if (reservation.remainingCount <= 0) return;
      reservation.isDisplayed = true;
      if (reservation.presentationGeneration != _presentationGeneration) return;
      show(_copyEvent(reservation.gift, count: reservation.remainingCount));
      return;
    }
  }

  void cancelLocalGift(int id) {
    _removeLocalGiftReservation(id);
  }

  void updatePreviewBottomInset(double inset) {
    animation.updatePreviewBottomInset(inset);
  }

  void reset() {
    if (_disposed) return;
    _localGiftReservations.clear();
    resetPresentation();
  }

  /// 清除当前展示，不丢失尚待真实 SDK 事件对账的发送预约。
  void resetPresentation() {
    if (_disposed) return;
    _presentationGeneration += 1;
    notice.reset();
    animation.reset();
  }

  void _setApplicationActive(bool isActive) {
    if (_isApplicationActive == isActive) return;
    _isApplicationActive = isActive;
    resetPresentation();
  }

  List<int> _consumeLocalGiftReservations({
    required String comboKey,
    required int count,
  }) {
    int unconsumedCount = count;
    final List<int> visibleCounts = <int>[];
    int index = 0;
    while (index < _localGiftReservations.length && unconsumedCount > 0) {
      final _LocalGiftReservation reservation = _localGiftReservations[index];
      if (reservation.comboKey != comboKey) {
        index += 1;
        continue;
      }
      final int consumed = unconsumedCount < reservation.remainingCount ? unconsumedCount : reservation.remainingCount;
      // 聚合广播先于发送回包到达时，每个尚未展示的发送分别进入特效队列。
      // 已展示的发送仅消费数量，不能再次排入特效。
      if (!reservation.isDisplayed && reservation.presentationGeneration == _presentationGeneration && consumed > 0) {
        visibleCounts.add(consumed);
      }
      unconsumedCount -= consumed;
      reservation.remainingCount -= consumed;
      if (reservation.remainingCount == 0) {
        _localGiftReservations.removeAt(index);
      } else {
        index += 1;
      }
    }
    if (unconsumedCount > 0) visibleCounts.add(unconsumedCount);
    return visibleCounts;
  }

  void _removeLocalGiftReservation(int id) {
    for (int index = 0; index < _localGiftReservations.length; index++) {
      final _LocalGiftReservation reservation = _localGiftReservations[index];
      if (reservation.id != id) continue;
      _localGiftReservations.removeAt(index);
      return;
    }
  }

  static GiftDisplayItem _copyEvent(GiftDisplayItem gift, {required int count}) {
    return GiftDisplayItem(
      giftID: gift.giftID,
      name: gift.name,
      iconURL: gift.iconURL,
      resourceURL: gift.resourceURL,
      coins: gift.coins,
      count: count,
      senderID: gift.senderID,
      senderName: gift.senderName,
      senderAvatarURL: gift.senderAvatarURL,
    );
  }

  void _attach() {
    if (_disposed) return;
    _setApplicationActive(
      WidgetsBinding.instance.lifecycleState != AppLifecycleState.paused &&
          WidgetsBinding.instance.lifecycleState != AppLifecycleState.hidden &&
          WidgetsBinding.instance.lifecycleState != AppLifecycleState.detached,
    );
    _viewCount += 1;
    if (_viewCount == 1) _activate();
  }

  void _detach() {
    if (_disposed || _viewCount == 0) return;
    _viewCount -= 1;
    if (_viewCount == 0) _deactivate();
  }

  @override
  void dispose() {
    if (_disposed) return;
    _deactivate();
    _disposed = true;
    notice.dispose();
    animation.dispose();
    super.dispose();
  }
}

class _LocalGiftReservation {
  _LocalGiftReservation({
    required this.id,
    required this.comboKey,
    required this.gift,
    required this.remainingCount,
    required this.presentationGeneration,
  });

  final int id;
  final String comboKey;
  final GiftDisplayItem gift;
  final int? presentationGeneration;
  int remainingCount;
  bool isDisplayed = false;
}

class GiftDisplayView extends StatefulWidget {
  const GiftDisplayView({super.key, required this.controller, this.noticeBottom, this.noticeTopBoundary});

  final double? noticeBottom;
  final double? noticeTopBoundary;

  final GiftDisplayController controller;

  @override
  State<GiftDisplayView> createState() => _GiftDisplayViewState();
}

class _GiftDisplayViewState extends State<GiftDisplayView> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.controller._attach();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.controller._detach();
    super.dispose();
  }

  @override
  void didUpdateWidget(GiftDisplayView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller._detach();
      widget.controller._attach();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden || state == AppLifecycleState.detached) {
      widget.controller._setApplicationActive(false);
    } else if (state == AppLifecycleState.resumed) {
      widget.controller._setApplicationActive(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final bottom =
          widget.noticeBottom ?? MediaQuery.paddingOf(context).bottom + GiftDisplayController.toolbarAndMessageOffset;
      final noticeHeight = widget.noticeTopBoundary == null
          ? 92.0
          : math.max(0.0, constraints.maxHeight - bottom - widget.noticeTopBoundary!);
      return IgnorePointer(
          child: Stack(children: [
        Positioned(
            left: 12,
            right: 12,
            bottom: bottom,
            height: noticeHeight,
            child: ClipRect(
                child: OverflowBox(
                    alignment: Alignment.bottomLeft,
                    minHeight: 92,
                    maxHeight: 92,
                    child: Align(
                        alignment: Alignment.bottomLeft,
                        child: GiftNoticeView(controller: widget.controller.notice))))),
        Positioned.fill(child: GiftAnimationView(controller: widget.controller.animation)),
      ]));
    });
  }
}

@immutable
class GiftDisplayItem {
  const GiftDisplayItem({
    required this.giftID,
    required this.name,
    required this.iconURL,
    required this.resourceURL,
    required this.coins,
    required this.count,
    required this.senderID,
    required this.senderName,
    required this.senderAvatarURL,
  });

  final String giftID;
  final String name;
  final String iconURL;
  final String resourceURL;
  final int coins;
  final int count;
  final String senderID;
  final String senderName;
  final String senderAvatarURL;

  /// 同一送礼人送同一礼物才参与连击合并。
  String get comboKey => '${senderID}_$giftID';

  /// 带动画资源的礼物走全屏特效。
  bool get isAdvanced => resourceURL.isNotEmpty;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is GiftDisplayItem &&
        other.giftID == giftID &&
        other.name == name &&
        other.iconURL == iconURL &&
        other.resourceURL == resourceURL &&
        other.coins == coins &&
        other.count == count &&
        other.senderID == senderID &&
        other.senderName == senderName &&
        other.senderAvatarURL == senderAvatarURL;
  }

  @override
  int get hashCode => Object.hash(
        giftID,
        name,
        iconURL,
        resourceURL,
        coins,
        count,
        senderID,
        senderName,
        senderAvatarURL,
      );
}
