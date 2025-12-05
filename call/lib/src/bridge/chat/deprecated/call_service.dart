import 'package:tencent_calls_uikit/tencent_calls_uikit.dart';
import 'package:tencent_cloud_uikit_core/tencent_cloud_uikit_core.dart';
import 'package:rtc_room_engine/rtc_room_engine.dart';


class CallService extends AbstractTUIService {
  static final CallService _instance = CallService();

  static CallService get instance => _instance;

  @override
  onCall(String serviceName, String method, Map<String, dynamic> param) {
    if (serviceName != TUICALLKIT_SERVICE_NAME) {
      return;
    }

    if (method == METHOD_NAME_ENABLE_FLOAT_WINDOW) {
      final enableFloatWindow = param[PARAM_NAME_ENABLE_FLOAT_WINDOW] as bool;
      TUICallKit.instance.enableFloatWindow(enableFloatWindow);
    } else if (method == METHOD_NAME_CALL) {
      final userIDs = param[PARAM_NAME_USERIDS] as List<String>;
      final groupId = param[PARAM_NAME_GROUPID] as String;

      final mediaTypeString = param[PARAM_NAME_TYPE] as String;
      CallMediaType? mediaType;
      if (mediaTypeString == TYPE_AUDIO) {
        mediaType = CallMediaType.audio;
      } else if (mediaTypeString == TYPE_VIDEO) {
        mediaType = CallMediaType.video;
      }

      CallParams callParams = CallParams();
      callParams.chatGroupId = groupId;
      TUICallKit.instance.calls(userIDs, mediaType ?? CallMediaType.audio, callParams);
    }
  }
}
