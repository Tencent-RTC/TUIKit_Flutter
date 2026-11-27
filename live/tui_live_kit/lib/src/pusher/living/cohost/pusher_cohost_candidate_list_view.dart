import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../common/live_avatar_image.dart';
import '../../../common/live_kit_resources.dart';
import '../../../common/theme/bottom_sheet_view.dart';
import 'pusher_cohost_store.dart';
import 'pusher_cohost_random_connection_view.dart';

class PusherCoHostCandidateListView extends StatefulWidget {
  const PusherCoHostCandidateListView(
      {super.key,
      required this.state,
      required this.hostAvatarURL,
      required this.isAdding,
      required this.onInvite,
      required this.onCancel,
      required this.onRefresh,
      required this.onLoadMore,
      required this.onBack,
      required this.onDismiss,
      this.controller});
  final PusherCoHostState state;
  final String hostAvatarURL;
  final bool isAdding;
  final ValueChanged<String> onInvite, onCancel;
  final Future<void> Function() onRefresh;
  final VoidCallback onLoadMore, onBack, onDismiss;
  final BottomSheetController? controller;
  @override
  State<PusherCoHostCandidateListView> createState() => _CandidateListState();
}

class _CandidateListState extends State<PusherCoHostCandidateListView> {
  final _scroll = ScrollController();
  final _headerVisible = ValueNotifier(true);
  bool _closing = false;
  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  void _onScroll() {
    _headerVisible.value = !_closing && _scroll.offset < 154;
    if (_scroll.position.extentAfter < 132 &&
        widget.state.hasMore &&
        !widget.state.isLoading &&
        widget.state.loadError == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_closing && widget.state.hasMore && !widget.state.isLoading && widget.state.loadError == null) {
          widget.onLoadMore();
        }
      });
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    _headerVisible.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final followed = state.candidates.where((u) => widget.isAdding ? u.isMutual : u.isFollowing).toList();
    final recommended = state.candidates.where((u) => widget.isAdding ? !u.isMutual : !u.isFollowing).toList();
    final rows = <Object>[
      if (!widget.isAdding) _RowKind.random,
      if (followed.isNotEmpty) ...[
        widget.isAdding ? 'mutual' : 'following',
        ...followed,
        widget.isAdding ? 14.0 : 26.0
      ],
      if (recommended.isNotEmpty) ...['recommended', ...recommended, 14.0],
      if (state.candidates.isEmpty && !state.isLoading && state.loadError == null) _RowKind.empty,
      if (state.isLoading || state.hasMore || state.loadError != null) _RowKind.footer,
    ];
    final safeBottom = MediaQuery.viewPaddingOf(context).bottom;
    return BottomSheetView(
        controller: widget.controller,
        sheetHeight: math.min(550 + safeBottom, math.max(0, MediaQuery.sizeOf(context).height - 80)),
        onWillDismiss: () {
          _closing = true;
          _headerVisible.value = false;
        },
        onDismiss: widget.onDismiss,
        child: Column(children: [
          SizedBox(
              height: widget.isAdding ? 98 : 78,
              child: Stack(children: [
                if (widget.isAdding)
                  Positioned(
                      left: 10,
                      top: 40,
                      width: 44,
                      height: 44,
                      child: GestureDetector(
                          onTap: widget.onBack,
                          behavior: HitTestBehavior.opaque,
                          child: Padding(
                              padding: const EdgeInsets.all(11),
                              child:
                                  Image(image: LiveKitResources.image('livekit_cohost_back'), width: 22, height: 22)))),
                Positioned(
                    left: widget.isAdding ? 52 : 18,
                    right: 18,
                    top: widget.isAdding ? 46 : 30,
                    height: 34,
                    child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                            LiveKitResources.localizedString(widget.isAdding
                                ? 'tuilivekit.pusher.cohost.invite_title'
                                : 'tuilivekit.pusher.cohost.interaction_title'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)))),
              ])),
          Expanded(
              child: RefreshIndicator(
                  color: Colors.white,
                  backgroundColor: const Color(0xFF1F3555),
                  onRefresh: widget.onRefresh,
                  child: ListView.builder(
                      controller: _scroll,
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + safeBottom),
                      itemCount: rows.length,
                      itemBuilder: (context, index) {
                        final row = rows[index];
                        if (row == _RowKind.random) {
                          return Padding(
                              padding: const EdgeInsets.only(right: 2, bottom: 12),
                              child: ValueListenableBuilder<bool>(
                                  valueListenable: _headerVisible,
                                  builder: (context, enabled, _) => PusherCoHostRandomConnectionView(
                                      hostAvatarURL: widget.hostAvatarURL,
                                      candidates: state.candidates,
                                      presentationEnabled: enabled)));
                        }
                        if (row is PusherCoHostUser) return _person(row);
                        if (row is double) return SizedBox(height: row);
                        if (row is String) {
                          return SizedBox(
                              height: !widget.isAdding && row == 'following' ? 32 : 31,
                              child: Padding(
                                  padding: const EdgeInsets.only(left: 2, top: 4),
                                  child: Text(LiveKitResources.localizedString('tuilivekit.pusher.cohost.$row'),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 13, color: Color(0xC7FFFFFF)))));
                        }
                        if (row == _RowKind.empty) {
                          return SizedBox(
                              height: 60,
                              child: Center(
                                  child: Text(LiveKitResources.localizedString('tuilivekit.pusher.cohost.empty'),
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(fontSize: 13, color: Color(0x7AFFFFFF)))));
                        }
                        return GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: state.isLoading
                                ? null
                                : () {
                                    if (state.candidates.isEmpty || state.loadError != null) {
                                      widget.onRefresh();
                                    } else {
                                      widget.onLoadMore();
                                    }
                                  },
                            child: SizedBox(
                                height: 44,
                                child: Center(
                                    child: Text(
                                        LiveKitResources.localizedString(state.isLoading
                                            ? 'tuilivekit.common.processing'
                                            : state.loadError != null
                                                ? 'tuilivekit.pusher.cohost.retry'
                                                : 'tuilivekit.pusher.cohost.load_more'),
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(fontSize: 13, color: Color(0xC7FFFFFF))))));
                      }))),
        ]));
  }

  Widget _person(PusherCoHostUser user) {
    final state = widget.state, connected = widget.state.connected.any((u) => u.liveID == user.liveID);
    final busy = state.isBusy(user.liveID);
    final title = connected
        ? 'tuilivekit.pusher.cohost.connected'
        : busy
            ? 'tuilivekit.common.processing'
            : state.isInvited(user.liveID)
                ? 'tuilivekit.pusher.cohost.cancel_invitation'
                : 'tuilivekit.pusher.cohost.invite';
    return SizedBox(
        height: 66,
        child: DecoratedBox(
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0x12FFFFFF), width: .5))),
            child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(children: [
                  ClipOval(
                      child: SizedBox(width: 44, height: 44, child: LiveAvatarImage(avatarURL: user.avatarURL.trim()))),
                  const SizedBox(width: 11),
                  Expanded(
                      child: Text(user.userName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13, color: Colors.white))),
                  const SizedBox(width: 8),
                  GestureDetector(
                      onTap: connected || busy
                          ? null
                          : () {
                              if (state.isInvited(user.liveID)) {
                                widget.onCancel(user.liveID);
                              } else {
                                widget.onInvite(user.liveID);
                              }
                            },
                      child: Opacity(
                          opacity: busy && !connected ? .46 : 1,
                          child: Container(
                              width: 94,
                              height: 34,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  color: connected ? const Color(0x0AFFFFFF) : const Color(0x771963DD),
                                  border:
                                      Border.all(color: connected ? const Color(0x0DFFFFFF) : const Color(0x6462ABFF))),
                              child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(LiveKitResources.localizedString(title),
                                      maxLines: 1,
                                      style: TextStyle(
                                          fontSize: 12, color: connected ? const Color(0x47FFFFFF) : Colors.white)))))),
                ]))));
  }
}

enum _RowKind { random, empty, footer }
