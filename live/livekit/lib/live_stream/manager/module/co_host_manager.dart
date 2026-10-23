import 'dart:ui';

import 'package:atomic_x_core/api/live/co_host_store.dart';
import 'package:atomic_x_core/api/live/live_seat_store.dart';
import 'package:tencent_live_uikit/common/index.dart';

import '../../state/co_host_state.dart';
import '../live_stream_manager.dart';

class CoHostManager {
  LSCoHostState coHostState = LSCoHostState();

  late final Context context;

  CoHostListener? coHostListener;
  late final VoidCallback _onConnectionUserListListener = onConnectionUserListChanged;

  void init(Context context) {
    this.context = context;
  }

  void setLiveID(String liveID) {
    coHostState.currentRoomId = liveID;
    _subscribeListener();
  }

  void dispose() {
    _unSubscribeListener();
  }

  void resetStore() {
    _subscribeListener();
  }

  void _subscribeListener() {
    CoHostStore coHostStore = CoHostStore.create(coHostState.currentRoomId);
    coHostStore.coHostState.connected.addListener(_onConnectionUserListListener);

    coHostListener ??= CoHostListener(
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

  void _unSubscribeListener() {
    CoHostStore coHostStore = CoHostStore.create(coHostState.currentRoomId);
    coHostStore.coHostState.connected.removeListener(_onConnectionUserListListener);
    coHostStore.removeCoHostListener(coHostListener!);
  }

  bool get isCoHostConnecting => CoHostStore.create(coHostState.currentRoomId).coHostState.connected.value.isNotEmpty;

  Future<void> fetchRecommendedList(bool isRefresh) async {
    CoHostStore coHostStore = CoHostStore.create(coHostState.currentRoomId);
    final cursor = isRefresh ? "" : coHostStore.coHostState.candidatesCursor.value;
    await coHostStore.getCoHostCandidates(cursor);
    final sentRequestList = coHostStore.coHostState.invitees.value;
    final List<SeatUserInfo> recommendUsers = [...coHostStore.coHostState.candidates.value]
        .map((user) {
          if (sentRequestList.any((invitee) => invitee.userID == user.userID)) {
            user.connectionStatus = TUIConnectionStatus.inviting;
          }
          return user;
        })
        .where((user) => user.liveID.isNotEmpty)
        .toList();
    coHostState.recommendedUsers.value = recommendUsers;
  }
}

extension CoHostManagerCallback on CoHostManager {
  void onRequestConnection(SeatUserInfo user) {
    final newRecommendUsers = coHostState.recommendedUsers.value.toList();
    for (var recommendedUser in newRecommendUsers) {
      if (recommendedUser.liveID == user.liveID) {
        recommendedUser.connectionStatus = TUIConnectionStatus.inviting;
      }
    }
    coHostState.recommendedUsers.value = newRecommendUsers;
  }

  void onRequestConnectionFailed(String roomId) {
    final newRecommendUsers = coHostState.recommendedUsers.value.toList();
    for (var recommendedUser in newRecommendUsers) {
      if (recommendedUser.liveID == roomId) {
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
        .removeWhere((recommendUser) => connected.any((connectedUser) => connectedUser.liveID == recommendUser.liveID));
    coHostState.recommendedUsers.value = newRecommendUsers;
  }

  void onConnectionRequestAccept(SeatUserInfo invitee) {
    final newRecommendUsers = coHostState.recommendedUsers.value.toList();
    for (var recommendedUser in newRecommendUsers) {
      if (recommendedUser.liveID == invitee.liveID) {
        recommendedUser.connectionStatus = TUIConnectionStatus.connected;
      }
    }
    coHostState.recommendedUsers.value = newRecommendUsers;
  }

  void onConnectionRequestTimeout(SeatUserInfo inviter, SeatUserInfo invitee) {
    final newRecommendUsers = coHostState.recommendedUsers.value.toList();
    for (var recommendedUser in newRecommendUsers) {
      if (inviter.liveID == coHostState.currentRoomId && recommendedUser.liveID == invitee.liveID) {
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
      if (recommendedUser.liveID == invitee.liveID) {
        recommendedUser.connectionStatus = TUIConnectionStatus.none;
      }
    }
    coHostState.recommendedUsers.value = newRecommendUsers;
    final name = invitee.userName.isNotEmpty ? invitee.userName : invitee.userID;
    final toast = LiveKitLocalizations.of(Global.appContext())!.common_request_rejected.replaceAll('xxx', name);
    context.toastSubject.target?.add(toast);
  }
}
