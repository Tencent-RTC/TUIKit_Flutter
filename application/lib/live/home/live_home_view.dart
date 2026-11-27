import 'dart:async';
import 'dart:math' as math;
import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/material.dart';
import '../../common/app_strings.dart';
import '../../login/login_store.dart';
import '../pusher_view.dart';
import 'live_home_header_view.dart';
import 'live_home_list_store.dart';
import 'live_home_list_view.dart';
import 'live_home_player_view.dart';
import 'live_home_preview_view.dart';
import 'live_home_room_transition.dart';

class LiveHomeView extends StatefulWidget {
  const LiveHomeView({
    super.key,
    required this.active,
    required this.auth,
    required this.onRoomChanged,
    required this.onInteractionChanged,
  });
  final bool active;
  final AppLoginStore auth;
  final ValueChanged<bool> onRoomChanged;
  final ValueChanged<bool> onInteractionChanged;
  @override
  State<LiveHomeView> createState() => _LiveHomeViewState();
}

class _LiveHomeViewState extends State<LiveHomeView> with WidgetsBindingObserver {
  final _store = LiveHomeListStore();
  final _scroll = ScrollController();
  final _gridKey = GlobalKey();
  final _previewKey = GlobalKey<LiveHomePreviewViewState>();
  final _cardKeys = <String, GlobalKey>{};
  LiveHomeMode _mode = LiveHomeMode.grid;
  bool _foreground = true;
  bool _covered = false;
  bool _room = false;
  bool _joining = false;
  bool _directPending = false;
  bool _previewCreated = false;
  String? _initialPreviewID;
  bool get _visible => widget.active && !_covered;
  bool get _active => _visible && _foreground;
  bool get _enabled => !_joining && !_directPending;
  bool get _canNavigate => _active && _enabled && !_room;
  @override
  void initState() {
    super.initState();
    _foreground =
        WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _activity();
    });
  }

  @override
  void didUpdateWidget(covariant LiveHomeView oldWidget) {
    super.didUpdateWidget(oldWidget);
    _activity();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _activity();
    if (mounted) setState(() {});
  }

  void _activity() {
    _store.setActive(_active);
    if (_active && !_store.state.loaded && !_store.state.loading) unawaited(_store.refresh());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scroll.dispose();
    _store.dispose();
    super.dispose();
  }

  void _joiningChanged(bool value, {bool direct = false}) {
    if (!mounted) return;
    if (direct) {
      _directPending = value;
    } else {
      _joining = value;
    }
    widget.onInteractionChanged(_enabled);
    setState(() {});
  }

  void _modeChanged(LiveHomeMode mode) {
    if (!_canNavigate || _mode == mode) return;
    if (mode == LiveHomeMode.preview && !_previewCreated) {
      final width = MediaQuery.sizeOf(context).width;
      final cardHeight = (width - 34) / 2 * 1.35;
      final row = (_scroll.hasClients ? _scroll.offset / (cardHeight + 12) : 0).floor();
      final index = math.min(math.max(0, row * 2), math.max(0, _store.state.items.length - 1));
      _initialPreviewID = _store.state.items.isEmpty ? null : _store.state.items[index].liveID;
      _previewCreated = true;
    }
    setState(() => _mode = mode);
  }

  Future<void> _open(LiveInfo info) async {
    if (!_canNavigate || info.liveID.isEmpty) return;
    if (info.liveOwner.userID == LoginStore.shared.loginState.loginUserInfo?.userID) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppStrings.of(context, 'ownLive'))));
      return;
    }
    final box = _cardKeys[info.liveID]?.currentContext?.findRenderObject() as RenderBox?;
    final gridBox = _gridKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || gridBox == null) return;
    final source = box.localToGlobal(Offset.zero) & box.size;
    final visible = source.intersect(gridBox.localToGlobal(Offset.zero) & gridBox.size);
    if (visible.isEmpty) return;
    final copy = _store.independentCopy();
    setState(() => _covered = true);
    _activity();
    try {
      await Navigator.of(context, rootNavigator: true).push(
        LiveHomeRoomTransition(
          info: info,
          source: source,
          visibleSource: visible,
          reduceMotion: MediaQuery.disableAnimationsOf(context),
          page: LiveHomePlayerView(
            store: copy,
            liveID: info.liveID,
            onJoiningChanged: (value) => _joiningChanged(value, direct: true),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _covered = false);
        _activity();
      }
    }
  }

  Future<void> _start() async {
    if (!_canNavigate) return;
    final user = LoginStore.shared.loginState.loginUserInfo?.userID;
    if (user == null || user.isEmpty) return;
    widget.auth.setPusherVisible(true);
    setState(() => _covered = true);
    _activity();
    try {
      await Navigator.of(
        context,
        rootNavigator: true,
      ).push(MaterialPageRoute<void>(builder: (_) => AppPusherView(liveID: 'live_$user')));
    } finally {
      widget.auth.setPusherVisible(false);
      if (mounted) {
        setState(() => _covered = false);
        _activity();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.viewPaddingOf(context).top;
    final bottom = 56 + MediaQuery.viewPaddingOf(context).bottom;
    return ColoredBox(
      color: const Color(0xff101116),
      child: Stack(
        children: [
          Positioned(
            top: top + 57,
            left: 0,
            right: 0,
            bottom: bottom,
            child: Offstage(
              offstage: _mode != LiveHomeMode.grid,
              child: LiveHomeListView(
                key: _gridKey,
                store: _store,
                controller: _scroll,
                active: _active && _mode == LiveHomeMode.grid,
                onSelect: _open,
                itemKey: (id) => _cardKeys.putIfAbsent(id, GlobalKey.new),
              ),
            ),
          ),
          if (_previewCreated)
            Positioned.fill(
              child: Offstage(
                offstage: _mode != LiveHomeMode.preview,
                child: LiveHomePreviewView(
                  key: _previewKey,
                  store: _store,
                  active: _visible && _mode == LiveHomeMode.preview,
                  initialLiveID: _initialPreviewID,
                  bottomInset: bottom,
                  onJoiningChanged: _joiningChanged,
                  onRoomChanged: (value) {
                    if (!mounted || _room == value) return;
                    setState(() => _room = value);
                    widget.onRoomChanged(value);
                  },
                ),
              ),
            ),
          if (!_room)
            Positioned(
              top: top,
              left: 0,
              right: 0,
              child: LiveHomeHeaderView(
                mode: _mode,
                enabled: _enabled && !_covered,
                onModeChanged: _modeChanged,
                onStartLive: _start,
              ),
            ),
        ],
      ),
    );
  }
}
