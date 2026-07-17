// Copyright (c) 2026 Tencent. All rights reserved.
// BGM data layer aligned with Android native BGMStore.

import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/foundation.dart';
import 'package:tencent_live_uikit/common/index.dart';

/// Music item that describes a single BGM entry in the panel.
class BGMInfo {
  static const int invalidId = -1;

  final int id;
  final String name;
  final String path;

  /// Pitch adjustment value, range -12 ~ 12.
  final ValueNotifier<double> pitch;

  BGMInfo({
    this.id = invalidId,
    this.name = '',
    this.path = '',
    double pitch = 0.0,
  }) : pitch = ValueNotifier<double>(pitch);
}

/// BGM panel state container.
class BGMState {
  final ValueNotifier<BGMInfo> currentMusicInfo = ValueNotifier<BGMInfo>(BGMInfo());
  final List<BGMInfo> musicList = <BGMInfo>[];
}

/// BGM store, encapsulates [MusicStore] for the BGM panel UI.
class BGMStore {
  static const String _tag = 'BGMStore';

  final String roomId;
  final BGMState bgmState = BGMState();
  final MusicStore _musicStore;

  BGMStore(this.roomId) : _musicStore = MusicStore.create(roomID: roomId);

  /// Whether the given [musicInfo] is currently playing.
  /// Both LOADING and PLAYING states are treated as "playing".
  ///
  /// Aligned with Android native [BGMStore.isMusicPlaying].
  bool isMusicPlaying(BGMInfo musicInfo) {
    final BGMInfo current = bgmState.currentMusicInfo.value;
    if (current.id == BGMInfo.invalidId || current.id != musicInfo.id) {
      return false;
    }
    final MusicPlayStatus status = _musicStore.musicState.playStatus.value;
    return status == MusicPlayStatus.playing || status == MusicPlayStatus.loading;
  }

  /// Toggle play/stop for [musicInfo], aligned with Android native
  /// [BGMStore.operatePlayMusic]:
  /// 1. If a different track is currently selected, stop it first.
  /// 2. Update the current selection to [musicInfo].
  /// 3. If [musicInfo] is already playing, stop it; otherwise start it.
  ///
  /// Note on Flutter-specific timing: [_musicStore.stopPlay] is implemented
  /// asynchronously and the underlying [MusicPlayStatus] does not flip to idle
  /// synchronously. After step 1, [isMusicPlaying] would still observe the
  /// previous track's status in the same microtask. To preserve the Android
  /// semantics, we capture "is the same track and was playing" before the
  /// stop call and reuse it for the branching decision.
  void operatePlayMusic(BGMInfo musicInfo) {
    final BGMInfo currentMusicInfo = bgmState.currentMusicInfo.value;
    final bool wasPlayingTappedTrack = isMusicPlaying(musicInfo);

    if (currentMusicInfo.id != BGMInfo.invalidId && currentMusicInfo.id != musicInfo.id) {
      _stopMusic();
    }
    bgmState.currentMusicInfo.value = musicInfo;
    LiveKitLogger.info('$_tag operatePlayMusic:[isPlaying:$wasPlayingTappedTrack]');
    if (wasPlayingTappedTrack) {
      _stopMusic();
    } else {
      _startMusic(musicInfo);
    }
  }

  /// Refresh [BGMState.currentMusicInfo] from the underlying [MusicStore]
  /// when the panel is opened.
  void refreshCurrentMusicInfo() {
    final String? currentPlayUrl = _musicStore.musicState.playURL.value;
    bgmState.currentMusicInfo.value = bgmState.musicList.firstWhere(
      (BGMInfo info) => info.path == currentPlayUrl,
      orElse: () => BGMInfo(),
    );
  }

  /// Listenable to playback status changes, exposed for UI rebuild.
  ValueListenable<MusicPlayStatus> get playStatusListenable => _musicStore.musicState.playStatus;

  void _startMusic(BGMInfo musicInfo) {
    LiveKitLogger.info('$_tag [$roomId] startMusic:[id:${musicInfo.id},name:${musicInfo.name}]');
    _musicStore.setPitch(musicInfo.pitch.value);
    _musicStore.startPlay(musicInfo.path);
  }

  void _stopMusic() {
    LiveKitLogger.info('$_tag [$roomId] stopMusic');
    _musicStore.stopPlay();
  }
}
