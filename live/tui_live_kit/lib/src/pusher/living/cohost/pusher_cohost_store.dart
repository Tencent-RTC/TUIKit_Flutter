import 'dart:async';
import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/foundation.dart';
import 'package:tencent_cloud_chat_sdk/enum/V2TimFriendshipListener.dart';
import 'package:tencent_cloud_chat_sdk/enum/follow_type.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_user_full_info.dart';
import 'package:tencent_cloud_chat_sdk/tencent_im_sdk_plugin.dart';
import '../../../common/live_kit_error_text.dart';
import '../../../common/live_kit_resources.dart';

enum CoHostFollowStatus { unknown, notFollowing, following, mutual }

@immutable
class PusherCoHostUser {
  const PusherCoHostUser(this.liveID, this.userID, this.userName, this.avatarURL,
      [this.followStatus = CoHostFollowStatus.unknown]);
  final String liveID, userID, userName, avatarURL;
  final CoHostFollowStatus followStatus;
  bool get isFollowing => followStatus == CoHostFollowStatus.following || isMutual;
  bool get isMutual => followStatus == CoHostFollowStatus.mutual;
}

class PusherCoHostState {
  List<PusherCoHostUser> candidates = [], connected = [], invitees = [];
  PusherCoHostUser? applicant;
  DateTime? applicantDeadline, connectionStartedAt;
  Set<String> pendingLiveIDs = {};
  bool isLoading = false, hasMore = true, isConnected = false, isExiting = false;
  String? loadError;
  bool isInvited(String id) => invitees.any((user) => user.liveID == id);
  bool isBusy(String id) => isExiting || pendingLiveIDs.contains(id);
}

class PusherCoHostStore extends ChangeNotifier {
  PusherCoHostStore(this.liveID);
  final String liveID;
  PusherCoHostState _state = PusherCoHostState();
  PusherCoHostState get state => _state;
  bool get isActive => _active;
  ValueChanged<String>? onToast;
  CoHostStore? _sdk;
  int _activation = 0, _sequence = 0;
  bool _active = false;
  String _cursor = '';
  int? _candidateRequest, _applicantID, _respondingID;
  String? _expiredLiveID;
  Timer? _timeout;
  final Map<String, int> _operations = {}, _followRequests = {};
  final Map<String, PusherCoHostUser> _unconfirmedCancellations = {};
  final Map<String, CoHostFollowStatus> _follows = {};
  final List<Listenable> _subscriptions = [];
  CoHostListener? _listener;
  V2TimFriendshipListener? _friendshipListener;
  final _friendship = TencentImSDKPlugin.v2TIMManager.getFriendshipManager();

  void activate() {
    if (_active) return;
    _active = true;
    final activation = ++_activation;
    final store = CoHostStore.create(liveID);
    _sdk = store;
    _subscriptions.addAll([
      store.coHostState.coHostStatus,
      store.coHostState.connected,
      store.coHostState.invitees,
      store.coHostState.applicant,
      store.coHostState.candidates
    ]);
    for (final source in _subscriptions) {
      source.addListener(_apply);
    }
    _listener = CoHostListener(
      onCoHostRequestReceived: (inviter, _) {
        if (!_valid(activation)) return;
        _expiredLiveID = null;
        _updateApplicant(_user(inviter));
        _apply();
      },
      onCoHostRequestCancelled: (inviter, _) {
        if (!_valid(activation)) return;
        if (state.applicant?.liveID == inviter.liveID) _resetApplicant();
        _apply();
      },
      onCoHostRequestTimeout: (inviter, invitee) {
        if (!_valid(activation)) return;
        if (state.applicant?.liveID == inviter.liveID) _resetApplicant();
        final id = inviter.liveID == liveID ? invitee.liveID : inviter.liveID;
        _unconfirmedCancellations.remove(id);
        _operations.remove(id);
        state.pendingLiveIDs.remove(id);
        _toast('request_timeout');
        _apply();
      },
      onCoHostRequestRejected: (invitee) {
        if (!_valid(activation)) return;
        _unconfirmedCancellations.remove(invitee.liveID);
        _toast('request_rejected');
        _apply();
      },
      onCoHostRequestAccepted: (invitee) {
        if (!_valid(activation)) return;
        _unconfirmedCancellations.remove(invitee.liveID);
        _apply();
      },
      onCoHostUserJoined: (_) {
        if (_valid(activation)) _apply();
      },
      onCoHostUserLeft: (_) {
        if (_valid(activation)) _apply();
      },
    );
    store.addCoHostListener(_listener!);
    _friendshipListener = V2TimFriendshipListener(
      onMyFollowingListChanged: (users, _) {
        if (_valid(activation)) _refreshFollows(users);
      },
      onMyFollowersListChanged: (users, _) {
        if (_valid(activation)) _refreshFollows(users);
      },
    );
    _friendship.addFriendListener(listener: _friendshipListener!);
    _apply();
  }

