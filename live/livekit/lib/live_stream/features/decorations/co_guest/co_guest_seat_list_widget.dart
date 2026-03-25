import 'package:atomic_x_core/api/device/device_store.dart';
import 'package:atomic_x_core/api/live/co_guest_store.dart';
import 'package:atomic_x_core/api/live/live_list_store.dart';
import 'package:collection/collection.dart';
import 'package:atomic_x_core/api/live/live_seat_store.dart';
import 'package:flutter/material.dart';
import 'package:tencent_live_uikit/common/index.dart';
import 'package:tencent_live_uikit/tencent_live_uikit.dart';

typedef GestureTapCallback = void Function(SeatInfo seatInfo);

// for SeatTemplate:200, maxSeatCount:4
class CoGuestSeatListWidget extends StatefulWidget {
  final String liveID;
  final GestureTapCallback? onTapSeat;

  const CoGuestSeatListWidget({super.key, required this.liveID, required this.onTapSeat});

  @override
  State<StatefulWidget> createState() => _CoGuestSeatListWidget();
}

class _CoGuestSeatListWidget extends State<CoGuestSeatListWidget> {
  final int seatCount = 4;

  @override
  Widget build(BuildContext context) {
    LiveSeatStore liveSeatStore = LiveSeatStore.create(widget.liveID);
    return ListenableBuilder(
        listenable: liveSeatStore.liveSeatState.seatList,
        builder: (context, _) {
          final List<SeatInfo> seatList = liveSeatStore.liveSeatState.seatList.value;
          return SizedBox(
            height: 100.height,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(seatCount, (index) {
                SeatInfo? seatInfo = seatList.firstWhereOrNull((item) => item.index == index);
                seatInfo ??= SeatInfo(index: index);
                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(4),
                    child: Center(
                      child: SeatWidget(
                        seatInfo: seatInfo,
                        onTapSeat: widget.onTapSeat,
                      ),
                    ),
                  ),
                );
              }),
            ),
          );
        });
  }
}

class SeatWidget extends StatefulWidget {
  final SeatInfo seatInfo;
  final GestureTapCallback? onTapSeat;

  const SeatWidget({super.key, required this.seatInfo, required this.onTapSeat});

  @override
  State<StatefulWidget> createState() {
    return SeatWidgetState();
  }
}

class SeatWidgetState extends State<SeatWidget> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        widget.onTapSeat?.call(widget.seatInfo);
      },
      child: Container(
        color: Colors.transparent,
        child: Column(
          children: [
            widget.seatInfo.userInfo.userID.isEmpty ? _buildEmptyWidget() : _buildAvatar(),
            SizedBox(height: 2.height),
            _buildMicAndNameWidget(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyWidget() {
    final liveInfo = LiveListStore.shared.liveState.currentLive.value;
    bool isOwner = TUIRoomEngine.getSelfInfo().userId == liveInfo.liveOwner.userID;
    return SizedBox(
      width: 50.width,
      height: 50.width,
      child: ClipOval(
        child: Container(
          color: LiveColors.userNameBlackColor,
          child: Center(
            child: Image.asset(
              isOwner ? LiveImages.emptySeat : LiveImages.add,
              package: Constants.pluginName,
              width: 18.radius,
              height: 18.radius,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return SizedBox(
      width: 50.width,
      height: 50.width,
      child: ClipOval(
        child: Image.network(
          widget.seatInfo.userInfo.avatarURL,
          errorBuilder: (context, error, stackTrace) {
            return Image.asset(
              LiveImages.defaultAvatar,
              package: Constants.pluginName,
            );
          },
        ),
      ),
    );
  }

  Widget _buildMicAndNameWidget() {
    final liveID = LiveListStore.shared.liveState.currentLive.value.liveID;
    if (liveID.isEmpty || widget.seatInfo.userInfo.userID.isEmpty) return const SizedBox.shrink();
    CoGuestStore coGuestStore = CoGuestStore.create(liveID);
    final show = coGuestStore.coGuestState.connected.value.length > 1 ||
        TUIRoomEngine.getSelfInfo().userId == widget.seatInfo.userInfo.userID;
    return Visibility(
      visible: show,
      child: SizedBox(
        width: 60.width,
        height: 20.height,
        child: Container(
          padding: EdgeInsets.only(left: 8.width, right: 8.width, top: 3.height, bottom: 3.height),
          decoration: BoxDecoration(
            color: LiveColors.userNameBlackColor,
            borderRadius: BorderRadius.circular(37.radius),
          ),
          child: Row(
            children: [
              Visibility(
                visible: widget.seatInfo.userInfo.microphoneStatus != DeviceStatus.on,
                child: SizedBox(
                  width: 12.width,
                  height: 12.width,
                  child: Image.asset(
                    LiveImages.muteMicrophone,
                    package: Constants.pluginName,
                  ),
                ),
              ),
              SizedBox(
                width: 2.width,
              ),
              Flexible(
                child: Text(
                  (widget.seatInfo.userInfo.userName.isNotEmpty)
                      ? widget.seatInfo.userInfo.userName
                      : widget.seatInfo.userInfo.userID,
                  style: const TextStyle(color: LiveColors.designStandardFlowkitWhite, fontSize: 10),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
