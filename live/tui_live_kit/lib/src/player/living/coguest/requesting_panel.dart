import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../../../common/live_avatar_image.dart';
import '../../../common/live_kit_resources.dart';
import '../../../common/theme/bottom_sheet_view.dart';
import 'co_guest_icon.dart';

class RequestingPanel extends StatefulWidget {
  const RequestingPanel({
    super.key,
    required this.liveInfo,
    required this.uiState,
    required this.openCameraAfterAccept,
    required this.onDismiss,
    required this.onRequestSettings,
    required this.onApply,
    required this.onCancel,
  });

  final LiveInfo liveInfo;
  final ValueListenable<CoGuestStatus> uiState;
  final ValueListenable<bool> openCameraAfterAccept;
  final VoidCallback onDismiss;
  final VoidCallback onRequestSettings;
  final ValueChanged<bool> onApply;
  final VoidCallback onCancel;

  @override
  State<RequestingPanel> createState() => _RequestingPanelState();
}

class _RequestingPanelState extends State<RequestingPanel> {
  @override
  void initState() {
    super.initState();
    widget.uiState.addListener(_refresh);
    widget.openCameraAfterAccept.addListener(_refresh);
  }

  @override
  void dispose() {
    widget.uiState.removeListener(_refresh);
    widget.openCameraAfterAccept.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final double bottomInset = MediaQuery.paddingOf(context).bottom;
    final bool applying = widget.uiState.value == CoGuestStatus.requesting;
    final LiveUserInfo owner = widget.liveInfo.liveOwner;
    final String rawName =
        owner.userName.isEmpty ? owner.userID : owner.userName;
    final String displayName = rawName.characters.length > 15
        ? '${rawName.characters.take(15).string}…'
        : rawName;
    return BottomSheetView(
      sheetHeight: 221 + bottomInset,
      onDismiss: widget.onDismiss,
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: Stack(
          children: <Widget>[
            Positioned(
              top: 32,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: 58,
                  height: 58,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: _CoGuestRequestStyle.avatarBorder),
                  ),
                  child: LiveAvatarImage(avatarURL: owner.avatarURL),
                ),
              ),
            ),
            Positioned(
              top: 100,
              left: 20,
              right: 20,
              height: 22,
              child: Text(
                displayName,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFFFFFFFF),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
            Positioned(
              left: 20,
              right: 20,
              top: 141,
              height: 40,
              child: applying
                  ? _CancelButton(onTap: widget.onCancel)
                  : _SplitActions(
                      onApply: widget.onApply,
                      onRequestSettings: widget.onRequestSettings,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SplitActions extends StatelessWidget {
  const _SplitActions({required this.onApply, required this.onRequestSettings});

  final ValueChanged<bool> onApply;
  final VoidCallback onRequestSettings;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: LiveKitResources.image('livekit_player_coguest_requesting_button_bg'),
          fit: BoxFit.fill,
        ),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onApply(false),
              child: Center(
                child: Text(
                  _text('语音连麦', 'Voice'),
                  style: const TextStyle(
                    color: Color(0xFFFFFFFF),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onRequestSettings,
              child: Center(
                child: Text(
                  _text('视频连麦', 'Video'),
                  style: const TextStyle(
                    color: Color(0xFFFFFFFF),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CancelButton extends StatelessWidget {
  const _CancelButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: _CoGuestRequestStyle.cancelBackground,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: _CoGuestRequestStyle.cancelBorder),
        ),
        child: Text(
          _text('取消申请', 'Cancel request'),
          style: const TextStyle(
            color: _CoGuestRequestStyle.cancelForeground,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            decoration: TextDecoration.none,
          ),
        ),
      ),
    );
  }
}

String _text(String zh, String en) {
  return WidgetsBinding.instance.platformDispatcher.locale.languageCode
              .toLowerCase() ==
          'zh'
      ? zh
      : en;
}

abstract final class _CoGuestRequestStyle {
  static const avatarBorder = Color(0xD14A9EFF);
  static const cancelBackground = Color(0x12FFFFFF);
  static const cancelBorder = Color(0x1AFFFFFF);
  static const cancelForeground = Color(0xB8FFFFFF);
}
