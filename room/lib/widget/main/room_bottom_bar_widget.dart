import 'package:tuikit_atomic_x/atomicx.dart';
import 'package:flutter/material.dart' hide AlertDialog;
import 'package:tencent_conference_uikit/base/index.dart';

import 'room_widget/room_button_item_widget.dart';
import 'room_participant_list_widget.dart';

class RoomBottomBarWidget extends StatefulWidget {
  final String roomId;
  final Orientation orientation;

  const RoomBottomBarWidget({super.key, required this.roomId, required this.orientation});

  @override
  State<RoomBottomBarWidget> createState() => _RoomBottomBarWidgetState();
}

class _RoomBottomBarWidgetState extends State<RoomBottomBarWidget> {
  final _roomStore = RoomStore.shared;
  late final RoomParticipantStore _roomParticipantStore;

  @override
  void initState() {
    super.initState();
    _roomParticipantStore = RoomParticipantStore.create(widget.roomId);
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          left: 0,
          bottom: 0,
          height: widget.orientation == Orientation.portrait ? 86.height : 68.width,
          width: MediaQuery.of(context).size.width,
          child: Container(color: RoomColors.darkBlack),
        ),
        Center(
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ValueListenableBuilder(
                      valueListenable: _roomStore.state.currentRoom,
                      builder: (context, currentRoom, _) {
                        return RoomButtonItemWidget(
                          iconPath: RoomImages.roomMember,
                          text: RoomLocalizations.of(
                            context,
                          )!
                              .roomkit_member_count
                              .replaceAll("xxx", (currentRoom?.participantCount ?? 0).toString()),
                          onPressed: _handleMembersPressed,
                        );
                      },
                    ),
                    ListenableBuilder(
                      listenable: Listenable.merge([
                        _roomParticipantStore.state.localParticipant,
                        _roomStore.state.currentRoom,
                      ]),
                      builder: (context, _) {
                        final localParticipant = _roomParticipantStore.state.localParticipant.value;
                        final isAllMicrophoneDisabled = _roomStore.state.currentRoom.value?.isAllMicrophoneDisabled;
                        return RoomButtonItemWidget(
                          iconPath: RoomImages.roomMicOff,
                          selectedIconPath: RoomImages.roomMicOnEmpty,
                          text: localParticipant?.microphoneStatus == DeviceStatus.on
                              ? RoomLocalizations.of(context)!.roomkit_mute
                              : RoomLocalizations.of(context)!.roomkit_unmute,
                          isSelected: ValueNotifier(localParticipant?.microphoneStatus == DeviceStatus.on),
                          onPressed: _handleMicToggle,
                          opacity: isAllMicrophoneDisabled == true &&
                                  localParticipant?.role == ParticipantRole.generalUser &&
                                  localParticipant?.microphoneStatus == DeviceStatus.off
                              ? 0.5
                              : 1,
                        );
                      },
                    ),
                    ListenableBuilder(
                      listenable: Listenable.merge([
                        _roomParticipantStore.state.localParticipant,
                        _roomStore.state.currentRoom,
                      ]),
                      builder: (context, _) {
                        final localParticipant = _roomParticipantStore.state.localParticipant.value;
                        final isAllCameraDisabled = _roomStore.state.currentRoom.value?.isAllCameraDisabled;
                        return RoomButtonItemWidget(
                          iconPath: RoomImages.roomCameraOff,
                          selectedIconPath: RoomImages.roomCameraOn,
                          text: localParticipant?.cameraStatus == DeviceStatus.on
                              ? RoomLocalizations.of(context)!.roomkit_stop_video
                              : RoomLocalizations.of(context)!.roomkit_start_video,
                          isSelected: ValueNotifier(localParticipant?.cameraStatus == DeviceStatus.on),
                          onPressed: _handleCameraToggle,
                          opacity: isAllCameraDisabled == true &&
                                  localParticipant?.role == ParticipantRole.generalUser &&
                                  localParticipant?.cameraStatus == DeviceStatus.off
                              ? 0.5
                              : 1,
                        );
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(height: widget.orientation == Orientation.landscape ? 6 : 24),
            ],
          ),
        ),
      ],
    );
  }

  void _handleMembersPressed() {
    popupWidget(RoomParticipantListWidget(roomId: widget.roomId), backgroundColor: RoomColors.g2);
  }

  void _handleCameraToggle() async {
    final currentStatus = _roomParticipantStore.state.localParticipant.value?.cameraStatus;

    if (currentStatus == DeviceStatus.on) {
      DeviceOperator.closeCamera();
    } else {
      DeviceOperator.openCamera(context);
    }
  }

  void _handleMicToggle() async {
    final currentStatus = _roomParticipantStore.state.localParticipant.value?.microphoneStatus;

    if (currentStatus == DeviceStatus.on) {
      DeviceOperator.muteMicrophone(_roomParticipantStore);
    } else {
      DeviceOperator.unmuteMicrophone(context: context, participantStore: _roomParticipantStore);
    }
  }
}
