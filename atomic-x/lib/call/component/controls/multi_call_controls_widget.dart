import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/material.dart';
import 'package:tuikit_atomic_x/base_component/localizations/atomic_localizations.dart';
import 'package:tuikit_atomic_x/call/common/widget/controls_button.dart';

import '../../common/call_colors.dart';

class MultiCallControlsWidget extends StatefulWidget {
  final ValueChanged<double>? onHeightChanged;

  const MultiCallControlsWidget({
    super.key,
    this.onHeightChanged,
  });

  @override
  State<MultiCallControlsWidget> createState() => _MultiCallControlsWidgetState();
}

class _MultiCallControlsWidgetState extends State<MultiCallControlsWidget> {
  final double bigBtnHeight = 56;
  final double smallBtnHeight = 42;
  final double edge = 40;
  final double bottomEdge = 16;
  final double collapsedBottomEdge = 28;
  final int duration = 300;
  final int btnWidth = 100;

  bool isFunctionExpand = false;
  late AtomicLocalizations _l10n;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    _l10n = AtomicLocalizations.of(context);
    return ValueListenableBuilder(
        valueListenable: CallStore.shared.state.selfInfo,
        builder: (context, selfInfo, child) {
          if (selfInfo.status == CallParticipantStatus.waiting &&
              selfInfo.id != CallStore.shared.state.activeCall.value.inviterId) {
            return _buildWaitingFunctionView();
          } else {
            return _buildAcceptedFunctionView(context);
          }
        });
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
        const SizedBox(height: 40,),
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
                height: isFunctionExpand ? 210 : 115,
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
                      bottom: isFunctionExpand ? bottomEdge + bigBtnHeight + edge : collapsedBottomEdge,
                      child: _getAnimatedMicButton(isFunctionExpand),
                    ),
                    AnimatedPositioned(
                      curve: curve,
                      duration: Duration(milliseconds: duration),
                      left: isFunctionExpand
                          ? (MediaQuery.of(context).size.width / 2 - btnWidth / 2)
                          : (MediaQuery.of(context).size.width * 3 / 6 - btnWidth / 2),
                      bottom: isFunctionExpand ? bottomEdge + bigBtnHeight + edge : collapsedBottomEdge,
                      child: _getAnimatedSpeakerPhoneButton(isFunctionExpand),
                    ),
                    AnimatedPositioned(
                      curve: curve,
                      duration: Duration(milliseconds: duration),
                      left: isFunctionExpand
                          ? (MediaQuery.of(context).size.width * 3 / 4 - btnWidth / 2)
                          : (MediaQuery.of(context).size.width * 4 / 6 - btnWidth / 2),
                      bottom: isFunctionExpand ? bottomEdge + bigBtnHeight + edge : collapsedBottomEdge,
                      child: _getAnimatedCameraButton(isFunctionExpand),
                    ),
                    AnimatedPositioned(
                      curve: curve,
                      duration: Duration(milliseconds: duration),
                      left: isFunctionExpand
                          ? (MediaQuery.of(context).size.width / 2 - btnWidth / 2)
                          : (MediaQuery.of(context).size.width * 5 / 6 - btnWidth / 2),
                      bottom: isFunctionExpand ? bottomEdge : collapsedBottomEdge,
                      child: _getAnimatedHangupButton(isFunctionExpand),
                    ),
                    AnimatedPositioned(
                        curve: curve,
                        duration: Duration(milliseconds: duration),
                        left: (MediaQuery.of(context).size.width / 6 - smallBtnHeight / 2),
                        bottom: isFunctionExpand ? bottomEdge + smallBtnHeight / 4 + 22 : bottomEdge + 35,
                        child: InkWell(
                          onTap: () {
                            isFunctionExpand = !isFunctionExpand;
                            widget.onHeightChanged?.call(isFunctionExpand ? 210 : 115);
                            setState(() {});
                          },
                          child: Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.identity()..scale(1.0, isFunctionExpand ? 1.0 : -1.0, 1.0),
                            child: Image.asset(
                              'call_assets/arrow.png',
                              package: 'tuikit_atomic_x',
                              width: smallBtnHeight,
                            ),
                          ),
                        )),
                    AnimatedPositioned(
                        curve: curve,
                        duration: Duration(milliseconds: duration),
                        left: (MediaQuery.of(context).size.width * 3 / 4 - bigBtnHeight / 2 - 20),
                        bottom: isFunctionExpand
                            ? bottomEdge + smallBtnHeight / 4
                            : bottomEdge + 35,
                        child: AnimatedOpacity(
                          duration: Duration(milliseconds: duration),
                          opacity: isFunctionExpand ? 1.0 : 0.0,
                          child: IgnorePointer(
                            ignoring: !isFunctionExpand,
                            child: ValueListenableBuilder(
                                valueListenable: DeviceStore.shared.state.cameraStatus,
                                builder: (context, value, child) {
                                  if (value != DeviceStatus.on) {
                                    return SizedBox(width: btnWidth.toDouble(), height: 28);
                                  }
                                  return _getSwitchCameraSmallButton();
                                }),
                          ),
                        )),
                  ],
                ))));
  }

  Widget _getSwitchCameraSmallButton() {
    return ValueListenableBuilder(
        valueListenable: DeviceStore.shared.state.isFrontCamera,
        builder: (context, value, child) {
          return ControlsButton(
            imgUrl: "call_assets/switch_camera.png",
            tips: '',
            textColor: CallColors.colorG7,
            imgHeight: 28,
            imgOffsetX: -16,
            onTap: () {
              DeviceStore.shared.switchCamera(!DeviceStore.shared.state.isFrontCamera.value);
            },
          );
        });
  }

  _functionWidgetVerticalDragUpdate(DragUpdateDetails details) {
    if (details.delta.dy < 0 && !isFunctionExpand) {
      isFunctionExpand = true;
      widget.onHeightChanged?.call(210);
    } else if (details.delta.dy > 0 && isFunctionExpand) {
      isFunctionExpand = false;
      widget.onHeightChanged?.call(115);
    }
    setState(() {});
  }

  Widget _getRejectButton() {
    return ControlsButton(
      imgUrl: "call_assets/hangup.png",
      tips: _l10n.callHangUp,
      textColor: CallColors.colorG7,
      imgHeight: 60,
      onTap: () {
        CallStore.shared.reject();
      },
    );
  }

  Widget _getAcceptButton() {
    return ControlsButton(
      imgUrl: "call_assets/dialing.png",
      tips: _l10n.callAcceptAction,
      textColor: CallColors.colorG7,
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
            imgUrl: value == DeviceStatus.on ? "call_assets/mute.png" : "call_assets/mute_on.png",
            tips: isFunctionExpand
                ? (value == DeviceStatus.on ? _l10n.callMicrophoneIsOn : _l10n.callMicrophoneIsOff)
                : '',
            textColor: CallColors.colorG7,
            imgHeight: isFunctionExpand ? bigBtnHeight : smallBtnHeight,
            onTap: () {
              if (value == DeviceStatus.on) {
                DeviceStore.shared.closeLocalMicrophone();
              } else {
                DeviceStore.shared.openLocalMicrophone();
              }
            },
            useAnimation: true,
            duration: Duration(milliseconds: duration),
          );
        });
  }

  Widget _getAnimatedSpeakerPhoneButton(bool isFunctionExpand) {
    return ValueListenableBuilder(
        valueListenable: DeviceStore.shared.state.currentAudioRoute,
        builder: (context, value, child) {
          return ControlsButton(
            imgUrl: value == AudioRoute.speakerphone ? "call_assets/handsfree_on.png" : "call_assets/handsfree.png",
            tips: isFunctionExpand
                ? (value == AudioRoute.speakerphone ? _l10n.callSpeakerIsOn : _l10n.callSpeakerIsOff)
                : '',
            textColor: CallColors.colorG7,
            imgHeight: isFunctionExpand ? bigBtnHeight : smallBtnHeight,
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
        });
  }

  Widget _getAnimatedCameraButton(bool isFunctionExpand) {
    return ValueListenableBuilder(
        valueListenable: DeviceStore.shared.state.cameraStatus,
        builder: (context, value, child) {
          return ControlsButton(
            imgUrl: value == DeviceStatus.on ? "call_assets/camera_on.png" : "call_assets/camera_off.png",
            tips:
                isFunctionExpand ? (value == DeviceStatus.on ? _l10n.callCameraIsOn : _l10n.callCameraIsOff) : '',
            textColor: CallColors.colorG7,
            imgHeight: isFunctionExpand ? bigBtnHeight : smallBtnHeight,
            onTap: () {
              if (value == DeviceStatus.on) {
                DeviceStore.shared.closeLocalCamera();
              } else {
                DeviceStore.shared.openLocalCamera(DeviceStore.shared.state.isFrontCamera.value);
              }
            },
            useAnimation: true,
            duration: Duration(milliseconds: duration),
          );
        });
  }

  Widget _getAnimatedHangupButton(bool isFunctionExpand) {
    return ControlsButton(
      imgUrl: "call_assets/hangup.png",
      textColor: CallColors.colorG7,
      imgHeight: isFunctionExpand ? bigBtnHeight : smallBtnHeight,
      onTap: () {
        CallStore.shared.hangup();
      },
      useAnimation: true,
      duration: Duration(milliseconds: duration),
    );
  }
}
