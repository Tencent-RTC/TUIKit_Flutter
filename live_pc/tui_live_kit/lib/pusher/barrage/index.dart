import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:remixicon/remixicon.dart';

import '../../l10n/live_kit_localizations.dart';
import 'gift/gift_widget.dart';
import 'message/message_widget.dart';
import '../pusher_style.dart';

class Index extends StatelessWidget {
  final String liveID;
  final ValueListenable<bool>? isLiveStarted;

  const Index({
    super.key,
    this.liveID = '',
    this.isLiveStarted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: PusherStyle.glassPanel(),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _buildHeader(context),
          Expanded(
            flex: 1,
            child: GiftWidget(
              liveID: liveID,
              isLiveStarted: isLiveStarted,
            ),
          ),
          const _Divider(),
          Expanded(
            flex: 1,
            child: MessageWidget(
              liveID: liveID,
              isLiveStarted: isLiveStarted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Row(
        children: [
          const Icon(
            RemixIcons.message_3_line,
            size: 14,
            color: PusherStyle.textTertiary,
          ),
          const SizedBox(width: 6),
          Text(
            LiveKitLocalizations.of(context).interactionTitle,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: PusherStyle.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Container(height: 1, color: PusherStyle.white10),
    );
  }
}
