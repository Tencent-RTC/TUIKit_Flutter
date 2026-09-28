import 'package:flutter/foundation.dart';

import '../../impl/common/store_factory.dart';

class LiveSummaryData {
  int totalDuration;
  int totalViewers;
  int totalGiftsSent;
  int totalGiftUniqueSenders;
  int totalGiftCoins;
  int totalLikesReceived;
  int totalMessageSent;

  LiveSummaryData({
    this.totalDuration = 0,
    this.totalViewers = 0,
    this.totalGiftsSent = 0,
    this.totalGiftUniqueSenders = 0,
    this.totalGiftCoins = 0,
    this.totalLikesReceived = 0,
    this.totalMessageSent = 0,
  });
}

abstract class LiveSummaryState {
  ValueListenable<LiveSummaryData> get summaryData;
}

abstract class LiveSummaryStore {
  LiveSummaryState get liveSummaryState;

  static LiveSummaryStore create(String liveID) {
    return StoreFactory.shared.getStore<LiveSummaryStore>(roomID: liveID);
  }
}
