import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/material.dart';
import 'package:tencent_live_uikit/common/error/error_handler.dart';
import 'package:tencent_live_uikit/common/screen/index.dart';
import 'package:tencent_live_uikit/component/float_window/global_float_window_manager.dart';
import 'package:tencent_live_uikit/live_stream/features/anchor_prepare/anchor_preview_widget_define.dart';
import 'package:tencent_live_uikit/live_stream/features/anchor_prepare/widgets/video_stream_source_widget.dart';
import 'package:tencent_live_uikit/live_stream/live_define.dart';
import 'package:rtc_room_engine/rtc_room_engine.dart';

import '../../../common/constants/constants.dart';
import '../../../common/language/index.dart';
import '../../../common/resources/index.dart';
import '../../../common/widget/index.dart';
import '../../manager/live_stream_manager.dart';
import 'widgets/anchor_preview_function_widget.dart';
import 'widgets/anchor_preview_info_edit_widget.dart';

class AnchorPreviewWidget extends StatefulWidget {
  final LiveStreamManager liveStreamManager;
  final DidClickBack? didClickBack;
  final DidClickStart? didClickStart;

  const AnchorPreviewWidget({super.key, required this.liveStreamManager, this.didClickBack, this.didClickStart});

  @override
  State<AnchorPreviewWidget> createState() => _AnchorPreviewWidgetState();
}

class _AnchorPreviewWidgetState extends State<AnchorPreviewWidget> {
  late final LiveStreamManager liveStreamManager;
  late final EditInfo _editInfo;

  @override
  void initState() {
    super.initState();
    liveStreamManager = widget.liveStreamManager;
    _initEditInfo();
    liveStreamManager.mediaManager.requestAllPermission().then((value) {
      _startCamera();
      _startMicrophone();
    });
    if (DeviceStore.shared.state.localMirrorType.value != MirrorType.enable) {
      DeviceStore.shared.switchMirror(MirrorType.enable);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Container(
        color: LiveColors.notStandardPureBlack,
        child: Stack(children: [
          _initBackgroundWidget(),
          _buildVideoWidget(),
          _buildBackWidget(),
          _buildLiveTabWidget(),
          _buildLiveInfoEditWidget(liveStreamManager),
          _buildFunctionWidget(),
          _buildStartLiveWidget()
        ]),
      ),
    );
  }

  Widget _initBackgroundWidget() {
    return SizedBox(
      width: 1.screenWidth,
      height: 1.screenHeight,
      child: ValueListenableBuilder(
          valueListenable: _editInfo.videoStreamSource,
          builder: (_, videoStreamSource, child) {
            if (videoStreamSource == VideoStreamSource.camera) {
              return const SizedBox.shrink();
            } else {
              return Image.asset(LiveImages.defaultBackground, fit: BoxFit.cover, package: Constants.pluginName);
            }
          }),
    );
  }

  Widget _buildLiveTabWidget() {
    return Positioned(
      top: 80.height,
      height: 44.height,
      child: SizedBox(
        width: 1.screenWidth,
        child: VideoStreamSourceWidget(videoStreamSourceChanged: (videoStreamSource) {
          _editInfo.videoStreamSource.value = videoStreamSource;
          if (videoStreamSource == VideoStreamSource.camera) {
            _editInfo.coGuestTemplateMode.value = LiveTemplateMode.verticalDynamicGrid;
            _startCamera();
          } else {
            _editInfo.coGuestTemplateMode.value = LiveTemplateMode.horizontalDynamic;
            _stopCamera();
          }
        }),
      ),
    );
  }

  Widget _buildVideoWidget() {
    return Positioned(
      width: 1.screenWidth,
      height: 1.screenHeight,
      child: ValueListenableBuilder(
          valueListenable: _editInfo.videoStreamSource,
          builder: (_, videoStreamSource, child) {
            if (videoStreamSource != VideoStreamSource.camera) return const SizedBox.shrink();
            return Padding(
              padding: EdgeInsets.only(top: 36.height, bottom: 96.height),
              child: ClipRRect(
                  borderRadius: BorderRadius.circular(16.radius),
                  child: VideoView(
                    onViewCreated: (id) {
                      widget.liveStreamManager.mediaManager.setLocalVideoView(id);
                    },
                    onViewDisposed: (id) {
                      widget.liveStreamManager.mediaManager.setLocalVideoView(0);
                    },
                  )),
            );
          }),
    );
  }

