// Copyright (c) 2026 Tencent. All rights reserved.
// BGM panel widget aligned with Android native BGMPanelView.

import 'package:flutter/material.dart';
import 'package:tencent_live_uikit/common/index.dart';

import 'store/bgm_store.dart';
import 'widget/bgm_list_widget.dart';

/// BGM panel widget. Displays the built-in music list and lets the anchor
/// play/stop background music in the room.
class BGMPanelWidget extends StatefulWidget {
  final String roomId;

  const BGMPanelWidget({super.key, required this.roomId});

  @override
  State<BGMPanelWidget> createState() => _BGMPanelWidgetState();
}

class _BGMPanelWidgetState extends State<BGMPanelWidget> {
  /// Key metric IDs, kept in sync with Android native BGMPanelView.
  static const int _kMetricsPanelShowLiveRoomMusic = 190018;
  static const int _kMetricsPanelShowVoiceRoomMusic = 191016;

  late final BGMStore _bgmStore;

  @override
  void initState() {
    super.initState();
    _bgmStore = BGMStore(widget.roomId);
    _reportData();
  }

  void _reportData() {
    final bool isVoiceRoom = widget.roomId.startsWith('voice_');
    KeyMetrics.reportKeyMetrics(
      isVoiceRoom ? _kMetricsPanelShowVoiceRoomMusic : _kMetricsPanelShowLiveRoomMusic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: SizedBox(
        height: 350.height,
        child: Column(
          children: [
            SizedBox(height: 20.height),
            _buildTitle(),
            SizedBox(height: 20.height),
            Expanded(child: BGMListWidget(bgmStore: _bgmStore)),
          ],
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return SizedBox(
      height: 24.height,
      width: 1.screenWidth,
      child: Center(
        child: Text(
          LiveKitLocalizations.of(Global.appContext())!.common_music,
          style: const TextStyle(color: LiveColors.designStandardG7, fontSize: 16),
        ),
      ),
    );
  }
}
