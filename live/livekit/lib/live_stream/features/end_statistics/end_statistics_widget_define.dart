import 'package:atomic_x_core/api/live/live_list_store.dart';

class AnchorEndStatisticsWidgetInfo {
  String roomId;
  int liveDuration;
  int viewCount;
  int messageCount;
  int giftIncome;
  int giftSenderCount;
  int likeCount;
  LiveEndedReason liveEndedReason;

  AnchorEndStatisticsWidgetInfo(
      {required this.roomId,
      required this.liveDuration,
      required this.viewCount,
      required this.messageCount,
      required this.giftIncome,
      required this.giftSenderCount,
      required this.likeCount,
      required this.liveEndedReason});
}
