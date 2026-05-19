import 'package:atomic_x_core/api/view/live/live_core_widget.dart';

import 'live_list_pager_preview_manager.dart';

class LiveCorePreviewController implements PreviewController {
  final LiveCoreController _coreController;

  LiveCorePreviewController()
      : _coreController = LiveCoreController.create(CoreViewType.playView);

  LiveCoreController get coreController => _coreController;

  @override
  void startPreview(String roomId, bool isMuteAudio) {
    _coreController.setLiveID(roomId);
    _coreController.startPreviewLiveStream(roomId, isMuteAudio, null);
  }

  @override
  void stopPreview(String roomId) {
    _coreController.stopPreviewLiveStream(roomId);
  }

  @override
  void dispose() {
  }
}

class LiveCorePreviewControllerFactory implements PreviewControllerFactory {
  @override
  PreviewController create() {
    return LiveCorePreviewController();
  }
}
