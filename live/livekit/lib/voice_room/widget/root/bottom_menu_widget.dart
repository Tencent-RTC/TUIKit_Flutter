import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/material.dart';
import 'package:live_uikit_gift/live_uikit_gift.dart';
import 'package:tencent_live_uikit/common/index.dart';
import 'package:tencent_live_uikit/common/widget/base_bottom_sheet.dart';
import 'package:tencent_live_uikit/component/audio_effect/audio_effect_panel_widget.dart';
import 'package:tencent_live_uikit/voice_room/manager/index.dart';
import 'package:tencent_live_uikit/voice_room/widget/panel/live_background_select_widget.dart';
import 'package:tencent_live_uikit/voice_room/widget/panel/seat_management_panel_widget.dart';
import 'package:tencent_live_uikit/voice_room/widget/panel/settings_panel_widget.dart';
import 'package:rtc_room_engine/rtc_room_engine.dart';

class BottomMenuWidget extends StatefulWidget {
  final String liveID;
  final VoiceRoomViewStore viewStore;
  final ToastService toastService;
  final bool isOwner;

  const BottomMenuWidget(
      {super.key, required this.liveID, required this.viewStore, required this.toastService, required this.isOwner});

  @override
  State<BottomMenuWidget> createState() => _BottomMenuWidgetState();
}

class _BottomMenuWidgetState extends State<BottomMenuWidget> {
  GiftListController? _giftListController;
  LikeSendController? _likeSendController;

  DeviceStore get _deviceStore => DeviceStore.shared;

  LiveListStore get _liveListStore => LiveListStore.shared;

  CoGuestStore get _coGuestStore => CoGuestStore.create(widget.liveID);

  late LiveListListener _liveListener;
  BottomSheetHandler? _seatManagementPanelHandler;
  BottomSheetHandler? _settingsPanelHandler;
  BottomSheetHandler? _liveBackgroundSelectPanelHandler;
  BottomSheetHandler? _audioEffectPanelHandler;

  @override
  void initState() {
    super.initState();
    _liveListener = LiveListListener(onLiveEnded: (liveID, reason, message) {
      _seatManagementPanelHandler?.close();
      _settingsPanelHandler?.close();
      _liveBackgroundSelectPanelHandler?.close();
      _audioEffectPanelHandler?.close();
    });
    _liveListStore.addLiveListListener(_liveListener);
  }

  @override
  void dispose() {
    _liveListStore.removeLiveListListener(_liveListener);
    _likeSendController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_giftListController == null) {
      final language = DeviceLanguage.getCurrentLanguageCode(context);
      _giftListController = GiftListController(roomId: widget.liveID, language: language);
    }
    _likeSendController ??= LikeSendController(roomId: widget.liveID);
    return Container(
        constraints: BoxConstraints(minWidth: 30.width, minHeight: 46.height),
        width: 50.width,
        height: 46.height,
        child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.center,
            spacing: 16.width,
            children: _generateBottomButtonWidgets()));
  }
}

extension on _BottomMenuWidgetState {
  List<Widget> _generateBottomButtonWidgets() {
    return widget.isOwner ? _generateOwnerBottomButtonWidgets() : _generateMemberBottomButtonWidgets();
  }

