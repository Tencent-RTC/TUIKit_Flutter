import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/material.dart';
import 'package:tencent_conference_uikit/base/index.dart';

class RoomExitWidget extends StatefulWidget {
  final VoidCallback onExit;

  const RoomExitWidget({super.key, required this.onExit});

  @override
  State<RoomExitWidget> createState() => _RoomExitWidgetState();
}

class _RoomExitWidgetState extends State<RoomExitWidget> {
  final _roomStore = RoomStore.shared;
  late final RoomParticipantStore _participantStore;

  @override
  void initState() {
    super.initState();
    final currentRoom = _roomStore.state.currentRoom.value;
    if (currentRoom != null) {
      _participantStore = RoomParticipantStore.create(currentRoom.roomID);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: _participantStore.state.localParticipant,
      builder: (context, localUser, _) {
        final isRoomOwner = localUser?.role == ParticipantRole.owner;
        return SizedBox(
          height: isRoomOwner ? 219.height : 169.height,
          child: Column(
            children: [
              _buildDropDownButton(context),
              SizedBox(
                height: 17.height,
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.width),
                    child: Text(
                      isRoomOwner
                          ? RoomLocalizations.of(context)!.roomkit_confirm_leave_room_by_owner
                          : RoomLocalizations.of(context)!.roomkit_confirm_leave_room_by_genera_user,
                      style: TextStyle(fontSize: 12.width, color: Color(0xFF7C85A6)),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 16.height),
              Divider(thickness: 1.height, height: 0, color: RoomColors.dividerGrey),
              _buildLeaveRoomButton(),
              Divider(thickness: 1.height, height: 0, color: RoomColors.dividerGrey),
              if (isRoomOwner) _buildDismissRoomButton(),
            ],
          ),
        );
      },
    );
  }
}

extension _RoomExitWidgetStatePrivate on _RoomExitWidgetState {
  Widget _buildLeaveRoomButton() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        _handleLeaveRoom();
      },
      child: SizedBox(
        height: 58.height,
        child: Center(
          child: Text(
            RoomLocalizations.of(context)!.roomkit_leave_room,
            style: TextStyle(fontSize: 18.width, color: RoomColors.brandBlue),
          ),
        ),
      ),
    );
  }

  Widget _buildDismissRoomButton() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        _handleDismissRoom();
      },
      child: SizedBox(
        height: 58.height,
        child: Center(
          child: Text(
            RoomLocalizations.of(context)!.roomkit_end_room,
            style: TextStyle(fontSize: 18.width, color: RoomColors.exitRed),
          ),
        ),
      ),
    );
  }

  void _handleLeaveRoom() async {
    Navigator.of(context).pop();
    await _roomStore.leaveRoom();
    widget.onExit();
  }

  void _handleDismissRoom() async {
    Navigator.of(context).pop();
    await _roomStore.endRoom();
    widget.onExit();
  }

  Widget _buildDropDownButton(BuildContext context) {
    return SizedBox(
      height: 35.height,
      width: double.infinity,
      child: IconButton(
        icon: Image.asset(RoomImages.roomLine, package: RoomConstants.pluginName, width: 24.width, height: 24.height),
        onPressed: () => Navigator.of(context).pop(),
      ),
    );
  }
}
