import 'package:flutter/foundation.dart';

class VRViewState {
  final ValueNotifier<bool> isApplyingToTakeSeat;

  VRViewState({bool isApplyingToTakeSeat = false}) : isApplyingToTakeSeat = ValueNotifier(isApplyingToTakeSeat);
}

class VoiceRoomViewStore {
  VRViewState state = VRViewState();

  void onSentTakeSeatRequest() {
    state.isApplyingToTakeSeat.value = true;
  }

  void onRespondedTakeSeatRequest() {
    state.isApplyingToTakeSeat.value = false;
  }

  void dispose() {
    state.isApplyingToTakeSeat.value = false;
  }
}
