import 'dart:async';

import 'package:atomic_x_core/api/live/live_list_store.dart';
import 'package:atomic_x_core/api/live/live_seat_store.dart';
import 'package:flutter/material.dart';
import 'package:tencent_live_uikit/common/index.dart';
import 'package:tencent_live_uikit/live_stream/manager/live_stream_manager.dart';

/// Audience-side placeholder shown when no host is on any seat for >= 1s.
class HostAbsentWidget extends StatefulWidget {
  final LiveStreamManager liveStreamManager;

  const HostAbsentWidget({super.key, required this.liveStreamManager});

  @override
  State<HostAbsentWidget> createState() => _HostAbsentWidgetState();
}

class _HostAbsentWidgetState extends State<HostAbsentWidget> {
  static const Duration _showDelay = Duration(milliseconds: 1500);

  final ValueNotifier<bool> _isVisible = ValueNotifier<bool>(false);
  Timer? _showTimer;

  late final LiveSeatStore _seatStore = LiveSeatStore.create(widget.liveStreamManager.roomState.roomId);
  late final VoidCallback _seatListListener = _onSeatListChanged;
  late final VoidCallback _floatWindowListener = _onFloatWindowChanged;

  @override
  void initState() {
    super.initState();
    _seatStore.liveSeatState.seatList.addListener(_seatListListener);
    widget.liveStreamManager.floatWindowState.isFloatWindowMode.addListener(_floatWindowListener);
    _onSeatListChanged();
  }

  @override
  void dispose() {
    _seatStore.liveSeatState.seatList.removeListener(_seatListListener);
    widget.liveStreamManager.floatWindowState.isFloatWindowMode.removeListener(_floatWindowListener);
    _showTimer?.cancel();
    _showTimer = null;
    _isVisible.dispose();
    super.dispose();
  }

  void _onFloatWindowChanged() {
    if (!mounted) return;
    setState(() {});
  }

  void _onSeatListChanged() {
    final seatList = _seatStore.liveSeatState.seatList.value;
    final bool hasHost = seatList.isNotEmpty && seatList.any((SeatInfo s) => s.userInfo.userID.isNotEmpty);

    // Any state change cancels a pending show timer.
    _showTimer?.cancel();
    _showTimer = null;

    if (hasHost) {
      _isVisible.value = false;
    } else {
      _showTimer = Timer(_showDelay, () {
        if (!mounted) return;
        _isVisible.value = true;
      });
    }
  }

  String _muteImageAsset(BuildContext context, {required bool isLandscape}) {
    final bool isEn = DeviceLanguage.getCurrentLanguageCode(context) == 'en';
    if (isLandscape) {
      return isEn ? LiveImages.muteImageEnLand : LiveImages.muteImageLand;
    }
    return isEn ? LiveImages.muteImageEn : LiveImages.muteImage;
  }

  @override
  Widget build(BuildContext context) {
    final seatTemplate = widget.liveStreamManager.roomState.liveInfo.seatTemplate;
    final bool isLandscape4Seats = seatTemplate is VideoLandscape4Seats;
    return ValueListenableBuilder<bool>(
      valueListenable: _isVisible,
      builder: (BuildContext context, bool visible, Widget? child) {
        if (!visible) return const SizedBox.shrink();
        return SizedBox.expand(
          child: Image.asset(
            _muteImageAsset(context, isLandscape: isLandscape4Seats),
            package: Constants.pluginName,
            fit: BoxFit.cover,
          ),
        );
      },
    );
  }
}