  List<Widget> _generateOwnerBottomButtonWidgets() {
    final List<Widget> buttons = List.empty(growable: true);

    final setting = BottomButtonWidget(
        normalImage: Image.asset(LiveImages.functionSettings, package: Constants.pluginName),
        normalTitle: Text(LiveKitLocalizations.of(Global.appContext())!.common_settings,
            style: const TextStyle(fontSize: 12, color: LiveColors.designStandardFlowkitWhite),
            textAlign: TextAlign.center),
        imageSize: 28.radius,
        onPressed: () {
          _showSettingsPanel();
        });
    buttons.add(setting);

    final seatManagement = ValueListenableBuilder(
      valueListenable: _coGuestStore.coGuestState.applicants,
      builder: (context, applications, _) {
        final filterApplications =
            applications.toList().where((application) => application.userID != TUIRoomEngine.getSelfInfo().userId);
        return BottomButtonWidget(
            normalImage: Image.asset(LiveImages.functionSeatManagement, package: Constants.pluginName),
            normalTitle: Text(LiveKitLocalizations.of(Global.appContext())!.common_seat_management,
                style: const TextStyle(fontSize: 12, color: LiveColors.designStandardFlowkitWhite),
                textAlign: TextAlign.center),
            imageSize: 28.radius,
            markCount: filterApplications.length,
            onPressed: () {
              _showSeatManagementPanel();
            });
      },
    );
    buttons.add(seatManagement);

    return buttons;
  }

  List<Widget> _generateMemberBottomButtonWidgets() {
    final List<Widget> buttons = List.empty(growable: true);
    final imageSize = 28.radius;

    final gift = SizedBox(
      height: imageSize,
      child: Stack(alignment: Alignment.center, clipBehavior: Clip.none, children: [
        SizedBox(
          width: imageSize,
          height: imageSize,
          child: GiftSendWidget(
            controller: _giftListController!,
            parentContext: Global.appContext(),
            icon: Image.asset(LiveImages.functionGift, package: Constants.pluginName),
          ),
        ),
        Positioned(
          top: imageSize,
          child: Text(LiveKitLocalizations.of(Global.appContext())!.common_gift_title,
              style: const TextStyle(fontSize: 12, color: LiveColors.designStandardFlowkitWhite),
              textAlign: TextAlign.center),
        ),
      ]),
    );
    buttons.add(gift);

    final like = SizedBox(
      height: imageSize,
      child: Stack(alignment: Alignment.center, clipBehavior: Clip.none, children: [
        SizedBox(
          width: imageSize,
          height: imageSize,
          child: LikeSendWidget(
            controller: _likeSendController!,
            icon: Image.asset(LiveImages.functionLike, package: Constants.pluginName),
          ),
        ),
        Positioned(
          top: imageSize,
          child: Text(LiveKitLocalizations.of(Global.appContext())!.common_like,
              style: const TextStyle(fontSize: 12, color: LiveColors.designStandardFlowkitWhite),
              textAlign: TextAlign.center),
        ),
      ]),
    );
    buttons.add(like);

    final ValueNotifier<bool> rotationNotifier = ValueNotifier(false);
    widget.viewStore.state.isApplyingToTakeSeat.addListener(() {
      rotationNotifier.value = widget.viewStore.state.isApplyingToTakeSeat.value;
    });

    final linkMic = ListenableBuilder(
        listenable:
            Listenable.merge([widget.viewStore.state.isApplyingToTakeSeat, _coGuestStore.coGuestState.connected]),
        builder: (context, _) {
          final isApplying = widget.viewStore.state.isApplyingToTakeSeat.value;
          final isOnSeat = _coGuestStore.coGuestState.connected.value
              .any((seatUserInfo) => seatUserInfo.userID == TUIRoomEngine.getSelfInfo().userId);
          final normalImageUrl = isOnSeat ? LiveImages.functionLinked : LiveImages.functionVoiceRoomLink;

          final hangupLocalization = LiveKitLocalizations.of(Global.appContext())!.common_hang_up;
          final linkMicLocalization = LiveKitLocalizations.of(Global.appContext())!.common_link;
          final normalTitle = isOnSeat ? hangupLocalization : linkMicLocalization;
          return BottomButtonWidget(
              normalImage: Image.asset(normalImageUrl, package: Constants.pluginName),
              selectedImage: Image.asset(LiveImages.functionVoiceRoomLinking, package: Constants.pluginName),
              normalTitle: Text(normalTitle,
                  style: const TextStyle(fontSize: 12, color: LiveColors.designStandardFlowkitWhite),
                  textAlign: TextAlign.center),
              selectedTitle: Text(LiveKitLocalizations.of(Global.appContext())!.common_cancel,
                  style: const TextStyle(fontSize: 12, color: LiveColors.designStandardFlowkitWhite),
                  textAlign: TextAlign.center),
              imageSize: 28.radius,
              onPressed: () {
                _handleAudienceLinkMic();
              },
              rotationNotifier: rotationNotifier,
              isSelected: isApplying);
        });
    buttons.add(linkMic);

    return buttons;
  }

