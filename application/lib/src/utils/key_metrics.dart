import 'package:tencent_cloud_chat_sdk/tencent_im_sdk_plugin.dart';

class KeyMetrics {
  static const kDemoLoginSuccess = 1302;
  static const kDemoClickCall = 1303;
  static const kDemoClickLive = 1119;
  static const kDemoClickRoom = 1205;

  static void reportKeyMetrics(int keyMetrics) {
    Map<String, dynamic> param = {
      'report_tuifeature_usage_uicomponent_type': keyMetrics,
    };

    TencentImSDKPlugin.v2TIMManager.callExperimentalAPI(
      api: 'report_tuifeature_usage',
      param: param,
    );
  }
}
