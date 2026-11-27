/// 主播私有观众状态与操作编排：列表、禁言状态来自 AtomicXCore，关注关系来自 IM。
library;

import 'dart:async';

import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/foundation.dart';
import 'package:tencent_cloud_chat_sdk/enum/V2TimFriendshipListener.dart';
import 'package:tencent_cloud_chat_sdk/enum/follow_type.dart';
import 'package:tencent_cloud_chat_sdk/manager/v2_tim_friendship_manager.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_follow_operation_result.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_follow_type_check_result.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_user_full_info.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_value_callback.dart';
import 'package:tencent_cloud_chat_sdk/tencent_im_sdk_plugin.dart';

import '../../../common/audience/audience_welcome_view.dart';

export '../../../common/audience/audience_welcome_view.dart' show AudienceWelcome;

class AudienceUser {
  const AudienceUser({
    required this.userID,
    required this.userName,
    required this.avatarURL,
    this.level = 0,
  });

  final String userID;
  final String userName;
  final String avatarURL;

  /// AtomicXCore 的真实用户等级，负值按基础档展示。
  final int level;
}

enum AudienceFollowStatus { unknown, notFollowing, following }

enum AudienceAction { follow, unfollow, mute, unmute, remove }

class AudienceState {
  AudienceState({
    this.users = const <AudienceUser>[],
    this.count = 0,
    Set<String>? mutedUserIDs,
    Map<String, AudienceFollowStatus>? followStatusByUserID,
    Map<String, AudienceAction>? pendingActionByUserID,
  })  : mutedUserIDs = mutedUserIDs ?? <String>{},
        followStatusByUserID = followStatusByUserID ?? <String, AudienceFollowStatus>{},
        pendingActionByUserID = pendingActionByUserID ?? <String, AudienceAction>{};

  List<AudienceUser> users;
  int count;
  Set<String> mutedUserIDs;
  Map<String, AudienceFollowStatus> followStatusByUserID;
  Set<String> get pendingUserIDs => pendingActionByUserID.keys.toSet();
  Map<String, AudienceAction> pendingActionByUserID;

  AudienceFollowStatus followStatus(String userID) {
    return followStatusByUserID[userID] ?? AudienceFollowStatus.unknown;
  }

  AudienceState copy() {
    return AudienceState(
      users: List<AudienceUser>.of(users),
      count: count,
      mutedUserIDs: Set<String>.of(mutedUserIDs),
      followStatusByUserID: Map<String, AudienceFollowStatus>.of(followStatusByUserID),
      pendingActionByUserID: Map<String, AudienceAction>.of(pendingActionByUserID),
    );
  }

  bool isSameAs(AudienceState other) {
    return count == other.count &&
        listEquals(users.map(_userKey).toList(), other.users.map(_userKey).toList()) &&
        setEquals(mutedUserIDs, other.mutedUserIDs) &&
        mapEquals(followStatusByUserID, other.followStatusByUserID) &&
        mapEquals(pendingActionByUserID, other.pendingActionByUserID);
  }

  static String _userKey(AudienceUser user) {
    return '${user.userID}\u0000${user.userName}\u0000${user.avatarURL}\u0000${user.level}';
  }
}

class PusherAudienceStore extends ChangeNotifier {
  PusherAudienceStore({
    required String liveID,
    LiveAudienceStore? audienceStore,
    V2TIMFriendshipManager? friendshipManager,
  })  : _audienceStore = audienceStore ?? LiveAudienceStore.create(liveID),
        _friendshipManager = friendshipManager ?? TencentImSDKPlugin.v2TIMManager.getFriendshipManager();

  final LiveAudienceStore _audienceStore;
  final V2TIMFriendshipManager _friendshipManager;
  final AudienceState _state = AudienceState();
  final List<(Listenable, VoidCallback)> _stateListeners = <(Listenable, VoidCallback)>[];
  final Map<String, int> _operationIDs = <String, int>{};
  final Map<String, int> _followQueryIDs = <String, int>{};

  LiveAudienceListener? _audienceListener;
  V2TimFriendshipListener? _friendshipListener;
  int _nextOperationID = 0;
  int _activationID = 0;
  bool _isActive = false;
  bool _isRefreshing = false;

  void Function(AudienceWelcome welcome)? onAudienceEntered;
  void Function(String userID, AudienceAction action, bool succeeded)? onActionCompleted;

  AudienceState get state => _state;

