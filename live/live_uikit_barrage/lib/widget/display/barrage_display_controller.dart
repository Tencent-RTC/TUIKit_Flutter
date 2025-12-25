import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/material.dart';

import '../../state/store.dart';
import 'custom_barrage_builder.dart';

class BarrageDisplayController {
  final ScrollController scrollController = ScrollController();
  CustomBarrageBuilder? customBarrageBuilder;

  BarrageDisplayController(
      {required String roomId,
      required String ownerId,
      required String selfUserId,
      String? selfName,
      OnBarrageError? onError}) {
    Store().manager.init(roomId, ownerId, selfUserId, selfName);
    Store().onError = onError;
  }

  void insertMessage(Barrage barrage) {
    Store().manager.insertBarrage(barrage);
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

  static void resetState() {
    Store().roomId = '';
    Store().selfUserId = '';
    Store().selfName = '';
    Store().ownerId = '';
  }
}
