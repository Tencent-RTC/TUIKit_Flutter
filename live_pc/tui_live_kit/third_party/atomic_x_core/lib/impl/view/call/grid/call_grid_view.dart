import 'package:atomic_x_core/impl/view/call/grid/call_grid_cell_view.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../api/call/call_store.dart';
import '../../../../api/device/device_store.dart';
import '../../../../api/view/call/call_core_view.dart';

class CallGridView extends StatefulWidget {
  final Widget? loadingAnimation;
  final Widget? defaultAvatar;
  final Map<VolumeLevel, Widget> volumeIcons;
  final Map<NetworkQuality, Widget> networkQualityIcons;
  final bool enableZoom;

  const CallGridView({
    super.key, 
    this.loadingAnimation,
    this.defaultAvatar,
    this.volumeIcons = const {},
    this.networkQualityIcons = const {},
    this.enableZoom = true,
  });

  @override
  State<CallGridView> createState() => _CallGridViewState();
}

class _CallGridViewState extends State<CallGridView> {
  static const Duration _animationDuration = Duration(milliseconds: 300);
  static const int _maxParticipantsPerRow = 3;
  static const int _maxParticipantsPerColumn = 3;
  static const double _largeViewRatio = 2.0 / 3.0;
  static const double _smallViewRatio = 1.0 / 3.0;
  static const double _twoParticipantsRatio = 1.0 / 2.0;
  static const double _threeParticipantsOffsetRatio = 1.0 / 4.0;
  
  CallGridLayoutController controller = CallGridLayoutController();
  List<String> participants = [];

  _initUsersViewWidget() {
    int userCount = CallStore.shared.state.allParticipants.value.length;
    controller.updateBlockBigger(userCount);
    controller.initCanPlaceSquare(userCount);
    participants.clear();

    participants = _createStreamViewList();
  }

  List<String> _createStreamViewList() {
    String selfId = CallStore.shared.state.selfInfo.value.id;
    List<String> viewList = [];
    List<CallParticipantInfo> infoList = CallStore.shared.state.allParticipants.value;

    viewList.add(selfId);

    for (var info in infoList) {
      if (info.id != selfId) {
        viewList.add(info.id);
      }
    }
    return viewList;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: CallStore.shared.state.allParticipants,
      builder: (context, value, child) {
        _initUsersViewWidget();
        return SizedBox(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.width * 4 / 3,
          child: _buildCallGridLayout(),
        );
      },
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Widget _buildCallGridLayout() {
    return Stack(
      children: participants.asMap().entries.map((entry) {
        final index = entry.key;
        final userId = entry.value;

        final size = _getWH(index, participants.length);
        final position = _getTopLeft(index, participants.length);
        return AnimatedPositioned(
          width: size,
          height: size,
          top: position.item1,
          left: position.item2,
          duration: _animationDuration,
          child: InkWell(
            onTap: () {
              Map<int, bool> newBlockBigger = {};
              controller.blockBigger.value.forEach((key, value) {
                newBlockBigger[key] =
                (key == index) ? !controller.blockBigger.value[key]! : false;
              });
              controller.blockBigger.value = newBlockBigger;

              controller.initCanPlaceSquare(
                  CallStore.shared.state.allParticipants.value.length);
              setState(() {});
            },
            child: CallGridCellView(
              userId: userId,
              key: ValueKey(userId),
              isLarge: controller.blockBigger.value[index] ?? false,
              loadingAnimation: widget.loadingAnimation,
              defaultAvatar: widget.defaultAvatar,
              volumeIcons: widget.volumeIcons,
              networkQualityIcons: widget.networkQualityIcons,
              enableZoom: widget.enableZoom,
            ),
          ),
        );
      }).toList(),
    );
  }

  double _getWH(int index, int count) {
    if (_hasBigger()) {
      if (controller.blockBigger.value[index]!) {
        if (count <= 4) {
          return MediaQuery.of(context).size.width;
        }
        return MediaQuery.of(context).size.width * _largeViewRatio;
      }

      return MediaQuery.of(context).size.width * _smallViewRatio;
    } else {
      if (count <= 4) {
        return MediaQuery.of(context).size.width * _twoParticipantsRatio;
      }
      return MediaQuery.of(context).size.width * _smallViewRatio;
    }
  }

  Tuple<double, double> _getTopLeft(int index, int count) {
    bool has = _hasBigger();
    bool selfIsBigger = controller.blockBigger.value[index]!;

    if (has) {
      if (selfIsBigger) {
        if (count <= 4) {
          return Tuple(0, 0);
        }

        int i = index ~/ _maxParticipantsPerRow;
        int j = index % _maxParticipantsPerColumn;
        j = (j > 1) ? 1 : j;
        return Tuple(
          MediaQuery.of(context).size.width * i / _maxParticipantsPerRow,
          MediaQuery.of(context).size.width * j / _maxParticipantsPerColumn,
        );
      }

      for (int i = 0; i < controller.canPlaceSquare.length; i++) {
        for (int j = 0; j < controller.canPlaceSquare[i].length; j++) {
          if (controller.canPlaceSquare[i][j] == true) {
            controller.canPlaceSquare[i][j] = false;
            return Tuple(MediaQuery.of(context).size.width * i / _maxParticipantsPerRow,
                MediaQuery.of(context).size.width * j / _maxParticipantsPerColumn);
          }
        }
      }
    }

    if (count == 2) {
      if (index == 0) {
        return Tuple(MediaQuery.of(context).size.width / _maxParticipantsPerRow, 0);
      }
      return Tuple(MediaQuery.of(context).size.width / _maxParticipantsPerRow, MediaQuery.of(context).size.width * _twoParticipantsRatio);
    }
    if (count == 3) {
      if (index == 0) {
        return Tuple(0, 0);
      } else if (index == 1) {
        return Tuple(0, MediaQuery.of(context).size.width * _twoParticipantsRatio);
      }
      return Tuple(MediaQuery.of(context).size.width * _twoParticipantsRatio, MediaQuery.of(context).size.width * _threeParticipantsOffsetRatio);
    }
    if (count == 4) {
      if (index == 0) {
        return Tuple(0, 0);
      } else if (index == 1) {
        return Tuple(0, MediaQuery.of(context).size.width * _twoParticipantsRatio);
      } else if (index == 2) {
        return Tuple(MediaQuery.of(context).size.width * _twoParticipantsRatio, 0);
      }
      return Tuple(MediaQuery.of(context).size.width * _twoParticipantsRatio, MediaQuery.of(context).size.width * _twoParticipantsRatio);
    }

    for (int i = 0; i < controller.canPlaceSquare.length; i++) {
      for (int j = 0; j < controller.canPlaceSquare[i].length; j++) {
        if (controller.canPlaceSquare[i][j] == true) {
          controller.canPlaceSquare[i][j] = false;
          return Tuple(
              MediaQuery.of(context).size.width * i / _maxParticipantsPerRow, MediaQuery.of(context).size.width * j / _maxParticipantsPerColumn);
        }
      }
    }
    return Tuple(0, 0);
  }


  _hasBigger() {
    bool has = false;
    controller.blockBigger.value.forEach((key, value) {
      if (value == true) {
        has = true;
      }
    });
    return has;
  }
}

class Tuple<T1, T2> {
  final T1 item1;
  final T2 item2;

