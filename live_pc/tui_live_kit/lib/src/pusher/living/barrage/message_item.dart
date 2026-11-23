import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/material.dart';

import '../../../common/style/live_kit_style.dart';
import '../audience/level_badge.dart';
import 'host_badge.dart';

class MessageItem extends StatelessWidget {
  final Barrage barrage;
  final bool isHost;

  const MessageItem({super.key, required this.barrage, required this.isHost});

  @override
  Widget build(BuildContext context) {
    final displayName = barrage.sender.userName.isNotEmpty
        ? barrage.sender.userName
        : barrage.sender.userID;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text.rich(
        TextSpan(
          style: const TextStyle(fontSize: 12, height: 1.4),
          children: [
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Padding(
                padding: const EdgeInsets.only(right: 4),
                child: LevelBadge(level: barrage.sender.level),
              ),
            ),
            if (isHost)
              const WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: Padding(
                  padding: EdgeInsets.only(right: 4),
                  child: HostBadgeView(),
                ),
              ),
            TextSpan(
              text: '$displayName: ',
              style: TextStyle(
                color: LiveKitStyle.barrageSenderColors(barrage.sender.userID),
              ),
            ),
            TextSpan(
              text: barrage.textContent,
              style: const TextStyle(color: LiveKitStyle.textSecondary),
            ),
          ],
        ),
        semanticsLabel: '$displayName: ${barrage.textContent}',
      ),
    );
  }
}
