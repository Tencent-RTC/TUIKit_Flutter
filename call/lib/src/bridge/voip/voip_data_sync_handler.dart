import 'package:tuikit_atomic_x/atomicx.dart';
import 'package:rtc_room_engine/rtc_room_engine.dart';
import 'package:atomic_x_core/atomicxcore.dart';
import 'package:tencent_calls_uikit/src/manager/call_manager.dart';

class VoIPDataSyncHandler {
  void handleVoipChangeMute(bool mute) {
    if (mute) {
      CallManager.instance.closeLocalMicrophone();
    } else {
      CallManager.instance.openLocalMicrophone();
    }
  }

  void handleVoipChangeAudioPlaybackDevice(AudioRoute audioDevice) {
    CallManager.instance.setAudioRoute(audioDevice);
  }

  void handleVoipHangup() {
    CallManager.instance.hangup();
  }

  void handleVoipAccept() {
    CallManager.instance.accept();
  }
}