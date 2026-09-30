// Copyright (c) 2025 Tencent. All rights reserved.
// Module:   CallCoreView @ AtomicXCore
// Function: Core call view component responsible for video rendering and interactive display of the call interface. Supports multi-layout switching (single-person float/multi-person grid/picture-in-picture), call waiting animations, and personalized configuration of volume, network status, and user avatars.

// <docgen-keep-start>
import 'package:atomic_x_core/atomicxcore.dart';
import 'package:atomic_x_core/impl/view/call/float/call_float_view.dart';
import 'package:atomic_x_core/impl/view/call/grid/call_grid_view.dart';
import 'package:atomic_x_core/impl/view/call/pip/call_pip_view.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';

import '../../device/device_store.dart';

part '../../../impl/view/call/call_core_view_impl.dart';
// <docgen-keep-end>

/// Call layout mode enum, used to define the display form of the call screen.
enum CallLayoutTemplate { float, grid, pip }

/// Volume level enum, used to identify the current volume intensity of participants.
enum VolumeLevel {
  /// Muted.
  mute,

  /// Low volume.
  low,

  /// Medium volume.
  medium,

  /// High volume.
  high,

  /// Peak volume.
  peak,
}

/// Controller for managing CallCoreView layout and state.
///
/// `CallCoreController` is used to control the layout template of `CallCoreView`. Create an instance using the factory method `create()`.
abstract class CallCoreController {
  /// Current layout template notifier.
  final ValueNotifier<CallLayoutTemplate> _currentTemplate = ValueNotifier(CallLayoutTemplate.float);

  /// Video zoom gesture enabled state.
  bool _zoomEnabled = true;

  /// Factory method to create a CallCoreController instance.
  static CallCoreController create() {
    return CallCoreControllerImpl();
  }

  /// Set the layout template for the call view.
  void setLayoutTemplate(CallLayoutTemplate template);

  /// Enable or disable Video Zoom Gestures on larger video views (float main view and grid enlarged views).
  /// When enabled, users can pinch to zoom in/out on video views (center zoom only).
  ///
  /// - [enable] : true to enable zoom gestures, false to disable
  void enableVideoZoomGesture(bool enable);

  /// Dispose the controller and release resources.
  void dispose();
}

/// Core call view component responsible for video rendering and interactive display of the call interface. Supports multi-layout switching (single-person float/multi-person grid/picture-in-picture), call waiting animations, and personalized configuration of volume, network status, and user avatars.
///
/// `CallCoreView` Core view component for displaying call screens.
/// `CallCoreView` is the main container for the call interface, providing the following core capabilities:
///
/// - **Multi-Layout Switching**: Supports switching between single-person float, multi-person grid, and picture-in-picture layouts.
/// - **Call Waiting Interaction**: Supports custom waiting animations before call connection.
/// - **Status Visualization**: Supports custom icons for different volume levels and network quality states.
/// - **User Personalization**: Supports setting participant avatars through User ID mapping.
///
/// ### Key Features
///
/// - **Multi-Layout Switching**：Supports switching between single-person float, multi-person grid, and picture-in-picture layouts.
/// - **Call Waiting Interaction**：Supports custom waiting animations before call connection.
/// - **Status Visualization**：Supports custom icons for different volume levels and network quality states.
/// - **User Personalization**：Supports setting participant avatars through User ID mapping.
///
/// > **Note**: This view component must be used together with [CallStore] to properly display call screens and receive call state updates.
///
/// ### Method Overview
///
/// | Feature | Method | Description |
/// |-------|------|-----------|
/// | Multi-Layout Switching | `controller.setLayoutTemplate` | Switch call interface layout (single-person float/multi-person grid/PiP) |
/// | Default Avatar | `defaultAvatar` | Set the default placeholder avatar widget |
/// | Loading Animation | `loadingAnimation` | Set the loading animation widget during call waiting state |
/// | Volume Icons | `volumeIcons` | Customize icons for each volume level |
/// | Network Icons | `networkQualityIcons` | Customize icons for each network quality level |
///
/// ### Usage Example
///
/// ```dart
/// import 'package:atomic_x_core/atomicxcore.dart';
///
/// // Create controller
/// final controller = CallCoreController.create();
///
/// // Create call view with configuration
/// CallCoreView(
///   controller: controller,
///   defaultAvatar: Icon(Icons.person),
///   loadingAnimation: CircularProgressIndicator(),
///   volumeIcons: {
///     VolumeLevel.mute: Icon(Icons.volume_off),
///     VolumeLevel.low: Icon(Icons.volume_down),
///     VolumeLevel.medium: Icon(Icons.volume_up),
///     VolumeLevel.high: Icon(Icons.volume_up),
///     VolumeLevel.peak: Icon(Icons.volume_up),
///   },
///   networkQualityIcons: {
///     NetworkQuality.unknown: Icon(Icons.signal_wifi_off),
///     NetworkQuality.excellent: Icon(Icons.signal_wifi_4_bar),
///     NetworkQuality.good: Icon(Icons.signal_wifi_4_bar),
///     NetworkQuality.poor: Icon(Icons.network_wifi_3_bar),
///     NetworkQuality.bad: Icon(Icons.network_wifi_2_bar),
///     NetworkQuality.veryBad: Icon(Icons.network_wifi_1_bar),
///     NetworkQuality.down: Icon(Icons.signal_wifi_off),
///   },
/// );
///
/// // Set layout mode
/// controller.setLayoutTemplate(CallLayoutTemplate.grid);
/// ```
///
/// ## Topics
///
/// ### Static Properties
/// - [defaultAvatar] : Default placeholder avatar.
/// - [loadingAnimation] : Call waiting animation.
/// - [volumeIcons] : Volume status icon collection.
/// - [networkQualityIcons] : Network signal icon collection.
///
/// ### Configuration Methods
/// - [CallCoreController.setLayoutTemplate] : Multi-layout switching.
///
/// ## See Also
///
/// - [CallLayoutTemplate]
/// - [VolumeLevel]
class CallCoreView extends StatefulWidget {
  /// The controller for managing call view layout and state.
  final CallCoreController controller;

  /// Default placeholder avatar widget. Displayed when a participant has not set a specific avatar or when loading fails.
  final Widget? defaultAvatar;

  /// Loading animation widget. Used to display waiting state before call connection.
  final Widget? loadingAnimation;

  /// Volume status icon collection. Defines widget resources for each volume level.
  final Map<VolumeLevel, Widget> volumeIcons;

  /// Network signal icon collection. Defines widget resources for different network quality levels.
  final Map<NetworkQuality, Widget> networkQualityIcons;

  /// Constructor and lifecycle methods for CallCoreView widget.
  const CallCoreView({
    super.key,
    required this.controller,
    this.defaultAvatar,
    this.loadingAnimation,
    this.volumeIcons = const {},
    this.networkQualityIcons = const {},
  });

  @override
  State<CallCoreView> createState() => _CallCoreViewState();
}
