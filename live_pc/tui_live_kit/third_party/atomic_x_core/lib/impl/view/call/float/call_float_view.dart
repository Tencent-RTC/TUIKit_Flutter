import 'package:atomic_x_core/impl/view/call/float/call_float_cell_view.dart';
import 'package:flutter/material.dart';

import '../../../../api/call/call_store.dart';

class CallFloatView extends StatefulWidget {
  final Widget? defaultAvatar;
  final bool enableZoom;

  const CallFloatView({
    super.key,
    this.defaultAvatar,
    this.enableZoom = true,
  });

  @override
  State<StatefulWidget> createState() => _CallFloatViewState();
}

class _CallFloatViewState extends State<CallFloatView> with TickerProviderStateMixin {
  static const double _defaultScale = 0.25;
  static const double _smallViewBorderRadius = 12.0;
  static const double _shadowBlurRadius = 8.0;
  static const double _shadowSpreadRadius = 1.0;
  static const double _shadowOffsetY = 4.0;
  static const double _borderWidth = 0;
  static const double _borderOpacity = 0.3;
  static const double _shadowOpacity = 0.3;
  static const double _smallViewTopOffset = 40.0;
  static const double _minSmallViewTop = 100.0;
  static const double _maxSmallViewTopOffset = 216.0;
  static const double _maxSmallViewRightOffset = 110.0;
  
  static const Color _audioBackgroundColor = Color(0xFFF2F2F2);
  static const Color _videoBackgroundColor = Color(0xFF444444);

  double scale = _defaultScale;
  final CallFloatController controller = CallFloatController();
  
  late AnimationController _switchAnimationController;

  String _cachedSelfId = "";
  String _cachedRemoteId = "";
  CallMediaType? _cachedMediaType;
  CallParticipantStatus _cachedSelfStatus = CallParticipantStatus.none;

  @override
  void initState() {
    super.initState();
    _switchAnimationController = AnimationController(
      duration: const Duration(milliseconds: 60),
      vsync: this,
    );
    _snapshotCallInfo();
    CallStore.shared.state.activeCall.addListener(_onActiveCallChanged);
    CallStore.shared.state.selfInfo.addListener(_onSelfInfoChanged);
  }

  void _snapshotCallInfo() {
    final selfInfo = CallStore.shared.state.selfInfo.value;
    final activeCall = CallStore.shared.state.activeCall.value;
    if (selfInfo.id.isNotEmpty) {
      _cachedSelfId = selfInfo.id;
    }
    _cachedSelfStatus = selfInfo.status;
    if (activeCall.inviterId.isNotEmpty || activeCall.inviteeIds.isNotEmpty) {
      _cachedMediaType = activeCall.mediaType;
      _cachedRemoteId = activeCall.inviterId == _cachedSelfId
          ? (activeCall.inviteeIds.isNotEmpty ? activeCall.inviteeIds[0] : "")
          : activeCall.inviterId;
    }
  }

  void _onActiveCallChanged() {
    final activeCall = CallStore.shared.state.activeCall.value;
    if (activeCall.inviterId.isNotEmpty || activeCall.inviteeIds.isNotEmpty) {
      _cachedMediaType = activeCall.mediaType;
      _cachedRemoteId = activeCall.inviterId == _cachedSelfId
          ? (activeCall.inviteeIds.isNotEmpty ? activeCall.inviteeIds[0] : "")
          : activeCall.inviterId;
      if (mounted) setState(() {});
    }
  }

  void _onSelfInfoChanged() {
    final selfInfo = CallStore.shared.state.selfInfo.value;
    if (selfInfo.id.isNotEmpty) {
      _cachedSelfId = selfInfo.id;
    }
    if (selfInfo.status != CallParticipantStatus.none) {
      _cachedSelfStatus = selfInfo.status;
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _getBackgroundColor(),
      child: Stack(
        alignment: Alignment.topLeft,
        fit: StackFit.expand,
        children: [
          _buildBigVideoWidget(),
          _buildSmallVideoWidget(),
        ],
      ),
    );
  }

  @override
  void dispose() {
    CallStore.shared.state.activeCall.removeListener(_onActiveCallChanged);
    CallStore.shared.state.selfInfo.removeListener(_onSelfInfoChanged);
    _switchAnimationController.dispose();
    controller.dispose();
    super.dispose();
  }

  _buildBigVideoWidget() {
    return Stack(
      alignment: Alignment.topLeft,
      fit: StackFit.expand,
      children: [
        _getBigVideoWidget(),
        Positioned.fill(
          child: GestureDetector(
            onTap: () {
              if (_cachedMediaType == CallMediaType.audio ||
                  _cachedSelfStatus == CallParticipantStatus.waiting) {
                return;
              }
              controller.isOnlyShowVideoView.value = !controller.isOnlyShowVideoView.value;
              setState(() {});
            },
          ),
        ),
      ],
    );
  }


