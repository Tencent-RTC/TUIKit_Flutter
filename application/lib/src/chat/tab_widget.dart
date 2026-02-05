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
    if (isActive) {
      final String iconPath = getIconPath(true);
      return SvgPicture.asset(
        iconPath,
        width: size,
        height: size,
        colorFilter: ColorFilter.mode(activeColor, BlendMode.srcIn),
      );
    } else {
      final String iconPath = getIconPath(false);
      return SvgPicture.asset(
        iconPath,
        width: size,
        height: size,
        colorFilter: ColorFilter.mode(inactiveColor, BlendMode.srcIn),
      );
    }
  }

  String getIconPath(bool isActive) {
    if (isActive) {
      if (iconType == TabIconType.chats) {
        return Constant.tabChatsActive;
      } else if (iconType == TabIconType.contact) {
        return Constant.tabContactsActive;
      } else {
        return Constant.tabSettingsActive;
      }
    } else {
      if (iconType == TabIconType.chats) {
        return Constant.tabChats;
      } else if (iconType == TabIconType.contact) {
        return Constant.tabContacts;
      } else {
        return Constant.tabSettings;
      }
    }
  }
}

enum TabIconType {
  chats,
  contact,
  settings,
}
