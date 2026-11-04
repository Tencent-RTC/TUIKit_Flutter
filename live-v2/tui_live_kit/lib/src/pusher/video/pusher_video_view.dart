import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/widgets.dart';

import '../living/coguest/pusher_coguest_store.dart';
import '../living/coguest/seat/pusher_coguest_seat_view_provider.dart';

/// 渲染层的命令入口。
class PusherVideoController {
  PusherVideoController({required String liveID}) {
    _seatViewProvider = PusherCoGuestSeatViewProvider(coGuestVideoStateNotifier);
    coreController.setViewChangeAdapter(_seatViewProvider);
    AtomicPusher.shared.setView(widget);
  }

  final AtomicLiveController coreController = AtomicLiveController.create(AtomicLiveViewType.pushView);
  late final AtomicLiveWidget widget = AtomicLiveWidget(controller: coreController);
  late final PusherCoGuestSeatViewProvider _seatViewProvider;
  Listenable get coGuestGeometryChanges => _seatViewProvider.geometryChanges;
  List<Rect> coGuestGridRegions() => _seatViewProvider.gridRegions;
  List<Rect> coGuestSmallWindowRegions() => _seatViewProvider.regions;

  final ValueNotifier<PusherCoGuestVideoState> coGuestVideoStateNotifier = ValueNotifier<PusherCoGuestVideoState>(
    const PusherCoGuestVideoState(
      isLiving: false,
      showsEmptySeats: false,
      connectedGuestCount: 0,
      showsHostOverlay: false,
      localCameraStatus: null,
    ),
  );

  PusherCoGuestVideoState get _coGuestVideoState => coGuestVideoStateNotifier.value;
  CoGuestLayoutTemplate _layout = CoGuestLayoutTemplate.dynamicLayout;

  final ValueNotifier<String?> selectedGuestUserID = ValueNotifier<String?>(null);

  /// 由上层 Living 手势层传入全局坐标，再命中实际渲染的观众席位。
  bool selectGuestAt(Offset globalPosition) {
    final String? userID = _seatViewProvider.guestUserIDAt(globalPosition);
    if (userID == null || userID.isEmpty) {
      return false;
    }
    selectedGuestUserID.value = userID;
    return true;
  }

  void clearSelectedGuest() {
    selectedGuestUserID.value = null;
  }

  void updateCoGuestVideoState({
    required bool isLiving,
    required CoGuestLayoutTemplate layout,
    required int connectedGuestCount,
  }) {
    _layout = layout;
    final bool showsHostOverlay = layout == CoGuestLayoutTemplate.gridLayout ||
        (layout == CoGuestLayoutTemplate.dynamicLayout && connectedGuestCount > 0);
    coGuestVideoStateNotifier.value = _coGuestVideoState.copyWith(
      isLiving: isLiving,
      showsEmptySeats: layout.showsEmptySeats,
      connectedGuestCount: connectedGuestCount,
      showsHostOverlay: showsHostOverlay,
      usesSmallWindows: layout == CoGuestLayoutTemplate.floatLayout || layout == CoGuestLayoutTemplate.columnLayout,
    );
  }

  void updateLocalCameraStatus(DeviceStatus? status) {
    if (_coGuestVideoState.localCameraStatus == status) return;
    coGuestVideoStateNotifier.value = _coGuestVideoState.copyWith(localCameraStatus: status);
  }

  bool get isCoGuestStageVisible {
    final PusherCoGuestVideoState state = _coGuestVideoState;
    return showsCoGuestStage(
      isLiving: state.isLiving,
      layout: _layout,
      connectedGuestCount: state.connectedGuestCount,
    );
  }

  static bool showsCoGuestStage({
    required bool isLiving,
    required CoGuestLayoutTemplate layout,
    required int connectedGuestCount,
  }) =>
      isLiving && (connectedGuestCount > 0 || layout != CoGuestLayoutTemplate.floatLayout);

  void dispose() {
    _seatViewProvider.dispose();
    coGuestVideoStateNotifier.dispose();
    selectedGuestUserID.dispose();
  }
}

class PusherVideoView extends StatelessWidget {
  const PusherVideoView({super.key, required this.controller});

  final PusherVideoController controller;

  /// 68 工具栏内容 + 10 舞台间距 + 实际安全区；键盘不改变画布。
  static double bottomInsetOf(BuildContext context) => 78 + MediaQuery.viewPaddingOf(context).bottom;

  /// UIColor(white: 0.12, alpha: 1)
  static const Color _idleBackgroundColor = Color(0xFF1F1F1F);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<PusherCoGuestVideoState>(
      valueListenable: controller.coGuestVideoStateNotifier,
      builder: (BuildContext context, PusherCoGuestVideoState videoState, Widget? child) {
        return ColoredBox(
          color: controller.isCoGuestStageVisible ? const Color(0x00000000) : _idleBackgroundColor,
          child: controller.widget,
        );
      },
    );
  }
}
