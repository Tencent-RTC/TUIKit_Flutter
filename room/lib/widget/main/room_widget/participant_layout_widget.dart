import 'dart:async';
import 'package:flutter/material.dart';
import 'package:tencent_conference_uikit/base/index.dart';
import 'package:atomic_x_core/atomicxcore.dart';

import 'participant_video_item_widget.dart';
import 'draggable_window_widget.dart';

class ParticipantLayoutWidget extends StatefulWidget {
  final String roomId;
  final List<RoomParticipant> participants;
  final int startIndex;
  final int endIndex;
  final int currentPageIndex;
  final bool isScreenLayout;
  final bool isTwoUserLayout;
  final RoomParticipant? screenParticipant;
  final ValueNotifier<bool> isScrolling;

  const ParticipantLayoutWidget({
    super.key,
    required this.roomId,
    required this.participants,
    required this.startIndex,
    required this.endIndex,
    required this.currentPageIndex,
    this.isScreenLayout = false,
    this.isTwoUserLayout = false,
    this.screenParticipant,
    required this.isScrolling,
  });

  @override
  State<ParticipantLayoutWidget> createState() => _ParticipantLayoutWidgetState();
}

class _ParticipantLayoutWidgetState extends State<ParticipantLayoutWidget> {
  late final RoomParticipantStore _participantStore;
  final ValueNotifier<RoomParticipant?> _speakingParticipant = ValueNotifier(null);
  final ValueNotifier<bool> _isDraggableVisible = ValueNotifier(false);

  Timer? _speakingUpdateTimer;

  @override
  void initState() {
    super.initState();
    _participantStore = RoomParticipantStore.create(widget.roomId);
  }

  @override
  void dispose() {
    _speakingUpdateTimer?.cancel();
    _speakingParticipant.dispose();
    _isDraggableVisible.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(
      builder: (context, orientation) {
        return _buildLayout(orientation);
      },
    );
  }

  // ignore: unused_element
  void _handleSpeakingUsersChanged() {
    if (!widget.isScreenLayout || _speakingUpdateTimer?.isActive == true) {
      return;
    }

    final speakingUsers = _participantStore.state.speakingUsers.value;
    final speakingEntry = speakingUsers.entries.firstWhere(
      (entry) => entry.value >= 10,
      orElse: () => const MapEntry<String, int>('', -1),
    );

    if (speakingEntry.key.isEmpty) {
      if (_isDraggableVisible.value) {
        _isDraggableVisible.value = false;
        _speakingParticipant.value = null;
      }
      return;
    }

    final participant = widget.participants.firstWhere(
      (p) => p.userID == speakingEntry.key,
      orElse: () => RoomParticipant(),
    );

    if (participant.userID.isNotEmpty) {
      _speakingParticipant.value = participant;
      _isDraggableVisible.value = true;
      _speakingUpdateTimer = Timer(const Duration(seconds: 5), () {});
    }
  }
}

extension _ParticipantLayoutWidgetStatePrivate on _ParticipantLayoutWidgetState {
  WrapAlignment _getWrapAlignment(int currentPageIndex) {
    final hasScreen = _participantStore.state.participantWithScreen.value != null;
    final userListLength = widget.participants.length;
    final totalPages = hasScreen ? (userListLength / 6).ceil() + 1 : (userListLength / 6).ceil();
    final result = (widget.isScreenLayout || userListLength > 6)
        ? (totalPages == currentPageIndex + 1 && userListLength % 6 != 0)
            ? WrapAlignment.start
            : WrapAlignment.center
        : WrapAlignment.center;
    return result;
  }

  WrapAlignment _getHorizontalWrapAlignment(int currentPageIndex) {
    final hasScreen = _participantStore.state.participantWithScreen.value != null;
    final userListLength = widget.participants.length;
    final totalPages = hasScreen ? (userListLength / 6).ceil() + 1 : (userListLength / 6).ceil();
    final isMultiPage = widget.isScreenLayout || userListLength > 6;

    if (isMultiPage) {
      return (totalPages == currentPageIndex + 1 && userListLength % 6 != 0)
          ? WrapAlignment.start
          : WrapAlignment.center;
    } else {
      final itemCount = widget.endIndex - widget.startIndex + 1;
      if (itemCount == 1) {
        return WrapAlignment.center;
      }
      return (itemCount % 2 != 0) ? WrapAlignment.start : WrapAlignment.center;
    }
  }

