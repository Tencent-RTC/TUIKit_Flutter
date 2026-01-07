import 'dart:math';
import 'package:flutter/material.dart';
import 'package:tencent_conference_uikit/base/index.dart';
import 'package:atomic_x_core/atomicxcore.dart';

import 'participant_video_item_widget.dart';

class DraggableWindowWidget extends StatefulWidget {
  final String roomId;
  final RoomParticipant mainParticipant;
  final bool isMainScreenStream;
  final RoomParticipant? draggableParticipant;
  final double draggableHeight;
  final double draggableWidth;
  final Orientation orientation;

  const DraggableWindowWidget({
    super.key,
    required this.roomId,
    required this.mainParticipant,
    this.isMainScreenStream = false,
    this.draggableParticipant,
    required this.draggableHeight,
    required this.draggableWidth,
    required this.orientation,
  });

  @override
  State<DraggableWindowWidget> createState() => _DraggableWindowWidgetState();
}

class _DraggableWindowWidgetState extends State<DraggableWindowWidget> {
  final ValueNotifier<double> _rightPadding = ValueNotifier(5.0);
  final ValueNotifier<double> _topPadding = ValueNotifier(5.0);

  double _videoLayoutHeight = 0;
  double _videoLayoutWidth = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateVideoLayoutSize();
  }

  @override
  void didUpdateWidget(covariant DraggableWindowWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.orientation != oldWidget.orientation) {
      _updateVideoLayoutSize();
      _updatePadding();
    }
  }

  @override
  void dispose() {
    _rightPadding.dispose();
    _topPadding.dispose();
    super.dispose();
  }

  void _updateVideoLayoutSize() {
    final size = MediaQuery.of(context).size;
    _videoLayoutWidth = widget.orientation == Orientation.portrait ? size.width : 648.width;
    _videoLayoutHeight = widget.orientation == Orientation.portrait ? 665.height : size.height;
  }

  void _updatePadding() {
    if (_rightPadding.value != 5.0) {
      _rightPadding.value = _videoLayoutWidth - 5 - widget.draggableWidth;
    }
    _topPadding.value = min(_topPadding.value, _videoLayoutHeight - 5 - widget.draggableHeight);
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    _rightPadding.value = (_rightPadding.value - details.delta.dx).clamp(
      5,
      _videoLayoutWidth - 5 - widget.draggableWidth,
    );

    if (_topPadding.value + details.delta.dy > 5) {
      _topPadding.value = (_topPadding.value + details.delta.dy).clamp(
        5,
        _videoLayoutHeight - 5 - widget.draggableHeight,
      );
    }
  }

  void _handlePanEnd(DragEndDetails details) {
    if (_rightPadding.value < (_videoLayoutWidth - widget.draggableWidth) / 2) {
      _rightPadding.value = 5.0;
    } else {
      _rightPadding.value = _videoLayoutWidth - 5 - widget.draggableWidth;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_videoLayoutHeight == 0 || _videoLayoutWidth == 0) {
      _updateVideoLayoutSize();
    }

    return Stack(
      children: [
        ParticipantVideoItemWidget(
          key: ValueKey('${widget.mainParticipant.userID}_${widget.isMainScreenStream ? 'screen' : 'camera'}'),
          roomId: widget.roomId,
          participant: widget.mainParticipant,
          isScreenStream: widget.isMainScreenStream,
        ),
        if (widget.draggableParticipant != null)
          ValueListenableBuilder(
            valueListenable: _rightPadding,
            builder: (context, rightPadding, _) {
              return ValueListenableBuilder(
                valueListenable: _topPadding,
                builder: (context, topPadding, _) {
                  return Positioned(
                    right: rightPadding,
                    top: topPadding,
                    child: GestureDetector(
                      onPanUpdate: _handlePanUpdate,
                      onPanEnd: _handlePanEnd,
                      child: ParticipantVideoItemWidget(
                        key: ValueKey('${widget.draggableParticipant!.userID}_camera'),
                        roomId: widget.roomId,
                        participant: widget.draggableParticipant!,
                        width: widget.draggableWidth,
                        height: widget.draggableHeight,
                        isScreenStream: false,
                      ),
                    ),
                  );
                },
              );
            },
          ),
      ],
    );
  }
}
