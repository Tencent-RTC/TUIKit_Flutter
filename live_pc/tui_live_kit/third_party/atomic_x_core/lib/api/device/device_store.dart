// Copyright (c) 2025 Tencent. All rights reserved.
// Module:   DeviceStore @ AtomicXCore
// Function: Device related interfaces, operating microphone, camera, etc.

// <docgen-keep-start>
import 'dart:async';
import 'dart:convert';

import 'package:atomic_x_core/api/define.dart';
import 'package:atomic_x_core/engine/engine_bridge.dart';
import 'package:atomic_x_core/impl/common/atomic_platform.dart';
import 'package:atomic_x_core/impl/common/list_modify_type.dart';
import 'package:flutter/foundation.dart';

part '../../impl/device/device_store_impl.dart';
// <docgen-keep-end>

/// Device type.
///
/// This enum defines the available device types.
///
/// ### Response Scenarios
///
/// | Type | Value | Description |
/// |------|------|-----------|
/// | `microphone` | 1 | Microphone type |
/// | `camera` | 2 | Camera type |
/// | `screenShare` | 3 | Screen sharing type |
enum DeviceType {
  /// Microphone type.
  microphone(1),

  /// Camera type.
  camera(2),

  /// Screen sharing type.
  screenShare(3);

  final int value;

  const DeviceType(this.value);
}

/// Device related error codes.
///
/// This enum defines the error codes that device operations may return.
///
/// ### Response Scenarios
///
/// | Error | Value | Description |
/// |------|------|-----------|
/// | `noError` | 0 | Operation successful |
/// | `noDeviceDetected` | 1 | No device detected |
/// | `noSystemPermission` | 2 | No system permission |
/// | `notSupportCapture` | 3 | Capture not supported |
/// | `occupiedError` | 4 | Device occupied |
/// | `unknownError` | 5 | Unknown error |
enum DeviceError {
  /// Operation successful.
  noError(0),

  /// No device detected.
  noDeviceDetected(1),

  /// No system permission.
  noSystemPermission(2),

  /// Capture not supported.
  notSupportCapture(3),

  /// Device occupied.
  occupiedError(4),

  /// Unknown error.
  unknownError(5);

  final int value;

  const DeviceError(this.value);
}

/// Device on/off status.
///
/// This enum defines the on/off status of devices.
///
/// ### Response Scenarios
///
/// | Status | Value | Description |
/// |------|------|-----------|
/// | `off` | 0 | False |
/// | `on` | 1 | True |
enum DeviceStatus {
  /// Off.
  off(0),

  /// On.
  on(1);

  final int value;

  const DeviceStatus(this.value);
}

/// Audio route.
///
/// This enum defines the audio output route location.
///
/// ### Response Scenarios
///
/// | Route | Value | Description |
/// |------|------|-----------|
/// | `speakerphone` | 0 | Speaker | suitable for playing music out loud |
/// | `earpiece` | 1 | Earpiece | suitable for private call scenarios |
enum AudioRoute {
  /// Speaker, using speaker to play (i.e., "hands-free"), located at the bottom of the phone, louder sound, suitable for playing music out loud.
  speakerphone(0),

  /// Earpiece, using earpiece to play, located at the top of the phone, quieter sound, suitable for private call scenarios.
  earpiece(1);

  final int value;

  const AudioRoute(this.value);
}

/// Video quality level. The final encoding resolution is determined by the combination of this level and VideoOrientation: landscape keeps the base resolution (width x height), portrait swaps the width and height.
///
/// This enum defines the video capture quality levels. The SDK has built-in resolution, frame rate, and bitrate combinations for each level, making it easy to choose for different scenarios.
///
/// The base (landscape) resolution of each level is shown in the table below; with VideoOrientation.portrait the width and height are swapped (e.g. quality720P is 1280 x 720 in landscape, 720 x 1280 in portrait).
///
/// Different levels affect RTC service billing. For pricing details, please refer to: https://trtc.io/document/42734?product=pricing
///
/// ### Response Scenarios
///
/// | Quality | Value | Landscape (W x H) / Portrait (W x H) |
/// |-------|------|------------------------------------|
/// | `quality360P` | 1 | 640 x 360 / 360 x 640 |
/// | `quality540P` | 2 | 960 x 540 / 540 x 960 |
/// | `quality720P` | 3 | 1280 x 720 / 720 x 1280 |
/// | `quality1080P` | 4 | 1920 x 1080 / 1080 x 1920 |
enum VideoQuality {
  /// 360P. Landscape resolution is 640 x 360; portrait (width and height swapped) is 360 x 640.
  quality360P(1),

