import 'package:atomic_x_core/api/live/battle_store.dart';
import 'package:atomic_x_core/api/live/co_guest_store.dart';
import 'package:atomic_x_core/api/live/co_host_store.dart';
import 'package:atomic_x_core/api/live/live_list_store.dart';
import 'package:atomic_x_core/api/live/live_seat_store.dart';
import 'package:flutter/material.dart';
import 'package:live_uikit_barrage/live_uikit_barrage.dart';
import 'package:rtc_room_engine/rtc_room_engine.dart';
import 'package:tencent_live_uikit/common/error/error_handler.dart';
import 'package:tencent_live_uikit/common/index.dart';
import 'package:tencent_live_uikit/common/screen/index.dart';
import 'package:tencent_live_uikit/live_stream/features/anchor_broadcast/co_host/co_host_management_panel_widget.dart';
import 'package:tencent_live_uikit/live_stream/features/anchor_broadcast/living_widget/more_features_panel_widget.dart';

import '../../../../common/constants/constants.dart';
import '../../../../common/language/index.dart';
import '../../../../common/resources/index.dart';
import '../../../../common/widget/base_bottom_sheet.dart';
import '../../../../common/widget/float_window/float_window_mode.dart';
import '../../../../common/widget/index.dart';
import '../../../live_define.dart';
import '../../../manager/live_stream_manager.dart';
import '../co_guest/co_guest_management_panel_widget.dart';

class AnchorBottomMenuWidget extends StatefulWidget {
  final LiveStreamManager liveStreamManager;

  const AnchorBottomMenuWidget({super.key, required this.liveStreamManager});

  @override
  State<AnchorBottomMenuWidget> createState() => _AnchorBottomMenuWidgetState();
}

class _AnchorBottomMenuWidgetState extends State<AnchorBottomMenuWidget> {
  final String kMoreFeaturesPanelWidgetName = "MoreFeaturesPanelWidget";
  late final LiveStreamManager liveStreamManager;
  late final LiveSeatStore liveSeatStore;
  late final CoGuestStore coGuestStore;
  late final CoHostStore coHostStore;
  late final BattleStore battleStore;
  BarrageSendController? _barrageSendController;
  AlertHandler? _exitBattleAlertHandler;
  BottomSheetHandler? _coHostPanelSheetHandler;
  BottomSheetHandler? _coGuestManagePanelSheetHandler;
  BottomSheetHandler? _moreFeaturesPanelSheetHandler;
  late final LiveListListener _liveListListener;
  late final VoidCallback _onFloatWindowModeChangedListener = _onFloatWindowModeChanged;

  @override
  void initState() {
    super.initState();
    liveStreamManager = widget.liveStreamManager;
    liveSeatStore = LiveSeatStore.create(liveStreamManager.roomState.roomId);
    coGuestStore = CoGuestStore.create(liveStreamManager.roomState.roomId);
    coHostStore = CoHostStore.create(liveStreamManager.roomState.roomId);
    battleStore = BattleStore.create(liveStreamManager.roomState.roomId);
    widget.liveStreamManager.floatWindowState.floatWindowMode.addListener(_onFloatWindowModeChangedListener);
    _liveListListener = LiveListListener(onLiveEnded: (String liveID, LiveEndedReason reason, String message) {
      _closeAllDialog();
    });
    LiveListStore.shared.addLiveListListener(_liveListListener);
  }

  @override
  void dispose() {
    _closeAllDialog();
    _barrageSendController = null;
    widget.liveStreamManager.floatWindowState.floatWindowMode.removeListener(_onFloatWindowModeChangedListener);
    LiveListStore.shared.removeLiveListListener(_liveListListener);
    super.dispose();
  }

  void _closeAllDialog() async {
    _exitBattleAlertHandler?.close();
    _coHostPanelSheetHandler?.close();
    _coGuestManagePanelSheetHandler?.close();
    _moreFeaturesPanelSheetHandler?.close();
  }

