import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/widgets.dart';
import '../../../common/live_avatar_image.dart';
import '../../../common/live_kit_resources.dart';
import '../../../common/theme/bottom_sheet_view.dart';
import 'pusher_cohost_store.dart';

class PusherCoHostIncomingInviteView extends StatefulWidget {
  const PusherCoHostIncomingInviteView(
      {super.key,
      required this.state,
      required this.onAccept,
      required this.onReject,
      required this.onDismiss,
      this.controller});
  final PusherCoHostState state;
  final VoidCallback onAccept, onReject, onDismiss;
  final BottomSheetController? controller;
  @override
  State<PusherCoHostIncomingInviteView> createState() => _IncomingInviteState();
}

class _IncomingInviteState extends State<PusherCoHostIncomingInviteView> {
  Timer? _timer;
  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.state.applicant;
    final remaining =
        math.max(0, ((widget.state.applicantDeadline?.difference(DateTime.now()).inMilliseconds ?? 0) / 1000).ceil());
    final busy = user == null || widget.state.isBusy(user.liveID);
    final enabled = !busy && remaining > 0;
    final bottom = MediaQuery.viewPaddingOf(context).bottom;
    return BottomSheetView(
        controller: widget.controller,
        isDismissibleByTappingOutside: false,
        sheetHeight: math.min(286 + bottom, math.max(0, MediaQuery.sizeOf(context).height - 40)),
        onWillDismiss: () {
          _timer?.cancel();
        },
        onDismiss: widget.onDismiss,
        child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(20, 35, 20, bottom),
            child: Column(children: [
              SizedBox(
                  height: 22,
                  child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                          LiveKitResources.localizedString(user?.isMutual == true
                              ? 'tuilivekit.pusher.cohost.incoming_mutual'
                              : 'tuilivekit.pusher.cohost.incoming'),
                          maxLines: 1,
                          style:
                              const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xD6FFFFFF))))),
              const SizedBox(height: 31),
              SizedBox(
                  width: 76,
                  height: 76,
                  child: Stack(clipBehavior: Clip.none, children: [
                    Container(
                        decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF72B3FF),
                            boxShadow: [BoxShadow(color: Color(0x3D000000), offset: Offset(0, 10), blurRadius: 25)]),
                        padding: const EdgeInsets.all(3),
                        child: ClipOval(child: LiveAvatarImage(avatarURL: user?.avatarURL ?? ''))),
                    Positioned(
                        left: 39,
                        top: 38,
                        width: 52,
                        height: 57,
                        child: Image(image: LiveKitResources.image('livekit_cohost_invitation_badge'))),
                  ])),
              const SizedBox(height: 12),
              SizedBox(
                  height: 24,
                  child: Text(user?.userName ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFFFFFFFF)))),
              const SizedBox(height: 42),
              Row(children: [
                Expanded(
                    child: _button(
                        busy
                            ? LiveKitResources.localizedString('tuilivekit.common.processing')
                            : LiveKitResources.localizedFormat('tuilivekit.pusher.cohost.reject_countdown', remaining),
                        enabled ? widget.onReject : null,
                        false)),
                const SizedBox(width: 10),
                Expanded(
                    child: _button(LiveKitResources.localizedString('tuilivekit.pusher.cohost.accept'),
                        enabled ? widget.onAccept : null, true)),
              ]),
            ])));
  }

  Widget _button(String text, VoidCallback? action, bool accept) => GestureDetector(
      onTap: action,
      child: Opacity(
          opacity: action == null ? .46 : 1,
          child: Container(
              height: 44,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(13),
                  color: accept ? null : const Color(0x17FFFFFF),
                  gradient: accept
                      ? const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF43D5FF), Color(0xFF5379FF)])
                      : null,
                  boxShadow: accept
                      ? const [BoxShadow(color: Color(0x474598FF), offset: Offset(0, 8), blurRadius: 11)]
                      : null),
              alignment: Alignment.center,
              child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(text,
                          maxLines: 1,
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: accept ? const Color(0xFFFFFFFF) : const Color(0xBDFFFFFF))))))));
}
