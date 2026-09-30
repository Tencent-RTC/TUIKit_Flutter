// Copyright (c) 2025 Tencent. All rights reserved.
// Module:   MusicStore @ AtomicXCore
// Function: BGM playback related interfaces, managing music playback control, state synchronization, and playback event listening in live rooms/voice chat rooms.

// <docgen-keep-start>
import 'package:flutter/foundation.dart';

import '../../impl/common/store_factory.dart';
import '../define.dart';
// <docgen-keep-end>

/// Music playback status.
enum MusicPlayStatus {
  /// Idle, not playing.
  idle(0),

  /// Playing.
  playing(1),

  /// Paused.
  paused(2),

  /// Loading (e.g. buffering network resource).
  loading(3);

  final int value;

  const MusicPlayStatus(this.value);
}

/// Music playback state, managing the playback data state of the current room.
abstract class MusicState {
  /// Currently playing music URL. null means no music is playing.
  ValueListenable<String?> get playURL;

  /// Current playback status.
  ValueListenable<MusicPlayStatus> get playStatus;

  /// Current playback progress (unit: milliseconds).
  ValueListenable<int> get playProgress;

  /// Total duration of current music (unit: milliseconds). 0 means unknown.
  ValueListenable<int> get totalDuration;

  /// BGM volume, range 0 - 100, default 60.
  ValueListenable<int> get musicVolume;
}

/// Music playback parameters.
///
/// Describes the music resource and playback behavior used by [MusicStore.startPlay].
/// The SDK supports playing multiple tracks simultaneously, so each track is identified
/// by a unique [id] used to control start/stop/volume and so on.
class AudioMusicParam {
  /// Music ID. Since the SDK allows playing multiple tracks at the same time, this ID is
  /// used to mark a track for start/stop/volume control, etc. When 0, an ID will be
  /// generated internally based on [path].
  int id;

  /// Full path or URL of the audio file. Supported formats: MP3, AAC, M4A, WAV.
  String? path;

  /// Number of times to loop the track. 0 means play once without looping.
  int loopCount;

  AudioMusicParam({this.id = 0, this.path, this.loopCount = 0});
}

/// Music playback event listener, used to receive playback dynamics in live rooms/voice chat rooms.
abstract class MusicListener {
  /// Event callback when music playback completes normally.
  /// - [playURL] : The music URL that finished playing.
  void onPlayCompleted(String playURL) {}

  /// Event callback when music playback encounters an error.
  /// - [playURL] : The music URL that encountered error.
  /// - [code] : Error code, passed through from TRTC SDK. Common error codes are as follows:
  ///
  /// | Error Code | Name | Description |
  /// |------------|------|-------------|
  /// | 0 | Success | Operation succeeded |
  /// | -4001 | ERR_BGM_OPEN_FAILED | Failed to open file, invalid audio data or FFMPEG protocol not found |
  /// | -4002 | ERR_BGM_DECODE_FAILED | Audio file decoding failed, file may be corrupted or encoding format unrecognized |
  /// | -4003 | ERR_BGM_OVER_LIMIT | Number of preloaded music exceeded the limit |
  /// | -4004 | ERR_BGM_INVALID_OPERATION | Invalid operation, e.g., calling preload during playback |
  /// | -4005 | ERR_BGM_INVALID_PATH | Invalid path, please check if the file path points to a valid music file |
  /// | -4006 | ERR_BGM_INVALID_URL | Invalid URL, please ensure the URL is accessible (iOS/Mac requires HTTPS) |
  /// | -4007 | ERR_BGM_NO_AUDIO_STREAM | No audio stream, please confirm the file is a valid audio file and not corrupted |
  /// | -4008 | ERR_BGM_FORMAT_NOT_SUPPORTED | Format not supported. Mobile supports: mp3, aac, m4a, wav, ogg, mp4, mkv; Desktop supports: mp3, aac, m4a, wav, mp4, mkv |
  /// | -4009 | ERR_CONCURRENT_BGM_OVER_LIMIT | Number of concurrent BGM playback exceeded the limit (max 10) |
  void onPlayError(String playURL, int code) {}
}

