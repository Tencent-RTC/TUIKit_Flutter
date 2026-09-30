import 'package:flutter/material.dart';
import 'package:remixicon/remixicon.dart';

import '../../l10n/live_kit_localizations.dart';
import '../pusher_style.dart';

/// 右侧上部观众组件（占位）：观众小条，可下拉展开观众列表。
///
/// 展开 / 收起、观众数据、操作菜单（禁言 / 踢出）在组件正式实现时接入，
/// 当前为收起态静态展示。
class PusherAudienceView extends StatelessWidget {
  const PusherAudienceView({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: PusherStyle.glassPanel(),
      clipBehavior: Clip.antiAlias,
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(RemixIcons.group_line,
                    size: 12, color: PusherStyle.textTertiary),
                const SizedBox(width: 6),
                Text(
                  LiveKitLocalizations.of(context).audienceTitle,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: PusherStyle.textPrimary,
                  ),
                ),
                const SizedBox(width: 4),
                const Text(
                  '3,842',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: PusherStyle.brand2,
                  ),
                ),
              ],
            ),
            const Icon(
              RemixIcons.arrow_down_s_line,
              size: 14,
              color: PusherStyle.textHint,
            ),
          ],
        ),
      ),
    );
  }
}
