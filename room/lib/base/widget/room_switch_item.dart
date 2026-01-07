import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:tencent_conference_uikit/base/index.dart';

class RoomSwitchItem extends StatelessWidget {
  final String label;

  final ValueNotifier<bool> valueNotifier;

  final ValueChanged<bool> onChanged;

  const RoomSwitchItem({super.key, required this.label, required this.valueNotifier, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 15.height),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16, color: RoomColors.g3)),
          ValueListenableBuilder(
            valueListenable: valueNotifier,
            builder: (context, value, _) {
              return SizedBox(
                height: 24.height,
                width: 42.width,
                child: CupertinoSwitch(
                  value: value,
                  onChanged: onChanged,
                  activeTrackColor: RoomColors.b1,
                  inactiveTrackColor: RoomColors.g7,
                  inactiveThumbColor: Colors.white,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