  void deactivate() {
    _detach();
    _state = PusherCoHostState();
    notifyListeners();
  }

  void _detach() {
    _active = false;
    _activation++;
    _timeout?.cancel();
    _timeout = null;
    for (final source in _subscriptions) {
      source.removeListener(_apply);
    }
    _subscriptions.clear();
    if (_listener != null) _sdk?.removeCoHostListener(_listener!);
    if (_friendshipListener != null) _friendship.removeFriendListener(listener: _friendshipListener!);
    _listener = null;
    _friendshipListener = null;
    _sdk = null;
    _operations.clear();
    _unconfirmedCancellations.clear();
    _follows.clear();
    _followRequests.clear();
    _cursor = '';
    _candidateRequest = null;
    _applicantID = null;
    _respondingID = null;
    _expiredLiveID = null;
  }

  @override
  void dispose() {
    _detach();
    super.dispose();
  }

  bool _valid(int activation) => _active && _activation == activation;
  Future<void> refresh() async {
    if (!state.isLoading) {
      _follows.clear();
      _followRequests.clear();
      await _fetch('');
    }
  }

  void loadMore() {
    if (!state.isLoading && state.hasMore) _fetch(_cursor);
  }

  void invite(String id) {
    final sdk = _sdk;
    if (sdk == null || id == liveID || state.isInvited(id) || state.connected.any((user) => user.liveID == id)) return;
    _perform(
        id,
        () => sdk.requestHostConnection(
            targetHostLiveID: id, layoutTemplate: CoHostLayoutTemplate.hostDynamicGrid, timeout: 10));
  }

  void cancelInvitation(String id) {
    final sdk = _sdk;
    if (sdk == null || state.isBusy(id)) return;
    final target = state.invitees.where((user) => user.liveID == id).firstOrNull;
    if (target == null) return;
    _unconfirmedCancellations[id] = target;
    _perform(id, () => sdk.cancelHostConnection(id), completion: (success) {
      if (success) _unconfirmedCancellations.remove(id);
      _apply();
    });
  }

  void acceptInvitation() => _respond(true);
  void rejectInvitation() => _respond(false);
  Future<void> exitConnection() async {
    final sdk = _sdk;
    if (sdk == null || !state.isConnected || state.isExiting || state.pendingLiveIDs.isNotEmpty) return;
    final activation = _activation;
    state.isExiting = true;
    notifyListeners();
    try {
      for (final target in List<PusherCoHostUser>.of(state.invitees)) {
        _unconfirmedCancellations[target.liveID] = target;
        final result = await sdk.cancelHostConnection(target.liveID);
        if (!_valid(activation)) return;
        if (!result.isSuccess) {
          state.isExiting = false;
          _apply();
          onToast?.call(LiveKitErrorText.message(result));
          return;
        }
        _unconfirmedCancellations.remove(target.liveID);
        _apply();
      }
      final result = await sdk.exitHostConnection();
      if (!_valid(activation)) return;
      state.isExiting = false;
      if (!result.isSuccess) onToast?.call(LiveKitErrorText.message(result));
      notifyListeners();
    } catch (_) {
      if (!_valid(activation)) return;
      state.isExiting = false;
      notifyListeners();
      _toast('operation_failed');
    }
  }