  /// 540P. Landscape resolution is 960 x 540; portrait (width and height swapped) is 540 x 960.
  quality540P(2),

  /// 720P. Landscape resolution is 1280 x 720; portrait (width and height swapped) is 720 x 1280.
  quality720P(3),

  /// 1080P. Landscape resolution is 1920 x 1080; portrait (width and height swapped) is 1080 x 1920.
  quality1080P(4);

  final int value;

  const VideoQuality(this.value);
}

/// Video orientation. Combined with VideoQuality to determine the final encoding resolution: landscape keeps the base resolution (width x height), portrait swaps the width and height.
///
/// This enum defines the orientation of the video encoding resolution. It must be used together with VideoQuality:
///
/// - landscape (value 0): the encoding resolution keeps the base width and height, e.g. 1280 x 720.
/// - portrait (value 1): the width and height are swapped, e.g. 720 x 1280.
///
/// For the resolution mapping of each level, see VideoQuality.
enum VideoOrientation {
  /// Landscape, the encoding resolution width is greater than the height (e.g. 1280 x 720).
  landscape(0),

  /// Portrait, the encoding resolution height is greater than the width (e.g. 720 x 1280).
  portrait(1);

  final int value;

  const VideoOrientation(this.value);
}

/// Network quality.
///
/// This enum defines the network quality levels.
///
/// ### Response Scenarios
///
/// | Quality | Value | Description |
/// |-------|------|-----------|
/// | `unknown` | 0 | Unknown network |
/// | `excellent` | 1 | Excellent |
/// | `good` | 2 | Good |
/// | `poor` | 3 | Poor |
/// | `bad` | 4 | Bad |
/// | `veryBad` | 5 | Very bad |
/// | `down` | 6 | Disconnected |
enum NetworkQuality {
  /// Unknown network.
  unknown(0),

  /// Excellent.
  excellent(1),

  /// Good.
  good(2),

  /// Poor.
  poor(3),

  /// Bad.
  bad(4),

  /// Very bad.
  veryBad(5),

  /// Disconnected.
  down(6);

  final int value;

  const NetworkQuality(this.value);
}

/// Camera mirror state.
///
/// This enum defines the camera mirror modes.
///
/// ### Response Scenarios
///
/// | Mode | Value | Description |
/// |------|------|-----------|
/// | `auto` | 0 | Auto | front camera mirrored | rear camera not mirrored |
/// | `enable` | 1 | Both front and rear cameras mirrored |
/// | `disable` | 2 | Neither front nor rear camera mirrored |
enum MirrorType {
  /// Auto, front camera mirrored, rear camera not mirrored.
  auto(0),

  /// Both front and rear cameras mirrored.
  enable(1),

  /// Neither front nor rear camera mirrored.
  disable(2);

  final int value;

  const MirrorType(this.value);
}

/// Device focus.
///
/// This enum defines the device focus owner scenarios.
///
/// ### Response Scenarios
///
/// | Scenario | Value | Description |
/// |--------|------|-----------|
/// | `call` | call | Voice call scenario |
/// | `live` | live | Live streaming scenario |
/// | `room` | room | Room scenario |
/// | `none` | none | Not set |
enum DeviceFocusOwner {
  call,

  live,

  room,

  none,
}

/// Device information.
class DeviceInfo {
  /// Device ID.
  final String deviceId;

  /// Device name.
  final String deviceName;
  const DeviceInfo({
    this.deviceId = '',
    this.deviceName = '',
  });
}

