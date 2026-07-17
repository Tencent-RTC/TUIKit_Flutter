import 'dart:async';

import 'package:atomic_x_core/api/live/live_list_store.dart';
import 'package:flutter/foundation.dart';
import 'package:tencent_live_uikit/common/index.dart';

import '../../features/audience/pager/live_core_preview_controller.dart';
import '../../features/audience/pager/live_list_pager_preview_manager.dart';

/// Manages live stream preview for the live list widget.
///
/// In single-column mode: previews the current visible page.
/// In double-column mode: previews the top fully visible row with a 0.5s delay
class LiveListPreviewManager {
  static const String tag = 'LiveListPreviewManager';

  final PreviewControllerFactory _controllerFactory;

  /// roomId → PreviewController
  final Map<String, PreviewController> _activePreviews = {};

  /// Tracks roomIds currently being previewed in double-column mode.
  final Set<String> _doublePlayingRoomIds = {};

  /// Returns a copy of the roomIds currently being previewed in double-column mode.
  Set<String> get doublePlayingRoomIds => Set.unmodifiable(_doublePlayingRoomIds);

  /// When true, preloadTopRow Timer callbacks will be suppressed.
  bool _isBlocked = false;

  /// Sets whether preload callbacks should be suppressed.
  void setBlocked(bool value) {
    _isBlocked = value;
  }

  /// Notifies listeners whenever preview state changes (start/stop).
  /// The value increments on each change to ensure ValueListenableBuilder rebuilds.
  final ValueNotifier<int> previewStateNotifier = ValueNotifier<int>(0);

  LiveListPreviewManager({PreviewControllerFactory? controllerFactory})
      : _controllerFactory = controllerFactory ?? LiveCorePreviewControllerFactory();

  /// Start preview for a specific live room.
  void startPreview(LiveInfo liveInfo, {bool isMuteAudio = true}) {
    final roomId = liveInfo.liveID;
    if (_activePreviews.containsKey(roomId)) {
      return;
    }
    if (LiveListStore.shared.liveState.currentLive.value.liveID == roomId) {
      LiveKitLogger.info('$tag startPreview: $roomId ignore, current live room is playing');
      return;
    }
    final controller = _controllerFactory.create();
    _activePreviews[roomId] = controller;
    controller.startPreview(roomId, isMuteAudio);
    notifyStateChange();
    LiveKitLogger.info('$tag startPreview: $roomId, mute: $isMuteAudio');
  }

  /// Stop preview for a specific live room.
  void stopPreview(String roomId) {
    final controller = _activePreviews.remove(roomId);
    if (controller == null) return;
    controller.stopPreview(roomId);
    controller.dispose();
    _doublePlayingRoomIds.remove(roomId);
    notifyStateChange();
    LiveKitLogger.info('$tag stopPreview: $roomId');
  }

  /// Stop all active previews.
  void stopAllPreviews() {
    final roomIds = _activePreviews.keys.toList();
    for (final roomId in roomIds) {
      stopPreview(roomId);
    }
    _doublePlayingRoomIds.clear();
  }

  /// Called in double-column mode after scroll ends.
  /// Previews only the top fully visible row's items, stops others.
  ///
  /// [topRowRoomIds] - roomIds in the top fully visible row.
  /// [allVisibleRoomIds] - all currently visible roomIds.
  void preloadTopRow({
    required List<String> topRowRoomIds,
    required List<String> allVisibleRoomIds,
  }) {

    if (topRowRoomIds.isEmpty) {
      // No fully visible row, stop all double-playing previews.
      final playing = _doublePlayingRoomIds.toList();
      for (final roomId in playing) {
        stopPreview(roomId);
      }
      return;
    }

    final topRowSet = topRowRoomIds.toSet();

    // Stop previews for ALL playing items NOT in the new top row
    // (including items already scrolled out of the viewport).
    final playing = _doublePlayingRoomIds.toList();
    for (final roomId in playing) {
      if (!topRowSet.contains(roomId)) {
        stopPreview(roomId);
      }
    }

    // Start previews for top row items with 0.5s delay.
    final roomIdsToPreload = topRowRoomIds
        .where((id) => !_doublePlayingRoomIds.contains(id))
        .toList();

    if (roomIdsToPreload.isEmpty) return;

    if (_isBlocked) return;
    for (int i = 0; i < roomIdsToPreload.length; i++) {
      final roomId = roomIdsToPreload[i];
      Future.delayed(Duration(milliseconds: i * 50), () {
        if (_isBlocked || _activePreviews.containsKey(roomId)) return;
        if (LiveListStore.shared.liveState.currentLive.value.liveID == roomId) {
          LiveKitLogger.info('$tag preloadTopRow, startPreview: $roomId ignore, current live room is playing');
          return;
        }
        final controller = _controllerFactory.create();
        _activePreviews[roomId] = controller;
        controller.startPreview(roomId, true);
        _doublePlayingRoomIds.add(roomId);
        notifyStateChange();
        LiveKitLogger.info('$tag preloadTopRow: $roomId');
      });
    }
  }

  /// Check if a preview is active for the given roomId.
  bool isPreviewActive(String roomId) {
    return _activePreviews.containsKey(roomId);
  }

  /// Get the PreviewController for a given roomId.
  PreviewController? getPreviewController(String roomId) {
    return _activePreviews[roomId];
  }

  void dispose() {
    stopAllPreviews();
    previewStateNotifier.dispose();
    LiveKitLogger.info('$tag disposed');
  }

  /// Increment the notifier value to trigger ValueListenableBuilder rebuilds.
  void notifyStateChange() {
    previewStateNotifier.value++;
  }
}
