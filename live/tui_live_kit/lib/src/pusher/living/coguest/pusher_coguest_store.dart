import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show StringCharacters;

import '../../../common/live_kit_error_text.dart';
import '../../../common/live_kit_resources.dart';

const pusherCoGuestLayouts = [
  CoGuestLayoutTemplate.floatLayout,
  CoGuestLayoutTemplate.dynamicLayout,
  CoGuestLayoutTemplate.columnLayout,
  CoGuestLayoutTemplate.gridLayout,
];

extension PusherCoGuestLayoutStyle on CoGuestLayoutTemplate {
  (String, String, int, bool) get _configuration => switch (this) {
        CoGuestLayoutTemplate.floatLayout => ('floating', 'livekit_coguest_layout_floating', 6, false),
        CoGuestLayoutTemplate.dynamicLayout => ('grid2', 'livekit_coguest_layout_grid2', 8, false),
        CoGuestLayoutTemplate.columnLayout => ('fixed', 'livekit_coguest_layout_fixed', 6, true),
        CoGuestLayoutTemplate.gridLayout => ('grid9', 'livekit_coguest_layout_grid9', 8, true),
        _ => ('', '', 0, false),
      };
  String get title => LiveKitResources.localizedString('tuilivekit.pusher.coguest.layout.${_configuration.$1}');
  String get assetName => _configuration.$2;
  int get guestCapacity => _configuration.$3;
  bool get showsEmptySeats => _configuration.$4;
}

class PusherCoGuestUser {
  const PusherCoGuestUser({
    required this.userID,
    required this.userName,
    required this.avatarURL,
    this.microphoneStatus = DeviceStatus.off,
    this.allowOpenMicrophone = true,
  });

  final String userID;
  final String userName;
  final String avatarURL;
  final DeviceStatus microphoneStatus;
  final bool allowOpenMicrophone;
}

class PusherCoGuestState {
  PusherCoGuestState({
    this.layout = CoGuestLayoutTemplate.dynamicLayout,
    this.connected = const <PusherCoGuestUser>[],
    this.applicants = const <PusherCoGuestUser>[],
    this.candidates = const <PusherCoGuestUser>[],
    this.invitees = const <PusherCoGuestUser>[],
    Set<String>? pendingUserIDs,
    this.isUpdatingLayout = false,
    this.hasUnreadApplicant = false,
    this.errorMessage,
  }) : pendingUserIDs = pendingUserIDs ?? <String>{};

  CoGuestLayoutTemplate layout;
  List<PusherCoGuestUser> connected;
  List<PusherCoGuestUser> applicants;
  List<PusherCoGuestUser> candidates;
  List<PusherCoGuestUser> invitees;
  Set<String> pendingUserIDs;
  bool isUpdatingLayout;
  bool hasUnreadApplicant;
  String? errorMessage;

  bool get isFull => connected.length >= layout.guestCapacity;
}

abstract interface class PusherCoGuestActionHandling {
  void selectLayout(CoGuestLayoutTemplate layout);
  void acceptApplication(String userID);
  void invite(String userID);
  void cancelInvitation(String userID);
  Future<void> disconnect(String userID);
  void endAllConnections();
  void markApplicantsSeen();
  Future<void> toggleRemoteMicrophone(String userID);
}

class PusherCoGuestStore extends ChangeNotifier implements PusherCoGuestActionHandling {
  PusherCoGuestStore({
    required String liveID,
    required LiveSeatStore seatStore,
    CoGuestStore? coGuestStore,
    String Function()? localUserID,
  })  : _liveID = liveID,
        _seatStore = seatStore,
        _localUserID = localUserID ?? _currentUserID,
        _sdkStore = coGuestStore ?? CoGuestStore.create(liveID);

  static String _currentUserID() => LoginStore.shared.loginState.loginUserInfo?.userID ?? '';

  final String Function() _localUserID;
  final String _liveID;
  final LiveSeatStore _seatStore;
  final CoGuestStore _sdkStore;
  final PusherCoGuestState _state = PusherCoGuestState();