  void _showSettingsPanel() {
    _settingsPanelHandler = popupWidget(
      SettingsPanelWidget(onTapSettingsPanelItem: (itemType) {
        _handleTapSettingsPanel(itemType);
      }),
      barrierColor: LiveColors.designStandardTransparent,
    );
  }

  void _handleTapSettingsPanel(SettingsItemType itemType) {
    switch (itemType) {
      case SettingsItemType.background:
        final currentLive = _liveListStore.liveState.currentLive.value;
        _liveBackgroundSelectPanelHandler = popupWidget(LiveBackgroundSelectPanelWidget(
            backgroundUrls: Constants.backgroundUrlList,
            initialBackgroundUrl: currentLive.backgroundURL,
            sceneType: SelectPanelSceneType.voice));
        break;
      case SettingsItemType.audioEffect:
        _audioEffectPanelHandler = popupWidget(AudioEffectPanelWidget(roomId: widget.liveID));
        break;
      default:
        break;
    }
  }

  void _showSeatManagementPanel() {
    _seatManagementPanelHandler =
        popupWidget(SeatManagementPanelWidget(liveID: widget.liveID, toastService: widget.toastService));
  }

  void _handleAudienceLinkMic() async {
    final selfUserId = TUIRoomEngine.getSelfInfo().userId;
    final isApplying = widget.viewStore.state.isApplyingToTakeSeat.value;

    if (isApplying) {
      final result = await _coGuestStore.cancelApplication();
      if (result.isSuccess) {
        widget.viewStore.onRespondedTakeSeatRequest();
      } else {
        widget.toastService.showToast(ErrorHandler.convertToErrorMessage(result.errorCode, result.errorMessage) ?? '');
      }
      return;
    }

    final isOnSeat =
        _coGuestStore.coGuestState.connected.value.any((seatUserInfo) => seatUserInfo.userID == selfUserId);
    if (isOnSeat) {
      final result = await _coGuestStore.disconnect();
      if (!result.isSuccess) {
        widget.toastService.showToast(ErrorHandler.convertToErrorMessage(result.errorCode, result.errorMessage) ?? '');
      }
      _deviceStore.closeLocalMicrophone();
      return;
    }

    widget.viewStore.onSentTakeSeatRequest();
    const timeoutValue = 60;
    final result = await _coGuestStore.applyForSeat(seatIndex: -1, timeout: timeoutValue);
    if (!result.isSuccess) {
      widget.viewStore.onRespondedTakeSeatRequest();
      widget.toastService.showToast(ErrorHandler.convertToErrorMessage(result.errorCode, result.errorMessage) ?? '');
    }
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
                    child: widget.isSelected ? _initSelectedImage() : widget.normalImage),
              )),
          SizedBox(height: 2.height),
          widget.isSelected ? _initSelectedTitle() : _initNormalTitle(),
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

  Widget _initSelectedImage() {
    return widget.selectedImage ?? widget.normalImage;
  }

  Widget _initNormalTitle() {
    return Visibility(
        visible: widget.normalTitle != null,
        child: Positioned(top: widget.imageSize, child: widget.normalTitle ?? Container()));
  }

  Widget _initSelectedTitle() {
    return Visibility(
        visible: widget.normalTitle != null,
        child: Positioned(top: widget.imageSize, child: widget.selectedTitle ?? Container()));
  }
}