  void activate() {
    if (_isActive) {
      return;
    }
    _isActive = true;
    final int activationID = ++_activationID;
    final LiveAudienceState sdkState = _audienceStore.liveAudienceState;

    void onAudienceStateChanged() {
      if (!_isCurrentActivation(activationID)) {
        return;
      }
      _applySDKState(sdkState);
    }

    _bind(sdkState.audienceList, onAudienceStateChanged);
    _bind(sdkState.audienceCount, onAudienceStateChanged);
    _bind(sdkState.messageBannedUserList, onAudienceStateChanged);
    _applySDKState(sdkState);

    final LiveAudienceListener audienceListener = LiveAudienceListener(
      onAudienceJoined: (LiveUserInfo user) {
        if (!_isCurrentActivation(activationID)) {
          return;
        }
        onAudienceEntered?.call(
          AudienceWelcome(
            userID: user.userID,
            userName: user.userName.isEmpty ? user.userID : user.userName,
            level: user.level < 0 ? 0 : user.level,
          ),
        );
      },
    );
    _audienceListener = audienceListener;
    _audienceStore.addLiveAudienceListener(audienceListener);

    final V2TimFriendshipListener friendshipListener = V2TimFriendshipListener(
      onMyFollowingListChanged: (List<V2TimUserFullInfo> users, bool isAdd) {
        if (!_isCurrentActivation(activationID)) {
          return;
        }
        final List<String> relevantIDs = users
            .map((V2TimUserFullInfo user) => user.userID ?? '')
            .where((String userID) => userID.isNotEmpty && _state.followStatusByUserID.containsKey(userID))
            .toList();
        if (relevantIDs.isNotEmpty) {
          _checkFollowStatus(relevantIDs, activationID);
        }
      },
    );
    _friendshipListener = friendshipListener;
    unawaited(
      _friendshipManager.addFriendListener(listener: friendshipListener),
    );
  }

  void deactivate({required bool resetState}) {
    if (!_isActive && !resetState) {
      return;
    }
    _isActive = false;
    _isRefreshing = false;
    _activationID += 1;
    for (final (Listenable listenable, VoidCallback callback) in _stateListeners) {
      listenable.removeListener(callback);
    }
    _stateListeners.clear();
    final LiveAudienceListener? audienceListener = _audienceListener;
    if (audienceListener != null) {
      _audienceStore.removeLiveAudienceListener(audienceListener);
      _audienceListener = null;
    }
    final V2TimFriendshipListener? friendshipListener = _friendshipListener;
    if (friendshipListener != null) {
      unawaited(
        _friendshipManager.removeFriendListener(listener: friendshipListener),
      );
      _friendshipListener = null;
    }
    _operationIDs.clear();
    _followQueryIDs.clear();
    _state.pendingActionByUserID.clear();
    _state.followStatusByUserID.clear();
    if (resetState) {
      _state.users = <AudienceUser>[];
      _state.count = 0;
      _state.mutedUserIDs.clear();
    }
    notifyListeners();
  }

  void refresh() {
    if (!_isActive || _isRefreshing) return;
    _isRefreshing = true;
    final activationID = _activationID;
    _audienceStore.fetchAudienceList().then((_) {
      if (_isCurrentActivation(activationID)) _isRefreshing = false;
    }).onError((Object error, StackTrace trace) {
      if (_isCurrentActivation(activationID)) _isRefreshing = false;
    });
  }

  void refreshFollowStatus(String userID) {
    if (!_isActive || userID.isEmpty) {
      return;
    }
    _state.followStatusByUserID[userID] = AudienceFollowStatus.unknown;
    notifyListeners();
    _checkFollowStatus(<String>[userID], _activationID);
  }

  void toggleFollow(String userID) {
    switch (_state.followStatus(userID)) {
      case AudienceFollowStatus.following:
        _performFollowAction(userID, AudienceAction.unfollow);
      case AudienceFollowStatus.notFollowing:
        _performFollowAction(userID, AudienceAction.follow);
      case AudienceFollowStatus.unknown:
        refreshFollowStatus(userID);
    }
  }

  void toggleMessagePermission(String userID) {
    final bool isMuted = _state.mutedUserIDs.contains(userID);
    _performAtomicAction(
      userID,
      isMuted ? AudienceAction.unmute : AudienceAction.mute,
      () => _audienceStore.disableSendMessage(
        userID: userID,
        isDisable: !isMuted,
      ),
    );
  }

  void removeFromRoom(String userID) {
    _performAtomicAction(
      userID,
      AudienceAction.remove,
      () => _audienceStore.kickUserOutOfRoom(userID),
    );
  }

  void _applySDKState(LiveAudienceState sdkState) {
    final List<AudienceUser> users = sdkState.audienceList.value
        .where((LiveUserInfo user) => user.userID.isNotEmpty)
        .map(
          (LiveUserInfo user) => AudienceUser(
            userID: user.userID,
            userName: user.userName,
            avatarURL: user.avatarURL,
            level: user.level < 0 ? 0 : user.level,
          ),
        )
        .toList();
    final Set<String> mutedUserIDs = sdkState.messageBannedUserList.value
        .map((LiveUserInfo user) => user.userID)
        .where((String userID) => userID.isNotEmpty)
        .toSet();
    final bool changed =
        !listEquals(users.map(AudienceState._userKey).toList(), _state.users.map(AudienceState._userKey).toList()) ||
            _state.count != sdkState.audienceCount.value ||
            !setEquals(_state.mutedUserIDs, mutedUserIDs);
    if (!changed) {
      return;
    }
    _state.users = users;
    _state.count = sdkState.audienceCount.value;
    _state.mutedUserIDs = mutedUserIDs;
    notifyListeners();
  }