/// BGM playback related interfaces, managing music playback control, state synchronization, and playback event listening in live rooms/voice chat rooms.
///
/// `MusicStore` BGM playback management class for handling music playback related business logic in live rooms/voice chat rooms.
/// `MusicStore` provides a complete set of music playback management APIs, including starting/pausing/resuming/stopping playback and volume control.
/// Through this class, BGM playback functionality can be implemented in live rooms.
///
/// ### Key Features
///
/// - **Playback Control**：Support starting, pausing, resuming, stopping, and seeking BGM playback.
/// - **Volume Control**：Adjustable BGM volume (0-100).
/// - **Pitch Adjustment**：Support pitch shifting (-12 ~ 12).
/// - **State Management**：Real-time playback state updates via reactive state publisher.
/// - **Event Listening**：Listen to playback completion and error events.
///
/// > **Important**: Use the [MusicStore.create] factory method to create a `MusicStore` instance, passing a valid live room ID.
///
/// > **Note**: Playback state updates are delivered through the [musicState] publisher. Subscribe to it to receive real-time updates of playback data in the room.
///
/// ## Topics
///
/// ### Creating Instance
/// - [MusicStore.create] : Create music playback management instance.
///
/// ### Observing State and Events
/// - [musicState] : Music playback state data.
/// - [addMusicListener]/[removeMusicListener] : Music playback event callbacks
///
/// ### Playback Control
/// - [startPlay] : Start playing music.
/// - [pausePlay] : Pause playback.
/// - [resumePlay] : Resume playback.
/// - [stopPlay] : Stop playback.
/// - [seek] : Seek to specified position.
///
/// ### Playback Parameters
/// - [setMusicVolume] : Set BGM volume.
/// - [setPitch] : Set pitch adjustment.
///
/// ## See Also
///
/// - [MusicPlayStatus]
/// - [MusicState]
/// - [MusicListener]
abstract class MusicStore {
  /// Music playback state subscription for the current room, containing playback status, volume and other information. By subscribing to this state, real-time updates of playback data in the room can be obtained.
  MusicState get musicState;

  /// Music playback event publisher. Subscribe to this publisher to receive one-time playback events such as completion and errors.
  void addMusicListener(MusicListener listener);
  void removeMusicListener(MusicListener listener);

  /// Create music playback management instance.
  /// - [liveID] : Live room ID.
  /// Returns: Music playback management instance for the specified room.
  static MusicStore create({required String liveID}) {
    return StoreFactory.shared.getStore<MusicStore>(roomID: liveID);
  }

  /// Start playing music.
  ///
  /// Starts playing the music described by [param]. If a network URL is provided in [AudioMusicParam.path],
  /// the SDK will handle downloading internally.
  /// The playback status will transition to LOADING first, then to PLAYING when playback actually starts.
  ///
  /// **Error Codes**: On failure, the completion callback will return TRTC SDK error codes. See the error code table in `onPlayError` for details.
  ///
  /// - [param] : Music playback parameters. See [AudioMusicParam].
  ///
  /// Returns: Playback operation result. errorCode is 0 on success, or a TRTC error code on failure.
  Future<CompletionHandler> startPlay(AudioMusicParam param);

  /// Pause music playback.
  ///
  /// Pauses the currently playing music. The playback status will change to PAUSED.
  /// Call resumePlay to resume playback from the paused position.
  void pausePlay();

  /// Resume music playback.
  ///
  /// Resumes playback from the paused position. The playback status will change to PLAYING.
  void resumePlay();

  /// Stop music playback.
  ///
  /// Stops the current music playback completely. The playback status will change to IDLE.
  /// Unlike pause, stop will reset the playback position.
  void stopPlay();

  /// Seek to specified playback position.
  ///
  /// Jumps to the specified time position in the currently playing music.
  ///
  /// - [ms] : Target playback position in milliseconds.
  void seek(int ms);

  /// Set BGM volume.
  ///
  /// Sets both the local playback volume and the remote publishing volume simultaneously.
  ///
  /// - [volume] : BGM volume, range 0 - 100.
  void setMusicVolume(int volume);

  /// Set pitch adjustment.
  ///
  /// Adjusts the pitch of the currently playing music.
  ///
  /// - [pitch] : Pitch adjustment value, range -12 ~ 12. Positive values raise the pitch, negative values lower it.
  void setPitch(double pitch);
}
