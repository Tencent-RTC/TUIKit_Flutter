import 'package:flutter/widgets.dart';
import '../../../common/live_kit_resources.dart';
import '../../../common/theme/bottom_sheet_view.dart';
import 'pusher_cohost_store.dart';

class PusherCoHostActionsView extends StatelessWidget {
  const PusherCoHostActionsView(
      {super.key,
      required this.state,
      required this.onInviteMore,
      required this.onEnd,
      required this.onDismiss,
      this.controller});
  final PusherCoHostState state;
  final VoidCallback onInviteMore, onEnd, onDismiss;
  final BottomSheetController? controller;
  @override
  Widget build(BuildContext context) {
    final title = state.connected.length == 1
        ? LiveKitResources.localizedFormat('tuilivekit.pusher.cohost.connected_with', state.connected.first.userName)
        : LiveKitResources.localizedFormat('tuilivekit.pusher.cohost.connected_count', state.connected.length + 1);
    final enabled = state.isConnected && !state.isExiting;
    return BottomSheetView(
        controller: controller,
        sheetHeight: 148 + MediaQuery.viewPaddingOf(context).bottom,
        onDismiss: onDismiss,
        child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(children: [
              const SizedBox(height: 28),
              SizedBox(
                  height: 44,
                  child: Row(children: [
                    Expanded(
                        child: Text(title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style:
                                const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFFFFFFFF)))),
                    const SizedBox(width: 12),
                    GestureDetector(
                        onTap: enabled && state.pendingLiveIDs.isEmpty ? onEnd : null,
                        behavior: HitTestBehavior.opaque,
                        child: Opacity(
                            opacity: enabled && state.pendingLiveIDs.isEmpty ? 1 : .46,
                            child: ConstrainedBox(
                                constraints: const BoxConstraints(minWidth: 64, minHeight: 44),
                                child: Center(
                                    child: Text(
                                        LiveKitResources.localizedString(state.isExiting
                                            ? 'tuilivekit.common.processing'
                                            : 'tuilivekit.pusher.cohost.end'),
                                        style: const TextStyle(
                                            fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF9ECFFF))))))),
                  ])),
              const SizedBox(height: 11),
              GestureDetector(
                  onTap: enabled ? onInviteMore : null,
                  child: Opacity(
                      opacity: enabled ? 1 : .46,
                      child: Container(
                          height: 41,
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0x6462ABFF)),
                              gradient: const LinearGradient(
                                  begin: Alignment.bottomLeft,
                                  end: Alignment.topRight,
                                  colors: [Color(0xFF1F7AFF), Color(0xFF0052D9)]),
                              boxShadow: const [
                                BoxShadow(color: Color(0x2E0052D9), offset: Offset(0, 8), blurRadius: 10)
                              ]),
                          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Image(image: LiveKitResources.image('livekit_cohost_add'), width: 14, height: 17),
                            const SizedBox(width: 4),
                            Flexible(
                                child: Text(LiveKitResources.localizedString('tuilivekit.pusher.cohost.invite_more'),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFFFFFFFF)))),
                          ])))),
            ])));
  }
}
