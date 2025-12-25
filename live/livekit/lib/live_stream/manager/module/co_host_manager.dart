import 'dart:ui';

import 'package:atomic_x_core/api/live/co_host_store.dart';
import 'package:atomic_x_core/api/live/live_seat_store.dart';
import 'package:rtc_room_engine/api/common/tui_common_define.dart';
import 'package:rtc_room_engine/api/extension/tui_live_connection_manager.dart';
import 'package:rtc_room_engine/api/extension/tui_live_list_manager.dart';
import 'package:tencent_live_uikit/common/index.dart';

import '../../api/live_stream_service.dart';
import '../../state/co_host_state.dart';
import '../live_stream_manager.dart';

class CoHostManager {
  LSCoHostState coHostState = LSCoHostState();

  late final Context context;
  late final LiveStreamService service;

  CoHostListener? coHostListener;
  late final VoidCallback _onConnectionUserListListener = onConnectionUserListChanged;

  void init(Context context) {
    this.context = context;
    service = context.service;
  }

  void setLiveID(String liveID) {
    coHostState.currentRoomId = liveID;
    CoHostStore coHostStore = CoHostStore.create(coHostState.currentRoomId);
    coHostStore.coHostState.connected.addListener(_onConnectionUserListListener);

    coHostListener = CoHostListener(
      onCoHostRequestReceived: (SeatUserInfo inviter, String extensionInfo) {},
      onCoHostRequestCancelled: (SeatUserInfo inviter, SeatUserInfo? invitee) {},
      onCoHostRequestAccepted: (SeatUserInfo invitee) {
        onConnectionRequestAccept(invitee);
      },
      onCoHostRequestRejected: (SeatUserInfo invitee) {
        onConnectionRequestReject(invitee);
      },
      onCoHostRequestTimeout: (SeatUserInfo inviter, SeatUserInfo invitee) {
        onConnectionRequestTimeout(inviter, invitee);
      },
      onCoHostUserJoined: (SeatUserInfo userInfo) {},
      onCoHostUserLeft: (SeatUserInfo userInfo) {},
    );
    coHostStore.addCoHostListener(coHostListener!);
  }

  final int _listCount = 20;

  void dispose() {
    CoHostStore coHostStore = CoHostStore.create(coHostState.currentRoomId);
    coHostStore.coHostState.connected.removeListener(_onConnectionUserListListener);
    coHostStore.removeCoHostListener(coHostListener!);
  }

  bool get isCoHostConnecting => CoHostStore.create(coHostState.currentRoomId).coHostState.connected.value.isNotEmpty;

  Future<void> fetchRecommendedList({String cursor = ''}) async {
    final cursor = coHostState.recommendListCursor.value;
    final result = await service.fetchRecommendedList(cursor, _listCount);
    if (result.code != TUIError.success || result.data == null) {
      LiveKitLogger.error('fetchRecommendedList failed. code:${result.code}, message:${result.message}');
    }
    final recommendListResult = result.data!;
    if (cursor.isEmpty) {
      coHostState.recommendedUsers.value.clear();
    }
    CoHostStore coHostStore = CoHostStore.create(coHostState.currentRoomId);
    final sentRequestList = coHostStore.coHostState.invitees.value;
    final List<TUIConnectionUser> recommendUsers = recommendListResult.liveInfoList
        .map((liveInfo) {
          final isConnected = coHostStore.coHostState.connected.value.any((user) => user.liveID == liveInfo.roomId);
          if (!isConnected) {
            final user = _convertLiveInfo2ConnectionUser(liveInfo);
            if (sentRequestList.any((invitee) => invitee.userID == user.userId)) {
              user.connectionStatus = TUIConnectionStatus.inviting;
            }
            return user;
          } else {
            return TUIConnectionUser();
          }
        })
        .where((user) => user.roomId.isNotEmpty)
        .toList();

    final List<TUIConnectionUser> newRecommendedUsers = coHostState.recommendedUsers.value.toList();
    newRecommendedUsers.addAll(recommendUsers);

    coHostState.recommendedUsers.value = newRecommendedUsers;
    coHostState.recommendListCursor.value = recommendListResult.cursor;
  }

