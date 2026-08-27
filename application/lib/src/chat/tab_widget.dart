import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:application/src/utils/constant.dart';

class TabWidget extends StatelessWidget {
  final TabIconType iconType;

  final bool isActive;

  final double size;

  final Color activeColor;

  final Color inactiveColor;

  const TabWidget({
    Key? key,
    required this.iconType,
    required this.isActive,
    this.size = 24,
    this.activeColor = const Color(0xFF1C66E5),
    this.inactiveColor = const Color(0x8C000000),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      iconType.assetPath,
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(
        isActive ? activeColor : inactiveColor,
        BlendMode.srcIn,
      ),
    );
  }
}

enum TabIconType {
  chats,
  contact,
  settings;

  String get assetPath {
    switch (this) {
      case TabIconType.chats:
        return Constant.tabChats;
      case TabIconType.contact:
        return Constant.tabContacts;
      case TabIconType.settings:
        return Constant.tabSettings;
    }
  }
}
