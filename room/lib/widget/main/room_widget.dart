import 'package:flutter/material.dart';
import 'package:tencent_conference_uikit/base/extension/room_extension.dart';

import 'room_widget/standard_room_widget.dart';
import 'room_widget/webinar_room_widget.dart';

class RoomWidget extends StatelessWidget {
  final String roomId;

  const RoomWidget({super.key, required this.roomId});

  @override
  Widget build(BuildContext context) {
    return roomId.isWebinar ? WebinarRoomWidget(roomId: roomId) : StandardRoomWidget(roomId: roomId);
  }
}
