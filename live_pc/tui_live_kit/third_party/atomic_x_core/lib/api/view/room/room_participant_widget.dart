// Copyright (c) 2025 Tencent. All rights reserved.
// Module:   RoomParticipantView @ AtomicXCore
// Function: Room participant video view for displaying participant video streams.

// <docgen-keep-start>
import 'dart:async';
import 'dart:convert';

import 'package:atomic_x_core/engine/engine_bridge.dart';
import 'package:atomic_x_core/impl/view/view_define.dart';
import 'package:atomic_x_core/impl/common/atomic_platform.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:atomic_x_core/atomicxcore.dart';

part 'package:atomic_x_core/impl/view/room/room_participant_widget_impl.dart';
part 'package:atomic_x_core/impl/view/room/room_participant_controller_impl.dart';
// <docgen-keep-end>

/// Video stream type.
enum VideoStreamType {
  /// Camera video stream.
  camera,

  /// Screen sharing video stream.
  screen,
}

/// Video fill mode.
enum FillMode {
  /// Fill mode, video fills the entire view area, may crop some content.
  fill,

  /// Fit mode, video displays completely, may have black borders.
  fit,
}

/// Room participant video view for displaying participant video streams.
///
/// `RoomParticipantView` View component for displaying room participant video streams.
/// `RoomParticipantView` is a view component specifically designed for rendering room participant video streams.
/// It supports both camera and screen sharing video stream types, and provides fill mode settings, active state control and other features.
///
/// ### Key Features
///
/// - **Video Stream Rendering**：Supports rendering camera video streams and screen sharing video streams.
/// - **Fill Mode**：Supports FILL and FIT video fill modes.
/// - **Active State**：Supports setting the active state of the view to control video rendering.
/// - **Gesture Interaction**：Supports click and other gesture interactions.
///
/// > **Note**: Before use, you need to initialize the video stream type and participant info through [RoomParticipantController.create] method.
///
/// ## Topics
///
/// ### Creating Instance
/// - [RoomParticipantController.create] : Create view instance.
///
/// ### Video Stream Control
/// - [updateStreamType] : Update video stream type.
/// - [updateParticipant] : Update participant info.
///
/// ### View Settings
/// - [setFillMode] : Set fill mode.
/// - [setActive] : Set active state.
///
/// ### Interaction
/// - [setOnClickAction] : Set click callback
///
/// ## See Also
///
/// - [VideoStreamType]
/// - [FillMode]
/// - [RoomParticipant]
/// Controller for managing room participant video view.
///
/// Use [RoomParticipantController.create] to create an instance,
/// then pass it to [RoomParticipantWidget] to display the video.
abstract class RoomParticipantController {
  /// Create controller instance
  /// - [streamType] : Video stream type.
  /// - [participant] : Participant info.
  /// Returns: Controller instance.
  static RoomParticipantController create({
    required VideoStreamType streamType,
    required RoomParticipant participant,
  }) {
    return RoomParticipantControllerImpl(
      streamType: streamType,
      participant: participant,
    );
  }

  /// Update video stream type
  ///
  /// Switch video stream type, for example from camera to screen sharing.
  ///
  /// - [streamType] : Video stream type.
  void updateStreamType(VideoStreamType streamType);

  /// Update participant info
  ///
  /// Update the participant rendered by the view, switch to display the new participant's video stream.
  ///
  /// - [participant] : Participant info.
  void updateParticipant(RoomParticipant participant);

  /// Set fill mode
  ///
  /// Set the fill mode of the video, can choose FILL or FIT mode.
  ///
  /// - [fillMode] : Fill mode.
  void setFillMode(FillMode fillMode);

  /// Set active state
  ///
  /// Set the active state of the view. When active, the view will render video; when inactive, it will stop rendering to save resources.
  ///
  /// - [isActive] : Whether active.
  void setActive(bool isActive);

  /// Set click callback
  ///
  /// Set the callback closure when the view is clicked.
  ///
  /// - [action] : Click callback closure.
  void setOnClickAction(VoidCallback action);
}

/// Widget for displaying room participant video stream.
///
/// This widget renders the video stream of a room participant.
/// Use [RoomParticipantController] to control the video display.
///
/// Example:
/// ```dart
/// final controller = RoomParticipantController.create(
///   streamType: VideoStreamType.camera,
///   participant: participant,
/// );
/// RoomParticipantWidget(controller: controller);
/// ```
class RoomParticipantWidget extends StatefulWidget {
  /// The controller for managing the video view.
  final RoomParticipantController controller;

  /// Creates a [RoomParticipantWidget].
  ///
  /// The [controller] parameter is required and controls the video display.
  const RoomParticipantWidget({
    super.key,
    required this.controller,
  });

  @override
  State<RoomParticipantWidget> createState() => _RoomParticipantWidgetState();
}
