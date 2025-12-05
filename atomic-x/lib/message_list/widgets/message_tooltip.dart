import 'dart:math' as math;

import 'package:tuikit_atomic_x/base_component/base_component.dart';
import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class MessageMenuItem {
  final String title;
  final IconData? icon;
  final String? assetName;
  final String? package;
  final VoidCallback onTap;
  final bool isDestructive;

  const MessageMenuItem({
    required this.title,
    this.icon,
    this.assetName,
    this.package,
    required this.onTap,
    this.isDestructive = false,
  });
}

abstract class MessageMenuCallbacks {
  void onCopyMessage(MessageInfo message);

  void onDeleteMessage(MessageInfo message);

  void onRecallMessage(MessageInfo message);

  void onForwardMessage(MessageInfo message);

  void onQuoteMessage(MessageInfo message);

  void onMultiSelectMessage(MessageInfo message);

  void onResendMessage(MessageInfo message);
}

class MessageTooltip extends StatefulWidget {
  final List<MessageMenuItem> menuItems;
  final MessageInfo message;
  final VoidCallback onCloseTooltip;
  final bool isSelf;

  const MessageTooltip({
    super.key,
    required this.menuItems,
    required this.message,
    required this.onCloseTooltip,
    required this.isSelf,
  });

  @override
  State<StatefulWidget> createState() => MessageTooltipState();
}

class MessageTooltipState extends State<MessageTooltip> {
  @override
  Widget build(BuildContext context) {
    final colorTheme = BaseThemeProvider.colorsOf(context);

    return Container(
      decoration: BoxDecoration(
        color: colorTheme.bgColorOperate,
        borderRadius: BorderRadius.all(Radius.circular(10)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: math.min(MediaQuery.of(context).size.width * 0.75, 350),
        ),
        child: Wrap(
          spacing: 4,
          runSpacing: 4,
          children: widget.menuItems.map((item) => _buildMenuItem(item, colorTheme)).toList(),
        ),
      ),
    );
  }

  Widget _buildMenuItem(MessageMenuItem item, SemanticColorScheme colorTheme) {
    return Material(
      color: colorTheme.bgColorOperate,
      child: InkWell(
        onTap: () {
          widget.onCloseTooltip();
          item.onTap();
        },
        child: Container(
          padding: const EdgeInsets.all(6),
          constraints: const BoxConstraints(
            minWidth: 44,
            maxWidth: 60,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildMenuIcon(item, colorTheme),
              const SizedBox(height: 4),
              Text(
                item.title,
                style: TextStyle(
                  decoration: TextDecoration.none,
                  color: item.isDestructive ? colorTheme.textColorError : colorTheme.textColorPrimary,
                  fontSize: 10,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuIcon(MessageMenuItem item, SemanticColorScheme colorTheme) {
    final color = item.isDestructive ? colorTheme.textColorError : colorTheme.textColorPrimary;
    
    if (item.assetName != null && item.assetName!.isNotEmpty) {
      final isSvg = item.assetName!.toLowerCase().endsWith('.svg');
      
      if (isSvg) {
        return SvgPicture.asset(
          item.assetName!,
          package: item.package,
          width: 20,
          height: 20,
          colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
          placeholderBuilder: (context) => Icon(
            item.icon,
            size: 20,
            color: color,
          ),
        );
      } else {
        return Image.asset(
          item.assetName!,
          package: item.package,
          width: 20,
          height: 20,
          color: color,
          errorBuilder: (context, error, stackTrace) {
            return Icon(
              item.icon,
              size: 20,
              color: color,
            );
          },
        );
      }
    }
    
    return Icon(
      item.icon ,
      size: 20,
      color: color,
    );
  }
}
