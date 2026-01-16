import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:atomic_x_core/atomicxcore.dart';
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

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _onAccept() async {
    await CallStore.shared.accept();
    widget.onShowCalling?.call();
  }

  Future<void> _onReject() async {
    await CallStore.shared.reject();
    widget.onCloseAll?.call();
  }
  
  void _onTapBanner() {
    widget.onShowCalling?.call();
  }

  @override
  Widget build(BuildContext context) {
    I18nUtils.setLanguage(Localizations.localeOf(context));
    final activeCall = CallStore.shared.state.activeCall.value;
    if (activeCall.callId.isEmpty) {
      return const SizedBox.shrink();
    }

    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        onTap: _onTapBanner,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
          decoration: BoxDecoration(
            color: const Color.fromRGBO(35, 38, 45, 1),
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
              _getInviterAvatarWidget(),
              const SizedBox(width: 12),
              _getInviterInfoWidget(),
              const SizedBox(width: 12),
              _getActionButtonWidget()
            ],
          ),
        ),
      ),
    );
  }

  _getInviterAvatarWidget() {
    return ValueListenableBuilder(valueListenable: CallStore.shared.state.allParticipants,
        builder: (context, allParticipants, child) {
          final inviterId = CallStore.shared.state.activeCall.value.inviterId;
          final inviter = allParticipants.firstWhere(
                (participant) => participant.id == inviterId,
            orElse: () => CallStore.shared.state.selfInfo.value,
          );

          return Container(
            width: 50,
            height: 50,
            clipBehavior: Clip.hardEdge,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: const Color(0xFFEFEFEF),
            ),
            child: Image(
              image: NetworkImage(inviter.avatarURL),
              fit: BoxFit.cover,
              errorBuilder: (ctx, err, stack) => Image.asset(
                'assets/images/user_icon.png',
                package: 'tencent_calls_uikit',
              ),
            ),
          );
        });
  }

  _getInviterInfoWidget() {
    return ValueListenableBuilder(valueListenable: CallStore.shared.state.allParticipants,
        builder: (context, allParticipants, child) {
          final inviterId = CallStore.shared.state.activeCall.value.inviterId;
          final inviter = allParticipants.firstWhere(
                (participant) => participant.id == inviterId,
            orElse: () => CallStore.shared.state.selfInfo.value,
          );

          var inviterName = inviter.remark.isNotEmpty ?  inviter.remark : inviter.name;
          if (inviterName.isEmpty) {
            inviterName = inviter.id;
          }

          var invitationInfo = '';
          if (CallStore.shared.state.activeCall.value.inviteeIds.length >= 2) {
            invitationInfo = getI18nString('invitedToGroupCall');
          } else if (CallStore.shared.state.activeCall.value.mediaType == TUICallMediaType.audio) {
            invitationInfo = getI18nString('invitedToAudioCall');
          } else if (CallStore.shared.state.activeCall.value.mediaType == TUICallMediaType.video) {
            invitationInfo = getI18nString('invitedToVideoCall');
          }

          return Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  inviterName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  invitationInfo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          );
    });

  }

  _getActionButtonWidget() {
    return Row(
      children: [
        GestureDetector(
          onTap: _onReject,
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
            ),
            alignment: Alignment.center,
            child: Image.asset(
              'assets/images/hangup.png',
              package: 'tencent_calls_uikit',
              width: 36,
              height: 36,
            ),
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: _onAccept,
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
            ),
            alignment: Alignment.center,
            child: Image.asset(
              'assets/images/dialing.png',
              package: 'tencent_calls_uikit',
              width: 36,
              height: 36,
            ),
          ),
        ),
      ],
    );
  }
}


