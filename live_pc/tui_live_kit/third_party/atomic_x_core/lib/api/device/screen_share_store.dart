// Copyright (c) 2025 Tencent. All rights reserved.
// Module:   ScreenShareStore @ AtomicXCore
// Function: Screen sharing related interfaces, starting/stopping screen sharing, and enumerating screen and window capture sources.

// <docgen-keep-start>
import 'package:atomic_x_core/api/device/device_store.dart';
import 'package:atomic_x_core/impl/common/store_factory.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
// <docgen-keep-end>

/// Share source type (desktop only).
///
/// Describes what kind of target a [ShareSource] represents.
///
/// ### Response Scenarios
///
/// | Type | Value | Description |
/// |------|------|-----------|
/// | `window` | 0 | An application window |
/// | `screen` | 1 | A physical monitor / whole screen |
enum ShareSourceType {
  /// An application window.
  window(0),

  /// A physical monitor / whole screen.
  screen(1);

  final int value;

  const ShareSourceType(this.value);
}

/// A shareable screen / window source (desktop only).
///
/// This is a one-shot snapshot returned by [ScreenShareStore.getShareSources], intended for rendering the source-picker UI at that moment. It is **not** a persistent state.
///
/// > **Note**: [sourceName] and [thumbnail] reflect the moment of enumeration and will drift from what the user currently sees (window titles change, contents change). [sourceId] is a volatile runtime handle (HWND / CGWindowID) and must not be persisted. Only pass it straight back to [ScreenShareStore.startScreenShare] while it is still live.
///
///
/// | Property | Type | Description |
/// |--------|------|-----------|
/// | [type] | [ShareSourceType] | Source type |
/// | [sourceId] | `String` | Live runtime handle, stringified |
/// | [sourceName] | `String` | Source name at enumeration time |
/// | [isMinimizeWindow] | `bool` | Whether the window is minimized |
/// | [thumbnail] | `ImageProvider?` | Thumbnail image |
/// | [icon] | `ImageProvider?` | Icon image |
class ShareSource {
  /// Source type.
  final ShareSourceType type;

  /// Live runtime handle (HWND / CGWindowID), stringified. Do not persist.
  final String sourceId;

  /// Source name at enumeration time. May be stale versus the live window title.
  final String sourceName;

  /// Whether the window is minimized. Use it to hide or gray out minimized windows in the source-picker UI (minimized windows cannot be captured effectively).
  final bool isMinimizeWindow;

  /// Thumbnail image, may be null if not requested / unavailable.
  final ImageProvider? thumbnail;

  /// Icon image, may be null if not requested / unavailable.
  final ImageProvider? icon;

  /// Source position in screen coordinates at enumeration time (pixels).
  final int x;
  final int y;

  /// Source size at enumeration time (pixels). 0 when the platform does not
  /// report it.
  final int width;
  final int height;
  const ShareSource({
    this.type = ShareSourceType.window,
    this.sourceId = '',
    this.sourceName = '',
    this.isMinimizeWindow = false,
    this.thumbnail,
    this.icon,
    this.x = 0,
    this.y = 0,
    this.width = 0,
    this.height = 0,
  });
}

/// Share capture config (desktop only).
///
/// Capture config for screen / window sharing. Defaults are used when null.
///
///
/// | Property | Type | Description |
/// |--------|------|-----------|
/// | [enableCaptureMouse] | `bool` | Whether to capture the mouse cursor |
class ShareConfig {
  /// Whether to capture the mouse cursor. Defaults to true.
  final bool enableCaptureMouse;
  const ShareConfig({
    this.enableCaptureMouse = true,
  });
}

/// Screen sharing state.
///
/// A snapshot of screen sharing state, containing the on/off status of screen sharing.
///
/// > **Note**: Screen sharing state is automatically updated. Subscribe to [state] to receive real-time updates.
///
/// ### State Properties Overview
///
/// | Property | Type | Description |
/// |--------|------|-----------|
/// | [screenStatus] | `ValueListenable<DeviceStatus>` | Screen sharing status |
abstract class ScreenShareState {
  /// Screen sharing status.
  ValueListenable<DeviceStatus> get screenStatus;
}

