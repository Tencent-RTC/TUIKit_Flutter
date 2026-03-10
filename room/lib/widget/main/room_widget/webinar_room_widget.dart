import 'package:flutter/material.dart';
import 'package:rtc_room_engine/rtc_room_engine.dart' hide DeviceStatus;
import 'package:tuikit_atomic_x/atomicx.dart';

class WebinarRoomWidget extends StatefulWidget {
  final String roomId;

  const WebinarRoomWidget({super.key, required this.roomId});

  @override
  State<WebinarRoomWidget> createState() => _WebinarRoomWidgetState();
}

class _WebinarRoomWidgetState extends State<WebinarRoomWidget> {
  final TUIRoomEngine _roomEngine = TUIRoomEngine.sharedInstance();
  late final TUIRoomObserver _roomEngineObserver;
  late final RoomParticipantStore _participantStore;

  int _mixViewPtr = 0;
  int _multiStreamViewPtr = 0;
  String _mixUserId = '';
  String _multiStreamUserId = '';

  @override
  void initState() {
    super.initState();
    _participantStore = RoomParticipantStore.create(widget.roomId);
    _roomEngineObserver = TUIRoomObserver(
        onUserVideoStateChanged: (userId, streamType, hasVideo, reason) =>
            _onUserVideoStateChanged(userId, streamType, hasVideo));
    _roomEngine.addObserver(_roomEngineObserver);
  }

  @override
  void dispose() {
    _roomEngine.removeObserver(_roomEngineObserver);
    _clearVideoView();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        VideoView(
          key: const ValueKey('mix_video_view'),
          onViewCreated: (id) {
            _mixViewPtr = id;
            if (_mixUserId.isNotEmpty) {
              _setRemoteVideoView(_mixUserId, _mixViewPtr);
            }
          },
          onViewDisposed: (id) {
            _mixViewPtr = 0;
          },
        ),
        VideoView(
          key: const ValueKey('multi_stream_video_view'),
          onViewCreated: (id) {
            _multiStreamViewPtr = id;
            if (_multiStreamUserId.isNotEmpty) {
              _setRemoteVideoView(_multiStreamUserId, _multiStreamViewPtr);
            }
          },
          onViewDisposed: (id) {
            _roomEngine.stopPlayRemoteVideo(_multiStreamUserId, TUIVideoStreamType.cameraStream);
            _multiStreamViewPtr = 0;
          },
        ),
        ValueListenableBuilder(
          valueListenable: _participantStore.state.participantList,
          builder: (context, participantList, _) {
            final seatList = _roomEngine.querySeatList();
            final firstSeatUserId = seatList.firstOrNull?.userId;
            final pushVideoUser =
                firstSeatUserId != null ? participantList.where((p) => p.userID == firstSeatUserId).firstOrNull : null;
            if (pushVideoUser == null || pushVideoUser.cameraStatus == DeviceStatus.on) {
              return const SizedBox.shrink();
            }
            return Stack(
              children: [
                Container(color: const Color(0xFF181A1E)),
                Center(
                  child: Avatar.image(
                    url: pushVideoUser.avatarURL,
                    shape: AvatarShape.round,
                    size: AvatarSize.xl,
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  void _clearVideoView() {
    if (_mixUserId.isNotEmpty) {
      _roomEngine.setRemoteVideoView(_mixUserId, TUIVideoStreamType.cameraStream, 0);
    }
    if (_multiStreamUserId.isNotEmpty) {
      _roomEngine.setRemoteVideoView(_multiStreamUserId, TUIVideoStreamType.cameraStream, 0);
    }
  }

  void _setRemoteVideoView(String userId, int viewPtr) {
    _roomEngine.setRemoteVideoView(userId, TUIVideoStreamType.cameraStream, viewPtr);
  }

  void _onUserVideoStateChanged(String userId, TUIVideoStreamType streamType, bool hasVideo) {
    final selfUserId = LoginStore.shared.loginState.loginUserInfo?.userID;
    if (userId == selfUserId) {
      return;
    }

    final isMixUser = userId.contains('_feedback_');

    if (hasVideo) {
      if (isMixUser) {
        _mixUserId = userId;
        if (_mixViewPtr != 0) {
          _setRemoteVideoView(userId, _mixViewPtr);
        }
      } else {
        _multiStreamUserId = userId;
        if (_multiStreamViewPtr != 0) {
          _setRemoteVideoView(userId, _multiStreamViewPtr);
        }
      }
      _roomEngine.startPlayRemoteVideo(userId, TUIVideoStreamType.cameraStream, null);
    } else {
      _roomEngine.stopPlayRemoteVideo(userId, TUIVideoStreamType.cameraStream);
    }
  }
}
