
export 'pusher/index_view.dart';

import 'tui_live_kit_platform_interface.dart';

class TuiLiveKit {
  Future<String?> getPlatformVersion() {
    return TuiLiveKitPlatform.instance.getPlatformVersion();
  }
}
