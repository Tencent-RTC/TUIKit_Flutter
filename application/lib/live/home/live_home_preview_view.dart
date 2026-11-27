import 'dart:async';
import 'dart:math' as math;
import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/material.dart';
import 'package:tencent_live_uikit/tencent_live_uikit.dart';
import '../../common/app_strings.dart';
import 'live_home_list_store.dart';
import 'live_home_preview_item_view.dart';

class LiveHomePreviewView extends StatefulWidget {
  const LiveHomePreviewView({
    super.key,
    required this.store,
    required this.active,
    required this.onRoomChanged,
    required this.onJoiningChanged,
    this.bottomInset = 0,
    this.initialLiveID,
    this.closesToGrid = false,
    this.onClose,
  });
  final LiveHomeListStore store;
  final bool active;
  final double bottomInset;
  final String? initialLiveID;
  final bool closesToGrid;
  final ValueChanged<bool> onRoomChanged;
  final ValueChanged<bool> onJoiningChanged;
  final VoidCallback? onClose;
  @override
  State<LiveHomePreviewView> createState() => LiveHomePreviewViewState();
}

class LiveHomePreviewViewState extends State<LiveHomePreviewView> with WidgetsBindingObserver {
  late final PageController _pages;
  final _sessions = <String, _Session>{};
  List<LiveInfo> _items = [];
  int _index = 0;
  int _refreshRevision = 0;
  bool _automatic = false;
  bool _scrolling = false;
  bool _joining = false;
  bool _roomReported = false;
  bool _scheduled = false;
  bool _tearingDown = false;
  bool _foreground = true;
  EdgeInsets _safe = EdgeInsets.zero;
  _Session? get _current => _items.isEmpty ? null : _sessions[_items[_index].liveID];
  bool get _room => _current?.inRoom == true;
  bool get _canPlay => widget.active && _foreground;
  bool get _locked => _joining || _current?.controller.status.value == PlayerStatus.coGuest;
  bool get _roomMode => widget.closesToGrid || _automatic;

  @override
  void initState() {
    super.initState();
    _foreground =
        WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    _automatic = widget.closesToGrid;
    _items = widget.store.state.items;
    _index = math.max(0, _items.indexWhere((info) => info.liveID == widget.initialLiveID));
    _pages = PageController(initialPage: _index);
    _refreshRevision = widget.store.state.refreshRevision;
    widget.store.addListener(_render);
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _activate();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _safe = MediaQuery.viewPaddingOf(context);
    for (final session in _sessions.values) {
      session.controller.setContentSafeAreaInsets(_safe);
    }
  }

  @override
  void didUpdateWidget(covariant LiveHomePreviewView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.active != widget.active) {
      if (!widget.active) {
        _automatic = widget.closesToGrid;
        _releaseAll();
      } else {
        _render();
        _activate();
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (!_foreground) {
      for (final id in _sessions.keys.toList()) {
        if (_sessions[id] != _current || !_room) _release(id);
      }
    } else {
      _render();
      _activate();
    }
    _changed();
  }

  @override
  void dispose() {
    _tearingDown = true;
    widget.store.removeListener(_render);
    WidgetsBinding.instance.removeObserver(this);
    _releaseAll();
    _pages.dispose();
    super.dispose();
  }

  void _changed() {
    if (!mounted || _scheduled) return;
    _scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduled = false;
      if (!mounted) return;
      final presented = _room || (!widget.closesToGrid && _automatic && widget.active);
      if (presented != _roomReported) {
        _roomReported = presented;
        widget.onRoomChanged(presented);
      }
      setState(() {});
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  void _render() {
    if (!mounted) return;
    final next = widget.store.state.items;
    final append =
        next.length >= _items.length &&
        List.generate(_items.length, (index) => _items[index].liveID == next[index].liveID).every((same) => same);
    if (!_joining && !_scrolling && (!_room || append)) {
      final id = _items.isEmpty ? widget.initialLiveID : _items[_index].liveID;
      _items = next;
      _index = math.max(0, _items.indexWhere((info) => info.liveID == id));
      if (_refreshRevision != widget.store.state.refreshRevision) {
        _refreshRevision = widget.store.state.refreshRevision;
        for (final session in _sessions.values.toList()) {
          if (session.failed || session.controller.status.value == PlayerStatus.end) _release(session.info.liveID);
        }
      }
      for (final id in _sessions.keys.toList()) {
        if (!_items.any((info) => info.liveID == id)) _release(id);
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted &&
            !_scrolling &&
            _pages.hasClients &&
            _items.isNotEmpty &&
            (_pages.page ?? _index).round() != _index) {
          _pages.jumpToPage(_index);
        }
      });
      _activate();
    }
    _changed();
  }

