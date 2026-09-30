import 'dart:convert';

import 'package:atomic_x_core/engine/engine_bridge.dart';
import 'package:tencent_cloud_chat_sdk/tencent_im_sdk_plugin.dart';

enum AtomicMetrics {
  messageList(1001),
  messageInput(1002),
  messageAction(1003),
  conversationList(1004),
  conversationGroup(1005),
  search(1006),
  contactList(1007),
  groupSetting(1008),
  c2cSetting(1009),
  liveList(1101),
  liveSeat(1103),
  liveAudience(1104),
  liveCoGuest(1105),
  liveCoHost(1106),
  liveBattle(1108),
  liveBarrage(1110),
  liveLike(1111),
  liveGift(1112),
  device(1113),
  audioEffect(1114),
  baseBeauty(1115),
  musicStore(1122),
  room(1201),
  roomParticipant(1202),
  call(1301),
  aiTranscriber(1401);

  final int value;
  const AtomicMetrics(this.value);
}

enum InteractionMetrics {
  chatInvokeCall(1020),
  chatInvokeRoom(1021);

  final int value;
  const InteractionMetrics(this.value);
}

const kSetFramework = 'LoginModule.setFramework';

class DataReport {
  static void reportAtomicMetrics(AtomicMetrics componentType) {
    _reportMetricsImpl(componentType.value);
  }

  static void reportInteractionMetrics(InteractionMetrics type) {
    _reportMetricsImpl(type.value);
  }

  static void _reportMetricsImpl(int type) {
    Map<String, dynamic> param = {
      'report_tuifeature_usage_uicomponent_type': type,
    };

    TencentImSDKPlugin.v2TIMManager.callExperimentalAPI(
      api: 'report_tuifeature_usage',
      param: param,
    );
  }

  static void reportComponent(int component) {
    try {
      Map<String, dynamic> params = {
        'framework': 1,
        'component': component,
        'language': 9,
      };

      String jsonString = jsonEncode(params);
      EngineBridge.invoke(kSetFramework, jsonString);
    } catch (_) {}
  }
}