  void _performAtomicAction(
    String userID,
    AudienceAction action,
    Future<CompletionHandler> Function() operation,
  ) {
    final int? operationID = _beginOperation(userID, action);
    if (operationID == null) {
      return;
    }
    final int activationID = _activationID;
    operation().then((CompletionHandler result) {
      if (!_isCurrentOperation(userID, operationID, activationID)) {
        return;
      }
      _finishOperation(userID, action, result.isSuccess);
      if (result.isSuccess) {
        refresh();
      }
    }).onError((Object error, StackTrace stackTrace) {
      if (!_isCurrentOperation(userID, operationID, activationID)) {
        return;
      }
      _finishOperation(userID, action, false);
    });
  }

  void _performFollowAction(String userID, AudienceAction action) {
    final int? operationID = _beginOperation(userID, action);
    if (operationID == null) {
      return;
    }
    final int activationID = _activationID;
    final Future<V2TimValueCallback<List<V2TimFollowOperationResult>>> future = action == AudienceAction.follow
        ? _friendshipManager.followUser(userIDList: <String>[userID])
        : _friendshipManager.unfollowUser(userIDList: <String>[userID]);
    future.then((V2TimValueCallback<List<V2TimFollowOperationResult>> result) {
      if (!_isCurrentOperation(userID, operationID, activationID)) {
        return;
      }
      final V2TimFollowOperationResult? userResult =
          result.data?.where((V2TimFollowOperationResult item) => item.userID == userID).firstOrNull;
      final bool succeeded = result.code == 0 && (userResult?.resultCode ?? 0) == 0;
      if (succeeded) {
        _state.followStatusByUserID[userID] =
            action == AudienceAction.follow ? AudienceFollowStatus.following : AudienceFollowStatus.notFollowing;
      }
      _finishOperation(userID, action, succeeded);
    }).onError((Object error, StackTrace stackTrace) {
      if (!_isCurrentOperation(userID, operationID, activationID)) {
        return;
      }
      _finishOperation(userID, action, false);
    });
  }

  void _checkFollowStatus(List<String> userIDs, int activationID) {
    final int queryID = ++_nextOperationID;
    for (final String userID in userIDs) {
      _followQueryIDs[userID] = queryID;
    }
    _friendshipManager
        .checkFollowType(userIDList: userIDs)
        .then((V2TimValueCallback<List<V2TimFollowTypeCheckResult>> result) {
      if (!_isCurrentActivation(activationID)) {
        return;
      }
      if (result.code != 0) {
        notifyListeners();
        return;
      }
      for (final V2TimFollowTypeCheckResult item in result.data ?? <V2TimFollowTypeCheckResult>[]) {
        final String userID = item.userID ?? '';
        if (userID.isEmpty || _followQueryIDs[userID] != queryID) {
          continue;
        }
        final int type = item.followType ?? FollowType.V2TIM_FOLLOW_TYPE_NONE;
        _state.followStatusByUserID[userID] = type == FollowType.V2TIM_FOLLOW_TYPE_IN_MY_FOLLOWING_LIST ||
                type == FollowType.V2TIM_FOLLOW_TYPE_IN_BOTH_FOLLOWERS_LIST
            ? AudienceFollowStatus.following
            : AudienceFollowStatus.notFollowing;
      }
      notifyListeners();
    }).onError((Object error, StackTrace stackTrace) {
      if (!_isCurrentActivation(activationID)) {
        return;
      }
      notifyListeners();
    });
  }

  int? _beginOperation(String userID, AudienceAction action) {
    if (!_isActive || userID.isEmpty || _operationIDs.containsKey(userID)) {
      return null;
    }
    final int operationID = ++_nextOperationID;
    _operationIDs[userID] = operationID;
    _followQueryIDs.remove(userID);
    _state.pendingActionByUserID[userID] = action;
    notifyListeners();
    return operationID;
  }

  void _finishOperation(
    String userID,
    AudienceAction action,
    bool succeeded,
  ) {
    _operationIDs.remove(userID);
    _state.pendingActionByUserID.remove(userID);
    notifyListeners();
    onActionCompleted?.call(userID, action, succeeded);
  }

  bool _isCurrentActivation(int activationID) {
    return _isActive && _activationID == activationID;
  }

  bool _isCurrentOperation(
    String userID,
    int operationID,
    int activationID,
  ) {
    return _isCurrentActivation(activationID) && _operationIDs[userID] == operationID;
  }

  void _bind(Listenable listenable, VoidCallback callback) {
    listenable.addListener(callback);
    _stateListeners.add((listenable, callback));
  }

  @override
  void dispose() {
    deactivate(resetState: true);
    super.dispose();
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