  final List<(Listenable, VoidCallback)> _stateListeners = <(Listenable, VoidCallback)>[];
  bool _isActive = false;
  bool _isConnected = false;
  int _activationID = 0;
  int _layoutOperationID = 0;
  CoGuestLayoutTemplate? _pendingDesiredLayout = CoGuestLayoutTemplate.dynamicLayout;
  Set<String> _seenApplicantIDs = <String>{};

  PusherCoGuestState get state => _state;
  ValueChanged<String>? onToast;

  void activate() {
    if (_isActive) {
      return;
    }
    _isActive = true;
    _pendingDesiredLayout = _state.layout;
    _activationID++;
    final CoGuestState sdkState = _sdkStore.coGuestState;
    for (final Listenable listenable in <Listenable>[
      sdkState.connected,
      sdkState.applicants,
      sdkState.invitees,
      sdkState.candidates,
      _seatStore.liveSeatState.seatList,
    ]) {
      void callback() => _apply();
      listenable.addListener(callback);
      _stateListeners.add((listenable, callback));
    }
    _apply();
  }

  void deactivate() {
    _stopObserving();
    _isConnected = false;
    _pendingDesiredLayout = null;
    _state.connected = const <PusherCoGuestUser>[];
    _state.applicants = const <PusherCoGuestUser>[];
    _state.candidates = const <PusherCoGuestUser>[];
    _state.invitees = const <PusherCoGuestUser>[];
    _state.pendingUserIDs.clear();
    _state.isUpdatingLayout = false;
    _state.errorMessage = null;
    _seenApplicantIDs.clear();
    _state.hasUnreadApplicant = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _stopObserving();
    super.dispose();
  }

  void _stopObserving() {
    _isActive = false;
    _activationID++;
    _layoutOperationID++;
    for (final (Listenable listenable, VoidCallback callback) in _stateListeners) {
      listenable.removeListener(callback);
    }
    _stateListeners.clear();
  }

  @override
  void markApplicantsSeen() {
    _seenApplicantIDs = _state.applicants.map((PusherCoGuestUser user) => user.userID).toSet();
    if (!_state.hasUnreadApplicant) {
      return;
    }
    _state.hasUnreadApplicant = false;
    notifyListeners();
  }

  @override
  void selectLayout(CoGuestLayoutTemplate layout) {
    if (!_isActive || !pusherCoGuestLayouts.contains(layout) || layout == _state.layout || _state.isUpdatingLayout) {
      return;
    }
    if (_state.connected.length > layout.guestCapacity) {
      onToast?.call(LiveKitResources.localizedString('tuilivekit.pusher.coguest.error.capacity'));
      return;
    }
    final CoGuestLayoutTemplate previousLayout = _state.layout;
    _state.errorMessage = null;
    _pendingDesiredLayout = layout;
    if (!_isConnected) {
      notifyListeners();
      return;
    }
    _updateLayout(layout, rollbackLayout: previousLayout);
  }

  /// Match iOS: the live session remains connected after its first successful
  /// connection, including while the transport is reconnecting.
  void didConnect() {
    if (!_isActive) return;
    _isConnected = true;
    synchronizeLayoutIfNeeded();
  }

  /// 开播成功后把开播前选择的布局补发一次。
  void synchronizeLayoutIfNeeded() {
    final CoGuestLayoutTemplate? desiredLayout = _pendingDesiredLayout;
    if (!_isActive || !_isConnected || _state.isUpdatingLayout || desiredLayout == null) {
      return;
    }
    _updateLayout(desiredLayout, rollbackLayout: _state.layout);
  }

  Future<void> _updateLayout(
    CoGuestLayoutTemplate layout, {
    required CoGuestLayoutTemplate rollbackLayout,
  }) async {
    final int operationID = ++_layoutOperationID;
    _state.isUpdatingLayout = true;
    notifyListeners();

    CompletionHandler handler;
    try {
      handler = await _sdkStore.setLayoutTemplate(
        template: layout,
      );
    } catch (_) {
      handler = CompletionHandler()..errorCode = -1;
    }
    if (_layoutOperationID != operationID) {
      return;
    }
    _state.isUpdatingLayout = false;
    _pendingDesiredLayout = null;
    if (handler.isSuccess) {
      _state.layout = layout;
    } else {
      _state.layout = rollbackLayout;
      onToast?.call(_layoutErrorMessage(handler.errorCode));
    }
    notifyListeners();
  }

