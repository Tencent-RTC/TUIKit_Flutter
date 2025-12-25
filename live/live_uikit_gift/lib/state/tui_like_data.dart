import 'package:atomic_x_core/api/live/live_audience_store.dart';

class TUILikeData {
  LiveUserInfo sender = LiveUserInfo();

  TUILikeData({LiveUserInfo? sender}) {
    if (sender != null) {
      this.sender = sender;
    }
  }

  @override
  String toString() {
    return 'TUILikeData{sender: $sender}';
  }
}
