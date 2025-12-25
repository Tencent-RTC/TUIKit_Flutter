import 'package:flutter/material.dart';

import '../../../common/index.dart';
import 'like_send_controller.dart';

class LikeSendWidget extends StatelessWidget {
  final LikeSendController controller;
  final Widget? icon;

  const LikeSendWidget({super.key, required this.controller, this.icon});

  @override
  Widget build(BuildContext context) {
    return IconButton(onPressed: () => controller.sendLike(),
        padding: EdgeInsets.zero,
        icon: icon ?? Image.asset(
          GiftImages.giftLikeSendIcon,
          package: Constants.pluginName,
          fit: BoxFit.fill,
        ));
  }
}
