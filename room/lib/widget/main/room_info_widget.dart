import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tencent_conference_uikit/base/index.dart';
import 'package:tuikit_atomic_x/atomicx.dart' hide FilledButton, IconButton;

import 'room_widget/room_info_item_widget.dart';
import 'room_widget/room_copy_button_widget.dart';

class RoomInfoWidget extends StatelessWidget {
  final String roomId;

  const RoomInfoWidget({super.key, required this.roomId});

  @override
  Widget build(BuildContext context) {
    final orientation = MediaQuery.of(context).orientation;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      width: double.infinity,
      height: orientation == Orientation.portrait ? 254.height : screenHeight,
      decoration: BoxDecoration(
        color: RoomColors.g2,
        borderRadius: orientation == Orientation.portrait
            ? const BorderRadius.only(topLeft: Radius.circular(20.0), topRight: Radius.circular(20.0))
            : const BorderRadius.only(topLeft: Radius.circular(20.0), bottomLeft: Radius.circular(20.0)),
      ),
      child: _buildContent(context, orientation),
    );
  }

  Widget _buildContent(BuildContext context, Orientation orientation) {
    final roomStore = RoomStore.shared;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (orientation == Orientation.portrait) _buildDropDownButton(context),
        Padding(
          padding: EdgeInsets.only(
            left: 16.width,
            right: 16.width,
            top: orientation == Orientation.portrait ? 0 : 24.height,
          ),
          child: SizedBox(
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ValueListenableBuilder(
                  valueListenable: roomStore.state.currentRoom,
                  builder: (context, currentRoom, _) {
                    return Text(
                      currentRoom?.roomName ?? roomId,
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: RoomColors.g7),
                      textAlign: TextAlign.left,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    );
                  },
                ),
                SizedBox(height: 24),
                ValueListenableBuilder(
                  valueListenable: roomStore.state.currentRoom,
                  builder: (context, currentRoom, _) {
                    return RoomInfoItemWidget(
                      prefixText: RoomLocalizations.of(context)!.roomkit_role_owner,
                      infoText: currentRoom?.roomOwner.userName ?? currentRoom?.roomOwner.userID ?? '',
                    );
                  },
                ),
                SizedBox(height: 16),
                RoomInfoItemWidget(
                  prefixText: RoomLocalizations.of(context)!.roomkit_room_id,
                  infoText: roomId,
                  child: RoomCopyButtonWidget(
                    infoText: roomId,
                    successToast: RoomLocalizations.of(context)!.roomkit_toast_room_id_copied,
                  ),
                ),
                SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48.height,
                  child: FilledButton(
                    onPressed: () => _copyAllRoomInfo(context),
                    style: FilledButton.styleFrom(
                      backgroundColor: RoomColors.g4.withValues(alpha: 0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.radius),
                      ),
                      padding: EdgeInsets.zero,
                    ),
                    child: Text(
                      RoomLocalizations.of(context)!.roomkit_copy_room_info,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: RoomColors.g6,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropDownButton(BuildContext context) {
    return SizedBox(
      height: 40.height,
      width: double.infinity,
      child: IconButton(
        icon: Image.asset(RoomImages.roomLine, package: RoomConstants.pluginName, width: 24.width, height: 24.height),
        onPressed: () => Navigator.of(context).pop(),
      ),
    );
  }
}

extension _RoomInfoWidgetPrivate on RoomInfoWidget {
  void _copyAllRoomInfo(BuildContext context) {
    final roomStore = RoomStore.shared;
    final currentRoom = roomStore.state.currentRoom.value;

    if (currentRoom == null) return;

    final allInfo = '${RoomLocalizations.of(context)!.roomkit_room_name}: ${currentRoom.roomName}\n'
        '${RoomLocalizations.of(context)!.roomkit_room_id}: ${currentRoom.roomID}';

    Clipboard.setData(ClipboardData(text: allInfo));
    Toast.info(context, RoomLocalizations.of(context)!.roomkit_toast_room_info_copied, useRootOverlay: true);
  }
}