  void _onFloatWindowModeChanged() {
    bool isFloatWindow = widget.liveStreamManager.floatWindowState.floatWindowMode.value != FloatWindowMode.none;
    _barrageSendController?.setFloatWindowMode(isFloatWindow);
    if (isFloatWindow) {
      _coHostPanelSheetHandler?.close();
      _coGuestManagePanelSheetHandler?.close();
      if (_moreFeaturesPanelSheetHandler?.isShowing() == true) {
        Navigator.of(Global.appContext()).popUntil((Route<dynamic> route) {
          return route.settings.name == kMoreFeaturesPanelWidgetName;
        });
        _moreFeaturesPanelSheetHandler?.close();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [_buildBarrageInputWidget(), _buildFeaturesButtonWidget()],
    );
  }

  Widget _buildBarrageInputWidget() {
    return Positioned(
        left: 24.width,
        bottom: 2.height,
        child: SizedBox(
          height: 36.height,
          width: 130.width,
          child: ValueListenableBuilder(
            valueListenable: liveStreamManager.roomState.liveStatus,
            builder: (context, liveStatus, child) {
              if (liveStatus != LiveStatus.pushing) {
                return Container();
              }
              _barrageSendController ??= BarrageSendController(
                  roomId: liveStreamManager.roomState.roomId,
                  ownerId: liveStreamManager.roomState.liveInfo.liveOwner.userID,
                  selfUserId: TUIRoomEngine.getSelfInfo().userId,
                  selfName: TUIRoomEngine.getSelfInfo().userName);

              return BarrageSendWidget(controller: _barrageSendController!, parentContext: Global.appContext());
            },
          ),
        ));
  }

  Widget _buildFeaturesButtonWidget() {
    return Positioned(
      right: 27.width,
      child: Container(
          constraints: BoxConstraints(minWidth: 30.width, minHeight: 46.height),
          child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.center,
              spacing: 16.width,
              children: _generateFeaturesButtonWidgets())),
    );
  }
}

extension on _AnchorBottomMenuWidgetState {
  List<Widget> _generateFeaturesButtonWidgets() {
    final List<Widget> buttons = List.empty(growable: true);

    final coHost = ListenableBuilder(
      listenable: Listenable.merge([
        coGuestStore.coGuestState.applicants,
        liveSeatStore.liveSeatState.seatList,
        liveStreamManager.battleState.battleUsers
      ]),
      builder: (context, _) {
        final hasCoGuestApplication = coGuestStore.coGuestState.applicants.value.isNotEmpty;
        final isInBattle = liveStreamManager.battleState.battleUsers.value
            .any((user) => user.userId == TUIRoomEngine.getSelfInfo().userId);
        final isCoGuesting = liveStreamManager.isCoGuesting();
        final normalImageUrl = (isInBattle || isCoGuesting || hasCoGuestApplication)
            ? LiveImages.connectionDisable
            : LiveImages.connection;
        if (isInBattle && _coHostPanelSheetHandler?.isShowing() == true) {
          _coHostPanelSheetHandler?.close();
        }
        return BottomButtonWidget(
            normalImage: Image.asset(normalImageUrl, package: Constants.pluginName),
            normalTitle: Text(LiveKitLocalizations.of(Global.appContext())!.common_link_host,
                style: const TextStyle(fontSize: 12, color: LiveColors.designStandardFlowkitWhite),
                textAlign: TextAlign.center),
            imageSize: 28.radius,
            onPressed: () {
              _handleCoHostClick();
            });
      },
    );
    buttons.add(coHost);

    final battle = ListenableBuilder(
      listenable: Listenable.merge([
        liveStreamManager.battleState.battleUsers,
        coHostStore.coHostState.connected,
        liveStreamManager.battleState.isOnDisplayResult
      ]),
      builder: (context, _) {
        return BottomButtonWidget(
            normalImage: Image.asset(_getBattleNormalImageUrl(), package: Constants.pluginName),
            normalTitle: Text(LiveKitLocalizations.of(Global.appContext())!.common_anchor_battle,
                style: const TextStyle(fontSize: 12, color: LiveColors.designStandardFlowkitWhite),
                textAlign: TextAlign.center),
            imageSize: 28.radius,
            onPressed: () {
              _handleBattleClick();
            });
      },
    );
    buttons.add(battle);

    final coGuest = ListenableBuilder(
      listenable: Listenable.merge([coGuestStore.coGuestState.applicants, coHostStore.coHostState.connected]),
      builder: (context, _) {
        final isInCoHost = coHostStore.coHostState.connected.value.isNotEmpty;
        final normalImageUrl = isInCoHost ? LiveImages.functionLinkDisable : LiveImages.functionLinkDefault;

        return BottomButtonWidget(
            normalImage: Image.asset(normalImageUrl, package: Constants.pluginName),
            normalTitle: Text(LiveKitLocalizations.of(Global.appContext())!.common_link_guest,
                style: const TextStyle(fontSize: 12, color: LiveColors.designStandardFlowkitWhite),
                textAlign: TextAlign.center),
            imageSize: 28.radius,
            onPressed: () {
              _handleCoGuestClick();
            });
      },
    );
    buttons.add(coGuest);

    final moreFeatures = BottomButtonWidget(
        normalImage: Image.asset(LiveImages.more, package: Constants.pluginName),
        normalTitle: Text(LiveKitLocalizations.of(Global.appContext())!.common_more,
            style: const TextStyle(fontSize: 12, color: LiveColors.designStandardFlowkitWhite),
            textAlign: TextAlign.center),
        imageSize: 28.radius,
        onPressed: () {
          _showMoreFeaturesPanel();
        });
    buttons.add(moreFeatures);

    return buttons;
  }