/// Network information.
///
/// Data structure for network status information, containing user ID, network quality, packet loss rate and latency.
///
///
/// | Property | Type | Description |
/// |--------|------|-----------|
/// | [userID] | `String` | User unique ID |
/// | [quality] | [NetworkQuality] | Network quality |
/// | [upLoss] | `int` | Uplink packet loss rate, with a value range from 0 to 100 |
/// | [downLoss] | `int` | Downlink packet loss rate, with a value range from 0 to 100 |
/// | [delay] | `int` | {'Latency (unit': 'milliseconds)'} |
class NetworkInfo {
  /// User unique ID.
  final String userID;

  /// Network quality.
  final NetworkQuality quality;

  /// Uplink packet loss rate, with a value range from 0 to 100.
  final int upLoss;

  /// Downlink packet loss rate, with a value range from 0 to 100.
  final int downLoss;

  /// Latency (unit: milliseconds).
  final int delay;
  NetworkInfo({
    this.userID = '',
    this.quality = NetworkQuality.excellent,
    this.upLoss = 0,
    this.downLoss = 0,
    this.delay = 0,
  });
}

/// Device state.
///
/// A comprehensive snapshot of device state, containing all device-related status information including microphone, camera, screen sharing and network.
///
/// > **Note**: Device state is automatically updated. Subscribe to [state] to receive real-time updates.
///
/// ### State Properties Overview
///
/// | Property | Type | Description |
/// |--------|------|-----------|
/// | [microphoneStatus] | `ValueListenable<DeviceStatus>` | Microphone status |
/// | [microphoneList] | `ValueListenable<List<DeviceInfo>>` | Available microphone list |
/// | [currentMicrophone] | `ValueListenable<DeviceInfo>` | Current selected microphone |
/// | [microphoneLastError] | `ValueListenable<DeviceError>` | Microphone error |
/// | [captureVolume] | `ValueListenable<int>` | Capture volume, with a value range from 0 to 100 |
/// | [currentMicVolume] | `ValueListenable<int>` | Current user's actual output volume |
/// | [outputVolume] | `ValueListenable<int>` | Maximum output volume, with a value range from 0 to 100 |
/// | [cameraStatus] | `ValueListenable<DeviceStatus>` | Camera status |
/// | [cameraList] | `ValueListenable<List<DeviceInfo>>` | Available camera list |
/// | [currentCamera] | `ValueListenable<DeviceInfo>` | Current selected camera |
/// | [cameraLastError] | `ValueListenable<DeviceError>` | Camera error |
/// | [isFrontCamera] | `ValueListenable<bool>` | Whether it's front camera |
/// | [localMirrorType] | `ValueListenable<MirrorType>` | Mirror state |
/// | [localVideoQuality] | `ValueListenable<VideoQuality>` | Local video quality |
/// | [currentAudioRoute] | `ValueListenable<AudioRoute>` | Current audio route location (deprecated, use [currentSpeaker] instead) |
/// | [speakerList] | `ValueListenable<List<DeviceInfo>>` | Available speaker list |
/// | [currentSpeaker] | `ValueListenable<DeviceInfo>` | Current selected speaker route |
/// | [screenStatus] | `ValueListenable<DeviceStatus>` | Screen sharing status (deprecated, use ScreenShareStore.state.screenStatus instead) |
/// | [networkInfo] | `ValueListenable<NetworkInfo>` | Network information |
abstract class DeviceState {
  /// Microphone status.
  ValueListenable<DeviceStatus> get microphoneStatus;

  /// Available microphone list.
  ValueListenable<List<DeviceInfo>> get microphoneList;

  /// Current selected microphone.
  ValueListenable<DeviceInfo> get currentMicrophone;

  /// Microphone error, used to extract error information when an error occurs.
  ValueListenable<DeviceError> get microphoneLastError;

  /// Capture volume, with a value range from 0 to 100.
  ValueListenable<int> get captureVolume;

  /// Current user's actual output volume.
  ValueListenable<int> get currentMicVolume;

  /// Maximum output volume, with a value range from 0 to 100.
  ValueListenable<int> get outputVolume;

  /// Camera status.
  ValueListenable<DeviceStatus> get cameraStatus;

  /// Available camera list.
  ValueListenable<List<DeviceInfo>> get cameraList;