  void _activate() {
    if (!_canPlay || _items.isEmpty) return;
    final wanted = {
      for (final index in [_index - 1, _index, _index + 1])
        if (index >= 0 && index < _items.length) _items[index].liveID,
    };
    for (final id in _sessions.keys.toList()) {
      if (!wanted.contains(id)) _release(id);
    }
    for (final index in [_index, _index - 1, _index + 1]) {
      if (index < 0 || index >= _items.length) continue;
      final info = _items[index];
      if (!_sessions.containsKey(info.liveID)) {
        final session = _Session(info);
        session.controller.setJoinLiveEntranceEnabled(false);
        session.controller.setContentSafeAreaInsets(_safe);
        session.listener = () {
          final status = session.controller.status.value;
          if (status == PlayerStatus.end) session.inRoom = false;
          if (status == PlayerStatus.coGuest) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && _pages.hasClients) _pages.jumpToPage(_index);
            });
          }
          _changed();
        };
        session.controller.status.addListener(session.listener);
        _sessions[info.liveID] = session;
      }
    }
    _changed();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_canPlay) return;
      for (final session in _sessions.values) {
        if (!session.started && !session.failed && session.controller.status.value != PlayerStatus.end) {
          session.started = true;
          session.controller.startPlay();
        }
        session.controller.setVolume(session == _current && !session.failed ? 100 : 0);
      }
      final current = _current;
      if (!_scrolling &&
          _automatic &&
          current != null &&
          !current.inRoom &&
          !current.failed &&
          current.controller.status.value != PlayerStatus.end) {
        unawaited(_enter(current));
      }
      final state = widget.store.state;
      if (_index >= _items.length - 2 && state.canLoadMore && !state.loading && state.error == null && !_joining) {
        unawaited(widget.store.loadMore());
      }
    });
  }

  Future<void> _enter(_Session session) async {
    if (!_canPlay || _joining || _scrolling || session.inRoom || session != _current) return;
    if (session.info.liveOwner.userID == LoginStore.shared.loginState.loginUserInfo?.userID) {
      session.failed = true;
      session.controller.showToast(AppStrings.of(context, 'ownLive'));
      _changed();
      return;
    }
    _joining = true;
    session.failed = false;
    widget.onJoiningChanged(true);
    _changed();
    try {
      session.join = session.controller.joinChannel();
      final success = await session.join!;
      if (session.retired || !mounted || !_canPlay || _current != session) {
        if (success) await session.controller.leaveChannel();
        return;
      }
      session.inRoom = success;
      session.failed = !success;
      if (success) _automatic = true;
    } catch (error) {
      session.failed = true;
      if (mounted && !session.retired) session.controller.showToast('$error');
    } finally {
      session.join = null;
      _joining = false;
      widget.onJoiningChanged(false);
      if (mounted) {
        _changed();
        _render();
      }
    }
  }

  void _release(String id) {
    final session = _sessions.remove(id);
    if (session == null) return;
    session.retired = true;
    session.controller.status.removeListener(session.listener);
    session.controller.setVolume(0);
    if (!_tearingDown) {
      session.controller.stopPlay();
      if (session.join == null) unawaited(session.controller.leaveChannel());
    }
    final pending = session.join;
    void finish() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(session.controller.leaveChannel());
        session.controller.stopPlay();
        session.controller.dispose();
      });
      WidgetsBinding.instance.ensureVisualUpdate();
    }

    if (pending != null) {
      unawaited(pending.then((_) => finish(), onError: (Object error) => finish()));
    } else {
      finish();
    }
  }

  void _releaseAll() {
    for (final id in _sessions.keys.toList()) {
      _release(id);
    }
  }

  void returnToPreview() {
    if (_joining) return;
    if (widget.closesToGrid) {
      widget.onClose?.call();
      return;
    }
    _automatic = false;
    final current = _current;
    if (current != null) {
      current.inRoom = false;
      unawaited(current.controller.leaveChannel());
    }
    _changed();
    _render();
  }

  void _pageChanged(int index) {
    if (index == _index || index < 0 || index >= _items.length) return;
    final previous = _current;
    if (previous != null) {
      previous.inRoom = false;
      previous.controller.setVolume(0);
      unawaited(previous.controller.leaveChannel());
    }
    _index = index;
    _activate();
    _changed();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.store.state;
    final bottom = _roomMode ? 0.0 : widget.bottomInset;
    return PopScope(
      canPop: widget.closesToGrid || !_automatic,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) returnToPreview();
      },
      child: LayoutBuilder(
        builder: (context, bounds) {
          if (_items.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (state.loading) const CircularProgressIndicator(color: Colors.white70),
                  Text(
                    state.error ?? AppStrings.of(context, 'emptyLive'),
                    style: const TextStyle(color: Colors.white70),
                  ),
                  TextButton(
                    onPressed: state.loading ? null : widget.store.refresh,
                    child: Text(AppStrings.of(context, 'retry')),
                  ),
                ],
              ),
            );
          }
          return Stack(
            children: [
              SizedBox(
                height: math.max(1, bounds.maxHeight - bottom),
                child: RefreshIndicator(
                  color: Colors.white70,
                  backgroundColor: const Color(0xff20232c),
                  edgeOffset: _safe.top + (_roomMode ? 0 : 57),
                  notificationPredicate: (event) => event.depth == 0 && !_room && !_joining && _canPlay,
                  onRefresh: widget.store.refresh,
                  child: NotificationListener<ScrollNotification>(
                    onNotification: (event) {
                      if (event is ScrollStartNotification) _scrolling = true;
                      if (event is ScrollEndNotification) {
                        _scrolling = false;
                        _render();
                        _activate();
                      }
                      return false;
                    },
                    child: PageView.builder(
                      controller: _pages,
                      scrollDirection: Axis.vertical,
                      allowImplicitScrolling: true,
                      physics: _locked ? const NeverScrollableScrollPhysics() : const AlwaysScrollableScrollPhysics(),
                      itemCount: _items.length,
                      onPageChanged: _pageChanged,
                      itemBuilder: (context, index) {
                        final info = _items[index];
                        final session = _sessions[info.liveID];
                        final status = session?.controller.status.value;
                        final showEnd = status == PlayerStatus.end;
                        final inRoom = status == PlayerStatus.inRoom || status == PlayerStatus.coGuest;
                        return ClipRect(
                          child: OverflowBox(
                            alignment: Alignment.topCenter,
                            minHeight: bounds.maxHeight,
                            maxHeight: bounds.maxHeight,
                            child: SizedBox(
                              height: bounds.maxHeight,
                              child: LiveHomePreviewItemView(
                                info: info,
                                bottomInset: bottom,
                                showPreview: !_roomMode && !showEnd && !inRoom,
                                joining: _joining,
                                ended: showEnd,
                                hidePlayer: widget.closesToGrid && !inRoom && !showEnd,
                                onEnter: session == null ? () {} : () => _enter(session),
                                player: session == null
                                    ? const SizedBox.shrink()
                                    : PlayerView(
                                        key: session.key,
                                        liveInfo: info,
                                        controller: session.controller,
                                        onCloseClicked: returnToPreview,
                                      ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              if (!widget.closesToGrid && _roomMode && !_room && !_joining && !_scrolling)
                Positioned(
                  top: _safe.top + 6,
                  right: 3,
                  child: TextButton(
                    onPressed: returnToPreview,
                    child: Text(AppStrings.of(context, 'backToPreview'), style: const TextStyle(color: Colors.white)),
                  ),
                ),
              if (_roomMode &&
                  _current?.failed == true &&
                  !_joining &&
                  !_scrolling &&
                  _current?.controller.status.value != PlayerStatus.end)
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(AppStrings.of(context, 'joinError'), style: const TextStyle(color: Colors.white)),
                      TextButton(onPressed: () => _enter(_current!), child: Text(AppStrings.of(context, 'retry'))),
                    ],
                  ),
                ),
              if (_index >= _items.length - 2 && (state.error != null || state.loading))
                Positioned(
                  bottom: bottom + 12,
                  left: 20,
                  right: 20,
                  child: Center(
                    child: TextButton(
                      onPressed: state.loading
                          ? null
                          : state.refreshFailed
                          ? widget.store.refresh
                          : widget.store.loadMore,
                      child: Text(
                        state.error ?? AppStrings.of(context, 'loading'),
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _Session {
  _Session(this.info) : controller = PlayerViewController() {
    controller.setLiveInfo(info);
  }
  final LiveInfo info;
  final PlayerViewController controller;
  final key = GlobalKey();
  late VoidCallback listener;
  Future<bool>? join;
  bool inRoom = false;
  bool started = false;
  bool retired = false;
  bool failed = false;
}
