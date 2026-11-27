import 'package:tencent_cloud_chat_sdk/tencent_im_sdk_plugin.dart';

const int componentLiveStream = 21;
const int liveIntegrationSuccessful = 1120;

void setComponent(int component) {}

void reportAtomicMetrics(int keyMetrics) {
  Map<String, dynamic> param = {
    'report_tuifeature_usage_uicomponent_type': keyMetrics,
  };

  TencentImSDKPlugin.v2TIMManager.callExperimentalAPI(
    api: 'report_tuifeature_usage',
    param: param,
  );
}