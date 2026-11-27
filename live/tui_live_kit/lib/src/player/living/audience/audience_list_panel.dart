import '../../../common/theme/live_theme.dart';
import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/material.dart';

import '../../../common/live_avatar_image.dart';
import '../../../common/live_kit_resources.dart';
import '../../../common/theme/bottom_sheet_view.dart';
import '../../../common/theme/level_badge_view.dart';
import 'audience_profile_panel.dart';

class AudienceListPanel extends StatefulWidget {
  const AudienceListPanel({
    super.key,
    this.onError,
  });

  final ValueChanged<String>? onError;

  @override
  State<AudienceListPanel> createState() => AudienceListPanelState();
}

class AudienceListPanelState extends State<AudienceListPanel> {
  final BottomSheetController _panelController = BottomSheetController();
  LiveAudienceStore? _store;
  VoidCallback? _audienceListener;
  List<LiveUserInfo> _items = <LiveUserInfo>[];
  String _liveID = '';
  bool _visible = false;
  LiveUserInfo? _profileUser;

  void attachStore(String liveID) {
    if (liveID.isEmpty) {
      detachStore();
      return;
    }
    if (_liveID == liveID && _store != null) return;
    detachStore();
    _liveID = liveID;
    final LiveAudienceStore store = LiveAudienceStore.create(liveID);
    _store = store;
    _audienceListener = () {
      if (!mounted || _store != store) return;
      setState(() {
        _items = List<LiveUserInfo>.from(
          store.liveAudienceState.audienceList.value,
        );
      });
    };
    store.liveAudienceState.audienceList.addListener(_audienceListener!);
    _items = List<LiveUserInfo>.from(
      store.liveAudienceState.audienceList.value,
    );
    if (mounted) setState(() {});
  }

  void detachStore() {
    final LiveAudienceStore? store = _store;
    if (store != null && _audienceListener != null) {
      store.liveAudienceState.audienceList.removeListener(_audienceListener!);
    }
    _store = null;
    _audienceListener = null;
    _items = <LiveUserInfo>[];
    _liveID = '';
    _visible = false;
    _profileUser = null;
    if (mounted) setState(() {});
  }

  void show() {
    if (_visible) return;
    setState(() {
      _profileUser = null;
      _visible = true;
    });
    _store?.fetchAudienceList();
  }

  Future<void> dismiss() async {
    if (_profileUser != null) {
      setState(() => _profileUser = null);
      return;
    }
    await _panelController.dismiss();
  }

  void _dismissList() {
    if (!_visible) return;
    setState(() => _visible = false);
  }

  void _showProfile(LiveUserInfo user) {
    final String selfUserID = LoginStore.shared.loginState.loginUserInfo?.userID ?? '';
    if (user.userID.isEmpty || user.userID == selfUserID) return;
    setState(() {
      _visible = false;
      _profileUser = user;
    });
  }

  @override
  void dispose() {
    final LiveAudienceStore? store = _store;
    if (store != null && _audienceListener != null) {
      store.liveAudienceState.audienceList.removeListener(_audienceListener!);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final LiveUserInfo? profileUser = _profileUser;
    return Stack(
      children: <Widget>[
        if (_visible)
          BottomSheetView(
            controller: _panelController,
            sheetHeight: 422,
            onDismiss: _dismissList,
            child: Column(
              children: <Widget>[
                const SizedBox(height: 30),
                SizedBox(
                  height: 18,
                  child: Text(
                    LiveKitResources.localizedString(
                      'tuilivekit.player.online_audience',
                    ),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    physics: const BouncingScrollPhysics(),
                    itemCount: _items.length,
                    itemExtent: 64,
                    itemBuilder: (BuildContext context, int index) {
                      final LiveUserInfo user = _items[index];
                      return _AudienceRow(
                        rank: index + 1,
                        user: user,
                        onTap: () => _showProfile(user),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        if (profileUser != null)
          AudienceProfilePanel(
            key: ValueKey<String>(profileUser.userID),
            userID: profileUser.userID,
            userName: profileUser.userName,
            avatarURL: profileUser.avatarURL,
            onError: widget.onError,
            onDismiss: () {
              if (mounted) setState(() => _profileUser = null);
            },
          ),
      ],
    );
  }
}

class _AudienceRow extends StatelessWidget {
  const _AudienceRow({
    required this.rank,
    required this.user,
    required this.onTap,
  });

  final int rank;
  final LiveUserInfo user;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final String rawName = user.userName.isEmpty ? user.userID : user.userName;
    final String displayName = rawName.characters.length > 10 ? '${rawName.characters.take(10).string}…' : rawName;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Stack(
        children: <Widget>[
          Row(
            children: <Widget>[
              SizedBox(
                width: 32,
                child: Text(
                  '$rank',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.38),
                    fontSize: 15,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              SizedBox(
                width: LiveAudienceRowStyle.avatarSize,
                height: LiveAudienceRowStyle.avatarSize,
                child: ClipOval(
                  child: LiveAvatarImage(avatarURL: user.avatarURL),
                ),
              ),
              const SizedBox(width: 14),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 100),
                child: Text(
                  displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.88),
                    fontSize: 15,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              LevelBadgeView(level: user.level),
              const Spacer(),
              const SizedBox(
                width: LiveAudienceRowStyle.giftValueWidth,
                child: Text(
                  '0',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: LiveTheme.audienceGiftValue,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
            ],
          ),
          Positioned(
            left: 10,
            right: 10,
            bottom: 0,
            child: Container(
              height: 0.5,
              color: Colors.white.withOpacity(0.08),
            ),
          ),
        ],
      ),
    );
  }
}
