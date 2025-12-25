import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/material.dart';
import 'package:rtc_room_engine/rtc_room_engine.dart';

import '../../../../../common/index.dart';

class AudienceListPanelWidget extends StatefulWidget {
  final LiveAudienceState state;
  final void Function(LiveUserInfo userInfo)? onClickUserItem;

  const AudienceListPanelWidget({super.key, required this.state, this.onClickUserItem});

  @override
  State<AudienceListPanelWidget> createState() => _AudienceListPanelWidgetState();
}

class _AudienceListPanelWidgetState extends State<AudienceListPanelWidget> {
  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.sizeOf(context).width;
    return SizedBox(
      height: 700.height,
      width: screenWidth,
      child: Column(
        children: [
          _initDiffWidget(15.height),
          _initTopWidget(),
          _initDiffWidget(12.height),
          _initListWidget(),
        ],
      ),
    );
  }
}

extension on _AudienceListPanelWidgetState {
  Widget _initDiffWidget(double height) {
    return SizedBox(
      height: height,
    );
  }

  Widget _initTopWidget() {
    final double screenWidth = MediaQuery.sizeOf(context).width;
    return SizedBox(
      height: 44.height,
      width: screenWidth,
      child: Stack(
        children: [
          Positioned(
            left: 14.width,
            child: GestureDetector(
              onTap: () {
                Navigator.pop(context);
              },
              child: Container(
                width: 44.radius,
                height: 44.radius,
                padding: EdgeInsets.all(10.radius),
                child: Image.asset(
                  LiveImages.returnArrow,
                  package: Constants.pluginName,
                ),
              ),
            ),
          ),
          Center(
            child: Text(
              LiveKitLocalizations.of(Global.appContext())!.common_anchor_audience_list_panel_title,
              style: const TextStyle(color: LiveColors.designStandardFlowkitWhite, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _initListWidget() {
    final double screenWidth = MediaQuery.sizeOf(context).width;
    return ValueListenableBuilder(
      valueListenable: widget.state.audienceList,
      builder: (BuildContext context, value, Widget? child) {
        return SizedBox(
            width: screenWidth,
            height: 629.height,
            child: ListView.builder(
                itemCount: widget.state.audienceList.value.length,
                itemExtent: 60.height,
                itemBuilder: (BuildContext context, int index) {
                  final user = widget.state.audienceList.value[index];
                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.width),
                    child: SizedBox(
                        height: 60.height,
                        width: double.infinity,
                        child: Stack(
                          children: [
                            Positioned(
                              left: 0,
                              top: 10.height,
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.all(Radius.circular(20.radius)),
                                    child: SizedBox(
                                      width: 40.radius,
                                      height: 40.radius,
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
                                  SizedBox(
                                    width: 12.width,
                                    height: 44.height,
                                  ),
                                  Text(
                                    user.userName.isNotEmpty ? user.userName : user.userID,
                                    style: const TextStyle(color: LiveColors.designStandardFlowkitWhite, fontSize: 16),
                                  )
                                ],
                              ),
                            ),
                            Positioned(
                              left: 52.width,
                              top: 59.height,
                              child: Container(
                                width: 251.width,
                                height: 1.height,
                                color: LiveColors.notStandardBlue30Transparency,
                              ),
                            ),
                            Positioned(
                                right: 24.width,
                                bottom: 17.height,
                                child: Visibility(
                                  visible: isSelfRoomOwner() && widget.onClickUserItem != null,
                                  child: GestureDetector(
                                    onTap: () {
                                      LiveUserInfo userInfo = LiveUserInfo(
                                          userID: user.userID,
                                          userName: user.userName,
                                          avatarURL: user.avatarURL);
                                      widget.onClickUserItem?.call(userInfo);
                                    },
                                    child: SizedBox(
                                        width: 24.radius,
                                        height: 24.radius,
                                        child: Image.asset(LiveImages.more, package: Constants.pluginName)),
                                  ),
                                ))
                          ],
                        )),
                  );
                }));
      },
    );
  }
}

extension on _AudienceListPanelWidgetState {
  bool isSelfRoomOwner() {
    return TUIRoomEngine.getSelfInfo().userId == LiveListStore.shared.liveState.currentLive.value.liveOwner.userID;
  }
}
