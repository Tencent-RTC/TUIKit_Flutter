import 'package:atomic_x_core/api/live/co_host_store.dart';
import 'package:atomic_x_core/api/live/live_list_store.dart';
import 'package:atomic_x_core/api/live/live_seat_store.dart';
import 'package:flutter/material.dart';
import 'package:tencent_live_uikit/common/error/error_handler.dart';
import 'package:tencent_live_uikit/common/screen/index.dart';
import 'package:tencent_live_uikit/live_stream/state/co_host_state.dart';

import '../../../../common/constants/constants.dart';
import '../../../../common/resources/index.dart';
import '../../../../common/widget/index.dart';
import '../../../../tencent_live_uikit.dart';
import '../../../manager/live_stream_manager.dart';

class CoHostManagementPanelWidget extends StatefulWidget {
  final LiveStreamManager liveStreamManager;

  const CoHostManagementPanelWidget({super.key, required this.liveStreamManager});

  @override
  State<CoHostManagementPanelWidget> createState() => _CoHostManagementPanelWidgetState();
}

class _CoHostManagementPanelWidgetState extends State<CoHostManagementPanelWidget> {
  late final LiveStreamManager liveStreamManager;
  static const coHostTimeout = 10;

  final ScrollController _scrollController = ScrollController();
  final GlobalKey<RefreshIndicatorState> _refreshKey = GlobalKey();
  final ValueNotifier<bool> _isLoading = ValueNotifier(false);
  AlertHandler? _disconnectCoHostHandler;
  late final CoHostStore coHostStore;

  @override
  void initState() {
    super.initState();
    liveStreamManager = widget.liveStreamManager;
    coHostStore = CoHostStore.create(liveStreamManager.roomState.roomId);
    _addObserver();
    _refreshRecommendUserList();
    liveStreamManager.coHostManager.setCoHostLayoutTemplateId();
  }