  Tuple(this.item1, this.item2);

  @override
  String toString() => '($item1, $item2)';
}

class CallGridLayoutController {
  static const int _gridColumns = 3;
  static const int _smallGridThreshold = 4;

  final ValueNotifier<Map<int, bool>> blockBigger = ValueNotifier({
    0: false, 1: false, 2: false,
    3: false, 4: false, 5: false,
    6: false, 7: false, 8: false
  });

  int blockCount = 0;

  List<List<bool>> canPlaceSquare = [
    [true, true, true],
    [true, true, true],
    [true, true, true],
    [true, true, true]
  ];

  CallGridLayoutController();

  void dispose() {
    blockBigger.dispose();
  }

  updateBlockBigger(int blockCount) {
    blockBigger.value.forEach((key, value) {
      if (value == true && key > blockCount) {
        blockBigger.value = {
          0: false, 1: false, 2: false,
          3: false, 4: false, 5: false,
          6: false, 7: false, 8: false
        };
      }
    });
  }

  bool hasBiggerSquare() {
    bool has = false;
    blockBigger.value.forEach((key, value) {
      if (value == true) {
        has = true;
      }
    });
    return has;
  }

  initCanPlaceSquare(int blockCount) {
    canPlaceSquare = [
      [true, true, true],
      [true, true, true],
      [true, true, true],
      [true, true, true]
    ];

    bool has = false;
    int biggerSquareIndex = 0;
    blockBigger.value.forEach((key, value) {
      if (value == true) {
        has = true;
        biggerSquareIndex = key;
      }
    });

    if (!has) return;

    if (blockCount <= _smallGridThreshold) {
      canPlaceSquare = [
        [false, false, false],
        [false, false, false],
        [false, false, false],
        [true, true, true]
      ];
      return;
    }
    int i = biggerSquareIndex ~/ _gridColumns;
    int j = biggerSquareIndex % _gridColumns;

    j = (j > 1) ? 1 : j;

    canPlaceSquare[i][j] = false;
    canPlaceSquare[i][j + 1] = false;
    canPlaceSquare[i + 1][j] = false;
    canPlaceSquare[i + 1][j + 1] = false;
  }
}