  void _respond(bool accept) {
    final sdk = _sdk, target = state.applicant;
    final request = _applicantID;
    if (sdk == null || target == null || request == null || state.isBusy(target.liveID)) return;
    if (state.applicantDeadline?.isAfter(DateTime.now()) != true) {
      _expire(request);
      return;
    }
    if (sdk.coHostState.applicant.value?.liveID != target.liveID) {
      _apply();
      return;
    }
    _timeout?.cancel();
    _respondingID = request;
    _perform(
        target.liveID, () => accept ? sdk.acceptHostConnection(target.liveID) : sdk.rejectHostConnection(target.liveID),
        completion: (_) {
      if (_applicantID != request) return;
      _respondingID = null;
      _apply();
      if (_applicantID == request) _scheduleTimeout(request);
    });
  }

  Future<void> _perform(String id, Future<CompletionHandler> Function() action,
      {void Function(bool)? completion}) async {
    if (!_active || id.isEmpty || state.isBusy(id)) return;
    final activation = _activation, request = ++_sequence;
    _operations[id] = request;
    state.pendingLiveIDs.add(id);
    notifyListeners();
    try {
      final result = await action();
      if (!_valid(activation) || _operations[id] != request) return;
      _operations.remove(id);
      state.pendingLiveIDs.remove(id);
      completion?.call(result.isSuccess);
      if (!result.isSuccess) onToast?.call(LiveKitErrorText.message(result));
      notifyListeners();
    } catch (_) {
      if (!_valid(activation) || _operations[id] != request) return;
      _operations.remove(id);
      state.pendingLiveIDs.remove(id);
      completion?.call(false);
      notifyListeners();
      _toast('operation_failed');
    }
  }

  Future<void> _fetch(String page) async {
    final sdk = _sdk;
    if (sdk == null) return;
    final activation = _activation, request = ++_sequence;
    _candidateRequest = request;
    state.isLoading = true;
    state.loadError = null;
    notifyListeners();
    try {
      final result = await sdk.getCoHostCandidates(page);
      if (!_valid(activation) || _candidateRequest != request) return;
      _candidateRequest = null;
      state.isLoading = false;
      if (result.isSuccess) {
        _cursor = sdk.coHostState.candidatesCursor.value;
        state.hasMore = _cursor.isNotEmpty && _cursor != page;
        _apply();
        _checkFollows(state.candidates.map((user) => user.userID).toList());
      } else {
        state.loadError = LiveKitErrorText.message(result);
      }
      notifyListeners();
    } catch (_) {
      if (!_valid(activation) || _candidateRequest != request) return;
      _candidateRequest = null;
      state.isLoading = false;
      state.loadError = LiveKitResources.localizedString('tuilivekit.pusher.cohost.operation_failed');
      notifyListeners();
    }
  }

  PusherCoHostUser _user(SeatUserInfo info) {
    final old = state.candidates.where((user) => user.liveID == info.liveID).firstOrNull;
    final id = info.userID.isEmpty ? old?.userID ?? '' : info.userID;
    return PusherCoHostUser(info.liveID, id, info.userName.isEmpty ? old?.userName ?? id : info.userName,
        info.avatarURL.isEmpty ? old?.avatarURL ?? '' : info.avatarURL, _follows[id] ?? CoHostFollowStatus.unknown);
  }

  List<PusherCoHostUser> _users(List<SeatUserInfo> source) {
    final ids = <String>{};
    return source
        .where((info) => info.liveID.isNotEmpty && info.liveID != liveID && ids.add(info.liveID))
        .map(_user)
        .toList();
  }

  void _apply() {
    final sdk = _sdk;
    if (!_active || sdk == null) return;
    final source = sdk.coHostState;
    state.connected = _users(source.connected.value);
    for (final user in state.connected) {
      _unconfirmedCancellations.remove(user.liveID);
    }
    final invitees = <String, PusherCoHostUser>{for (final user in _users(source.invitees.value)) user.liveID: user};
    for (final user in _unconfirmedCancellations.values) {
      invitees.putIfAbsent(user.liveID, () => user);
    }
    state.invitees = invitees.values.toList();
    final candidates = <String, PusherCoHostUser>{
      for (final user in _users([...source.connected.value, ...source.candidates.value, ...source.invitees.value]))
        user.liveID: user
    };
    for (final user in state.invitees) {
      candidates.putIfAbsent(user.liveID, () => user);
    }
    state.candidates = candidates.values.toList();
    final connected = source.coHostStatus.value == CoHostStatus.connected;
    if (connected != state.isConnected) {
      state.isConnected = connected;
      state.connectionStartedAt = connected ? DateTime.now() : null;
    }
    final applicant = source.applicant.value;
    if (applicant != null && applicant.liveID.isNotEmpty && applicant.liveID != liveID) {
      if (_expiredLiveID != applicant.liveID) _updateApplicant(_user(applicant));
    } else if (_respondingID == null) {
      _resetApplicant();
      _expiredLiveID = null;
    }
    notifyListeners();
  }

