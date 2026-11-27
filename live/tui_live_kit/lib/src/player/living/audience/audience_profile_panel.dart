import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/material.dart';

import '../../../common/live_avatar_image.dart';
import '../../../common/live_kit_resources.dart';
import '../../../common/theme/bottom_sheet_view.dart';
import '../follow_service.dart';

class AudienceProfilePanel extends StatefulWidget {
  const AudienceProfilePanel({
    super.key,
    required this.userID,
    required this.userName,
    required this.avatarURL,
    this.onDismiss,
    this.onError,
  });

  final String userID;
  final String userName;
  final String avatarURL;
  final VoidCallback? onDismiss;
  final ValueChanged<String>? onError;

  @override
  State<AudienceProfilePanel> createState() => AudienceProfilePanelState();
}

class AudienceProfilePanelState extends State<AudienceProfilePanel> {
  final PlayerFollowService _followService = PlayerFollowService.shared;
  final BottomSheetController _panelController = BottomSheetController();
  bool _visible = true;

  @override
  void initState() {
    super.initState();
    _followService.addListener(_refresh);
    _followService.refresh(widget.userID);
  }

  @override
  void dispose() {
    _followService.removeListener(_refresh);
    super.dispose();
  }

  void present() {
    if (_visible) return;
    setState(() => _visible = true);
    _followService.refresh(widget.userID);
  }

  Future<void> dismiss() async {
    await _panelController.dismiss();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  void _onDismiss() {
    if (!_visible) return;
    setState(() => _visible = false);
    widget.onDismiss?.call();
  }

  Future<void> _toggleFollow() async {
    if (_followService.isLoading(widget.userID)) return;
    final String? error = await _followService.toggle(widget.userID);
    if (!mounted || error == null || error.isEmpty) return;
    widget.onError?.call(error);
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.shrink();
    final bool following = _followService.isFollowing(widget.userID);
    final bool loading = _followService.isLoading(widget.userID);
    final String selfUserID = LoginStore.shared.loginState.loginUserInfo?.userID ?? '';
    final bool showFollow = widget.userID.isNotEmpty && widget.userID != selfUserID;
    final String rawName = widget.userName.isEmpty ? widget.userID : widget.userName;
    final String displayName = rawName.characters.length > 15 ? '${rawName.characters.take(15).string}…' : rawName;
    final double bottomInset = MediaQuery.paddingOf(context).bottom;

    return BottomSheetView(
      controller: _panelController,
      sheetHeight: 212 + bottomInset,
      onDismiss: _onDismiss,
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: Column(
          children: <Widget>[
            const SizedBox(height: 32),
            Container(
              width: 58,
              height: 58,
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[
                    _AudienceProfileStyle.avatarGradientStart,
                    _AudienceProfileStyle.avatarGradientMiddle,
                    _AudienceProfileStyle.avatarGradientEnd,
                  ],
                ),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Color(0x4D000000),
                    offset: Offset(0, 8),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: ClipOval(
                child: LiveAvatarImage(avatarURL: widget.avatarURL),
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (showFollow) ...<Widget>[
              const SizedBox(height: 22),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: loading ? null : _toggleFollow,
                child: Container(
                  height: 40,
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: following ? Colors.white.withOpacity(0.07) : null,
                    gradient: following
                        ? null
                        : const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: <Color>[
                              _AudienceProfileStyle.followGradientStart,
                              _AudienceProfileStyle.followGradientEnd,
                            ],
                          ),
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(
                      color: following ? Colors.white.withOpacity(0.1) : _AudienceProfileStyle.followBorder,
                    ),
                    boxShadow: following
                        ? null
                        : const <BoxShadow>[
                            BoxShadow(
                              color: _AudienceProfileStyle.actionShadow,
                              offset: Offset(0, 7),
                              blurRadius: 9,
                            ),
                          ],
                  ),
                  child: Text(
                    LiveKitResources.localizedString(
                      following ? 'tuilivekit.player.unfollow' : 'tuilivekit.player.follow',
                    ),
                    style: TextStyle(
                      color: following ? Colors.white.withOpacity(0.72) : Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

abstract final class _AudienceProfileStyle {
  static const avatarGradientStart = Color(0xFF0052D9);
  static const avatarGradientMiddle = Color(0xFF4A9EFF);
  static const avatarGradientEnd = Color(0xFF7EE8FF);
  static const followGradientStart = Color(0xFF0E48B9);
  static const followGradientEnd = Color(0xFF3976BD);
  static const actionShadow = Color(0x330052D9);
  static const followBorder = Color(0x594A9EFF);
}