  /// Current selected camera.
  ValueListenable<DeviceInfo> get currentCamera;

  /// Camera error, used to extract error information when an error occurs.
  ValueListenable<DeviceError> get cameraLastError;

  /// Whether it's front camera.
  ValueListenable<bool> get isFrontCamera;

  /// Mirror state.
  ValueListenable<MirrorType> get localMirrorType;

  /// Local video quality.
  ValueListenable<VideoQuality> get localVideoQuality;

  /// Current audio route location. Deprecated, use currentSpeaker instead.
  @Deprecated('Use currentSpeaker instead')
  ValueListenable<AudioRoute> get currentAudioRoute;

  /// Available speaker (audio output) list.
  ValueListenable<List<DeviceInfo>> get speakerList;

  /// Current selected speaker (audio output) route.
  ValueListenable<DeviceInfo> get currentSpeaker;

  /// Screen sharing status. Deprecated, use ScreenShareStore.state.screenStatus instead.
  @Deprecated('Use ScreenShareStore.state.screenStatus instead')
  ValueListenable<DeviceStatus> get screenStatus;

  /// Network information.
  ValueListenable<NetworkInfo> get networkInfo;
}

/// Device related interfaces, operating microphone, camera, etc.
///
/// `DeviceStore` Device management class for handling host camera, microphone and other business.
/// `DeviceStore` provides a comprehensive set of APIs to manage audio and video devices, including microphone, camera and screen sharing features.
///
/// ### Key Features
///
/// - **Microphone Management**：Open/close microphone, set capture volume and output volume.
/// - **Camera Management**：Open/close camera, switch front/rear camera, set mirror and video quality.
/// - **Audio Route**：Switch between speaker and earpiece.
/// - **Network Status**：Real-time monitoring of network quality information.
///
/// > **Important**: Use [DeviceStore.shared] singleton to get the `DeviceStore` instance. Do not attempt to initialize directly.
///
/// > **Note**: Device state updates are delivered through the [state] publisher. Subscribe to it to receive real-time updates about microphone, camera, network and other states.
///
/// ### Device Operations Overview
///
/// | Feature | Method | Description |
/// |-------|------|-----------|
/// | Microphone | [openLocalMicrophone]/[closeLocalMicrophone] | Open/close local microphone |
/// | Microphone | [setCurrentMicrophone] | Switch to the specified microphone |
/// | Camera | [openLocalCamera]/[closeLocalCamera] | Open/close local camera |
/// | Camera | [setCurrentCamera] | Switch to the specified camera |
/// | Audio Route | [setCurrentSpeaker] | Switch to the specified speaker |
/// | Audio Route | [setAudioRoute] | Switch speaker/earpiece |
/// | Volume Control | [setCaptureVolume]/[setOutputVolume] | Set capture/output volume |
///
/// ## Topics
///
/// ### Getting Instance
/// - [shared] : Singleton object.
///
/// ### Observing State
/// - [state] : Reactive state containing microphone, camera, network and other device states.
///
/// ### Microphone Operations
/// - [openLocalMicrophone] : Open local microphone.
/// - [closeLocalMicrophone] : Close local microphone.
/// - [setCurrentMicrophone] : Set current microphone device.
/// - [setCaptureVolume] : Set capture volume.
/// - [setOutputVolume] : Set output volume.
///
/// ### Audio Route
/// - [setCurrentSpeaker] : Set current speaker device.
/// - [setAudioRoute] : Set audio route (deprecated, use [setCurrentSpeaker] instead).
///
/// ### Camera Operations
/// - [startCameraTest] : Start camera test.
/// - [stopCameraTest] : Stop camera test.
/// - [openLocalCamera] : Open local camera.
/// - [closeLocalCamera] : Close local camera.
/// - [setCurrentCamera] : Set current camera device.
/// - [switchCamera] : Switch camera (deprecated, use [setCurrentCamera] instead).
/// - [switchMirror] : Switch mirror state.
/// - [updateVideoQuality] : Update video quality.
///
/// ### Reset
/// - [reset] : Reset to default state.
///
/// ## See Also
///
/// - [DeviceInfo]
/// - [DeviceType]
/// - [DeviceError]
/// - [DeviceStatus]
/// - [AudioRoute]
/// - [VideoQuality]
/// - [VideoOrientation]
/// - [NetworkQuality]
/// - [MirrorType]
/// - [DeviceState]
/// - [NetworkInfo]
/// - [ScreenShareStore]
abstract class DeviceStore {
  /// Singleton object
  ///
  /// @param shared Singleton instance.
  static final DeviceStore _instance = _DeviceStoreImpl();

