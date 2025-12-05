import 'package:tuikit_atomic_x/atomicx.dart';
import 'package:tuikit_atomic_x/call/component/hint/hint_widget.dart';
import 'package:tuikit_atomic_x/call/component/stream_widget/stream_view/stream_view_factory.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:tuikit_atomic_x/call/common/constants.dart';
import 'package:tuikit_atomic_x/call/common/utils/utils.dart';

class SingleCallStreamWidget extends StatefulWidget {
  final List<CallFeature> disableFeatures;

  const SingleCallStreamWidget({
    super.key,
    required this.disableFeatures,
  });

  @override
  State<StatefulWidget> createState() => _SingleCallStreamWidgetState();
}

class _SingleCallStreamWidgetState extends State<SingleCallStreamWidget> {
  double scale = 0.25;

  @override
  void initState() {
    SingleCallUserWidgetData.initIndividualUserWidgetData();
    super.initState();
  }

  @override
  void dispose() {
    StreamViewFactory.instance.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: CallParticipantStore.shared.state.selfInfo,
      builder: (context, selfInfo, child) {
        return Container(
          color: _getBackgroundColor(),
          child: Stack(
            alignment: Alignment.topLeft,
            fit: StackFit.expand,
            children: [
              _buildBigVideoWidget(),
              _buildSmallVideoWidget(),
              ValueListenableBuilder(
                valueListenable: SingleCallUserWidgetData.isOnlyShowVideoView,
                builder: (context, value, child) {
                  return Visibility(
                    visible: CallStore.shared.state.activeCall.value.mediaType == CallMediaType.audio || !value,
                    child: _buildUserInfoWidget(),
                  );
                },
              ),
              ValueListenableBuilder(
                valueListenable: SingleCallUserWidgetData.isOnlyShowVideoView,
                builder: (context, value, child) {
                  return Visibility(
                    visible: !value,
                    child: Positioned(
                      top: MediaQuery.of(context).size.height * 2 / 3,
                      width: MediaQuery.of(context).size.width,
                      child: const Center(
                        child: HintWidget(),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBigVideoWidget() {
    return Stack(
      alignment: Alignment.topLeft,
      fit: StackFit.expand,
      children: [
        _getBigVideoWidget(),
        Positioned.fill(
          child: GestureDetector(
            onTap: () {
              if (CallStore.shared.state.activeCall.value.mediaType == CallMediaType.audio ||
                  CallParticipantStore.shared.state.selfInfo.value.status == CallParticipantStatus.waiting) {
                return;
              }
              SingleCallUserWidgetData.isOnlyShowVideoView.value = !SingleCallUserWidgetData.isOnlyShowVideoView.value;
              setState(() {});
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSmallVideoWidget() {
    if (CallStore.shared.state.activeCall.value.mediaType == CallMediaType.audio
        || CallParticipantStore.shared.state.selfInfo.value.status == CallParticipantStatus.waiting) {
      return const SizedBox();
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    double windowWidth = screenWidth * scale;
    double windowHeight = screenHeight * scale;
    
    return Positioned(
      top: SingleCallUserWidgetData.smallViewTop - 40,
      right: SingleCallUserWidgetData.smallViewRight,
      child: Stack(
        children: [
          SizedBox(
            width: windowWidth,
            child: Container(
              width: windowWidth,
              height: windowHeight,
              decoration: const BoxDecoration(color: Colors.transparent),
              child: SingleCallUserWidgetData.bigViewIndex == 1
                  ? StreamViewFactory.instance.createSingleSelfStreamView()
                  : StreamViewFactory.instance.createSingleRemoteStreamView(),
            ),
          ),
          Positioned.fill(
            child: GestureDetector(
              onTap: () {
                _changeVideoView();
              },
              onPanUpdate: (DragUpdateDetails e) {
                if (CallStore.shared.state.activeCall.value.mediaType == CallMediaType.video) {
                  _refreshViewPosition(e);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserInfoWidget() {
    if (CallStore.shared.state.activeCall.value.mediaType == CallMediaType.video
        && CallParticipantStore.shared.state.selfInfo.value.status == CallParticipantStatus.accept) {
      return Container();
    }
    return Positioned(
      top: MediaQuery.of(context).size.height / 4,
      width: MediaQuery.of(context).size.width,
      child: ValueListenableBuilder(
        valueListenable: CallParticipantStore.shared.state.allParticipants,
        builder: (context, allParticipants, child) {
          CallParticipantInfo? remoteParticipant;
          for (var participant in allParticipants) {
            if (participant.id != CallParticipantStore.shared.state.selfInfo.value.id) {
              remoteParticipant = participant;
            }
          }
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                height: 110,
                width: 110,
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
              const SizedBox(height: 20),
              Text(
                remoteParticipant != null
                    ? _getUserDisplayName(remoteParticipant)
                    : "",
                textScaleFactor: 1.0,
                style: const TextStyle(
                  fontSize: 24,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _getBigVideoWidget() {
    if (CallStore.shared.state.activeCall.value.mediaType == CallMediaType.audio
        || (CallParticipantStore.shared.state.selfInfo.value.status != CallParticipantStatus.waiting
            && SingleCallUserWidgetData.bigViewIndex == 1)) {
      return StreamViewFactory.instance.createSingleRemoteStreamView();
    }
    return StreamViewFactory.instance.createSingleSelfStreamView();
  }

  _changeVideoView() {
    if (CallStore.shared.state.activeCall.value.mediaType == CallMediaType.audio ||
        CallParticipantStore.shared.state.selfInfo.value.status == CallParticipantStatus.waiting) {
      return;
    }

    setState(() {
      SingleCallUserWidgetData.bigViewIndex = SingleCallUserWidgetData.bigViewIndex == 0 ? 1 : 0;
    });
  }

  _getBackgroundColor() {
    return CallStore.shared.state.activeCall.value.mediaType == CallMediaType.audio
        ? const Color(0xFFF2F2F2)
        : const Color(0xFF444444);
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

  _refreshViewPosition(DragUpdateDetails e) {
    SingleCallUserWidgetData.smallViewRight -= e.delta.dx;
    SingleCallUserWidgetData.smallViewTop += e.delta.dy;
    if (SingleCallUserWidgetData.smallViewTop < 100) {
      SingleCallUserWidgetData.smallViewTop = 100;
    }
    if (SingleCallUserWidgetData.smallViewTop > MediaQuery.of(context).size.height - 216) {
      SingleCallUserWidgetData.smallViewTop = MediaQuery.of(context).size.height - 216;
    }
    if (SingleCallUserWidgetData.smallViewRight < 0) {
      SingleCallUserWidgetData.smallViewRight = 0;
    }
    if (SingleCallUserWidgetData.smallViewRight > MediaQuery.of(context).size.width - 110) {
      SingleCallUserWidgetData.smallViewRight = MediaQuery.of(context).size.width - 110;
    }
    setState(() {});
  }
}


class SingleCallUserWidgetData {
  static int bigViewIndex = 1;
  static double smallViewTop = 128;
  static double smallViewRight = 20;
  static ValueNotifier<bool> isOnlyShowVideoView = ValueNotifier(false);

  static initIndividualUserWidgetData() {
    bigViewIndex = 1;
    smallViewTop = 128;
    smallViewRight = 20;
    isOnlyShowVideoView.value = false;
  }
}
