import "package:atomic_x/atomicx.dart";
import "package:atomic_x/base_component/utils/tui_event_bus.dart";
import "package:tencent_calls_uikit/src/tui_call_kit_impl.dart";

class EventBusHandler extends TUIObserver {
  static final EventBusHandler _instance = EventBusHandler();
  static EventBusHandler get instance => _instance;

  EventBusHandler() {
    TUIEventBus.shared.subscribe("call.startCall", null, this);
  }
  
  @override
  void onNotify(String event, String? key, NotifyParams? params) {
    if (event != "call.startCall" || params == null || params.data == null || params.data!.isEmpty) {
      return;
    }

    List<String> participantIds = params.data?["participantIds"] ?? [];
    String chatGroupId = params.data?["chatGroupId"] ?? "";
    TUICallMediaType mediaType = params.data?["mediaType"] ?? TUICallMediaType.audio;
    int timeout = params.data?["timeout"] ?? 30;
    TUIOfflinePushInfo offlinePushInfo = params.data?["offlinePushInfo"];

    TUICallParams callParams = TUICallParams();
    callParams.chatGroupId = chatGroupId;
    callParams.timeout = timeout;
    callParams.offlinePushInfo = offlinePushInfo;

    TUICallKitImpl.instance.calls(participantIds, mediaType, callParams);
  }
}