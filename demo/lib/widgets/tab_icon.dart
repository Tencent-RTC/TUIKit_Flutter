import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class TabIcon extends StatelessWidget {
  final TabIconType iconType;

  final bool isActive;

  final double size;

  final Color activeColor;

  final Color inactiveColor;

  const TabIcon({
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
        return 'assets/tab/tab_chats_active.svg';
      } else if (iconType == TabIconType.contact) {
        return 'assets/tab/tab_contacts_active.svg';
      } else {
        return 'assets/tab/tab_settings_active.svg';
      }
    } else {
      if (iconType == TabIconType.chats) {
        return 'assets/tab/tab_chats.svg';
      } else if (iconType == TabIconType.contact) {
        return 'assets/tab/tab_contacts.svg';
      } else {
        return 'assets/tab/tab_settings.svg';
      }
    }
  }
}

enum TabIconType {
  chats,
  contact,
  settings,
}
