// Copyright (c) 2026 Tencent. All rights reserved.
// BGM list widget aligned with Android native BGMListAdapter.

import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/material.dart';
import 'package:tencent_live_uikit/common/index.dart';

import '../store/bgm_store.dart';

/// Built-in BGM URLs, kept in sync with Android native [BGMListAdapter].
const String _kMusicUrlCheerful =
    'https://dldir1.qq.com/hudongzhibo/TUIKit/resource/music/PositiveHappyAdvertising.mp3';
const String _kMusicUrlMelancholy = 'https://dldir1.qq.com/hudongzhibo/TUIKit/resource/music/SadCinematicPiano.mp3';
const String _kMusicUrlWonderWorld = 'https://dldir1.qq.com/hudongzhibo/TUIKit/resource/music/WonderWorld.mp3';

class BGMListWidget extends StatefulWidget {
  final BGMStore bgmStore;

  const BGMListWidget({super.key, required this.bgmStore});

  @override
  State<BGMListWidget> createState() => _BGMListWidgetState();
}

class _BGMListWidgetState extends State<BGMListWidget> {
  late final BGMStore _bgmStore;

  @override
  void initState() {
    super.initState();
    _bgmStore = widget.bgmStore;
    _initData();
    _bgmStore.refreshCurrentMusicInfo();
  }

  void _initData() {
    if (_bgmStore.bgmState.musicList.isNotEmpty) return;
    final l10n = LiveKitLocalizations.of(Global.appContext())!;
    _bgmStore.bgmState.musicList.addAll(<BGMInfo>[
      BGMInfo(id: 1, name: l10n.common_music_cheerful, path: _kMusicUrlCheerful),
      BGMInfo(id: 2, name: l10n.common_music_melancholy, path: _kMusicUrlMelancholy),
      BGMInfo(id: 3, name: l10n.common_music_wonder_world, path: _kMusicUrlWonderWorld),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<BGMInfo>(
      valueListenable: _bgmStore.bgmState.currentMusicInfo,
      builder: (context, _, __) {
        return ValueListenableBuilder<MusicPlayStatus>(
          valueListenable: _bgmStore.playStatusListenable,
          builder: (context, _, __) {
            final list = _bgmStore.bgmState.musicList;
            return ListView.builder(
              shrinkWrap: true,
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: list.length,
              itemBuilder: (context, index) => _buildItem(list[index]),
            );
          },
        );
      },
    );
  }

  Widget _buildItem(BGMInfo info) {
    final bool playing = _bgmStore.isMusicPlaying(info);
    return SizedBox(
      height: 60.height,
      child: Stack(
        children: [
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.width),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      info.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: LiveColors.designStandardG7,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            right: 12.width,
            top: 0,
            bottom: 0,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _bgmStore.operatePlayMusic(info),
              child: SizedBox(
                width: 40.width + 24.width,
                child: Center(
                  child: Image.asset(
                    playing ? LiveImages.musicPause : LiveImages.musicStart,
                    package: Constants.pluginName,
                    width: 16.width,
                    height: 16.height,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 24.width,
            right: 24.width,
            bottom: 0,
            child: Container(
              height: 0.5.height,
              color: LiveColors.designStandardG3,
            ),
          ),
        ],
      ),
    );
  }
}
