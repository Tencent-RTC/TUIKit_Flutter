import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/material.dart';
import 'package:tuikit_atomic_x/call/common/i18n/i18n_utils.dart';
import 'package:tuikit_atomic_x/call/common/widget/controls_button.dart';
import 'package:tuikit_atomic_x/call/call_view.dart';

class MultiCallControlsWidget extends StatefulWidget {
  final List<CallFeature> disableFeatures;

  const MultiCallControlsWidget({
    super.key,
    required this.disableFeatures,
  });

  @override
  State<MultiCallControlsWidget> createState() => _MultiCallControlsWidgetState();
}

class _MultiCallControlsWidgetState extends State<MultiCallControlsWidget> {
  final double bigBtnHeight = 52;
  final double smallBtnHeight = 35;
  final double edge = 40;
  final double bottomEdge = 10;
  final int duration = 300;
  final int btnWidth = 100;

  bool isFunctionExpand = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
        valueListenable: CallParticipantStore.shared.state.selfInfo,
        builder: (context, selfInfo, child) {
          if (selfInfo.status == CallParticipantStatus.waiting
              && selfInfo.id != CallStore.shared.state.activeCall.value.inviterId) {
            return _buildWaitingFunctionView();
          } else {
            return _buildAcceptedFunctionView(context);
          }
        }
    );
  }

  _buildWaitingFunctionView() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _getRejectButton(),
            _getAcceptButton(),
          ],
        ),
      ],
    );
  }

  _buildAcceptedFunctionView(BuildContext context) {
    Curve curve = Curves.easeInOut;
    return ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16.0),
          topRight: Radius.circular(16.0),
        ),
        child: GestureDetector(
            onVerticalDragUpdate: (details) => _functionWidgetVerticalDragUpdate(details),
            child: AnimatedContainer(
                curve: curve,
                height: isFunctionExpand ? 200 : 90,
                duration: Duration(milliseconds: duration),
                color: const Color.fromRGBO(52, 56, 66, 1.0),
                child: Stack(
                  children: [
                    AnimatedPositioned(
                      curve: curve,
                      duration: Duration(milliseconds: duration),
                      left: isFunctionExpand
                          ? ((MediaQuery.of(context).size.width / 4) - (btnWidth / 2))
                          : (MediaQuery.of(context).size.width * 2 / 6 - btnWidth / 2),
                      bottom: isFunctionExpand
                          ? bottomEdge + bigBtnHeight + edge
                          : bottomEdge,
                      child: _getAnimatedMicButton(isFunctionExpand),
                    ),
                    AnimatedPositioned(
                      curve: curve,
                      duration: Duration(milliseconds: duration),
                      left: isFunctionExpand
                          ? (MediaQuery.of(context).size.width / 2 - btnWidth / 2)
                          : (MediaQuery.of(context).size.width * 3 / 6 - btnWidth / 2),
                      bottom: isFunctionExpand
                          ? bottomEdge + bigBtnHeight + edge
                          : bottomEdge,
                      child: _getAnimatedSpeakerPhoneButton(isFunctionExpand),
                    ),
                    AnimatedPositioned(
                      curve: curve,
                      duration: Duration(milliseconds: duration),
                      left: isFunctionExpand
                          ? (MediaQuery.of(context).size.width * 3 / 4 - btnWidth / 2)
                          : (MediaQuery.of(context).size.width * 4 / 6 - btnWidth / 2),
                      bottom: isFunctionExpand
                          ? bottomEdge + bigBtnHeight + edge
                          : bottomEdge,
                      child: _getAnimatedCameraButton(isFunctionExpand),
                    ),
                    AnimatedPositioned(
                      curve: curve,
                      duration: Duration(milliseconds: duration),
                      left: isFunctionExpand
                          ? (MediaQuery.of(context).size.width / 2 - btnWidth / 2)
                          : (MediaQuery.of(context).size.width * 5 / 6 - btnWidth / 2),
                      bottom: bottomEdge,
                      child: _getAnimatedHangupButton(isFunctionExpand),
                    ),
                    AnimatedPositioned(
                        curve: curve,
                        duration: Duration(milliseconds: duration),
                        left: (MediaQuery.of(context).size.width / 6 - smallBtnHeight / 2),
                        bottom: isFunctionExpand
                            ? bottomEdge + smallBtnHeight / 4 + 22
                            : bottomEdge + 22,
                        child: InkWell(
                          onTap: () {
                            isFunctionExpand = !isFunctionExpand;
                            setState(() {});
                          },
                          child: Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.identity()
                              ..scale(1.0, isFunctionExpand ? 1.0 : -1.0, 1.0),
                            child: Image.asset(
                              'call_assets/arrow.png',
                              package: 'tuikit_atomic_x',
                              width: smallBtnHeight,
                            ),
                          ),
                        ))
                  ],
                ))));
  }

  _functionWidgetVerticalDragUpdate(DragUpdateDetails details) {
    if (details.delta.dy < 0 && !isFunctionExpand) {
      isFunctionExpand = true;
    } else if (details.delta.dy > 0 && isFunctionExpand) {
      isFunctionExpand = false;
    }
    setState(() {});
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


  Widget _getAnimatedMicButton(bool isFunctionExpand) {
    return ValueListenableBuilder(
        valueListenable: DeviceStore.shared.state.microphoneStatus,
        builder: (context, value, child) {
          return ControlsButton(
            isDisabled: _isWidgetDisabled(CallFeature.toggleMicrophone),
            imgUrl: value == DeviceSwitchStatus.on
                ? "call_assets/mute.png"
                : "call_assets/mute_on.png",
            tips: isFunctionExpand
                ? (value == DeviceSwitchStatus.on
                ? CallKit_t("microphoneIsOn")
                : CallKit_t("microphoneIsOff"))
                : '',
            textColor: Colors.white,
            imgHeight: isFunctionExpand
                ? bigBtnHeight
                : smallBtnHeight,
            onTap: () {
              if (value == DeviceSwitchStatus.on) {
                DeviceStore.shared.closeLocalMicrophone();
              } else {
                DeviceStore.shared.openLocalMicrophone();
              }
            },
            useAnimation: true,
            duration: Duration(milliseconds: duration),
          );
        }
    );
  }

  Widget _getAnimatedSpeakerPhoneButton(bool isFunctionExpand) {
    return ValueListenableBuilder(
        valueListenable: DeviceStore.shared.state.currentAudioRoute,
        builder: (context, value, child) {
          return ControlsButton(
            isDisabled: _isWidgetDisabled(CallFeature.selectAudioRoute),
            imgUrl: value == AudioRoute.speakerphone
                ? "call_assets/handsfree_on.png"
                : "call_assets/handsfree.png",
            tips: isFunctionExpand
                ? (value == AudioRoute.speakerphone
                ? CallKit_t("speakerIsOn")
                : CallKit_t("speakerIsOff"))
                : '',
            textColor: Colors.white,
            imgHeight: isFunctionExpand
                ? bigBtnHeight
                : smallBtnHeight,
            onTap: () {
              if (value == AudioRoute.speakerphone) {
                DeviceStore.shared.setAudioRoute(AudioRoute.earpiece);
              } else {
                DeviceStore.shared.setAudioRoute(AudioRoute.speakerphone);
              }
            },
            useAnimation: true,
            duration: Duration(milliseconds: duration),
          );
        }
    );
  }

  Widget _getAnimatedCameraButton(bool isFunctionExpand) {
    return ValueListenableBuilder(
        valueListenable: DeviceStore.shared.state.cameraStatus,
        builder: (context, value, child) {
          return ControlsButton(
            isDisabled: _isWidgetDisabled(CallFeature.toggleCamera),
            imgUrl: value == DeviceSwitchStatus.on
                ? "call_assets/camera_on.png"
                : "call_assets/camera_off.png",
            tips: isFunctionExpand
                ? (value == DeviceSwitchStatus.on
                ? CallKit_t("cameraIsOn")
                : CallKit_t("cameraIsOff"))
                : '',
            textColor: Colors.white,
            imgHeight: isFunctionExpand
                ? bigBtnHeight
                : smallBtnHeight,
            onTap: () {
              if (value == DeviceSwitchStatus.on) {
                DeviceStore.shared.closeLocalCamera();
              } else {
                DeviceStore.shared.openLocalCamera(DeviceStore.shared.state.isFrontCamera.value);
              }
            },
            useAnimation: true,
            duration: Duration(milliseconds: duration),
          );
        }
    );
  }

  Widget _getAnimatedHangupButton(bool isFunctionExpand) {
    return ControlsButton(
      isDisabled: _isWidgetDisabled(CallFeature.hangup),
      imgUrl: "call_assets/hangup.png",
      textColor: Colors.white,
      imgHeight: isFunctionExpand
          ? bigBtnHeight
          : smallBtnHeight,
      onTap: () {
        CallStore.shared.hangup();
      },
      useAnimation: true,
      duration: Duration(milliseconds: duration),
    );
  }
  
  bool _isWidgetDisabled(CallFeature feature) {
    return widget.disableFeatures.contains(CallFeature.all) || widget.disableFeatures.contains(feature);
  }
}