import 'package:tuikit_atomic_x/call/call_view.dart';
import 'package:tuikit_atomic_x/call/common/widget/controls_button.dart';
import 'package:tuikit_atomic_x/call/component/stream_widget/single_call_stream_widget.dart';
import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/material.dart';
import 'package:tuikit_atomic_x/call/common/i18n/i18n_utils.dart';

typedef _ViewBuilder = Widget Function();

class SingleCallControlsWidget extends StatelessWidget {
  final List<CallFeature> disableFeatures;
  late final Map<String, _ViewBuilder> _viewStrategies;

  SingleCallControlsWidget({
    super.key,
    required this.disableFeatures,
  }) {
    _viewStrategies = _getViewStrategies();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: SingleCallUserWidgetData.isOnlyShowVideoView,
      builder: (context, value, child) {
        if (value) {
          return Container();
        }
        return ValueListenableBuilder(
          valueListenable: CallStore.shared.state.activeCall,
          builder: (context, activeCall, child) {
            if (activeCall.mediaType == null) {
              return Container();
            }
            final type = activeCall.mediaType!;
            return ValueListenableBuilder(
                valueListenable: CallParticipantStore.shared.state.selfInfo,
                builder: (context, selfInfo, child) {
                  if (selfInfo.id == activeCall.inviterId) {
                    return _selectViewStrategy(type, selfInfo.status, "caller");
                  }
                  return _selectViewStrategy(type, selfInfo.status, "called");
                });
          },
        );
      },
    );
  }

  Map<String, _ViewBuilder> _getViewStrategies() {
    return {
      'audio_waiting_caller': _buildAudioCallerWaitingView,
      'audio_waiting_called': _buildAudioAndVideoCalleeWaitingView,
      'audio_accept': _buildAudioAcceptedView,
      'video_waiting_caller': _buildVideoCallerWaitingView,
      'video_waiting_called': _buildAudioAndVideoCalleeWaitingView,
      'video_accept': _buildVideoCallerAndCalleeAcceptedView,
    };
  }

  String _generateViewKey(CallMediaType mediaType, CallParticipantStatus status, String role) {
    final mediaStr = mediaType.toString().split('.').last;
    final statusStr = status.toString().split('.').last;

    return '${mediaStr}_${statusStr}_$role'.toLowerCase();
  }

  String _generateAcceptViewKey(CallMediaType mediaType, CallParticipantStatus status) {
    if (status != CallParticipantStatus.accept) return '';

    final mediaStr = mediaType.toString().split('.').last;
    final statusStr = status.toString().split('.').last;

    return '${mediaStr}_${statusStr}'.toLowerCase();
  }

  Widget _selectViewStrategy(CallMediaType mediaType, CallParticipantStatus status, String role) {
    final preciseKey = _generateViewKey(mediaType, status, role);
    if (_viewStrategies.containsKey(preciseKey)) {
      return _viewStrategies[preciseKey]!();
    }

    if (status == CallParticipantStatus.accept) {
      final acceptKey = _generateAcceptViewKey(mediaType, status);
      if (_viewStrategies.containsKey(acceptKey)) {
        return _viewStrategies[acceptKey]!();
      }
    }

    return Container();
  }

  Widget _buildVideoCallerWaitingView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          _getSwitchCameraButton(),
          _getHangupButton(),
          _getCameraControlButton(),
        ]),
      ],
    );
  }

  Widget _buildAudioAndVideoCalleeWaitingView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          _getRejectButton(),
          _getAcceptButton(),
        ]),
      ],
    );
  }

  Widget _buildAudioCallerWaitingView() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _getMicControlButton(),
        _getHangupButton(),
        _getSpeakerphoneButton(),
      ],
    );
  }

  Widget _buildAudioAcceptedView() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _getMicControlButton(),
        _getHangupButton(),
        _getSpeakerphoneButton(),
      ],
    );
  }

  Widget _buildVideoCallerAndCalleeAcceptedView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _getMicControlButton(),
            _getSpeakerphoneButton(),
            _getCameraControlButton(),
          ],
        ),
        const SizedBox(
          height: 20,
        ),
        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          const SizedBox(
            width: 100,
          ),
          _getHangupButton(),
          ValueListenableBuilder(
              valueListenable: DeviceStore.shared.state.cameraStatus,
              builder: (context, value, child) {
                return value == DeviceStatus.on
                    ? _getSwitchCameraSmallButton()
                    : const SizedBox(
                        width: 100,
                      );
              }),
        ]),
      ],
    );
  }

  Widget _getSwitchCameraButton() {
    return ControlsButton(
      isDisabled: _isWidgetDisabled(CallFeature.switchCamera),
      imgUrl: "call_assets/switch_camera_group.png",
      tips: CallKit_t("switchCamera"),
      textColor: _getTextColor(),
      imgHeight: 60,
      onTap: () {
        DeviceStore.shared.switchCamera(!DeviceStore.shared.state.isFrontCamera.value);
      },
    );
  }

  Widget _getAcceptButton() {
    return ControlsButton(
      isDisabled: _isWidgetDisabled(CallFeature.accept),
      imgUrl: "call_assets/dialing.png",
      tips: CallKit_t("accept"),
      textColor: Colors.white,
      imgHeight: 60,
      onTap: () {
        CallStore.shared.accept();
      },
    );
  }

  Widget _getHangupButton() {
    return ControlsButton(
      isDisabled: _isWidgetDisabled(CallFeature.hangup),
      imgUrl: "call_assets/hangup.png",
      tips: CallKit_t("hangUp"),
      textColor: Colors.white,
      imgHeight: 60,
      onTap: () {
        CallStore.shared.hangup();
      },
    );
  }

  Widget _getRejectButton() {
    return ControlsButton(
      isDisabled: _isWidgetDisabled(CallFeature.hangup),
      imgUrl: "call_assets/hangup.png",
      tips: CallKit_t("hangUp"),
      textColor: Colors.white,
      imgHeight: 60,
      onTap: () {
        CallStore.shared.reject();
      },
    );
  }

  Widget _getMicControlButton() {
    return ValueListenableBuilder(
        valueListenable: DeviceStore.shared.state.microphoneStatus,
        builder: (context, value, child) {
          return ControlsButton(
            isDisabled: _isWidgetDisabled(CallFeature.toggleMicrophone),
            imgUrl: value == DeviceStatus.on ? "call_assets/mute.png" : "call_assets/mute_on.png",
            tips: value == DeviceStatus.on ? CallKit_t("microphoneIsOn") : CallKit_t("microphoneIsOff"),
            textColor: _getTextColor(),
            imgHeight: 60,
            onTap: () {
              if (value == DeviceStatus.on) {
                DeviceStore.shared.closeLocalMicrophone();
              } else {
                DeviceStore.shared.openLocalMicrophone();
              }
            },
          );
        });
  }

  Widget _getSpeakerphoneButton() {
    return ValueListenableBuilder(
        valueListenable: DeviceStore.shared.state.currentAudioRoute,
        builder: (context, value, child) {
          return ControlsButton(
            isDisabled: _isWidgetDisabled(CallFeature.selectAudioRoute),
            imgUrl: value == AudioRoute.speakerphone ? "call_assets/handsfree_on.png" : "call_assets/handsfree.png",
            tips: value == AudioRoute.speakerphone ? CallKit_t("speakerIsOn") : CallKit_t("speakerIsOff"),
            textColor: _getTextColor(),
            imgHeight: 60,
            onTap: () {
              if (value == AudioRoute.speakerphone) {
                DeviceStore.shared.setAudioRoute(AudioRoute.earpiece);
              } else {
                DeviceStore.shared.setAudioRoute(AudioRoute.speakerphone);
              }
            },
          );
        });
  }

  Widget _getCameraControlButton() {
    return ValueListenableBuilder(
        valueListenable: DeviceStore.shared.state.cameraStatus,
        builder: (context, value, child) {
          return ControlsButton(
            isDisabled: _isWidgetDisabled(CallFeature.toggleCamera),
            imgUrl: value == DeviceStatus.on ? "call_assets/camera_on.png" : "call_assets/camera_off.png",
            tips: value == DeviceStatus.on ? CallKit_t("cameraIsOn") : CallKit_t("cameraIsOff"),
            textColor: _getTextColor(),
            imgHeight: 60,
            onTap: () {
              if (value == DeviceStatus.on) {
                DeviceStore.shared.closeLocalCamera();
              } else {
                DeviceStore.shared.openLocalCamera(DeviceStore.shared.state.isFrontCamera.value);
              }
            },
          );
        });
  }

  Widget _getSwitchCameraSmallButton() {
    return ValueListenableBuilder(
        valueListenable: DeviceStore.shared.state.isFrontCamera,
        builder: (context, value, child) {
          return ControlsButton(
            isDisabled: _isWidgetDisabled(CallFeature.switchCamera),
            imgUrl: "call_assets/switch_camera.png",
            tips: '',
            textColor: _getTextColor(),
            imgHeight: 28,
            imgOffsetX: -16,
            onTap: () {
              DeviceStore.shared.switchCamera(!DeviceStore.shared.state.isFrontCamera.value);
            },
          );
        });
  }

  bool _isWidgetDisabled(CallFeature feature) {
    return disableFeatures.contains(CallFeature.all) || disableFeatures.contains(feature);
  }

  Color _getTextColor() {
    return Colors.white;
  }
}
