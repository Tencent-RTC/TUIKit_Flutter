import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/material.dart';
import 'package:tencent_live_uikit/common/index.dart';
import 'package:rtc_room_engine/rtc_room_engine.dart';

import '../../../manager/live_stream_manager.dart';

class CoGuestManagePanelWidget extends StatefulWidget {
  final LiveStreamManager liveStreamManager;

  const CoGuestManagePanelWidget({super.key, required this.liveStreamManager});

  @override
  State<CoGuestManagePanelWidget> createState() => _CoGuestManagePanelWidgetState();
}

class _CoGuestManagePanelWidgetState extends State<CoGuestManagePanelWidget> {
  late final LiveStreamManager manager;

  @override
  void initState() {
    super.initState();
    manager = widget.liveStreamManager;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1.screenWidth,
      height: 718.height,
      padding: EdgeInsets.only(bottom: 20.height),
      decoration: BoxDecoration(
        color: LiveColors.designStandardG2,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(20.radius), topRight: Radius.circular(20.radius)),
      ),
      child: SingleChildScrollView(
        child:
        Column(mainAxisAlignment: MainAxisAlignment.start, crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(height: 20.height),
          _buildTitleWidget(),
          SizedBox(height: 20.height),
          _buildCoGuestTitleWidget(),
          _buildCoGuestListWidget(),
          _buildSeparationWidget(),
          _buildApplicantsTitleWidget(),
          _buildApplicantsListWidget(),
        ]),
      ),
    );
  }

  Widget _buildTitleWidget() {
    return SizedBox(
      height: 28.height,
      child: Stack(
        children: [
          Positioned(
            left: 24.width,
            child: GestureDetector(
              onTap: () {
                Navigator.pop(context);
              },
              child: SizedBox(
                width: 24.width,
                height: 24.width,
                child: Image.asset(
                  LiveImages.returnArrow,
                  package: Constants.pluginName,
                ),
              ),
            ),
          ),
          Center(
            child: Text(
              LiveKitLocalizations.of(Global.appContext())!.common_link_mic_manager,
              style: const TextStyle(color: LiveColors.designStandardG7, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoGuestTitleWidget() {
    return ValueListenableBuilder(
      valueListenable: _getLiveSeatState().seatList,
      builder: (context, seatList, _) {
        final filterCoGuestList =
        seatList.where((seat) =>
        seat.userInfo.userID.isNotEmpty && seat.userInfo.userID != _getSelfID() &&
            seat.userInfo.liveID == _getLiveID());
        final isCoGuesting = filterCoGuestList.isNotEmpty;
        return Visibility(
          visible: isCoGuesting,
          child: Container(
            margin: EdgeInsets.only(left: 24.width),
            child: Text(
              '${LiveKitLocalizations.of(Global.appContext())!.common_link_mic_up_title} (${filterCoGuestList.length})',
              style: const TextStyle(color: LiveColors.notStandardGrey, fontSize: 12),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCoGuestListWidget() {
    return ValueListenableBuilder(
      valueListenable: _getLiveSeatState().seatList,
      builder: (context, seatList, _) {
        final filterCoGuestList = seatList
            .where((seat) =>
        seat.userInfo.userID.isNotEmpty && seat.userInfo.userID != _getSelfID() && seat.userInfo.liveID == _getLiveID())
            .toList();
        return Visibility(
          visible: filterCoGuestList.isNotEmpty,
          child: SizedBox(
            height: _calculateCoGuestListHeight(),
            child: ListView.builder(
                shrinkWrap: true,
                physics: const ClampingScrollPhysics(),
                scrollDirection: Axis.vertical,
                itemCount: filterCoGuestList.length,
                itemBuilder: (context, index) {
                  final coGuest = filterCoGuestList[index];
                  return _buildCoGuestUserItem(coGuest);
                }),
          ),
        );
      },
    );
  }

  Widget _buildSeparationWidget() {
    return ListenableBuilder(
      listenable: Listenable.merge([_getCoGuestState().applicants, _getLiveSeatState().seatList]),
      builder: (context, _) {
        final isCoGuesting = manager.isCoGuesting();
        final hasCoGuestApplication = _getCoGuestState().applicants.value.isNotEmpty;
        return Visibility(
          visible: isCoGuesting && hasCoGuestApplication,
          child: Container(
            color: LiveColors.designStandardG3Divider,
            height: 7.height,
          ),
        );
      },
    );
  }

  Widget _buildApplicantsTitleWidget() {
    return ValueListenableBuilder(
      valueListenable: _getCoGuestState().applicants,
      builder: (context, applicantList, _) {
        return Visibility(
          visible: _getCoGuestState().applicants.value.isNotEmpty,
          child: Container(
            margin: EdgeInsets.only(left: 24.width, top: 20.height),
            child: Text(
              '${LiveKitLocalizations.of(Global.appContext())!.common_apply_link_mic} (${applicantList.length})',
              style: const TextStyle(color: LiveColors.notStandardGrey, fontSize: 12),
            ),
          ),
        );
      },
    );
  }

  Widget _buildApplicantsListWidget() {
    return ValueListenableBuilder(
      valueListenable: _getCoGuestState().applicants,
      builder: (context, applicantSet, _) {
        final applicants = applicantSet.toList();
        return Visibility(
          visible: _getCoGuestState().applicants.value.isNotEmpty,
          child: SizedBox(
            height: _calculateApplicantListHeight(),
            child: ListView.builder(
                shrinkWrap: true,
                physics: const ClampingScrollPhysics(),
                scrollDirection: Axis.vertical,
                itemCount: _getCoGuestState().applicants.value.length,
                itemBuilder: (context, index) {
                  final applicant = applicants[index];
                  return _buildApplicantItem(applicant);
                }),
          ),
        );
      },
    );
  }

  Widget _buildCoGuestUserItem(SeatInfo seat) {
    return Container(
      height: 60.height,
      color: LiveColors.designStandardG2,
      padding: EdgeInsets.only(left: 24.width, right: 24.width),
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
                child: ClipOval(
                  child: Image.network(
                    seat.userInfo.avatarURL ?? "",
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Image.asset(
                        LiveImages.defaultAvatar,
                        package: Constants.pluginName,
                      );
                    },
                  ),
                ),
              ),
              SizedBox(width: 12.width),
              Container(
                constraints: BoxConstraints(maxWidth: 135.width),
                alignment: Alignment.centerLeft,
                child: Text(
                  seat.userInfo.userName.isNotEmpty ? seat.userInfo.userName : seat.userInfo.userID,
                  style: const TextStyle(color: LiveColors.designStandardG7, fontSize: 16),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          GestureDetector(
            onTap: () {
              _disconnectUser(seat.userInfo.userID);
            },
            child: Container(
              width: 64.width,
              height: 24.height,
              decoration: BoxDecoration(
                border: Border.all(color: LiveColors.notStandardRed, width: 1.width),
                borderRadius: BorderRadius.circular(12.height),
              ),
              alignment: Alignment.center,
              child: Text(
                LiveKitLocalizations.of(Global.appContext())!.common_hang_up,
                style: const TextStyle(color: LiveColors.notStandardRed, fontSize: 12),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildApplicantItem(LiveUserInfo user) {
    return Container(
      height: 60.height,
      color: LiveColors.designStandardG2,
      padding: EdgeInsets.only(left: 24.width, right: 24.width),
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
                child: ClipOval(
                  child: Image.network(
                    user.avatarURL,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Image.asset(
                        LiveImages.defaultAvatar,
                        package: Constants.pluginName,
                      );
                    },
                  ),
                ),
              ),
              SizedBox(width: 10.width),
              Container(
                constraints: BoxConstraints(maxWidth: 135.width),
                alignment: Alignment.centerLeft,
                child: Text(
                  user.userName.isNotEmpty ? user.userName : user.userID,
                  style: const TextStyle(color: LiveColors.designStandardG7, fontSize: 16),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  _acceptIntraRoomConnection(user.userID);
                },
                child: Container(
                  width: 64.width,
                  height: 24.height,
                  decoration: BoxDecoration(
                    color: LiveColors.designStandardB1,
                    borderRadius: BorderRadius.circular(12.height),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    LiveKitLocalizations.of(Global.appContext())!.common_accept,
                    style: const TextStyle(color: LiveColors.designStandardFlowkitWhite, fontSize: 12),
                  ),
                ),
              ),
              SizedBox(width: 10.width),
              GestureDetector(
                onTap: () {
                  _rejectIntraRoomConnection(user.userID);
                },
                child: Container(
                  width: 64.width,
                  height: 24.height,
                  decoration: BoxDecoration(
                    border: Border.all(color: LiveColors.designStandardB1, width: 1.width),
                    borderRadius: BorderRadius.circular(12.height),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    LiveKitLocalizations.of(Global.appContext())!.common_reject,
                    style: const TextStyle(color: LiveColors.designStandardB1, fontSize: 12),
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}

extension on _CoGuestManagePanelWidgetState {
  String _getSelfID() {
    return TUIRoomEngine
        .getSelfInfo()
        .userId;
  }

  String _getLiveID() {
    LiveListState liveListState = LiveListStore.shared.liveState;
    return liveListState.currentLive.value.liveID;
  }

  CoGuestState _getCoGuestState() {
    return CoGuestStore
        .create(_getLiveID())
        .coGuestState;
  }

  LiveSeatState _getLiveSeatState() {
    return LiveSeatStore
        .create(_getLiveID())
        .liveSeatState;
  }

  void _acceptIntraRoomConnection(String userId) {
    CoGuestStore coGuestStore = CoGuestStore.create(_getLiveID());
    coGuestStore.acceptApplication(userId).then((result) {
      if (result.errorCode != TUIError.success.rawValue) {
        manager.toastSubject.add(ErrorHandler.convertToErrorMessage(result.errorCode, result.errorMessage) ?? '');
      }
    });
  }

  void _rejectIntraRoomConnection(String userId) {
    CoGuestStore coGuestStore = CoGuestStore.create(_getLiveID());
    coGuestStore.rejectApplication(userId).then((result) {
      if (result.errorCode != TUIError.success.rawValue) {
        manager.toastSubject.add(ErrorHandler.convertToErrorMessage(result.errorCode, result.errorMessage) ?? '');
      }
    });
  }

  void _disconnectUser(String userId) {
    LiveSeatStore liveSeatStore = LiveSeatStore.create(_getLiveID());
    liveSeatStore.kickUserOutOfSeat(userId).then((result) {
      if (result.errorCode != TUIError.success.rawValue) {
        manager.toastSubject.add(ErrorHandler.convertToErrorMessage(result.errorCode, result.errorMessage) ?? '');
      }
    });
  }

  double _calculateCoGuestListHeight() {
    LiveSeatState liveSeatState = _getLiveSeatState();
    double totalHeight = 0;
    if (liveSeatState.seatList.value.isNotEmpty) {
      final filterCoGuestList = liveSeatState.seatList.value
          .where((seat) => seat.userInfo.userID.isNotEmpty && seat.userInfo.userID != _getSelfID());
      totalHeight = (filterCoGuestList.length) * 60.height;
    }
    return totalHeight > 280.height ? 280.height : totalHeight;
  }

  double _calculateApplicantListHeight() {
    double totalHeight = 0;
    final applicants = _getCoGuestState().applicants.value;
    if (applicants.isNotEmpty) {
      totalHeight = applicants.length * 60.height;
    }
    return totalHeight > 280.height ? 280.height : totalHeight;
  }
}
