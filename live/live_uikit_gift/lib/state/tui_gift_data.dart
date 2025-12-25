import 'package:atomic_x_core/atomicxcore.dart';

class TUIGiftData {
  int giftCount = 0;
  Gift gift = Gift();
  LiveUserInfo sender = LiveUserInfo();

  TUIGiftData({int? giftCount, Gift? gift, LiveUserInfo? sender}) {
    if (giftCount != null) {
      this.giftCount = giftCount;
    }
    if (gift != null) {
      this.gift = gift;
    }
    if (sender != null) {
      this.sender = sender;
    }
  }

  @override
  String toString() {
    return 'TUIGiftData{giftCount: $giftCount, gift: $gift, sender: $sender}';
  }
}