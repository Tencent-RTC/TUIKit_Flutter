part of '../../../api/view/call/call_core_view.dart';


class CallCoreControllerImpl extends CallCoreController {
  CallCoreControllerImpl() {
    final activeCall = CallStore.shared.state.activeCall.value;

    if (activeCall.chatGroupId.isNotEmpty || activeCall.inviteeIds.length > 1) {
      _currentTemplate.value = CallLayoutTemplate.grid;
    } else {
      _currentTemplate.value = CallLayoutTemplate.float;
    }
  }

  @override
  void setLayoutTemplate(CallLayoutTemplate template) {
    final activeCall = CallStore.shared.state.activeCall.value;
    if (template == CallLayoutTemplate.float && activeCall.inviteeIds.length > 1) {
      debugPrint('[CallCoreView] setLayoutTemplate fail. The Float layout type only supports a single invited participant.');
      return;
    }
    _currentTemplate.value = template;
  }

  @override
  void enableVideoZoomGesture(bool enable) {
    debugPrint('[CallCoreView] enableVideoZoomGesture enable: $enable');
    _zoomEnabled = enable;
  }

  @override
  void dispose() {
    _currentTemplate.dispose();
  }
}

class _CallCoreViewState extends State<CallCoreView> {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: widget.controller._currentTemplate,
      builder: (context, template, child) {
        final zoomEnabled = widget.controller._zoomEnabled;
        switch (template) {
          case CallLayoutTemplate.float:
            return CallFloatView(
              defaultAvatar: widget.defaultAvatar,
              enableZoom: zoomEnabled,
            );
          case CallLayoutTemplate.grid:
            return CallGridView(
              loadingAnimation: widget.loadingAnimation,
              defaultAvatar: widget.defaultAvatar,
              volumeIcons: widget.volumeIcons,
              networkQualityIcons: widget.networkQualityIcons,
              enableZoom: zoomEnabled,
            );
          case CallLayoutTemplate.pip:
            return CallPipView(
              defaultAvatar: widget.defaultAvatar,
            );
          // ignore: unreachable_switch_default
          default:
            return CallGridView(
              loadingAnimation: widget.loadingAnimation,
              defaultAvatar: widget.defaultAvatar,
              volumeIcons: widget.volumeIcons,
              networkQualityIcons: widget.networkQualityIcons,
              enableZoom: zoomEnabled,
            );
        }
      },
    );
  }
}