  void _handleCoHostClick() {
    final hasCoGuestApplication = coGuestStore.coGuestState.applicants.value.isNotEmpty;
    final hasCoGuested = liveStreamManager.isCoGuesting();
    if (hasCoGuestApplication ||
        hasCoGuested ||
        liveStreamManager.battleState.battleUsers.value
            .any((user) => user.userId == TUIRoomEngine.getSelfInfo().userId)) {
      return;
    }
    _showCoHostPanel();
  }

  void _showCoHostPanel() {
    _coHostPanelSheetHandler = popupWidget(
      context: Global.appContext(),
      CoHostManagementPanelWidget(liveStreamManager: liveStreamManager),
    );
  }

  String _getBattleNormalImageUrl() {
    String imageUrl = LiveImages.battle;
    if (liveStreamManager.battleState.isOnDisplayResult.value) {
      imageUrl = LiveImages.battleDisable;
    } else {
      final isSelfInBattle = liveStreamManager.battleState.battleUsers.value
          .any((user) => user.userId == TUIRoomEngine.getSelfInfo().userId);
      if (isSelfInBattle) {
        imageUrl = LiveImages.battleExit;
      } else {
        final inSelfInConnection =
            coHostStore.coHostState.connected.value.any((user) => user.userID == TUIRoomEngine.getSelfInfo().userId);
        imageUrl = inSelfInConnection ? LiveImages.battle : LiveImages.battleDisable;
      }
    }
    return imageUrl;
  }

  void _handleBattleClick() async {
    final isOnDisplayResult = liveStreamManager.battleState.isOnDisplayResult.value;
    if (isOnDisplayResult) {
      return;
    }
    final selfUserId = TUIRoomEngine.getSelfInfo().userId;
    final isSelfInBattle = liveStreamManager.battleState.battleUsers.value.any((user) => user.userId == selfUserId);
    if (isSelfInBattle) {
      return _confirmToExitBattle();
    }
    final isSelfInCoHost = coHostStore.coHostState.connected.value.any((user) => user.userID == selfUserId);
    if (!isSelfInCoHost) {
      return;
    }

    final config = BattleConfig();
    config.needResponse = true;
    config.duration = Constants.battleDuration;
    final inviteeUserIds = coHostStore.coHostState.connected.value
        .where((user) => user.userID != selfUserId)
        .map((user) => user.userID)
        .toList();

    final result = await battleStore.requestBattle(
        config: config, userIDList: inviteeUserIds, timeout: Constants.battleRequestTimeout);
    if (result.errorCode != TUIError.success.rawValue || result.battleInfo == null) {
      return liveStreamManager.toastSubject
          .add(ErrorHandler.convertToErrorMessage(result.errorCode, result.errorMessage) ?? '');
    }
    final requestedUserList = coHostStore.coHostState.connected.value
        .where((user) => result.resultMap?.containsKey(user.userID) ?? false)
        .toList();
    liveStreamManager.onRequestBattle(result.battleInfo!.battleID, requestedUserList);
  }

  void _confirmToExitBattle() {
    const terminateBattleNumber = 1;
    const cancelNumber = 2;
    const lineColor = LiveColors.designStandardG8;
    final List<ActionSheetModel> menuData = List.empty(growable: true);
    final terminateBattle = ActionSheetModel(
        text: LiveKitLocalizations.of(Global.appContext())!.common_battle_end_pk,
        textStyle: const TextStyle(
          color: LiveColors.notStandardRed,
          fontSize: 16,
        ),
        lineColor: lineColor,
        bingData: terminateBattleNumber,
        autoPopSheet: false);
    menuData.add(terminateBattle);

    final cancel = ActionSheetModel(
        text: LiveKitLocalizations.of(Global.appContext())!.common_cancel,
        textStyle: const TextStyle(
          color: LiveColors.designStandardG2,
          fontSize: 16,
        ),
        lineColor: lineColor,
        bingData: cancelNumber);
    menuData.add(cancel);

    ActionSheet.show(menuData, (model) async {
      if (model.bingData != terminateBattleNumber) return;
      Navigator.of(Global.appContext()).pop();
      _showExitBattleAlert();
    }, backgroundColor: LiveColors.designStandardFlowkitWhite);
  }