  Widget _buildLayout(Orientation orientation) {
    if (widget.isScreenLayout && widget.screenParticipant != null) {
      return _buildScreenShareLayout(orientation);
    } else if (widget.isTwoUserLayout) {
      return _buildTwoUserLayout(orientation);
    } else {
      return _buildGridLayout(orientation);
    }
  }

  Widget _buildScreenShareLayout(Orientation orientation) {
    return ValueListenableBuilder(
      valueListenable: _isDraggableVisible,
      builder: (context, isDraggableVisible, _) {
        return ValueListenableBuilder(
          valueListenable: _speakingParticipant,
          builder: (context, speakingParticipant, _) {
            return ValueListenableBuilder(
              valueListenable: widget.isScrolling,
              builder: (context, isScrolling, _) {
                final shouldShowDraggable = isDraggableVisible &&
                    isScrolling &&
                    speakingParticipant != null &&
                    speakingParticipant.cameraStatus == DeviceStatus.on;

                final draggableHeight =
                    (orientation == Orientation.portrait && shouldShowDraggable) ? 180.height : 100.height;

                final draggableWidth =
                    (orientation == Orientation.landscape && shouldShowDraggable) ? 180.width : 100.width;

                return DraggableWindowWidget(
                  roomId: widget.roomId,
                  mainParticipant: widget.screenParticipant!,
                  isMainScreenStream: true,
                  draggableParticipant: shouldShowDraggable ? speakingParticipant : null,
                  draggableHeight: draggableHeight,
                  draggableWidth: draggableWidth,
                  orientation: orientation,
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildTwoUserLayout(Orientation orientation) {
    final mainParticipant = widget.participants.isNotEmpty ? widget.participants[0] : null;
    final draggableParticipant = widget.participants.length == 2 ? widget.participants[1] : null;

    if (mainParticipant == null) {
      return const SizedBox.shrink();
    }

    final draggableHeight = (orientation == Orientation.portrait &&
            draggableParticipant != null &&
            draggableParticipant.cameraStatus == DeviceStatus.on)
        ? 180.height
        : 100.height;

    final draggableWidth = (orientation == Orientation.landscape &&
            draggableParticipant != null &&
            draggableParticipant.cameraStatus == DeviceStatus.on)
        ? 180.width
        : 100.width;

    return DraggableWindowWidget(
      roomId: widget.roomId,
      mainParticipant: mainParticipant,
      isMainScreenStream: false,
      draggableParticipant: draggableParticipant,
      draggableHeight: draggableHeight,
      draggableWidth: draggableWidth,
      orientation: orientation,
    );
  }

  Widget _buildGridLayout(Orientation orientation) {
    final itemCount = widget.endIndex - widget.startIndex + 1;
    if (itemCount <= 0) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: orientation == Orientation.portrait
          ? EdgeInsets.only(left: 7.width, right: 7.width, top: 47.height, bottom: 47.height)
          : EdgeInsets.only(top: 7.height, bottom: 7.height, left: 53.width, right: 53.width),
      child: SizedBox(
        width: orientation == Orientation.portrait ? MediaQuery.of(context).size.width - 14.width : 542.width,
        height: orientation == Orientation.portrait ? 542.height : MediaQuery.of(context).size.height,
        child: Wrap(
          spacing: 7.width,
          runSpacing: 7.height,
          alignment: _getHorizontalWrapAlignment(widget.currentPageIndex),
          runAlignment: _getWrapAlignment(widget.currentPageIndex),
          children: List.generate(itemCount, (index) {
            final participantIndex = widget.startIndex + index;
            if (participantIndex >= widget.participants.length) {
              return const SizedBox.shrink();
            }
            return ParticipantVideoItemWidget(
              key: ValueKey('${widget.participants[participantIndex].userID}_camera'),
              roomId: widget.roomId,
              participant: widget.participants[participantIndex],
              width: 176.width,
              height: 176.height,
              isScreenStream: false,
            );
          }),
        ),
      ),
    );
  }
}
