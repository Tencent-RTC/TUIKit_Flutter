import 'package:atomic_x_core/api/device/base_beauty_store.dart';
import 'package:flutter/cupertino.dart';

import '../../common/logger/logger.dart';
import '../../tencent_live_uikit.dart';

const kTEBeautyService = 'TEBeautyService';
const kEnableBeauty = 'enableBeauty';
const kGetBeautyPanel = 'getBeautyPanel';
const kReset = 'reset';

class LiveBeautyStore {
  LiveBeautyStore._internal() {
    TUICore.instance.getService(kTEBeautyService).then((result) {
      _isSupportTEBeauty = result;
      LiveKitLogger.info("LiveBeautyStore _isSupportTEBeauty:$_isSupportTEBeauty");
    });
  }

  static LiveBeautyStore shared = LiveBeautyStore._internal();

  bool? _isSupportTEBeauty;

  void enableBeauty(bool enable) async {
    LiveKitLogger.info("LiveBeautyStore enableBeauty:$enable");
    _isSupportTEBeauty ??= await TUICore.instance.getService(kTEBeautyService);
    LiveKitLogger.info("LiveBeautyStore _isSupportTEBeauty:$_isSupportTEBeauty");
    if (_isSupportTEBeauty == true) {
      _teEnableBeauty(enable);
    }
  }

  bool isSupportTEBeauty() {
    return _isSupportTEBeauty == true;
  }

  Widget? getTEBeautyPanel(Color backgroundColor) {
    Map<String, dynamic> param = {
      'backgroundColor' : backgroundColor.toARGB32(),
    };
    const beautyPanel = 'beautyPanel';
    TUICore.instance.callService(kTEBeautyService, kGetBeautyPanel, param);
    if (param.containsKey(beautyPanel) && param[beautyPanel] is Widget) {
      return param[beautyPanel] as Widget;
    }
    return null;
  }

  void reset() {
    LiveKitLogger.info("LiveBeautyStore reset");
    BaseBeautyStore.shared.reset();
    _teReset();
  }

  void _teEnableBeauty(bool enable) {
    Map<String, dynamic> param = {'enable': enable};
    TUICore.instance.callService(kTEBeautyService, kEnableBeauty, param);
  }

  void _teReset() {
    enableBeauty(false);
    TUICore.instance.callService(kTEBeautyService, kReset, {});
  }
}
