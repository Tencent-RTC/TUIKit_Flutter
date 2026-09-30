part of 'package:atomic_x_core/api/view/room/room_participant_widget.dart';

class RoomParticipantControllerImpl extends RoomParticipantController with ChangeNotifier {
  VideoStreamType _streamType;
  RoomParticipant _participant;
  FillMode? _fillMode;
  bool _isActive = false;
  VoidCallback? _clickAction;

  RoomParticipantControllerImpl({
    required VideoStreamType streamType,
    required RoomParticipant participant,
  })  : _streamType = streamType,
        _participant = participant;

  @override
  void updateStreamType(VideoStreamType streamType) {
    if (_streamType == streamType) return;
    _streamType = streamType;
    notifyListeners();
  }

  @override
  void updateParticipant(RoomParticipant participant) {
    _participant = participant;
    notifyListeners();
  }

  @override
  void setFillMode(FillMode fillMode) {
    if (_fillMode == fillMode) return;
    _fillMode = fillMode;
    notifyListeners();
  }

  @override
  void setActive(bool isActive) {
    if (_isActive == isActive) return;
    _isActive = isActive;
    notifyListeners();
  }

  @override
  void setOnClickAction(VoidCallback action) {
    _clickAction = action;
  }
}
