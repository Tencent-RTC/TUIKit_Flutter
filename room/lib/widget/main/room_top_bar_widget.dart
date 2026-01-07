import 'dart:async';

import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/material.dart';
import 'package:tencent_conference_uikit/base/index.dart';

import 'room_info_widget.dart';
import 'room_widget/room_exit_widget.dart';

class RoomTopBarWidget extends StatefulWidget {
  final String roomId;
  final Orientation orientation;

  const RoomTopBarWidget({super.key, required this.roomId, required this.orientation});

  @override
  State<RoomTopBarWidget> createState() => _RoomTopBarWidgetState();
}

class _RoomTopBarWidgetState extends State<RoomTopBarWidget> {
  final _deviceStore = DeviceStore.shared;
  final _roomStore = RoomStore.shared;

  final ValueNotifier<String> _timerText = ValueNotifier('00:00');
  Timer? _timer;
  late final int _initTimestamp;

  @override
  void initState() {
    super.initState();
    _initTimestamp = DateTime.now().millisecondsSinceEpoch;
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timerText.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: RoomColors.darkBlack,
      child: SizedBox(
        width: MediaQuery.of(context).size.width,
        height: widget.orientation == Orientation.portrait ? 106.height : 73.width,
        child: Column(
          children: [
            SizedBox(height: widget.orientation == Orientation.portrait ? 52.height : 20.width),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _buildSpeakerButton(),
                  const SizedBox(width: 24),
                  _buildSwitchCameraButton(),
                  const Spacer(),
                  widget.orientation == Orientation.portrait ? _buildPortraitTitle() : _buildLandscapeTitle(),
                  const Spacer(),
                  _buildExitButton(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension _RoomTopBarWidgetStatePrivate on _RoomTopBarWidgetState {
  Widget _buildSpeakerButton() {
    return ValueListenableBuilder(
      valueListenable: _deviceStore.state.currentAudioRoute,
      builder: (context, audioRoute, _) {
        return GestureDetector(
          onTap: _handleSpeakerToggle,
          child: SizedBox(
            width: 20.radius,
            height: 20.radius,
            child: Image.asset(
              audioRoute == AudioRoute.speakerphone ? RoomImages.roomSpeakerphone : RoomImages.roomEarpiece,
              package: RoomConstants.pluginName,
              width: 20.radius,
              height: 20.radius,
            ),
          ),
        );
      },
    );
  }

  Widget _buildSwitchCameraButton() {
    return GestureDetector(
      onTap: _handleSwitchCamera,
      child: SizedBox(
        width: 20.radius,
        height: 20.radius,
        child: Image.asset(
          RoomImages.roomSwitchCamera,
          package: RoomConstants.pluginName,
          width: 20.radius,
          height: 20.radius,
        ),
      ),
    );
  }

  Widget _buildPortraitTitle() {
    return GestureDetector(
      onTap: _handleRoomInfoTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: widget.orientation == Orientation.portrait ? 180.width : 240.width,
                ),
                child: ValueListenableBuilder(
                  valueListenable: _timerText,
                  builder: (context, timerText, _) {
                    return Text(
                      _roomStore.state.currentRoom.value?.roomName ?? widget.roomId,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: RoomColors.white),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    );
                  },
                ),
              ),
              const SizedBox(width: 2),
              Image.asset(
                RoomImages.roomDropDown,
                package: RoomConstants.pluginName,
                width: 18,
                height: 18,
                fit: BoxFit.contain,
                color: RoomColors.g5,
              ),
            ],
          ),
          const SizedBox(height: 5),
          ValueListenableBuilder(
            valueListenable: _timerText,
            builder: (context, timerText, _) {
              return Text(
                timerText,
                style: const TextStyle(fontSize: 12, color: RoomColors.white),
                textAlign: TextAlign.center,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLandscapeTitle() {
    return GestureDetector(
      onTap: _handleRoomInfoTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: widget.orientation == Orientation.portrait ? 180.width : 240.width),
            child: Text(
              _roomStore.state.currentRoom.value?.roomName ?? widget.roomId,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: RoomColors.white),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 2),
          Image.asset(
            RoomImages.roomDropDown,
            package: RoomConstants.pluginName,
            width: 18,
            height: 18,
            fit: BoxFit.contain,
            color: RoomColors.g5,
          ),
          const SizedBox(width: 16),
          ValueListenableBuilder(
            valueListenable: _timerText,
            builder: (context, timerText, _) {
              return Text(timerText, style: const TextStyle(fontSize: 12, color: RoomColors.white));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildExitButton() {
    return GestureDetector(
      onTap: _handleExitTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(RoomImages.roomExit, package: RoomConstants.pluginName, width: 20, height: 20),
          const SizedBox(width: 3),
          Text(
            RoomLocalizations.of(context)!.roomkit_end,
            style: const TextStyle(fontSize: 14, color: RoomColors.exitRed, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  void _startTimer() {
    _updateTimerText();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      _updateTimerText();
    });
  }

  void _updateTimerText() {
    final currentTimeStamp = DateTime.now().millisecondsSinceEpoch;
    final totalSeconds = ((currentTimeStamp - _initTimestamp) / 1000).floor();

    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds ~/ 60) % 60;
    final seconds = totalSeconds % 60;

    if (hours > 0) {
      _timerText.value = '${hours.toString().padLeft(2, '0')}:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    } else {
      _timerText.value = '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    }
  }

  void _handleSpeakerToggle() {
    _deviceStore.setAudioRoute(
      _deviceStore.state.currentAudioRoute.value == AudioRoute.speakerphone
          ? AudioRoute.earpiece
          : AudioRoute.speakerphone,
    );
  }

  void _handleSwitchCamera() {
    _deviceStore.switchCamera(!_deviceStore.state.isFrontCamera.value);
  }

  void _handleExitTap() {
    popupWidget(
      RoomExitWidget(
        onExit: () {
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _handleRoomInfoTap() {
    popupWidget(RoomInfoWidget(roomId: widget.roomId));
  }
}