  String _layoutErrorMessage(int code) {
    final suffix = switch (code) {
      -5 || 7008 || 9506 || 100012 => 'too_frequent',
      -2 => 'unavailable',
      -3 || 6013 => 'not_ready',
      -4 => 'unsupported',
      -7 => 'room_unsupported',
      6014 => 'login_required',
      9508 || 9512 || 9523 || 9524 || 9525 => 'network',
      9510 || 9518 || 9519 || 9520 || 9521 => 'timeout',
      100004 => 'room_missing',
      100006 => 'permission_denied',
      _ => 'failed',
    };
    return LiveKitResources.localizedString('tuilivekit.pusher.coguest.error.layout_$suffix');
  }

  @override
  void acceptApplication(String userID) {
    if (_state.isFull) {
      _showCapacityError();
      return;
    }
    _perform(userID, () => _sdkStore.acceptApplication(userID));
  }

  @override
  void invite(String userID) {
    if (_state.isFull) {
      _showCapacityError();
      return;
    }
    _perform(
      userID,
      () => _sdkStore.inviteToSeat(inviteeID: userID, seatIndex: -1, timeout: 30),
    );
  }

  @override
  void cancelInvitation(String userID) {
    _perform(userID, () => _sdkStore.cancelInvitation(userID));
  }

  @override
  Future<void> disconnect(String userID) async {
    await _perform(userID, () => _seatStore.kickUserOutOfSeat(userID));
  }

  @override
  Future<void> toggleRemoteMicrophone(String userID) async {
    final user = _deviceUser(userID);
    if (user == null) return;
    if (user.allowOpenMicrophone && user.microphoneStatus != DeviceStatus.on) {
      onToast?.call(LiveKitResources.localizedString('tuilivekit.pusher.coguest.microphone_manual_open'));
      return;
    }
    final name = _microphoneToastName(_connectedUser(userID)!);
    final successMessage = LiveKitResources.localizedFormat(
        user.allowOpenMicrophone
            ? 'tuilivekit.pusher.coguest.microphone_closed'
            : 'tuilivekit.pusher.coguest.microphone_unlocked',
        name);
    await _perform(
      userID,
      () => user.allowOpenMicrophone
          ? _seatStore.closeRemoteMicrophone(userID)
          : _seatStore.openRemoteMicrophone(userID: userID, policy: DeviceControlPolicy.unlockOnly),
      successMessage: successMessage,
    );
  }

  String _microphoneToastName(PusherCoGuestUser user) {
    final normalized = user.userName.trim().split(RegExp(r'\s+')).join(' ');
    final name = normalized.isEmpty ? user.userID : normalized;
    final prefix = name.characters.take(8).toString();
    return prefix.length < name.length ? '$prefix…' : name;
  }

  SeatUserInfo? _deviceUser(String userID) {
    if (!_isActive || _state.pendingUserIDs.contains(userID) || _connectedUser(userID) == null) return null;
    for (final seat in _seatStore.liveSeatState.seatList.value) {
      if (seat.userInfo.userID == userID) return seat.userInfo;
    }
    return null;
  }

  /// 结束所有连麦。AtomicXCore 没有批量踢下麦接口，逐个释放席位；
  /// `_perform` 已经对处理中的用户去重。
  @override
  void endAllConnections() {
    for (final PusherCoGuestUser user in List<PusherCoGuestUser>.of(_state.connected)) {
      disconnect(user.userID);
    }
  }

  Future<void> _perform(String userID, Future<CompletionHandler> Function() action, {String? successMessage}) async {
    if (!_isActive || userID.isEmpty || _state.pendingUserIDs.contains(userID)) {
      return;
    }
    _state.pendingUserIDs.add(userID);
    _state.errorMessage = null;
    notifyListeners();

    final int activationID = _activationID;
    CompletionHandler handler;
    try {
      handler = await action();
    } catch (_) {
      handler = CompletionHandler()..errorCode = -1;
    }
    if (!_isActive || _activationID != activationID) {
      return;
    }
    _state.pendingUserIDs.remove(userID);
    if (!handler.isSuccess) {
      onToast?.call(LiveKitErrorText.message(handler));
    }
    notifyListeners();
    if (handler.isSuccess && successMessage != null) {
      onToast?.call(successMessage);
    }
  }