  void _updateApplicant(PusherCoHostUser user) {
    final isNew = state.applicant?.liveID != user.liveID || state.applicant?.userID != user.userID;
    state.applicant = user;
    if (!isNew || !_active) return;
    _timeout?.cancel();
    final id = ++_sequence;
    _applicantID = id;
    _respondingID = null;
    state.applicantDeadline = DateTime.now().add(const Duration(seconds: 10));
    _scheduleTimeout(id);
    _checkFollows([user.userID]);
  }

  void _resetApplicant() {
    _timeout?.cancel();
    _timeout = null;
    _applicantID = null;
    _respondingID = null;
    state.applicant = null;
    state.applicantDeadline = null;
  }

  void _scheduleTimeout(int id) {
    _timeout?.cancel();
    final delay = state.applicantDeadline?.difference(DateTime.now()) ?? Duration.zero;
    _timeout = Timer(delay.isNegative ? Duration.zero : delay, () => _expire(id));
  }

  void _expire(int id) {
    final sdk = _sdk, target = state.applicant;
    if (sdk == null || target == null || id != _applicantID || _respondingID != null) return;
    final current = sdk.coHostState.applicant.value;
    _expiredLiveID = target.liveID;
    _resetApplicant();
    notifyListeners();
    if (current?.liveID == target.liveID && current?.userID == target.userID) {
      unawaited(sdk.rejectHostConnection(target.liveID).then<void>((_) {}, onError: (Object _, StackTrace __) {}));
    } else {
      _apply();
    }
  }

  void _refreshFollows(List<V2TimUserFullInfo> users) {
    final visible = {
      ...state.candidates.map((user) => user.userID),
      if (state.applicant != null) state.applicant!.userID
    };
    final ids = users.map((user) => user.userID ?? '').where(visible.contains).toList();
    for (final id in ids) {
      _follows.remove(id);
      _followRequests.remove(id);
    }
    _checkFollows(ids);
  }

  Future<void> _checkFollows(List<String> source) async {
    if (!_active) return;
    final ids = source
        .toSet()
        .where((id) => id.isNotEmpty && !_follows.containsKey(id) && !_followRequests.containsKey(id))
        .toList();
    if (ids.isEmpty) return;
    final batch = ids.take(100).toList(), activation = _activation, request = ++_sequence;
    for (final id in batch) {
      _followRequests[id] = request;
    }
    try {
      final result = await _friendship.checkFollowType(userIDList: batch);
      if (!_valid(activation)) return;
      if (result.code == 0) {
        for (final item in result.data ?? []) {
          final id = item.userID ?? '';
          if (_followRequests[id] != request || item.resultCode != 0) continue;
          _follows[id] = item.followType == FollowType.V2TIM_FOLLOW_TYPE_IN_BOTH_FOLLOWERS_LIST
              ? CoHostFollowStatus.mutual
              : item.followType == FollowType.V2TIM_FOLLOW_TYPE_IN_MY_FOLLOWING_LIST
                  ? CoHostFollowStatus.following
                  : CoHostFollowStatus.notFollowing;
        }
      } else {
        _toast('follow_query_failed');
      }
      for (final id in batch) {
        if (_followRequests[id] == request) _followRequests.remove(id);
      }
      _apply();
      _checkFollows(ids.skip(100).toList());
    } catch (_) {
      if (!_valid(activation)) return;
      for (final id in batch) {
        if (_followRequests[id] == request) _followRequests.remove(id);
      }
      _toast('follow_query_failed');
    }
  }

  void _toast(String key) => onToast?.call(LiveKitResources.localizedString('tuilivekit.pusher.cohost.$key'));
}