  @override
  void dispose() {
    _disconnectCoHostHandler?.close();
    _removeObserver();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1.screenWidth,
      height: 718.height,
      padding: EdgeInsets.only(bottom: 20.height),
      decoration: BoxDecoration(
        color: LiveColors.designStandardG2,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(20.radius), topRight: Radius.circular(20.radius)),
      ),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child:
            Column(mainAxisAlignment: MainAxisAlignment.start, crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(height: 20.height),
          _buildTitleWidget(),
          SizedBox(height: 20.height),
          _buildConnectedUserListTitleWidget(),
          _buildConnectedUserListWidget(),
          _buildSeparationWidget(),
          _buildRecommendListTitleWidget(),
          _buildRecommendListWidget()
        ]),
      ),
    );
  }

  Widget _buildTitleWidget() {
    return SizedBox(
      height: 28.height,
      child: Stack(
        children: [
          Center(
            child: Text(
              LiveKitLocalizations.of(Global.appContext())!.common_connection,
              style: const TextStyle(color: LiveColors.designStandardG7, fontSize: 16),
            ),
          ),
          Positioned(
            right: 16.width,
            child: DebounceGestureRecognizer(
              onTap: () {
                _disconnectCoHost();
              },
              child: Container(
                constraints: BoxConstraints(maxHeight: 20.height, minWidth: 50.width, maxWidth: 90.width),
                child: ValueListenableBuilder(
                    valueListenable: coHostStore.coHostState.connected,
                    builder: (context, connectedUsers, _) {
                      return Visibility(
                        visible: connectedUsers.any((user) => user.userID == _getSelfID()),
                        child: Row(
                          children: [
                            Image.asset(
                              LiveImages.connectionDisconnect,
                              package: Constants.pluginName,
                            ),
                            SizedBox(width: 4.width),
                            Text(
                              LiveKitLocalizations.of(Global.appContext())!.common_end_connect,
                              style: const TextStyle(color: LiveColors.notStandardRed, fontSize: 14),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      );
                    }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectedUserListTitleWidget() {
    return ValueListenableBuilder(
        valueListenable: coHostStore.coHostState.connected,
        builder: (context, connectedUsers, _) {
          final filterConnectedUsers = connectedUsers.where((user) => user.userID != _getSelfID());
          return Visibility(
            visible: connectedUsers.isNotEmpty,
            child: Container(
              margin: EdgeInsets.only(left: 24.width),
              child: Text(
                LiveKitLocalizations.of(Global.appContext())!
                    .common_connection_list_title
                    .replaceAll('xxx', '${filterConnectedUsers.length}'),
                style: const TextStyle(color: LiveColors.designStandardG7, fontSize: 14),
              ),
            ),
          );
        });
  }

  Widget _buildConnectedUserListWidget() {
    return ValueListenableBuilder(
      valueListenable: coHostStore.coHostState.connected,
      builder: (context, connectedUsers, _) {
        final filterConnectedUsers = connectedUsers.where((user) => user.userID != _getSelfID()).toList();
        return Visibility(
          visible: connectedUsers.isNotEmpty,
          child: SizedBox(
            height: _calculateConnectedUserListHeight(),
            child: ListView.builder(
                shrinkWrap: true,
                physics: const ClampingScrollPhysics(),
                scrollDirection: Axis.vertical,
                itemCount: filterConnectedUsers.length,
                itemBuilder: (context, index) {
                  final connectedUser = filterConnectedUsers[index];
                  return _buildConnectedUserItem(connectedUser);
                }),
          ),
        );
      },
    );
  }

  Widget _buildConnectedUserItem(SeatUserInfo user) {
    return Container(
      height: 60.height,
      color: LiveColors.designStandardG2,
      padding: EdgeInsets.only(left: 24.width, right: 24.width),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        children: [
          Row(
            children: [
              SizedBox(
                width: 40.radius,
                height: 40.radius,
                child: ClipOval(
                  child: Image.network(
                    user.avatarURL,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Image.asset(
                        LiveImages.defaultAvatar,
                        package: Constants.pluginName,
                      );
                    },
                  ),
                ),
              ),
              SizedBox(width: 12.width),
              Container(
                constraints: BoxConstraints(maxWidth: 135.width),
                alignment: Alignment.centerLeft,
                child: Text(
                  user.userName.isNotEmpty ? user.userName : user.userID,
                  style: const TextStyle(color: LiveColors.designStandardG7, fontSize: 16),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSeparationWidget() {
    return ListenableBuilder(
      listenable:
          Listenable.merge([coHostStore.coHostState.connected, liveStreamManager.coHostState.recommendedUsers]),
      builder: (context, _) {
        return Visibility(
          visible: coHostStore.coHostState.connected.value.isNotEmpty &&
              liveStreamManager.coHostState.recommendedUsers.value.isNotEmpty,
          child: SizedBox(
            height: 3.height,
          ),
        );
      },
    );
  }

  Widget _buildRecommendListTitleWidget() {
    return Container(
      margin: EdgeInsets.only(left: 24.width),
      child: Text(
        LiveKitLocalizations.of(Global.appContext())!.common_recommended_list,
        style: const TextStyle(color: LiveColors.designStandardG7, fontSize: 14),
      ),
    );
  }

  Widget _buildRecommendListWidget() {
    return RefreshIndicator(
      key: _refreshKey,
      onRefresh: _refreshRecommendUserList,
      child: ValueListenableBuilder(
        valueListenable: liveStreamManager.coHostState.recommendedUsers,
        builder: (context, recommendedUsers, _) {
          final filterRecommendUsers = recommendedUsers
              .where((user) =>
                  user.connectionStatus != TUIConnectionStatus.connected &&
                  user.roomId != liveStreamManager.roomState.roomId)
              .toList();
          return Column(
            children: [
              SizedBox(
                height: _calculateRecommendListHeight(),
                child: ListView.builder(
                    controller: _scrollController,
                    shrinkWrap: true,
                    physics: const AlwaysScrollableScrollPhysics(),
                    scrollDirection: Axis.vertical,
                    itemCount: filterRecommendUsers.length + 1,
                    itemBuilder: (context, index) {
                      if (index == filterRecommendUsers.length) {
                        return _buildRecommendListFooter();
                      }
                      final recommendUser = filterRecommendUsers[index];
                      return _buildRecommendUserItem(recommendUser);
                    }),
              ),
              _buildRecommendListLoadingWidget(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRecommendUserItem(TUIConnectionUser user) {
    return Container(
      height: 60.height,
      color: LiveColors.designStandardG2,
      padding: EdgeInsets.only(left: 24.width, right: 24.width),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        children: [
          Row(
            children: [
              SizedBox(
                width: 40.radius,
                height: 40.radius,
                child: ClipOval(
                  child: Image.network(
                    user.avatarUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Image.asset(
                        LiveImages.defaultAvatar,
                        package: Constants.pluginName,
                      );
                    },
                  ),
                ),
              ),
              SizedBox(width: 12.width),
              Container(
                constraints: BoxConstraints(maxWidth: 135.width),
                alignment: Alignment.centerLeft,
                child: Text(
                  user.userName.isNotEmpty ? user.userName : user.userId,
                  style: const TextStyle(color: LiveColors.designStandardG7, fontSize: 16),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          DebounceGestureRecognizer(
            delay: const Duration(milliseconds: 1000),
            onTap: () {
              _inviteToCoHost(user);
            },
            child: ValueListenableBuilder(
                valueListenable: coHostStore.coHostState.invitees,
                builder: (context, inviteeList, _) {
                  final isInInviting = inviteeList.any((invitee) => invitee.liveID == user.roomId);
                  return Container(
                    width: 64.width,
                    height: 24.height,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12.height),
                        color:
                            isInInviting ? LiveColors.designStandardB1.withAlpha(0x80) : LiveColors.designStandardB1),
                    alignment: Alignment.center,
                    child: Text(
                      isInInviting
                          ? LiveKitLocalizations.of(Global.appContext())!.common_connect_inviting
                          : LiveKitLocalizations.of(Global.appContext())!.common_voiceroom_invite,
                      style: const TextStyle(color: LiveColors.designStandardG8, fontSize: 12),
                    ),
                  );
                }),
          )
        ],
      ),
    );
  }

  Widget _buildRecommendListLoadingWidget() {
    return ValueListenableBuilder(
      valueListenable: _isLoading,
      builder: (context, loading, _) {
        return Visibility(
            visible: loading,
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(LiveColors.designStandardG5),
                    strokeWidth: 1,
                  ),
                  Text(
                    LiveKitLocalizations.of(context)!.livelist_loading,
                    style: const TextStyle(
                      color: LiveColors.designStandardG5,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ));
      },
    );
  }

  Widget _buildRecommendListFooter() {
    return ValueListenableBuilder(
      valueListenable: liveStreamManager.coHostState.recommendListCursor,
      builder: (context, cursor, _) {
        return Visibility(
          visible: cursor.isEmpty && liveStreamManager.coHostState.recommendedUsers.value.isNotEmpty,
          child: Container(
            color: LiveColors.designStandardTransparent,
            padding: EdgeInsets.symmetric(vertical: 16.height),
            alignment: Alignment.center,
            child: Text(
              LiveKitLocalizations.of(Global.appContext())!.livelist_no_more_data,
              style: const TextStyle(
                color: LiveColors.designStandardG5,
                fontSize: 14,
              ),
            ),
          ),
        );
      },
    );
  }
}

extension on _CoHostManagementPanelWidgetState {
  String _getSelfID() {
    return TUIRoomEngine.getSelfInfo().userId;
  }

  String _getLiveID() {
    return liveStreamManager.roomState.roomId;
  }

  void _addObserver() {
    _scrollController.addListener(_loadMore);
  }

  void _removeObserver() {
    _scrollController.removeListener(_loadMore);
  }

  void _loadMore() {
    if (_isScrollToBottom()) {
      final cursor = liveStreamManager.coHostState.recommendListCursor.value;
      if (cursor.isNotEmpty && !_isLoading.value) {
        _fetchMoreRecommendUsers();
      }
    }
  }

  bool _isScrollToBottom() {
    if (!_scrollController.hasClients) {
      return false;
    }
    final position = _scrollController.position;
    if (position.maxScrollExtent == 0) {
      return false;
    }

    const threshold = 30;
    if (position.maxScrollExtent >= position.pixels && position.maxScrollExtent - position.pixels <= threshold) {
      return true;
    }
    return false;
  }

  Future<void> _refreshRecommendUserList() async {
    if (_isLoading.value) return;
    _isLoading.value = true;
    try {
      await liveStreamManager.fetchRecommendedList();
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> _fetchMoreRecommendUsers() async {
    if (_isLoading.value) return;
    _isLoading.value = true;
    try {
      final cursor = liveStreamManager.coHostState.recommendListCursor.value;
      if (cursor.isNotEmpty) {
        await liveStreamManager.fetchRecommendedList(cursor: cursor);
      }
    } finally {
      _isLoading.value = false;
    }
  }

  double _calculateConnectedUserListHeight() {
    double totalHeight = 0;
    if (coHostStore.coHostState.connected.value.isNotEmpty) {
      final filterConnectedUsers =
          coHostStore.coHostState.connected.value.where((user) => user.userID != _getSelfID());
      totalHeight = filterConnectedUsers.length * 60.height;
    }
    return totalHeight > 300.height ? 300.height : totalHeight;
  }

  double _calculateRecommendListHeight() {
    final totalHeight = 600.height - _calculateConnectedUserListHeight();
    return totalHeight;
  }

  void _disconnectCoHost() {
    if (_disconnectCoHostHandler?.isShowing() == true) {
      return;
    }

    final confirmInfo = AlertInfo(
        description: LiveKitLocalizations.of(Global.appContext())!.common_disconnect_tips,
        defaultActionInfo: (
          title: LiveKitLocalizations.of(Global.appContext())!.common_end_connect,
          titleColor: LiveColors.designStandardB1
        ),
        defaultCallback: () {
          _disconnectCoHostHandler?.close();
          coHostStore.exitHostConnection();
        },
        cancelActionInfo: (
          title: LiveKitLocalizations.of(Global.appContext())!.common_cancel,
          titleColor: LiveColors.designStandardG3
        ),
        cancelCallback: () {
          _disconnectCoHostHandler?.close();
        });

    _disconnectCoHostHandler = Alert.showAlert(confirmInfo);
  }

  void _inviteToCoHost(TUIConnectionUser user) async {
    final inviteeList = coHostStore.coHostState.invitees.value;
    final isInInviting = inviteeList.any((invitee) => invitee.liveID == user.roomId);
    if (isInInviting) return;

    liveStreamManager.onRequestCrossRoomConnection(user);
    final result = await coHostStore.requestHostConnection(
        targetHostLiveID: user.roomId,
        layoutTemplate: CoHostLayoutTemplate.hostDynamicGrid,
        timeout: _CoHostManagementPanelWidgetState.coHostTimeout);
    if (result.errorCode != TUIConnectionCode.success.value()) {
      liveStreamManager.onRequestCrossRoomConnectionFailed(user.roomId);
      liveStreamManager.toastSubject
          .add(ErrorHandler.convertToConnectionErrorMessage(TUIConnectionCodeExt.fromValue(result.errorCode)) ?? '');
      return;
    }
    liveStreamManager.onRequestCrossRoomConnectionFailed(user.roomId);
  }
}