  void _showExitBattleAlert() {
    if (_exitBattleAlertHandler?.isShowing() == true) {
      return;
    }

    final alertInfo = AlertInfo(
        description: LiveKitLocalizations.of(Global.appContext())!.common_battle_end_pk_tips,
        cancelActionInfo: (
          title: LiveKitLocalizations.of(Global.appContext())!.common_cancel,
          titleColor: LiveColors.designStandardG3
        ),
        cancelCallback: () => _exitBattleAlertHandler?.close(),
        defaultActionInfo: (
          title: LiveKitLocalizations.of(Global.appContext())!.common_battle_end_pk,
          titleColor: LiveColors.notStandardRed
        ),
        defaultCallback: () {
          battleStore.exitBattle(liveStreamManager.battleState.battleId.value);
          _exitBattleAlertHandler?.close();
        });

    _exitBattleAlertHandler = Alert.showAlert(alertInfo);
  }

  void _handleCoGuestClick() {
    if (coHostStore.coHostState.connected.value.isNotEmpty) {
      return;
    }
    _showCoGuestPanel();
  }

  void _showCoGuestPanel() {
    _coGuestManagePanelSheetHandler = popupWidget(CoGuestManagePanelWidget(liveStreamManager: liveStreamManager));
  }

  void _showMoreFeaturesPanel() {
    _moreFeaturesPanelSheetHandler = popupWidget(MoreFeaturesPanelWidget(liveStreamManager: liveStreamManager),
        routeSettings: RouteSettings(name: kMoreFeaturesPanelWidgetName));
  }
}

class BottomButtonWidget extends StatefulWidget {
  final Widget normalImage;
  final Widget? selectedImage;
  final double imageSize;
  final int markCount;
  final Widget? normalTitle;
  final Widget? selectedTitle;
  final VoidCallback? onPressed;
  final bool isSelected;
  final ValueNotifier<bool>? rotationNotifier;
  final Duration delay;

  const BottomButtonWidget(
      {super.key,
      required this.normalImage,
      required this.imageSize,
      this.markCount = 0,
      this.normalTitle,
      this.selectedTitle,
      this.selectedImage,
      this.onPressed,
      this.isSelected = false,
      this.rotationNotifier,
      this.delay = const Duration(milliseconds: 100)});

  @override
  State<BottomButtonWidget> createState() => _BottomButtonWidgetState();
}

class _BottomButtonWidgetState extends State<BottomButtonWidget> with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;
  late ValueNotifier<bool> _internalNotifier;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(duration: const Duration(seconds: 2), vsync: this);

    _internalNotifier = widget.rotationNotifier ?? ValueNotifier(false);
    _internalNotifier.addListener(_handleRotationState);
  }

  void _handleRotationState() {
    if (_internalNotifier.value) {
      _rotationController.repeat();
    } else {
      _rotationController.reset();
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    if (widget.rotationNotifier == null) {
      _internalNotifier.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.imageSize,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          RotationTransition(
              turns: _rotationController,
              child: DebounceGestureRecognizer(
                onTap: () => widget.onPressed?.call(),
                child: SizedBox(
                    width: 28.radius,
                    height: 28.radius,
                    child: widget.isSelected ? _buildSelectedImage() : widget.normalImage),
              )),
          SizedBox(height: 2.height),
          widget.isSelected ? _buildSelectedTitle() : _buildNormalTitle(),
          Visibility(
              visible: widget.markCount != 0,
              child: Positioned(
                  top: -5,
                  right: -5,
                  child: Container(
                    width: 20.radius,
                    height: 20.radius,
                    decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10.radius)),
                    child: Text(
                      widget.markCount > 99 ? '99+' : '${widget.markCount}',
                      style: const TextStyle(color: LiveColors.designStandardFlowkitWhite, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  )))
        ],
      ),
    );
  }

  void startRotate() {
    if (!_rotationController.isAnimating) {
      _rotationController.repeat();
    }
  }

  void stopRotate() {
    _rotationController.stop();
  }

  Widget _buildSelectedImage() {
    return widget.selectedImage ?? widget.normalImage;
  }

  Widget _buildNormalTitle() {
    return Visibility(
        visible: widget.normalTitle != null,
        child: Positioned(top: widget.imageSize, child: widget.normalTitle ?? Container()));
  }

  Widget _buildSelectedTitle() {
    return Visibility(
        visible: widget.normalTitle != null,
        child: Positioned(top: widget.imageSize, child: widget.selectedTitle ?? Container()));
  }
}
