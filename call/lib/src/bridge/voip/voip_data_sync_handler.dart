import 'package:tuikit_atomic_x/atomicx.dart';
import 'package:rtc_room_engine/rtc_room_engine.dart';
import 'package:atomic_x_core/atomicxcore.dart';

class VoIPDataSyncHandler {
  void handleVoipChangeMute(bool mute) {
    if (mute) {
      DeviceStore.shared.closeLocalMicrophone();
    } else {
      DeviceStore.shared.openLocalMicrophone();
    }
  }

  void handleVoipChangeAudioPlaybackDevice(AudioRoute audioDevice) {
    DeviceStore.shared.setAudioRoute(audioDevice);
  }

  void handleVoipHangup() {
    CallStore.shared.hangup();
  }

  void handleVoipAccept() {
    CallStore.shared.accept();
  }
}