  void setLayoutTemplateId(int id) {
    coHostState.templateId = id;
  }

  void setCoHostLayoutTemplateId() {
    service.setCoHostLayoutTemplateId(coHostState.templateId);
  }
}

extension CoHostManagerCallback on CoHostManager {
  void onRequestConnection(TUIConnectionUser user) {
    final newRecommendUsers = coHostState.recommendedUsers.value.toList();
    for (var recommendedUser in newRecommendUsers) {
      if (recommendedUser.roomId == user.roomId) {
        recommendedUser.connectionStatus = TUIConnectionStatus.inviting;
      }
    }
    coHostState.recommendedUsers.value = newRecommendUsers;
  }

  void onRequestConnectionFailed(String roomId) {
    final newRecommendUsers = coHostState.recommendedUsers.value.toList();
    for (var recommendedUser in newRecommendUsers) {
      if (recommendedUser.roomId == roomId) {
        recommendedUser.connectionStatus = TUIConnectionStatus.none;
      }
    }
    coHostState.recommendedUsers.value = newRecommendUsers;
  }

  void onConnectionUserListChanged() {
    CoHostStore coHostStore = CoHostStore.create(coHostState.currentRoomId);
    List<SeatUserInfo> connected = coHostStore.coHostState.connected.value;
    final newRecommendUsers = coHostState.recommendedUsers.value.toList();
    newRecommendUsers
        .removeWhere((recommendUser) => connected.any((connectedUser) => connectedUser.liveID == recommendUser.roomId));
    coHostState.recommendedUsers.value = newRecommendUsers;
  }

  void onConnectionRequestAccept(SeatUserInfo invitee) {
    final newRecommendUsers = coHostState.recommendedUsers.value.toList();
    for (var recommendedUser in newRecommendUsers) {
      if (recommendedUser.roomId == invitee.liveID) {
        recommendedUser.connectionStatus = TUIConnectionStatus.connected;
      }
    }
    coHostState.recommendedUsers.value = newRecommendUsers;
  }

  void onConnectionRequestTimeout(SeatUserInfo inviter, SeatUserInfo invitee) {
    final newRecommendUsers = coHostState.recommendedUsers.value.toList();
    for (var recommendedUser in newRecommendUsers) {
      if (inviter.liveID == coHostState.currentRoomId && recommendedUser.roomId == invitee.liveID) {
        recommendedUser.connectionStatus = TUIConnectionStatus.none;
      }
    }
    coHostState.recommendedUsers.value = newRecommendUsers;
    final toast = LiveKitLocalizations.of(Global.appContext())!.common_connect_invitation_timeout;
    context.toastSubject.target?.add(toast);
  }

  void onConnectionRequestReject(SeatUserInfo invitee) {
    final newRecommendUsers = coHostState.recommendedUsers.value.toList();
    for (var recommendedUser in newRecommendUsers) {
      if (recommendedUser.roomId == invitee.liveID) {
        recommendedUser.connectionStatus = TUIConnectionStatus.none;
      }
    }
    coHostState.recommendedUsers.value = newRecommendUsers;
    final name = invitee.userName.isNotEmpty ? invitee.userName : invitee.userID;
    final toast = LiveKitLocalizations.of(Global.appContext())!.common_request_rejected.replaceAll('xxx', name);
    context.toastSubject.target?.add(toast);
  }
}

extension on CoHostManager {
  TUIConnectionUser _convertLiveInfo2ConnectionUser(TUILiveInfo liveInfo) {
    final connectionUser = TUIConnectionUser();
    connectionUser.roomId = liveInfo.roomId;
    connectionUser.userId = liveInfo.ownerId;
    connectionUser.userName = liveInfo.ownerName;
    connectionUser.avatarUrl = liveInfo.ownerAvatarUrl;
    connectionUser.joinConnectionTime = 0;
    return connectionUser;
  }
}
