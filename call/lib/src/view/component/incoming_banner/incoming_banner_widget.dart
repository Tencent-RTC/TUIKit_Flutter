import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:atomic_x_core/api/call/call_list_store.dart';
import 'package:atomic_x_core/api/call/call_participant_store.dart';
import 'package:rtc_room_engine/rtc_room_engine.dart';
import 'package:tencent_cloud_chat_sdk/tencent_im_sdk_plugin.dart';
import 'package:tencent_calls_uikit/src/common/constants.dart';
import 'package:tencent_calls_uikit/src/common/i18n/i18n_utils.dart';

class IncomingBannerWidget extends StatefulWidget {
  final VoidCallback? onShowCalling;
  final VoidCallback? onCloseAll;

  const IncomingBannerWidget({Key? key, this.onShowCalling, this.onCloseAll}) : super(key: key);

  @override
  State<IncomingBannerWidget> createState() => _IncomingBannerWidgetState();
}

class _IncomingBannerWidgetState extends State<IncomingBannerWidget> {
  late final CallListState _callListState;
  late final CallParticipantState _participantState;

  String _inviterAvatar = Constants.defaultAvatar;
  String _inviterName = '';
  TUICallMediaType _mediaType = TUICallMediaType.none;

  @override
  void initState() {
    super.initState();
    _callListState = CallListStore.shared.state;
    _participantState = CallParticipantStore.shared.state;
    _bind();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _bind() {
    final activeCall = _callListState.activeCall.value;
    _mediaType = activeCall.mediaType;

    final participants = _participantState.allParticipants.value;
    final inviter = participants.firstWhere(
        (p) => p.id == activeCall.inviterId,
        orElse: () => _participantState.selfInfo.value);

    String name = inviter.name.isNotEmpty ? inviter.name : inviter.remark;
    String avatar = inviter.avatarURL;

    if ((name.isEmpty || avatar.isEmpty) && activeCall.inviterId.isNotEmpty) {
      TencentImSDKPlugin.v2TIMManager
          .getUsersInfo(userIDList: [activeCall.inviterId]).then((res) {
        if (res.data != null && res.data!.isNotEmpty) {
          final info = res.data!.first;
          if (mounted) {
            setState(() {
              _inviterName = (name.isNotEmpty)
                  ? name
                  :  (info.nickName ?? activeCall.inviterId);
              _inviterAvatar = (avatar.isNotEmpty)
                  ? avatar
                  : (info.faceUrl?.isNotEmpty == true
                      ? info.faceUrl!
                      : Constants.defaultAvatar);
            });
          }
        }
      });
    }

    setState(() {
      _inviterName = name.isNotEmpty ? name : activeCall.inviterId;
      _inviterAvatar = avatar.isNotEmpty ? avatar : Constants.defaultAvatar;
    });
  }

  String _buildSubtitle() {
    switch (_mediaType) {
      case TUICallMediaType.audio:
        return getI18nString('k_0000002'); // Invited you to audio call
      case TUICallMediaType.video:
        return getI18nString('k_0000002_1'); // Invited you to video call
      default:
        return '';
    }
  }

  Future<void> _onAccept() async {
    await CallListStore.shared.accept();
    widget.onShowCalling?.call();
  }

  Future<void> _onReject() async {
    await CallListStore.shared.reject();
    widget.onCloseAll?.call();
  }

  @override
  Widget build(BuildContext context) {
    I18nUtils.setLanguage(Localizations.localeOf(context));
    final activeCall = _callListState.activeCall.value;
    if (activeCall.callId.isEmpty) {
      return const SizedBox.shrink();
    }

    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              clipBehavior: Clip.hardEdge,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                color: const Color(0xFFEFEFEF),
              ),
              child: Image(
                image: NetworkImage(_inviterAvatar),
                fit: BoxFit.cover,
                errorBuilder: (ctx, err, stack) => Image.asset(
                  'assets/images/user_icon.png',
                  package: 'tencent_calls_uikit',
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _inviterName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textScaleFactor: 1.0,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _buildSubtitle(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textScaleFactor: 1.0,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Row(
              children: [
                _ActionButton(
                  background: const Color(0xFFE74C3C),
                  iconAsset: 'assets/images/hangup.png',
                  onTap: _onReject,
                ),
                const SizedBox(width: 10),
                _ActionButton(
                  background: const Color(0xFF2ECC71),
                  iconAsset: _mediaType == TUICallMediaType.video
                      ? 'assets/images/camera_on.png'
                      : 'assets/images/handsfree.png',
                  onTap: _onAccept,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final Color background;
  final String iconAsset;
  final VoidCallback onTap;

  const _ActionButton({
    required this.background,
    required this.iconAsset,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(18),
        ),
        alignment: Alignment.center,
        child: Image.asset(
          iconAsset,
          package: 'tencent_calls_uikit',
          width: 18,
          height: 18,
        ),
      ),
    );
  }
}


