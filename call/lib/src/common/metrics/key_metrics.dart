import 'package:tencent_calls_uikit/tencent_calls_uikit.dart';

import 'trtc_metrics_channel.dart';
import 'chat_metrics_channel.dart';

class KeyMetrics {
  static final KeyMetrics instance = KeyMetrics._internal();
  factory KeyMetrics() => instance;
  final _chatMetrics = ChatMetricsChannel();
  final _trtcMetrics = TRTCMetricsChannel();
  String _callId = "";

  KeyMetrics._internal();

  void countUV(EventId eventId) {
    if (eventId == EventId.wakeup) {
      if (CallStore.shared.state.activeCall.value.callId == _callId ||
          CallStore.shared.state.selfInfo.value.id == CallStore.shared.state.activeCall.value.inviterId) {
        return;
      }
      _callId = CallStore.shared.state.activeCall.value.callId;
    }

    _chatMetrics.countEvent(eventId);
    _trtcMetrics.countEvent(eventId);
  }
}

enum EventId {
  received,
  wakeup,
  wakeupByPush,
}

const _EventIdEnumMap = {
  EventId.received: 171010,
  EventId.wakeup: 171011,
  EventId.wakeupByPush: 171012,
};

extension EventIdExt on EventId {
  int value() {
    return _EventIdEnumMap[this]!;
  }
}

class MetricsJsonKeys {
  // Event Payload Keys
  static const String eventId = "event_id";
  static const String eventCode = "event_code";
  static const String eventResult = "event_result";
  static const String eventMessage = "event_message";
  static const String moreMessage = "more_message";
  static const String extensionMessage = "extension_message";

  // Extension Payload Keys
  static const String basicInfo = "basicInfo";
  static const String platformInfo = "platformInfo";

  // Basic Info Keys
  static const String callId = "callId";
  static const String intRoomId = "intRoomId";
  static const String strRoomId = "strRoomId";
  static const String uiKitVersion = "uiKitVersion";

  // Platform Info Keys
  static const String platform = "platform";
  static const String framework = "framework";
  static const String deviceBrand = "deviceBrand";
  static const String deviceModel = "deviceModel";
  static const String androidVersion = "androidVersion";
  static const String isForeground = "isForeground";
  static const String isScreenLocked = "isScreenLocked";
  static const String hasFloatingWindowPermission = "hasFloatingWindowPermission";
  static const String hasBackgroundLaunchPermission = "hasBackgroundLaunchPermission";
  static const String hasNotificationPermission = "hasNotificationPermission";
}
