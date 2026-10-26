import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/material.dart';

import 'custom_barrage_builder.dart';

class BarrageDisplayController {
  final ScrollController scrollController = ScrollController();
  CustomBarrageBuilder? customBarrageBuilder;

  final String roomId;
  final String ownerId;

  BarrageDisplayController({required this.roomId, required this.ownerId});

  void insertMessage(Barrage barrage) {
    if (barrage.liveID != roomId) return;
    BarrageStore.create(roomId).appendLocalTip(barrage);
  }

  void setCustomBarrageBuilder(CustomBarrageBuilder? builder) {
    customBarrageBuilder = builder;
  }

  void scrollToBottom() {
    if (scrollController.hasClients) {
      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }
}