  void _apply() {
    final CoGuestState sdkState = _sdkStore.coGuestState;
    final String loginUserID = _localUserID();
    final Map<String, SeatUserInfo> seatUsers = <String, SeatUserInfo>{
      for (final SeatInfo seat in _seatStore.liveSeatState.seatList.value)
        if (seat.userInfo.userID.isNotEmpty) seat.userInfo.userID: seat.userInfo,
    };

    final List<PusherCoGuestUser> connected = _unique(
      sdkState.connected.value
          .where((SeatUserInfo user) =>
              user.userID != loginUserID && (user.liveID.isEmpty || user.liveID == _liveID) && user.role != Role.owner)
          .map((SeatUserInfo user) => _userFromSeatUser(user, deviceUser: seatUsers[user.userID]))
          .toList(),
    );
    final Set<String> connectedIDs = connected.map((PusherCoGuestUser user) => user.userID).toSet();

    final List<PusherCoGuestUser> applicants = _unique(
      sdkState.applicants.value.map(_userFromLiveUser).toList(),
    ).where((PusherCoGuestUser user) => !connectedIDs.contains(user.userID) && user.userID != loginUserID).toList();
    final Set<String> applicantIDs = applicants.map((PusherCoGuestUser user) => user.userID).toSet();

    final List<PusherCoGuestUser> invitees = _unique(
      sdkState.invitees.value.map(_userFromLiveUser).toList(),
    ).where((PusherCoGuestUser user) => !connectedIDs.contains(user.userID) && user.userID != loginUserID).toList();
    final Set<String> inviteeIDs = invitees.map((PusherCoGuestUser user) => user.userID).toSet();

    final List<PusherCoGuestUser> candidates = _unique(
      sdkState.candidates.value.map(_userFromLiveUser).toList(),
    )
        .where((PusherCoGuestUser user) =>
            !connectedIDs.contains(user.userID) &&
            !applicantIDs.contains(user.userID) &&
            !inviteeIDs.contains(user.userID) &&
            user.userID != loginUserID)
        .toList();

    _state.connected = connected;
    _state.applicants = applicants;
    _state.invitees = invitees;
    _state.candidates = candidates;
    // 丢掉已经消失的申请人，取消后重新申请视为一条新的未读申请。
    _seenApplicantIDs = _seenApplicantIDs.intersection(applicantIDs);
    _state.hasUnreadApplicant = applicants.any((PusherCoGuestUser user) => !_seenApplicantIDs.contains(user.userID));
    notifyListeners();
  }

  List<PusherCoGuestUser> _unique(List<PusherCoGuestUser> users) {
    final Set<String> seen = <String>{};
    return users.where((PusherCoGuestUser user) => user.userID.isNotEmpty && seen.add(user.userID)).toList();
  }

  PusherCoGuestUser _userFromLiveUser(LiveUserInfo user) {
    return PusherCoGuestUser(
      userID: user.userID,
      userName: user.userName.isEmpty ? user.userID : user.userName,
      avatarURL: user.avatarURL,
    );
  }

  PusherCoGuestUser? _connectedUser(String userID) {
    for (final PusherCoGuestUser user in _state.connected) {
      if (user.userID == userID) {
        return user;
      }
    }
    return null;
  }

  PusherCoGuestUser _userFromSeatUser(SeatUserInfo user, {SeatUserInfo? deviceUser}) {
    final SeatUserInfo device = deviceUser ?? user;
    return PusherCoGuestUser(
      userID: user.userID,
      userName: user.userName.isEmpty ? user.userID : user.userName,
      avatarURL: user.avatarURL,
      microphoneStatus: device.microphoneStatus,
      allowOpenMicrophone: device.allowOpenMicrophone,
    );
  }

  void _showCapacityError() {
    onToast?.call(
        LiveKitResources.localizedFormat('tuilivekit.pusher.coguest.error.max_capacity', _state.layout.guestCapacity));
  }
}