/// Screen sharing related interfaces, starting/stopping screen sharing, and enumerating screen and window capture sources.
///
/// `ScreenShareStore` Screen sharing management class for starting/stopping screen sharing and enumerating shareable screens and windows.
/// `ScreenShareStore` provides a complete set of screen sharing APIs, including full-screen sharing on mobile, and screen / window source enumeration and targeted sharing on desktop (Win/Mac).
///
/// ### Key Features
///
/// - **Screen Sharing**：Start and stop screen sharing, with support for iOS App Group and desktop capture property configuration.
/// - **Source Enumeration**：Enumerate shareable screens and application windows with thumbnails and icons for building source-picker UI (desktop only).
/// - **State Subscription**：Real-time subscription to screen sharing state changes.
///
/// > **Important**: Use [shared] singleton to get the `ScreenShareStore` instance. Do not attempt to initialize directly.
///
/// > **Note**: Screen sharing state updates are delivered through the [state] publisher. Subscribe to it to receive real-time updates about screen sharing status.
///
/// ### Screen Sharing Operations Overview
///
/// | Feature | Method | Description |
/// |-------|------|-----------|
/// | Screen Sharing | [startScreenShare]/[stopScreenShare] | Start/stop screen sharing |
/// | Source Enumeration | [getShareSources] | Enumerate shareable screens / windows (desktop only) |
///
/// ### Usage Example
///
/// ```dart
/// // Get singleton instance
/// final store = ScreenShareStore.shared;
///
/// // Subscribe to state changes
/// store.state.screenStatus.addListener(() {
///     print('Screen sharing status: ${store.state.screenStatus.value}');
/// });
///
/// // Mobile: start screen sharing
/// store.startScreenShare(iOSAppGroup: 'group.com.example.app');
///
/// // Desktop: enumerate sources and share a specific target
/// final sources = await store.getShareSources(
///   thumbnailSize: const Size(320, 180),
///   iconSize: const Size(48, 48),
/// );
/// if (sources.isNotEmpty) {
///   store.startScreenShare(sourceId: sources.first.sourceId);
/// }
///
/// // Stop screen sharing
/// store.stopScreenShare();
/// ```
///
/// ## Topics
///
/// ### Getting Instance
/// - [shared] : Singleton object.
///
/// ### Observing State
/// - [state] : Reactive state containing screen sharing status.
///
/// ### Screen Sharing
/// - [startScreenShare] : Start screen sharing.
/// - [getShareSources] : Enumerate shareable screens / windows (desktop only).
/// - [stopScreenShare] : Stop screen sharing.
///
/// ### Reset
/// - [reset] : Reset to default state.
///
/// ## See Also
///
/// - [ScreenShareState]
/// - [DeviceStatus]
/// - [DeviceError]
/// - [ShareSourceType]
/// - [ShareSource]
/// - [ShareConfig]
abstract class ScreenShareStore {
  /// Singleton object
  ///
  /// @param shared Singleton instance.
  static ScreenShareStore get shared => StoreFactory.shared.getStore<ScreenShareStore>();

  /// State.
  ScreenShareState get state;

  /// Start screen sharing
  ///
  /// - [iOSAppGroup] : Defaults to '', which is the correct value for Android (ignored on the Android platform). On iOS, the value must match the App Group string configured in the Broadcast Upload Extension, used for sharing data between the host app and the Extension, in the format group.<reverse-domain>. Passing an empty string is allowed but does not guarantee screen sharing stability; configuring it correctly is recommended.
  /// - [sourceId] : Desktop only (Win/Mac). The runtime handle of the screen / window to share, taken from [ShareSource.sourceId] returned by [getShareSources]. When null, no specific target is selected. The handle is volatile and must not be persisted; only pass it back while it is still live.
  /// - [property] : Desktop only (Win/Mac). Capture config, see [ShareConfig]. Uses default config when null.
  void startScreenShare({String iOSAppGroup = '', String? sourceId, ShareConfig? property});

  /// Enumerate shareable screens / windows (desktop only)
  ///
  /// - [thumbnailSize] : Desired thumbnail size for each source.
  /// - [iconSize] : Desired icon size for each source.
  Future<List<ShareSource>> getShareSources({required Size thumbnailSize, required Size iconSize});

  /// Stop screen capture
  void stopScreenShare();

  /// Reset to default state
  void reset();
}
