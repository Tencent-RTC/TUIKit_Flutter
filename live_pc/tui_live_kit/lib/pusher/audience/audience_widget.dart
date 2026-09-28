import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:remixicon/remixicon.dart';

import '../../l10n/live_kit_localizations.dart';
import '../pusher_style.dart';
import 'audience_item.dart';

class AudienceView extends StatefulWidget {
  final String liveID;

  const AudienceView({super.key, this.liveID = ''});

  @override
  State<AudienceView> createState() => _AudienceViewState();
}

class _AudienceViewState extends State<AudienceView> {
  static const double _listMaxHeight = 218;

  LiveAudienceStore? _store;
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _store = LiveAudienceStore.create(widget.liveID);
    _store!.fetchAudienceList();
  }

  void _toggleExpanded() {
    setState(() => _expanded = !_expanded);
    if (_expanded) {
      _store!.fetchAudienceList();
    }
  }

  void _disableSendMessage(LiveUserInfo user, bool isMuted) {
    _store!.disableSendMessage(userID: user.userID, isDisable: !isMuted);
  }

  Future<void> _kickUserOutOfRoom(LiveUserInfo user) async {
    final result = await _store!.kickUserOutOfRoom(user.userID);
    if (!result.isSuccess) {
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final audienceState = _store!.liveAudienceState;
    return Container(
      decoration: PusherStyle.glassPanel(),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(audienceState.audienceList),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: _expanded
                ? _buildExpandedList(audienceState)
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ValueListenable<List<LiveUserInfo>> audienceList) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: _toggleExpanded,
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(RemixIcons.group_line,
                      size: 14, color: PusherStyle.textTertiary),
                  const SizedBox(width: 6),
                  Text(
                    LiveKitLocalizations.of(context).audienceTitle,
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                      color: PusherStyle.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  ValueListenableBuilder<List<LiveUserInfo>>(
                    valueListenable: audienceList,
                    builder: (context, audiences, _) => Text(
                      _formatCount(audiences.length),
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.4,
                        fontWeight: FontWeight.w600,
                        color: PusherStyle.brand2,
                      ),
                    ),
                  ),
                ],
              ),
              AnimatedRotation(
                turns: _expanded ? 0.5 : 0,
                duration: const Duration(milliseconds: 220),
                child: const Icon(
                  RemixIcons.arrow_down_s_line,
                  size: 14,
                  color: PusherStyle.textHint,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedList(LiveAudienceState audienceState) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(height: 1, color: PusherStyle.white4),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: _listMaxHeight),
          child: ValueListenableBuilder<List<LiveUserInfo>>(
            valueListenable: audienceState.audienceList,
            builder: (context, audiences, _) {
              if (audiences.isEmpty) {
                return _buildEmpty();
              }
              return ValueListenableBuilder<List<LiveUserInfo>>(
                valueListenable: audienceState.messageBannedUserList,
                builder: (context, bannedUsers, _) {
                  final bannedIDs =
                      bannedUsers.map((u) => u.userID).toSet();
                  return ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                    itemCount: audiences.length,
                    separatorBuilder: (_, i) => const SizedBox(height: 6),
                    itemBuilder: (context, index) {
                      final user = audiences[index];
                      final isMuted = bannedIDs.contains(user.userID);
                      return AudienceItem(
                        userInfo: user,
                        isAudienceMuted: isMuted,
                        onDisableSendMessage: () =>
                            _disableSendMessage(user, isMuted),
                        onKickUserOutOfRoom: () => _kickUserOutOfRoom(user),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmpty() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Text(
        LiveKitLocalizations.of(context).audienceEmpty,
        style: const TextStyle(fontSize: 12, color: PusherStyle.textHint),
      ),
    );
  }

  String _formatCount(int count) {
    if (count < 1000) return '$count';
    final k = count / 1000;
    return '${k.toStringAsFixed(k >= 10 ? 0 : 1)}k';
  }
}
