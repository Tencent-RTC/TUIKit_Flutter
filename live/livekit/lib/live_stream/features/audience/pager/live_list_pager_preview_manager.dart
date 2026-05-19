import 'package:atomic_x_core/api/live/live_list_store.dart';
import 'package:tencent_live_uikit/common/index.dart';

abstract class PreviewController {
  void startPreview(String roomId, bool isMuteAudio);
  void stopPreview(String roomId);
  void dispose();
}

abstract class PreviewControllerFactory {
  PreviewController create();
}

class LiveListPagerPreviewManager {
  static const String tag = 'LiveListPagerPreviewManager';

  final PreviewControllerFactory _controllerFactory;

  /// roomId → PreviewController
  final Map<String, PreviewController> _activePreviews = {};

  LiveListPagerPreviewManager({required PreviewControllerFactory controllerFactory})
      : _controllerFactory = controllerFactory;

  void startPreview(LiveInfo liveInfo) {
    final roomId = liveInfo.liveID;
    if (_activePreviews.containsKey(roomId)) {
      return;
    }
    final controller = _controllerFactory.create();
    _activePreviews[roomId] = controller;
    controller.startPreview(roomId, true);
    LiveKitLogger.info('$tag startPreview: $roomId');
  }

  void stopPreview(String roomId) {
    final controller = _activePreviews.remove(roomId);
    if (controller == null) return;
    controller.stopPreview(roomId);
    controller.dispose();
    LiveKitLogger.info('$tag stopPreview: $roomId');
  }

  void stopAllPreviews() {
    final roomIds = _activePreviews.keys.toList();
    for (final roomId in roomIds) {
      stopPreview(roomId);
    }
  }

  void onPageChanged({
    required String newCurrentRoomId,
    required List<String> adjacentRoomIds,
  }) {
    final adjacentSet = adjacentRoomIds.toSet();
    final roomIdsToStop = <String>[];

    for (final roomId in _activePreviews.keys) {
      if (roomId == newCurrentRoomId || !adjacentSet.contains(roomId)) {
        roomIdsToStop.add(roomId);
      }
    }

    for (final roomId in roomIdsToStop) {
      stopPreview(roomId);
    }
  }

  bool isPreviewActive(String roomId) {
    return _activePreviews.containsKey(roomId);
  }

  PreviewController? getPreviewController(String roomId) {
    return _activePreviews[roomId];
  }

  void dispose() {
    stopAllPreviews();
    LiveKitLogger.info('$tag disposed');
  }
}
