import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/material.dart';

import '../../../../ai/ai_transcriber.dart';
import '../../../common/call_colors.dart';
import '../../../common/constants.dart';
import '../../aisubtitle/ai_subtitle.dart';
import '../../../common/utils/utils.dart';
import '../../controls/single_call_controls_widget.dart';
import '../../hint/hint_widget.dart';
import '../../hint/timer_widget.dart';

class CallFloatWidget extends StatefulWidget {
  final CallCoreController controller;
  final bool enableAITranscriber;

  const CallFloatWidget({
    super.key,
    required this.controller,
    this.enableAITranscriber = false,
  });

  @override
  State<StatefulWidget> createState() => _CallFloatWidgetState();
}

class _CallFloatWidgetState extends State<CallFloatWidget> {
  final GlobalKey _controlsKey = GlobalKey();
  double _controlsHeight = 120;

  void _measureControlsHeight() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final renderBox = _controlsKey.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox != null && mounted) {
        final height = renderBox.size.height;
        if (height != _controlsHeight) {
          setState(() {
            _controlsHeight = height;
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    _measureControlsHeight();
    var activeCall = CallStore.shared.state.activeCall.value;
    return ValueListenableBuilder(
      valueListenable: CallStore.shared.state.selfInfo,
      builder: (context, self, child) {
        return Stack(
          children: [
            CallCoreView(
              controller: widget.controller,
              defaultAvatar: Constants.defaultAvatarImage,
            ),
            _buildUserInfoWidget(context),
            Positioned(
              top: MediaQuery.of(context).size.height * 2 / 3,
              width: MediaQuery.of(context).size.width,
              child: const Center(child: HintWidget()),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: activeCall.mediaType == CallMediaType.video ? 240 : 120,
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.9,
                  maxHeight: MediaQuery.of(context).size.height * 0.3,
                ),
                child: AISubtitle(userId: CallStore.shared.state.selfInfo.value.id),
              ),
            ),

            if (widget.enableAITranscriber && self.status == CallParticipantStatus.accept)
              AITranscriberPanel(bottomOffset: _controlsHeight + 48),

            Positioned(
              right: 0,
              left: 0,
              bottom: 40,
              child: SingleCallControlsWidget(key: _controlsKey),
            ),
            _getTimerWidget(),
            _buildAITranscriberBtnWidget(),
          ],
        );
      },
    );
  }

  Widget _buildUserInfoWidget(BuildContext context) {
    if (CallStore.shared.state.activeCall.value.mediaType == CallMediaType.video
        && CallStore.shared.state.selfInfo.value.status == CallParticipantStatus.accept) {
      return Container();
    }
    return Positioned(
      top: MediaQuery.of(context).size.height / 4,
      width: MediaQuery.of(context).size.width,
      child: ValueListenableBuilder(
        valueListenable: CallStore.shared.state.allParticipants,
        builder: (context, allParticipants, child) {
          CallParticipantInfo? remoteParticipant;
          for (var participant in allParticipants) {
            if (participant.id != CallStore.shared.state.selfInfo.value.id) {
              remoteParticipant = participant;
            }
          }
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                height: 100,
                width: 100,
                clipBehavior: Clip.hardEdge,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
                child: Image(
                  image: NetworkImage(
                    StringStream.makeNull(remoteParticipant?.avatarURL, Constants.defaultAvatar),
                  ),
                  fit: BoxFit.cover,
                  errorBuilder: (ctx, err, stackTrace) => Image.asset(
                    'call_assets/user_icon.png',
                    package: 'tuikit_atomic_x',
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                remoteParticipant != null
                    ? _getUserDisplayName(remoteParticipant)
                    : "",
                textScaleFactor: 1.0,
                style: TextStyle(
                  fontSize: 18,
                  color: _getUserNameColor(),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _getTimerWidget() {
    return Positioned(
      top: 20,
      width: MediaQuery.of(context).size.width,
      height: 100,
      child: const Center(
        child: TimerWidget(),
      ),
    );
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

  _getUserNameColor() {
    return CallStore.shared.state.activeCall.value.mediaType == CallMediaType.audio
        ? CallColors.colorG7
        : CallColors.colorWhite;
  }

  _buildAITranscriberBtnWidget() {
    return ValueListenableBuilder(
      valueListenable: CallStore.shared.state.selfInfo,
      builder: (context, selfInfo, child) {
        if (selfInfo.status != CallParticipantStatus.accept || !widget.enableAITranscriber) {
          return const SizedBox();
        }
        return const Positioned(
          left: 52,
          top: 52,
          width: 40,
          height: 40,
          child: AITranscriberButton(),
        );
      },
    );
  }
}