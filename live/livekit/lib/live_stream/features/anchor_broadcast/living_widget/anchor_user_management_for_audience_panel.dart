import 'package:atomic_x_core/api/live/live_audience_store.dart';
import 'package:atomic_x_core/api/live/live_list_store.dart';
import 'package:flutter/material.dart';
import 'package:tencent_live_uikit/common/index.dart';
import 'package:tencent_live_uikit/live_stream/manager/live_stream_manager.dart';
import 'package:tencent_live_uikit/tencent_live_uikit.dart';

import '../common/anchor_user_management_panel_base.dart';

class AnchorUserManagementForAudiencePanel extends StatefulWidget {
  final LiveUserInfo user;
  final LiveStreamManager liveStreamManager;
  final VoidCallback closeCallback;

  const AnchorUserManagementForAudiencePanel({
    super.key,
    required this.user,
    required this.liveStreamManager,
    required this.closeCallback,
  });

  @override
  State<AnchorUserManagementForAudiencePanel> createState() => _AnchorUserManagementForAudiencePanelState();
}

class _AnchorUserManagementForAudiencePanelState extends State<AnchorUserManagementForAudiencePanel> {
  final ValueNotifier<bool> _isMessageDisabled = ValueNotifier(false);
  AlertHandler? _kickOutAlertHandler;
  late final LiveAudienceStore? liveAudienceStore;
  late final VoidCallback _messageBannedUserListListener = _onMessageBannedUserListChanged;
  late final VoidCallback _floatWindowModeListener = _onFloatWindowModeChanged;

  @override
  void initState() {
    super.initState();
    final liveInfo = LiveListStore.shared.liveState.currentLive.value;
    if (liveInfo.liveID.isNotEmpty) {
      liveAudienceStore = LiveAudienceStore.create(liveInfo.liveID);
      liveAudienceStore!.liveAudienceState.messageBannedUserList.addListener(_messageBannedUserListListener);
      _onMessageBannedUserListChanged();
    }
    widget.liveStreamManager.floatWindowState.isFloatWindowMode.addListener(_floatWindowModeListener);
  }

  @override
  void dispose() {
    _kickOutAlertHandler?.close();
    widget.liveStreamManager.floatWindowState.isFloatWindowMode.removeListener(_floatWindowModeListener);
    liveAudienceStore?.liveAudienceState.messageBannedUserList.removeListener(_messageBannedUserListListener);
    _isMessageDisabled.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnchorUserManagementPanelBase(
      user: widget.user,
      liveStreamManager: widget.liveStreamManager,
      child: _buildMenuWidget(),
    );
  }

  Widget _buildMenuWidget() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.width),
      child: Container(
        constraints: BoxConstraints(maxWidth: 327.width),
        height: 77.height,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          spacing: 20.width,
          children: _buildMessageAndKickOutChildren(),
        ),
      ),
    );
  }

  List<Widget> _buildMessageAndKickOutChildren() {
    List<Widget> children = <Widget>[];
    children.add(ValueListenableBuilder(
      valueListenable: _isMessageDisabled,
      builder: (context, isMessageDisabled, child) {
        return CommonMenuWidget(
          imageName: isMessageDisabled ? LiveImages.disableChat : LiveImages.enableChat,
          title: isMessageDisabled
              ? LiveKitLocalizations.of(context)!.common_enable_message
              : LiveKitLocalizations.of(context)!.common_disable_message,
          onTap: () => _messageButtonClicked(),
        );
      },
    ));

    children.add(CommonMenuWidget(
      imageName: LiveImages.anchorKickOut,
      title: LiveKitLocalizations.of(context)!.common_kick_out_of_room,
      onTap: () => _kickOutButtonClicked(),
    ));

    return children;
  }
}

extension on _AnchorUserManagementForAudiencePanelState {
  void _messageButtonClicked() {
    widget.closeCallback.call();
    if (liveAudienceStore == null) return;
    final userID = widget.user.userID;
    final isDisable = !_isMessageDisabled.value;
    liveAudienceStore!.disableSendMessage(userID: userID, isDisable: isDisable).then((result) {
      if (result.errorCode != TUIError.success.rawValue) {
        widget.liveStreamManager.toastSubject
            .add(ErrorHandler.convertToErrorMessage(result.errorCode, result.errorMessage) ?? '');
      }
    });
  }

  void _kickOutButtonClicked() {
    final userName = widget.user.userName.isNotEmpty ? widget.user.userName : widget.user.userID;
    final alertInfo = AlertInfo(
        description:
            LiveKitLocalizations.of(Global.appContext())!.common_kick_user_confirm_message.replaceAll('xxx', userName),
        cancelText: LiveKitLocalizations.of(Global.appContext())!.common_cancel,
        cancelCallback: () => _closeKickOutAlert(),
        defaultText: LiveKitLocalizations.of(Global.appContext())!.common_remove,
        defaultCallback: () {
          if (liveAudienceStore == null) return;
          liveAudienceStore!.kickUserOutOfRoom(widget.user.userID).then((result) {
            if (result.errorCode != TUIError.success.rawValue) {
              widget.liveStreamManager.toastSubject
                  .add(ErrorHandler.convertToErrorMessage(result.errorCode, result.errorMessage) ?? '');
            }
          });
          _closeKickOutAlert();
        });
    _kickOutAlertHandler = Alert.showAlert(alertInfo, context);
  }

  void _closeKickOutAlert() {
    _kickOutAlertHandler?.close();
    widget.closeCallback.call();
  }

  void _onMessageBannedUserListChanged() {
    if (liveAudienceStore == null) return;
    final messageBannedUserList = liveAudienceStore!.liveAudienceState.messageBannedUserList.value;
    _isMessageDisabled.value = messageBannedUserList.any((user) => user.userID == widget.user.userID);
  }

  void _onFloatWindowModeChanged() {
    bool isFloatWindowMode = widget.liveStreamManager.floatWindowState.isFloatWindowMode.value;
    if (isFloatWindowMode) {
      _closeKickOutAlert();
    }
  }
}