  static DeviceStore get shared => _instance;

  /// State.
  DeviceState get state;

  /// Open local microphone
  ///
  /// - [completion] : Whether operation succeeded.
  Future<CompletionHandler> openLocalMicrophone();

  /// Close local microphone
  void closeLocalMicrophone();

  /// Set current microphone device
  ///
  /// - [microphone] : Microphone device to use, see [DeviceInfo].
  void setCurrentMicrophone(DeviceInfo microphone);

  /// Set capture volume
  ///
  /// - [volume] : Capture volume, with a value range from 0 to 100.
  void setCaptureVolume(int volume);

  /// Set maximum output volume
  ///
  /// - [volume] : Maximum volume, with a value range from 0 to 100.
  void setOutputVolume(int volume);

  /// Set current speaker device
  ///
  /// - [speaker] : Speaker device to use, see [DeviceInfo].
  void setCurrentSpeaker(DeviceInfo speaker);

  /// Set audio route (deprecated, use setCurrentSpeaker instead)
  ///
  /// - [route] : Route location.
  @Deprecated('Use setCurrentSpeaker instead')
  void setAudioRoute(AudioRoute route);

  /// Start camera test, if camera opens successfully, the view will be rendered to the set CameraView
  ///
  /// - [cameraViewPtr] : Rendering view for camera capture.
  /// - [completion] : Whether operation succeeded.
  Future<CompletionHandler> startCameraTest(int cameraViewPtr);

  /// Stop camera test
  void stopCameraTest();

  /// Open local camera
  ///
  /// - [isFront] : Whether front camera.
  /// - [completion] : Whether operation succeeded.
  Future<CompletionHandler> openLocalCamera(bool isFront);

  /// Close local camera
  void closeLocalCamera();

  /// Set current camera device
  ///
  /// - [camera] : Camera device to use, see [DeviceInfo].
  void setCurrentCamera(DeviceInfo camera);

  /// Switch camera (deprecated, use setCurrentCamera instead)
  ///
  /// - [isFront] : Whether front camera.
  @Deprecated('Use setCurrentCamera instead')
  void switchCamera(bool isFront);

  /// Switch mirror state
  ///
  /// - [mirrorType] : Mirror state.
  void switchMirror(MirrorType mirrorType);

  /// Update video quality
  ///
  /// - [quality] : Video quality.
  /// - [orientation] : Video orientation. Defaults to portrait. Pass landscape to use the base (width x height) resolution.
  void updateVideoQuality(VideoQuality quality, {VideoOrientation orientation = VideoOrientation.portrait});

  /// Refresh device lists
  ///
  /// Re-enumerates physical devices (camera / microphone / speaker on desktop)
  /// and republishes the device list state. Call this after subscribing to
  /// [state] when the initial lists published at module init may have been
  /// missed.
  void refreshDeviceList();

  /// Start screen sharing (deprecated, use ScreenShareStore.startScreenShare instead)
  ///
  /// - [iOSAppGroup] : Defaults to '', which is the correct value for Android (ignored on the Android platform). On iOS, the value must match the App Group string configured in the Broadcast Upload Extension, used for sharing data between the host app and the Extension, in the format group.<reverse-domain>. Passing an empty string is allowed but does not guarantee screen sharing stability; configuring it correctly is recommended.
  @Deprecated('Use ScreenShareStore.startScreenShare instead')
  void startScreenShare({String iOSAppGroup = ''});

  /// Stop screen capture (deprecated, use ScreenShareStore.stopScreenShare instead)
  @Deprecated('Use ScreenShareStore.stopScreenShare instead')
  void stopScreenShare();

  /// Reset to default state
  void reset();
}
