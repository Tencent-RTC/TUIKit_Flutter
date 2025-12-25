import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/material.dart';
import 'package:tencent_live_uikit/common/index.dart';
import 'package:tencent_live_uikit/seat_grid_widget/seat_grid_define.dart';
import 'package:tencent_live_uikit/voice_room/manager/index.dart';
import 'package:rtc_room_engine/rtc_room_engine.dart';

class SeatInvitationPanelWidget extends StatefulWidget {
  final String liveID;
  final ToastService toastService;
  final int seatIndex;

  const SeatInvitationPanelWidget(
      {super.key, required this.liveID, required this.toastService, required this.seatIndex});

  @override
  State<SeatInvitationPanelWidget> createState() => _SeatInvitationPanelWidgetState();
}

class _SeatInvitationPanelWidgetState extends State<SeatInvitationPanelWidget> {
  late final int seatIndex;

  final List<(LiveUserInfo, bool)> audienceInvited = [];

  LiveSeatStore get _seatStore => LiveSeatStore.create(widget.liveID);

  CoGuestStore get _coGuestStore => CoGuestStore.create(widget.liveID);

  LiveAudienceStore get _audienceStore => LiveAudienceStore.create(widget.liveID);

  @override
  void initState() {
    super.initState();
    seatIndex = widget.seatIndex;
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        decoration: BoxDecoration(
            borderRadius: BorderRadius.only(topLeft: Radius.circular(15.width), topRight: Radius.circular(15.width))),
        height: 722.height,
        child: Column(
          children: [
            SizedBox(height: 20.height),
            SizedBox(
              width: 1.screenWidth,
              height: 28.height,
              child: Center(
                child: Text(
                  LiveKitLocalizations.of(Global.appContext())!.common_voiceroom_invite,
                  style: const TextStyle(color: LiveColors.designStandardFlowkitWhite, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            SizedBox(height: 24.height),
            SizedBox(
                width: 1.screenWidth,
                height: 28.height,
                child: Padding(
                  padding: EdgeInsets.only(left: 24.width),
                  child: Text(
                    LiveKitLocalizations.of(Global.appContext())!.common_anchor_audience_list_panel_title,
                    style: const TextStyle(color: LiveColors.designStandardFlowkitWhite, fontSize: 16),
                    textAlign: TextAlign.left,
                  ),
                )),
            SizedBox(height: 16.height),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.width),
              child: Container(color: LiveColors.designStandardG3.withAlpha(0x4D), height: 1.height),
            ),
            _initAudienceInvitationListWidget()
          ],
        ));
  }

  Widget _initAudienceInvitationListWidget() {
    return ListenableBuilder(
      listenable: Listenable.merge([
        _audienceStore.liveAudienceState.audienceList,
        _seatStore.liveSeatState.seatList,
        _coGuestStore.coGuestState.invitees
      ]),
      builder: (context, child) {
        final seatUserIds = _seatStore.liveSeatState.seatList.value.map((seat) => seat.userInfo.userID).toSet();
        final selfUserId = TUIRoomEngine.getSelfInfo().userId;
        final invitedIds = _coGuestStore.coGuestState.invitees.value.map((invitee) => invitee.userID).toSet();
        final invitableUsers = _audienceStore.liveAudienceState.audienceList.value
            .where((user) => user.userID != selfUserId && !seatUserIds.contains(user.userID))
            .toList();

        audienceInvited
          ..clear()
          ..addAll(invitableUsers.map((user) => (user, invitedIds.contains(user.userID))));

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.width),
          child: Visibility(
            visible: audienceInvited.isNotEmpty,
            child: SizedBox(
              height: _calculateAudienceInvitationListHeight(),
              child: ListView.builder(
                  shrinkWrap: true,
                  physics: const ClampingScrollPhysics(),
                  scrollDirection: Axis.vertical,
                  itemCount: audienceInvited.length,
                  itemBuilder: (context, index) {
                    return _buildAudienceInvitationItem(index);
                  }),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAudienceInvitationItem(int index) {
    return Container(
      height: 60.height,
      color: LiveColors.designStandardG2,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        children: [
          Row(
            children: [
              SizedBox(
                width: 40.radius,
                height: 40.radius,
                child: Stack(
                  children: [
                    ClipOval(
                      child: Image.network(
                        audienceInvited[index].$1.avatarURL,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Image.asset(
                            LiveImages.defaultAvatar,
                            package: Constants.pluginName,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 12.width),
              Container(
                alignment: Alignment.centerLeft,
                constraints: BoxConstraints(maxWidth: 135.width),
                child: Text(
                  audienceInvited[index].$1.userName.isNotEmpty
                      ? audienceInvited[index].$1.userName
                      : audienceInvited[index].$1.userID,
                  style: const TextStyle(color: LiveColors.designStandardG6, fontSize: 16),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          DebounceGestureRecognizer(
            onTap: () {
              _handleAudienceInvitation(audienceInvited[index].$1, audienceInvited[index].$2);
            },
            child: Container(
              width: 60.width,
              height: 24.height,
              decoration: BoxDecoration(
                color: audienceInvited[index].$2 ? LiveColors.designStandardTransparent : LiveColors.notStandardBlue,
                border: Border.all(
                    color: audienceInvited[index].$2 ? LiveColors.notStandardRed : LiveColors.notStandardBlue,
                    width: 1),
                borderRadius: BorderRadius.circular(12.radius),
              ),
              alignment: Alignment.center,
              child: Text(
                audienceInvited[index].$2
                    ? LiveKitLocalizations.of(Global.appContext())!.common_cancel
                    : LiveKitLocalizations.of(Global.appContext())!.common_voiceroom_invite,
                style: TextStyle(
                    color:
                        audienceInvited[index].$2 ? LiveColors.notStandardRed : LiveColors.designStandardFlowkitWhite,
                    fontSize: 12),
              ),
            ),
          )
        ],
      ),
    );
  }
}

extension on _SeatInvitationPanelWidgetState {
  double _calculateAudienceInvitationListHeight() {
    double totalHeight = 0;
    if (audienceInvited.isNotEmpty) {
      totalHeight = audienceInvited.length * 60.height;
    }
    return totalHeight > 280.height ? 280.height : totalHeight;
  }

  void _handleAudienceInvitation(LiveUserInfo audience, bool isInvited) async {
    if (!isInvited) {
      if (_coGuestStore.coGuestState.invitees.value.any((invitee) => invitee.userID == audience.userID)) {
        return;
      }

      final future =
          _coGuestStore.inviteToSeat(inviteeID: audience.userID, seatIndex: seatIndex, timeout: defaultTimeout);

      if (seatIndex != -1 && mounted) {
        Navigator.of(Global.appContext()).pop();
      }

      final result = await future;
      if (!result.isSuccess) {
        widget.toastService.showToast(ErrorHandler.convertToErrorMessage(result.errorCode, result.errorMessage) ?? '');
        return;
      }
      return;
    }

    final result = await _coGuestStore.cancelInvitation(audience.userID);
    if (!result.isSuccess) {
      widget.toastService.showToast(ErrorHandler.convertToErrorMessage(result.errorCode, result.errorMessage) ?? '');
    }
  }
}