  Widget _buildBackWidget() {
    return Positioned(
        left: 16.width,
        top: 56.height,
        width: 24.radius,
        height: 24.radius,
        child: GestureDetector(
            onTap: () {
              _closeWidget();
            },
            child: Image.asset(LiveImages.returnArrow, package: Constants.pluginName)));
  }

  Widget _buildLiveInfoEditWidget(LiveStreamManager manager) {
    return Positioned(
        top: 120.height,
        left: 16.width,
        right: 16.width,
        height: 112.height,
        child: AnchorPreviewInfoEditWidget(editInfo: _editInfo, liveStreamManager: liveStreamManager));
  }

  Widget _buildFunctionWidget() {
    return Positioned(
      left: 0,
      bottom: 134.height,
      width: 375.width,
      height: 62.height,
      child: ValueListenableBuilder(
          valueListenable: _editInfo.videoStreamSource,
          builder: (_, videoStreamSource, child) {
            if (videoStreamSource == VideoStreamSource.camera) {
              _editInfo.coGuestTemplateMode.value = LiveTemplateMode.verticalDynamicGrid;
            }
            return Visibility(
                visible: videoStreamSource == VideoStreamSource.camera,
                child: AnchorPreviewFunctionWidget(editInfo: _editInfo, liveStreamManager: liveStreamManager));
          }),
    );
  }

  Widget _buildStartLiveWidget() {
    return Positioned(
      left: 50.width,
      right: 50.width,
      bottom: 64.height,
      height: 48.height,
      child: GestureDetector(
        onTap: () {
          _createRoom();
        },
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24.height),
            color: LiveColors.designStandardB1,
          ),
          child: Text(
            LiveKitLocalizations.of(Global.appContext())!.common_start_live,
            style: const TextStyle(
                color: LiveColors.designStandardFlowkitWhite, fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }
}

extension on _AnchorPreviewWidgetState {
  void _initEditInfo() {
    _editInfo = EditInfo(
      roomName: _getDefaultRoomName(),
      privacyMode: LiveStreamPrivacyStatus.public,
      videoStreamSource: VideoStreamSource.camera,
    );
  }

  String _getDefaultRoomName() {
    final selfInfo = TUIRoomEngine.getSelfInfo();
    if (selfInfo.userName == null || selfInfo.userName!.isEmpty) {
      return selfInfo.userId;
    }
    return selfInfo.userName!;
  }

  void _startCamera() async {
    final isFront = DeviceStore.shared.state.isFrontCamera.value;
    final startCameraResult = await liveStreamManager.mediaManager.openLocalCamera(isFront);
    if (startCameraResult.code != TUIError.success) {
      liveStreamManager.toastSubject
          .add(ErrorHandler.convertToErrorMessage(startCameraResult.code.rawValue, startCameraResult.message) ?? '');
    }
  }

  void _startMicrophone() async {
    final startMicrophoneResult = await liveStreamManager.mediaManager.openLocalMicrophone();
    if (startMicrophoneResult.code != TUIError.success) {
      liveStreamManager.toastSubject.add(
          ErrorHandler.convertToErrorMessage(startMicrophoneResult.code.rawValue, startMicrophoneResult.message) ?? '');
    }
  }

  void _stopCamera() {
    liveStreamManager.mediaManager.closeLocalCamera();
  }

  void _stopMicrophone() {
    liveStreamManager.mediaManager.closeLocalMicrophone();
  }

  void _createRoom() {
    widget.didClickStart?.call(_editInfo);
  }

  void _closeWidget() {
    _stopMicrophone();
    if (_editInfo.videoStreamSource.value == VideoStreamSource.camera) {
      _stopCamera();
    }
    if (GlobalFloatWindowManager.instance.isEnableFloatWindowFeature()) {
      GlobalFloatWindowManager.instance.overlayManager.closeOverlay();
    } else {
      Navigator.pop(context);
    }
  }
}
