import 'package:atomic_x/atomicx.dart';
import 'package:atomic_x/call/component/stream_widget/multi_call_stream_widget.dart';
import 'package:flutter/material.dart';
import 'package:atomic_x/call/component/stream_widget/stream_view/participant_stream_view.dart';
import 'package:atomic_x/call/common/utils/utils.dart';

class MultiCallStreamLayoutWidget extends StatefulWidget {
  final List<ParticipantStreamView> participantViews;

  const MultiCallStreamLayoutWidget({Key? key, required this.participantViews}) : super(key: key);

  @override
  State<MultiCallStreamLayoutWidget> createState() => _MultiCallStreamLayoutWidgetState();
}

class _MultiCallStreamLayoutWidgetState extends State<MultiCallStreamLayoutWidget> {
  final _duration = const Duration(milliseconds: 300);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: widget.participantViews.map((view) {
        final size = _getWH(view.index, widget.participantViews.length);
        final position = _getTopLeft(view.index, widget.participantViews.length);
        return AnimatedPositioned(
          width: size,
          height: size,
          top: position.item1,
          left: position.item2,
          duration: _duration,
          child: InkWell(
            onTap: () {
              Map<int, bool> newBlockBigger = {};
              MultiCallUserWidgetData.blockBigger.value.forEach((key, value) {
                newBlockBigger[key] =
                (key == view.index) ? !MultiCallUserWidgetData.blockBigger.value[key]! : false;
              });
              MultiCallUserWidgetData.blockBigger.value = newBlockBigger;

              MultiCallUserWidgetData.initCanPlaceSquare(
                  CallParticipantStore.shared.state.allParticipants.value.length);
              setState(() {});
            },
            child: view,
          ),
        );
      }).toList(),
    );
  }

  double _getWH(int index, int count) {
    if (_hasBigger()) {
      if (MultiCallUserWidgetData.blockBigger.value[index]!) {
        if (count <= 4) {
          return MediaQuery.of(context).size.width;
        }
        return MediaQuery.of(context).size.width * 2 / 3;
      }

      return MediaQuery.of(context).size.width * 1 / 3;
    } else {
      if (count <= 4) {
        return MediaQuery.of(context).size.width / 2;
      }
      return MediaQuery.of(context).size.width * 1 / 3;
    }
  }

  Tuple<double, double> _getTopLeft(int index, int count) {
    bool has = _hasBigger();
    bool selfIsBigger = MultiCallUserWidgetData.blockBigger.value[index]!;

    if (has) {
      if (selfIsBigger) {
        if (count <= 4) {
          return Tuple(0, 0);
        }

        int i = (index - 1) ~/ 3;
        int j = (index - 1) % 3;
        j = (j > 1) ? 1 : j;
        return Tuple(
            MediaQuery.of(context).size.width * i / 3, MediaQuery.of(context).size.width * j / 3);
      }

      for (int i = 0; i < MultiCallUserWidgetData.canPlaceSquare.length; i++) {
        for (int j = 0; j < MultiCallUserWidgetData.canPlaceSquare[i].length; j++) {
          if (MultiCallUserWidgetData.canPlaceSquare[i][j] == true) {
            MultiCallUserWidgetData.canPlaceSquare[i][j] = false;
            return Tuple(MediaQuery.of(context).size.width * i / 3,
                MediaQuery.of(context).size.width * j / 3);
          }
        }
      }
    }

    if (count == 2) {
      if (index == 1) {
        return Tuple(MediaQuery.of(context).size.width / 3, 0);
      }
      return Tuple(MediaQuery.of(context).size.width / 3, MediaQuery.of(context).size.width / 2);
    }
    if (count == 3) {
      if (index == 1) {
        return Tuple(0, 0);
      } else if (index == 2) {
        return Tuple(0, MediaQuery.of(context).size.width / 2);
      }
      return Tuple(MediaQuery.of(context).size.width / 2, MediaQuery.of(context).size.width / 4);
    }
    if (count == 4) {
      if (index == 1) {
        return Tuple(0, 0);
      } else if (index == 2) {
        return Tuple(0, MediaQuery.of(context).size.width / 2);
      } else if (index == 3) {
        return Tuple(MediaQuery.of(context).size.width / 2, 0);
      }
      return Tuple(MediaQuery.of(context).size.width / 2, MediaQuery.of(context).size.width / 2);
    }

    for (int i = 0; i < MultiCallUserWidgetData.canPlaceSquare.length; i++) {
      for (int j = 0; j < MultiCallUserWidgetData.canPlaceSquare[i].length; j++) {
        if (MultiCallUserWidgetData.canPlaceSquare[i][j] == true) {
          MultiCallUserWidgetData.canPlaceSquare[i][j] = false;
          return Tuple(
              MediaQuery.of(context).size.width * i / 3, MediaQuery.of(context).size.width * j / 3);
        }
      }
    }
    return Tuple(0, 0);
  }


  _hasBigger() {
    bool has = false;
    MultiCallUserWidgetData.blockBigger.value.forEach((key, value) {
      if (value == true) {
        has = true;
      }
    });
    return has;
  }
}
