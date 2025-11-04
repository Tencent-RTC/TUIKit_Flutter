import 'package:atomic_x/call/common/constants.dart';
import 'package:atomic_x/call/common/utils/utils.dart';
import 'package:atomic_x/call/component/stream_widget/multi_call_stream_widget.dart';
import 'package:atomic_x/call/component/stream_widget/stream_view/stream_view_factory.dart';
import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:atomic_x/call/call_view.dart';

class ParticipantStreamView extends StatefulWidget {
  final int index;
  final String userId;
  final ViewConfig config;

  const ParticipantStreamView(
      {Key? key,
        required this.userId,
        required this.index,
        required this.config,})
      : super(key: key);

  @override
  State<ParticipantStreamView> createState() => _ParticipantStreamViewState();
}

class _ParticipantStreamViewState extends State<ParticipantStreamView> {
  @override
  void initState() {
    if (CallParticipantStore.shared.state.selfInfo.value.id == widget.userId
        && CallListStore.shared.state.activeCall.value.mediaType == TUICallMediaType.video) {
      DeviceStore.shared.openLocalCamera(true);
    }
    super.initState();
  }

  @override
  void dispose() {
    if (CallParticipantStore.shared.state.selfInfo.value.id == widget.userId) {
      DeviceStore.shared.closeLocalCamera();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
        valueListenable: CallListStore.shared.state.activeCall,
        builder: (context, activeCall, child) {
          final isMultiCall = activeCall.chatGroupId.isNotEmpty
              || activeCall.inviteeIds.length > 1;
          return ValueListenableBuilder(
            valueListenable: CallParticipantStore.shared.state.allParticipants,
            builder: (context, allParticipants, child) {
              CallParticipantInfo? info;
              for (var participant in allParticipants) {
                if (participant.id == widget.userId) {
                  info = participant;
                }
              }
              if (info == null) {
                return const Center(
                  child: _LoadingAnimation(isCircular: true,),
                );
              }
              return isMultiCall
                  ? _buildMultiCallStreamView(info)
                  : _buildSingleCallStreamView(info);
            },
          );
        },
    );
  }

