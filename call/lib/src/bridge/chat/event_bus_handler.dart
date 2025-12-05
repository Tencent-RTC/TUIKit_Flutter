import "package:tuikit_atomic_x/atomicx.dart";
import "package:tuikit_atomic_x/base_component/utils/tui_event_bus.dart";
import "package:tencent_calls_uikit/src/tui_call_kit_impl.dart";

class EventBusHandler extends TUIObserver {
  static final EventBusHandler _instance = EventBusHandler();
  static EventBusHandler get instance => _instance;

  EventBusHandler() {
    TUIEventBus.shared.subscribe("call.startCall", null, this);
    TUIEventBus.shared.subscribe("call.startJoin", null, this);
  }

  @override
  void onNotify(String event, String? key, NotifyParams? params) {
    if (params == null ||
        params.data == null ||
        params.data!.isEmpty) {
      return;
    }

    if (event == "call.startCall") {
      handleStartCall(key, params);
      return;
    }

    if (event == "call.startJoin") {
      handleStartJoin(key, params);
      return;
    }
  }

  void handleStartCall(String? key, NotifyParams? params) {
    List<String> participantIds = params?.data?["participantIds"] ?? [];
    String chatGroupId = params?.data?["chatGroupId"] ?? "";
    CallMediaType mediaType =
        params?.data?["mediaType"] ?? CallMediaType.audio;
    int timeout = params?.data?["timeout"] ?? 30;

    CallParams callParams = CallParams();
    callParams.chatGroupId = chatGroupId;
    callParams.timeout = timeout;

    TUICallKitImpl.instance.calls(participantIds, mediaType, callParams);
  }

  void handleStartJoin(String? key, NotifyParams? params) {
    String callId = params?.data?["callId"] ?? "";
    TUICallKitImpl.instance.join(callId);
  }
}