  Widget _buildSmallVideoWidget() {
    if (_cachedMediaType == CallMediaType.audio
        || _cachedSelfStatus == CallParticipantStatus.waiting) {
      return const SizedBox();
    }

    final screenWidth = MediaQuery.of(context).size.width;

    double windowWidth = screenWidth * scale;
    double windowHeight = windowWidth / 9 * 16;

    return Positioned(
      top: controller.smallViewTop - _smallViewTopOffset,
      right: controller.smallViewRight,
      child: Stack(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 60),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
            child: SizedBox(
              width: windowWidth,
              child: Container(
                width: windowWidth,
                height: windowHeight,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(_smallViewBorderRadius),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(_shadowOpacity),
                      blurRadius: _shadowBlurRadius,
                      spreadRadius: _shadowSpreadRadius,
                      offset: const Offset(0, _shadowOffsetY),
                    ),
                  ],
                  border: Border.all(
                    color: Colors.white.withOpacity(_borderOpacity),
                    width: _borderWidth,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(_smallViewBorderRadius),
                  child: controller.isLocalInMainView
                      ? _getRemoteStreamView()
                      : _getLocalStreamView(),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: GestureDetector(
              onTap: () {
                _changeVideoView();
              },
              onPanUpdate: (DragUpdateDetails e) {
                if (_cachedMediaType == CallMediaType.video) {
                  _refreshViewPosition(e);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _getBigVideoWidget() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 60),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      child: _getBigVideoContent(),
    );
  }

  Widget _getBigVideoContent() {
    if (_cachedMediaType == CallMediaType.audio
        || (_cachedSelfStatus != CallParticipantStatus.waiting
            && !controller.isLocalInMainView)) {
      return _getRemoteStreamView();
    }
    return _getLocalStreamView();
  }

  CallFloatCellView _getLocalStreamView() {
    return CallFloatCellView(
      userId: _cachedSelfId,
      key: ValueKey('local_$_cachedSelfId'),
      isInMainView: controller.isLocalInMainView,
      defaultAvatar: widget.defaultAvatar,
      enableZoom: widget.enableZoom,
    );
  }

  CallFloatCellView _getRemoteStreamView() {
    return CallFloatCellView(
      userId: _cachedRemoteId,
      key: ValueKey('remote_$_cachedRemoteId'),
      isInMainView: !controller.isLocalInMainView,
      defaultAvatar: widget.defaultAvatar,
      enableZoom: widget.enableZoom,
    );
  }


  _refreshViewPosition(DragUpdateDetails e) {
    controller.smallViewRight -= e.delta.dx;
    controller.smallViewTop += e.delta.dy;
    if (controller.smallViewTop < _minSmallViewTop) {
      controller.smallViewTop = _minSmallViewTop;
    }
    if (controller.smallViewTop > MediaQuery.of(context).size.height - _maxSmallViewTopOffset) {
      controller.smallViewTop = MediaQuery.of(context).size.height - _maxSmallViewTopOffset;
    }
    if (controller.smallViewRight < 0) {
      controller.smallViewRight = 0;
    }
    if (controller.smallViewRight > MediaQuery.of(context).size.width - _maxSmallViewRightOffset) {
      controller.smallViewRight = MediaQuery.of(context).size.width - _maxSmallViewRightOffset;
    }
    setState(() {});
  }

  _changeVideoView() {
    if (_cachedMediaType == CallMediaType.audio ||
        _cachedSelfStatus == CallParticipantStatus.waiting) {
      return;
    }

    if (_switchAnimationController.isAnimating) {
      return;
    }

    _switchAnimationController.forward().then((_) {
      if (!mounted) return;
      
      setState(() {
        controller.isLocalInMainView = !controller.isLocalInMainView;
      });
      _switchAnimationController.reset();
    });
  }

  Color _getBackgroundColor() {
    return _cachedMediaType == CallMediaType.audio
        ? _audioBackgroundColor
        : _videoBackgroundColor;
  }
}

class CallFloatController {
  static const double _defaultSmallViewTop = 128.0;
  static const double _defaultSmallViewRight = 20.0;

  bool isLocalInMainView = false;
  double smallViewTop = _defaultSmallViewTop;
  double smallViewRight = _defaultSmallViewRight;
  ValueNotifier<bool> isOnlyShowVideoView = ValueNotifier(false);

  void dispose() {
    isOnlyShowVideoView.dispose();
  }
}