  Widget _buildMultiCallStreamView(CallParticipantInfo info) {
    return ValueListenableBuilder(
      valueListenable: MultiCallUserWidgetData.blockBigger,
      builder: (context, _, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            AbsorbPointer(
              absorbing: true,
              child: ParticipantView(participantId: info.id),
            ),
            Visibility(
              visible: _isShowBackgroundImage(info),
              child: Positioned.fill(
                child: _getUserAvatar(info),
              ),
            ),
            Visibility(
              visible: info.status == TUICallStatus.waiting,
              child: const Center(child: _LoadingAnimation(),),
            ),
            _getSwitchCameraButton(info),
            _getNetworkQualityReminder(info),
            _getUserStateDisplay(info),
          ],
        );
      },
    );
  }

  Widget _buildSingleCallStreamView(CallParticipantInfo info) {
    return Stack(
      alignment: Alignment.center,
      children: [
        ParticipantView(participantId: info.id),
        _getBackgroundImage(info),
      ],
    );
  }

  Widget _getSwitchCameraButton(CallParticipantInfo info) {
    return Visibility(
      visible: !widget.config.disableFeatures.contains(CallFeature.all)
          && CallParticipantStore.shared.state.selfInfo.value.id == info.id
          && DeviceStore.shared.state.cameraStatus.value == DeviceSwitchStatus.on
          && MultiCallUserWidgetData.blockBigger.value[widget.index]!,
      child: Positioned(
        right: 10,
        bottom: 5,
        width: 24,
        height: 24,
        child: InkWell(
            onTap: () {
              DeviceStore.shared.switchCamera(!DeviceStore.shared.state.isFrontCamera.value);
            },
            child: Container(
                decoration: BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.rectangle,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Stack(
                  alignment: AlignmentDirectional.center,
                  children: [
                    Positioned(
                      width: 14,
                      height: 14,
                      child: Image.asset(
                        "call_assets/switch_camera.png",
                        package: 'atomic_x',
                        width: 14,
                        height: 14,
                      ),
                    ),
                  ],
                ),
            ),
        ),
      ),
    );
  }

  Widget _getNetworkQualityReminder(CallParticipantInfo info) {
    return Positioned(
      right: _getNetworkBadHintRightMargin(info),
      bottom: 5,
      width: 24,
      height: 24,
      child: ValueListenableBuilder(
        valueListenable: CallParticipantStore.shared.state.networkQualities,
        builder: (context, map, child) {
          return Visibility(
            visible: !widget.config.disableFeatures.contains(CallFeature.all)
                && !widget.config.disableFeatures.contains(CallFeature.networkQuality)
                && _isBadNetWork(map[widget.userId]),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.rectangle,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Image.asset(
                "call_assets/network_bad.png",
                package: 'atomic_x',
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _getUserStateDisplay(CallParticipantInfo info) {
    return Positioned(
      left: 5,
      bottom: 5,
      height: 24,
      child: Row(
        children: [
          Visibility(
            visible: MultiCallUserWidgetData.blockBigger.value[widget.index]!,
            child: Row(
              children: [
                Text(
                  _getUserDisplayName(info),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(width: 10,),
              ],
            ),
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              ValueListenableBuilder(
                valueListenable: CallParticipantStore.shared.state.speakerVolumes,
                builder: (context, map, _) {
                  if (!widget.config.disableFeatures.contains(CallFeature.all)
                      && map.containsKey(widget.userId) && map[widget.userId]! > 0) {
                    return Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.rectangle,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Image.asset(
                          "call_assets/speaking.png",
                          package: 'atomic_x',
                        )
                    );
                  }
                  return const SizedBox();
                },),
              Visibility(
                visible: !widget.config.disableFeatures.contains(CallFeature.all)
                    && CallParticipantStore.shared.state.selfInfo.value.id == widget.userId
                    && !CallParticipantStore.shared.state.selfInfo.value.isMicrophoneOpened,
                child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.rectangle,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Image.asset(
                      "call_assets/audio_unavailable.png",
                      package: 'atomic_x',
                    )),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _getBackgroundImage(CallParticipantInfo info) {
    return Visibility(
      visible: _isShowBackgroundImage(info),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: _getUserAvatar(info),
          ),
          Opacity(
              opacity: 1,
              child: Container(
                color: const Color.fromRGBO(45, 45, 45, 0.9),
              ),
          ),
          Visibility(
            visible: info.status == TUICallStatus.accept
            && CallListStore.shared.state.activeCall.value.mediaType == TUICallMediaType.video,
            child: Center(
              child: Container(
                height: 80,
                width: 80,
                clipBehavior: Clip.hardEdge,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
                child: _getUserAvatar(info),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _getUserAvatar(CallParticipantInfo info) {
    return Image(
      image: NetworkImage(
        StringStream.makeNull(info.avatarURL, Constants.defaultAvatar),
      ),
      fit: BoxFit.cover,
      errorBuilder: (ctx, err, stackTrace) => Image.asset(
        'call_assets/user_icon.png',
        package: 'atomic_x',
      ),
    );
  }

  bool _isBadNetWork(TUINetworkQuality? network) {
    return network == TUINetworkQuality.qualityBad
        || network == TUINetworkQuality.qualityVeryBad
        || network == TUINetworkQuality.qualityDown;
  }
  
  bool _isShowBackgroundImage(CallParticipantInfo info) {
    return info.id == CallParticipantStore.shared.state.selfInfo.value.id 
        ? DeviceStore.shared.state.cameraStatus.value == DeviceSwitchStatus.off
        : !info.isCameraOpened;
  }

  double _getNetworkBadHintRightMargin(CallParticipantInfo info) {
    return MultiCallUserWidgetData.blockBigger.value[widget.index]!
        ? info.isCameraOpened ? 90 : 10
        : 10;
  }

  String _getUserDisplayName(CallParticipantInfo info) {
    if (info.remark.isNotEmpty) {
      return info.remark;
    } else if (info.name.isNotEmpty) {
      return info.name;
    } else {
      return info.id;
    }
  }
}

class _LoadingAnimation extends StatefulWidget {
  final bool isCircular;

  const _LoadingAnimation({Key? key, this.isCircular = false}) : super(key: key);

  @override
  _LoadingAnimationState createState() => _LoadingAnimationState();
}

class _LoadingAnimationState extends State<_LoadingAnimation> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        if (widget.isCircular) {
          return Transform.rotate(
            angle: _controller.value * 2 * 3.1415926535,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 2,
                ),
              ),
            ),
          );
        } else {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (index) => _buildDot(index)),
          );
        }
      },
    );
  }

  Widget _buildDot(int index) {
    final double opacity = _calculateOpacity(index);
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: Transform.scale(
        scale: 10.0 / 20,
        child: Opacity(
          opacity: opacity,
          child: Container(
            width: 20,
            height: 20,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  double _calculateOpacity(int index) {
    return ((1.0 - ((_controller.value - 0.33 * index) % 1.0)) * 10 + 5) / 20;
  }
}