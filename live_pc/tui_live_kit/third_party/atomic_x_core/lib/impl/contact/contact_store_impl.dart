import 'dart:async';

import 'package:atomic_x_core/api/contact/contact_store.dart';
import 'package:atomic_x_core/api/define.dart';
import 'package:atomic_x_core/api/login/login_store.dart';
import 'package:atomic_x_core/impl/common/data_report.dart';
import 'package:atomic_x_core/impl/common/notification_center.dart';
import 'package:atomic_x_core/impl/login/login_store_impl.dart';
import 'package:flutter/foundation.dart';
import 'package:tencent_cloud_chat_sdk/enum/V2TimFriendshipListener.dart';
import 'package:tencent_cloud_chat_sdk/enum/friend_application_type_enum.dart';
import 'package:tencent_cloud_chat_sdk/enum/friend_response_type_enum.dart';
import 'package:tencent_cloud_chat_sdk/enum/friend_type.dart' hide FriendApplicationType;
import 'package:tencent_cloud_chat_sdk/enum/friend_type_enum.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_friend_add_friend_param.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_friend_application.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_friend_info.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_friend_info_result.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_friend_operation_result.dart';
import 'package:tencent_cloud_chat_sdk/native_im/bindings/native_imsdk_bindings_generated.dart';
import 'package:tencent_cloud_chat_sdk/tencent_im_sdk_plugin.dart';

class _ContactStateImpl implements ContactState {
  final ValueNotifier<List<ContactInfo>> friendListValue = ValueNotifier([]);
  final ValueNotifier<List<FriendApplicationInfo>> friendApplicationListValue = ValueNotifier([]);
  final ValueNotifier<int> friendApplicationUnreadCountValue = ValueNotifier(0);
  final ValueNotifier<List<ContactInfo>> blackListValue = ValueNotifier([]);

  @override
  ValueListenable<List<ContactInfo>> get friendList => friendListValue;

  @override
  ValueListenable<List<FriendApplicationInfo>> get friendApplicationList => friendApplicationListValue;

  @override
  ValueListenable<int> get friendApplicationUnreadCount => friendApplicationUnreadCountValue;

  @override
  ValueListenable<List<ContactInfo>> get blackList => blackListValue;
}

class ContactStoreImpl extends ContactStore {
  static final ContactStoreImpl shared = ContactStoreImpl._();

  final _contactState = _ContactStateImpl();

  V2TimFriendshipListener? _friendshipListener;

  LoginStatus _lastObservedLoginStatus = LoginStatus.unlogin;

  ContactStoreImpl._() {
    _addListeners();
    LoginStoreImpl.instance.addListener(_onLoginStateChanged);
  }

  @override
  ContactState get state => _contactState;

  void _onLoginStateChanged() {
    final next = LoginStoreImpl.instance.loginState.loginStatus;
    if (next == _lastObservedLoginStatus) return;
    final prev = _lastObservedLoginStatus;
    _lastObservedLoginStatus = next;

    if (next == LoginStatus.logined) {
      _reattachAfterLogin();
    } else if (prev == LoginStatus.logined) {
      _resetAfterLogout();
    }
  }

  void _reattachAfterLogin() {
    _addListeners();
  }

  void _resetAfterLogout() {
    _contactState.friendListValue.value = const [];
    _contactState.friendApplicationListValue.value = const [];
    _contactState.friendApplicationUnreadCountValue.value = 0;
    _contactState.blackListValue.value = const [];
  }

  void _addListeners() {
    _friendshipListener ??= V2TimFriendshipListener(
      onFriendInfoChanged: _onFriendInfoChanged,
      onFriendApplicationListAdded: _onFriendApplicationListAdded,
      onFriendApplicationListDeleted: _onFriendApplicationListDeleted,
      onFriendApplicationListRead: _onFriendApplicationListRead,
      onFriendListAdded: _onFriendListAdded,
      onFriendListDeleted: _onFriendListDeleted,
      onBlackListAdd: _onBlackListAdded,
      onBlackListDeleted: _onBlackListDeleted,
    );

    TencentImSDKPlugin.v2TIMManager.getFriendshipManager().addFriendListener(listener: _friendshipListener!);
  }

  @override
  Future<CompletionHandler> loadFriends() async {
    DataReport.reportAtomicMetrics(AtomicMetrics.contactList);

    final handler = CompletionHandler();
    final result = await TencentImSDKPlugin.v2TIMManager.getFriendshipManager().getFriendList();

    if (result.code != TIMErrCode.ERR_SUCC.value) {
      handler.errorCode = result.code;
      handler.errorMessage = result.desc;
      return handler;
    }

    final friends = (result.data ?? []).map((friendInfo) => _convertToContactInfo(friendInfo, isFriend: true)).toList();
    _contactState.friendListValue.value = List.unmodifiable(friends);

    return handler;
  }

  @override
  Future<CompletionHandler> addFriend({required String userID, String? remark, String? addWording}) async {
    final handler = CompletionHandler();
    final param = V2TimFriendAddFriendParam(
      userID: userID,
      remark: remark,
      addWording: addWording,
      addSource: "Flutter",
      addType: FriendTypeEnum.V2TIM_FRIEND_TYPE_BOTH,
    );

    final result = await TencentImSDKPlugin.v2TIMManager.getFriendshipManager().addFriend(
        userID: param.userID,
        remark: param.remark,
        friendGroup: param.friendGroup,
        addWording: param.addWording,
        addSource: param.addSource,
        addType: param.addType);

    if (result.code != TIMErrCode.ERR_SUCC.value) {
      handler.errorCode = result.code;
      handler.errorMessage = result.desc;
      return handler;
    }

    final operationResult = result.data;
    if (operationResult != null &&
        (operationResult.resultCode ?? TIMErrCode.ERR_SUCC.value) != TIMErrCode.ERR_SUCC.value) {
      handler.errorCode = operationResult.resultCode!;
      handler.errorMessage = operationResult.resultInfo ?? "Add friend failed";
    }

    return handler;
  }

  @override
  Future<CompletionHandler> deleteFriend({required String userID}) async {
    final handler = CompletionHandler();
    final result = await TencentImSDKPlugin.v2TIMManager
        .getFriendshipManager()
        .deleteFromFriendList(userIDList: [userID], deleteType: FriendTypeEnum.V2TIM_FRIEND_TYPE_BOTH);

    if (result.code != TIMErrCode.ERR_SUCC.value) {
      handler.errorCode = result.code;
      handler.errorMessage = result.desc;
      return handler;
    }

    final firstFailure = _firstFriendFailure(result.data);
    if (firstFailure != null) {
      handler.errorCode = firstFailure.code;
      handler.errorMessage = firstFailure.info;
      return handler;
    }

    final currentList = List<ContactInfo>.from(_contactState.friendListValue.value);
    currentList.removeWhere((f) => f.userID == userID);
    _contactState.friendListValue.value = List.unmodifiable(currentList);

    NotificationCenter().post<Map<String, String>>('FriendDeleted', {
      'userID': userID,
      'conversationID': 'c2c_$userID',
    });

    return handler;
  }

  @override
  Future<CompletionHandler> setFriendRemark({required String userID, required String remark}) async {
    final handler = CompletionHandler();
    final result = await TencentImSDKPlugin.v2TIMManager
        .getFriendshipManager()
        .setFriendInfo(userID: userID, friendRemark: remark);

    if (result.code != TIMErrCode.ERR_SUCC.value) {
      handler.errorCode = result.code;
      handler.errorMessage = result.desc;
      return handler;
    }

    final currentList = List<ContactInfo>.from(_contactState.friendListValue.value);
    final index = currentList.indexWhere((f) => f.userID == userID);
    if (index != -1) {
      currentList[index].friendRemark = remark;
      _contactState.friendListValue.value = List.unmodifiable(currentList);
    }

    return handler;
  }

  @override
  Future<GetContactInfoCompletionHandler> getContactInfo({required List<String> userIDList}) async {
    final handler = GetContactInfoCompletionHandler();
    final imResult = await TencentImSDKPlugin.v2TIMManager.getUsersInfo(userIDList: userIDList);

    if (imResult.code != TIMErrCode.ERR_SUCC.value) {
      handler.errorCode = imResult.code;
      handler.errorMessage = imResult.desc;
      return handler;
    }

    final userInfoList = imResult.data ?? [];
    final queryUserIDs = userInfoList.where((u) => u.userID != null).map((u) => u.userID!).toList();

    // Friend info (relation + remark) keyed by userID.
    final Map<String, V2TimFriendInfoResult> friendInfoMap = {};
    if (queryUserIDs.isNotEmpty) {
      final friendInfoResult =
          await TencentImSDKPlugin.v2TIMManager.v2TIMFriendshipManager.getFriendsInfo(userIDList: queryUserIDs);
      for (final r in friendInfoResult.data ?? []) {
        final id = r.friendInfo?.userID;
        if (id != null && id.isNotEmpty) {
          friendInfoMap[id] = r;
        }
      }
    }

    // Blacklisted userIDs.
    final Set<String> blacklistUserIDs = {};
    final blackListResult = await TencentImSDKPlugin.v2TIMManager.getFriendshipManager().getBlackList();
    if (blackListResult.code == TIMErrCode.ERR_SUCC.value) {
      for (final info in blackListResult.data ?? []) {
        blacklistUserIDs.add(info.userID);
      }
    }

    final contactInfoList = userInfoList.map((userInfo) {
      final userID = userInfo.userID ?? '';
      final friendInfoResult = friendInfoMap[userID];
      return ContactInfo(
        userID: userID,
        avatarURL: userInfo.faceUrl,
        nickname: userInfo.nickName,
        aboutMe: userInfo.selfSignature,
        friendRemark: friendInfoResult?.friendInfo?.friendRemark,
        isFriend: friendInfoResult?.relation == FriendType.V2TIM_FRIEND_TYPE_BOTH,
        isInBlacklist: blacklistUserIDs.contains(userID),
      );
    }).toList();

    // Merge friends into friendList
    _mergeFriendsIntoFriendList(contactInfoList);

    handler.contactInfoList = contactInfoList;
    return handler;
  }

  /// Merge ContactInfo items with isFriend=true into the friendList.
  /// Updates existing entries, adds new ones.
  void _mergeFriendsIntoFriendList(List<ContactInfo> contactInfoList) {
    final friends = contactInfoList.where((c) => c.isFriend).toList();
    if (friends.isEmpty) return;

    final currentList = List<ContactInfo>.from(_contactState.friendListValue.value);
    bool changed = false;

    for (final friend in friends) {
      final index = currentList.indexWhere((c) => c.userID == friend.userID);
      if (index >= 0) {
        // Update existing
        final existing = currentList[index];
        existing.nickname = friend.nickname ?? existing.nickname;
        existing.avatarURL = friend.avatarURL ?? existing.avatarURL;
        existing.aboutMe = friend.aboutMe ?? existing.aboutMe;
        existing.friendRemark = friend.friendRemark ?? existing.friendRemark;
        changed = true;
      } else {
        // Add new
        currentList.add(friend);
        changed = true;
      }
    }

    if (changed) {
      _contactState.friendListValue.value = List.unmodifiable(currentList);
    }
  }

  @override
  Future<CompletionHandler> loadBlackList() async {
    final handler = CompletionHandler();
    final result = await TencentImSDKPlugin.v2TIMManager.getFriendshipManager().getBlackList();

    if (result.code != TIMErrCode.ERR_SUCC.value) {
      handler.errorCode = result.code;
      handler.errorMessage = result.desc;
      return handler;
    }

    final blackList = (result.data ?? []).map((info) => _convertToContactInfo(info, isInBlacklist: true)).toList();
    _contactState.blackListValue.value = List.unmodifiable(blackList);

    return handler;
  }

  @override
  Future<CompletionHandler> addToBlacklist({required String userID}) async {
    final handler = CompletionHandler();
    final result = await TencentImSDKPlugin.v2TIMManager.getFriendshipManager().addToBlackList(userIDList: [userID]);

    if (result.code != TIMErrCode.ERR_SUCC.value) {
      handler.errorCode = result.code;
      handler.errorMessage = result.desc;
      return handler;
    }

    final firstFailure = _firstFriendFailure(result.data);
    if (firstFailure != null) {
      handler.errorCode = firstFailure.code;
      handler.errorMessage = firstFailure.info;
    }

    return handler;
  }

  @override
  Future<CompletionHandler> removeFromBlacklist({required String userID}) async {
    final handler = CompletionHandler();
    final result =
        await TencentImSDKPlugin.v2TIMManager.getFriendshipManager().deleteFromBlackList(userIDList: [userID]);

    if (result.code != TIMErrCode.ERR_SUCC.value) {
      handler.errorCode = result.code;
      handler.errorMessage = result.desc;
      return handler;
    }

    final firstFailure = _firstFriendFailure(result.data);
    if (firstFailure != null) {
      handler.errorCode = firstFailure.code;
      handler.errorMessage = firstFailure.info;
    }

    return handler;
  }

  @override
  Future<CompletionHandler> loadFriendApplications() async {
    final handler = CompletionHandler();
    final result = await TencentImSDKPlugin.v2TIMManager.getFriendshipManager().getFriendApplicationList();

    if (result.code != TIMErrCode.ERR_SUCC.value) {
      handler.errorCode = result.code;
      handler.errorMessage = result.desc;
      return handler;
    }

    final applicationList = _convertToApplicationList(result.data?.friendApplicationList ?? []);
    _contactState.friendApplicationListValue.value = List.unmodifiable(applicationList);
    _contactState.friendApplicationUnreadCountValue.value = result.data?.unreadCount ?? 0;

    return handler;
  }

  @override
  Future<CompletionHandler> acceptFriendApplication({required FriendApplicationInfo info}) async {
    final handler = CompletionHandler();
    final result = await TencentImSDKPlugin.v2TIMManager.getFriendshipManager().acceptFriendApplication(
        responseType: FriendResponseTypeEnum.V2TIM_FRIEND_ACCEPT_AGREE_AND_ADD,
        type: FriendApplicationTypeEnum.V2TIM_FRIEND_APPLICATION_COME_IN,
        userID: info.userID);

    if (result.code != TIMErrCode.ERR_SUCC.value) {
      handler.errorCode = result.code;
      handler.errorMessage = result.desc;
      return handler;
    }

    final op = result.data;
    if (op != null && (op.resultCode ?? TIMErrCode.ERR_SUCC.value) != TIMErrCode.ERR_SUCC.value) {
      handler.errorCode = op.resultCode!;
      handler.errorMessage = op.resultInfo ?? "Accept friend application failed";
      return handler;
    }

    final currentList = List<FriendApplicationInfo>.from(_contactState.friendApplicationListValue.value);
    currentList.removeWhere((app) => app.userID == info.userID);
    _contactState.friendApplicationListValue.value = List.unmodifiable(currentList);

    return handler;
  }

  @override
  Future<CompletionHandler> refuseFriendApplication({required FriendApplicationInfo info}) async {
    final handler = CompletionHandler();
    final result = await TencentImSDKPlugin.v2TIMManager
        .getFriendshipManager()
        .refuseFriendApplication(type: FriendApplicationTypeEnum.V2TIM_FRIEND_APPLICATION_COME_IN, userID: info.userID);

    if (result.code != TIMErrCode.ERR_SUCC.value) {
      handler.errorCode = result.code;
      handler.errorMessage = result.desc;
      return handler;
    }

    final op = result.data;
    if (op != null && (op.resultCode ?? TIMErrCode.ERR_SUCC.value) != TIMErrCode.ERR_SUCC.value) {
      handler.errorCode = op.resultCode!;
      handler.errorMessage = op.resultInfo ?? "Refuse friend application failed";
      return handler;
    }

    final currentList = List<FriendApplicationInfo>.from(_contactState.friendApplicationListValue.value);
    currentList.removeWhere((app) => app.userID == info.userID);
    _contactState.friendApplicationListValue.value = List.unmodifiable(currentList);

    return handler;
  }

  @override
  Future<CompletionHandler> clearFriendApplicationUnreadCount() async {
    final handler = CompletionHandler();
    final result = await TencentImSDKPlugin.v2TIMManager.v2TIMFriendshipManager.setFriendApplicationRead();

    if (result.code != TIMErrCode.ERR_SUCC.value) {
      handler.errorCode = result.code;
      handler.errorMessage = result.desc;
      return handler;
    }

    _contactState.friendApplicationUnreadCountValue.value = 0;

    return handler;
  }

  // ======== Helpers ========

  ({int code, String info})? _firstFriendFailure(List<V2TimFriendOperationResult>? list) {
    if (list == null) return null;
    for (final r in list) {
      final code = r.resultCode ?? TIMErrCode.ERR_SUCC.value;
      if (code != TIMErrCode.ERR_SUCC.value) {
        return (code: code, info: r.resultInfo ?? 'Unknown error');
      }
    }
    return null;
  }

  // ======== Data conversion helpers ========

  ContactInfo _convertToContactInfo(V2TimFriendInfo friendInfo, {bool isFriend = false, bool isInBlacklist = false}) {
    return ContactInfo(
      userID: friendInfo.userID,
      avatarURL: friendInfo.userProfile?.faceUrl,
      nickname: friendInfo.userProfile?.nickName,
      aboutMe: friendInfo.userProfile?.selfSignature,
      friendRemark: friendInfo.friendRemark,
      isFriend: isFriend,
      isInBlacklist: isInBlacklist,
    );
  }

  List<FriendApplicationInfo> _convertToApplicationList(List<V2TimFriendApplication?> v2List) {
    return v2List
        .where((app) => app != null && app.type == FriendApplicationTypeEnum.V2TIM_FRIEND_APPLICATION_COME_IN.index)
        .map((app) => FriendApplicationInfo(
              rawApplication: app!,
              userID: app.userID,
              avatarURL: app.faceUrl,
              title: app.nickname?.isNotEmpty == true ? app.nickname : app.userID,
              type: FriendApplicationType.received,
              addWording: app.addWording,
            ))
        .toList();
  }

  // ======== V2TimFriendshipListener callbacks ========

  void _onFriendInfoChanged(List<V2TimFriendInfo> infoList) {
    bool hasChanges = false;
    final currentList = List<ContactInfo>.from(_contactState.friendListValue.value);

    final friendMap = <String, ContactInfo>{};
    for (final contactInfo in currentList) {
      friendMap[contactInfo.userID] = contactInfo;
    }

    for (var friendInfo in infoList) {
      ContactInfo? contactInfo = friendMap[friendInfo.userID];
      if (contactInfo != null) {
        contactInfo.nickname = friendInfo.userProfile?.nickName;
        contactInfo.avatarURL = friendInfo.userProfile?.faceUrl;
        contactInfo.aboutMe = friendInfo.userProfile?.selfSignature;
        contactInfo.friendRemark = friendInfo.friendRemark;
        hasChanges = true;
      }
    }

    if (hasChanges) {
      _contactState.friendListValue.value = List.unmodifiable(currentList);
    }
  }

  void _onFriendApplicationListAdded(List<V2TimFriendApplication> applicationList) {
    final newApplications = _convertToApplicationList(applicationList);
    final currentList = List<FriendApplicationInfo>.from(_contactState.friendApplicationListValue.value);

    for (final newApp in newApplications) {
      final existingIndex = currentList.indexWhere((app) => app.userID == newApp.userID);
      if (existingIndex == -1) {
        currentList.add(newApp);
      } else {
        currentList[existingIndex] = newApp;
      }
    }

    _contactState.friendApplicationListValue.value = List.unmodifiable(currentList);
    _contactState.friendApplicationUnreadCountValue.value = currentList.length;
  }

  void _onFriendApplicationListDeleted(List<String> userIDList) {
    final currentList = List<FriendApplicationInfo>.from(_contactState.friendApplicationListValue.value);
    currentList.removeWhere((app) => userIDList.contains(app.userID));
    _contactState.friendApplicationListValue.value = List.unmodifiable(currentList);
    _contactState.friendApplicationUnreadCountValue.value = currentList.length;
  }

  void _onFriendApplicationListRead() {
    _contactState.friendApplicationUnreadCountValue.value = 0;
  }

  void _onFriendListAdded(List<V2TimFriendInfo> infoList) {
    final newFriends = infoList.map((info) => _convertToContactInfo(info, isFriend: true)).toList();
    final currentList = List<ContactInfo>.from(_contactState.friendListValue.value);

    for (final newFriend in newFriends) {
      final existingIndex = currentList.indexWhere((friend) => friend.userID == newFriend.userID);
      if (existingIndex == -1) {
        currentList.add(newFriend);
      } else {
        currentList[existingIndex] = newFriend;
      }
    }

    _contactState.friendListValue.value = List.unmodifiable(currentList);
  }

  void _onFriendListDeleted(List<String> userIDList) {
    final currentList = List<ContactInfo>.from(_contactState.friendListValue.value);
    currentList.removeWhere((friend) => userIDList.contains(friend.userID));
    _contactState.friendListValue.value = List.unmodifiable(currentList);
  }

  void _onBlackListAdded(List<V2TimFriendInfo> infoList) {
    final newContacts = infoList.map((info) => _convertToContactInfo(info, isInBlacklist: true)).toList();
    final currentList = List<ContactInfo>.from(_contactState.blackListValue.value);

    for (final newContact in newContacts) {
      final existingIndex = currentList.indexWhere((contact) => contact.userID == newContact.userID);
      if (existingIndex == -1) {
        currentList.add(newContact);
      } else {
        currentList[existingIndex] = newContact;
      }
    }

    _contactState.blackListValue.value = List.unmodifiable(currentList);
  }

  void _onBlackListDeleted(List<String> userIDList) {
    final currentList = List<ContactInfo>.from(_contactState.blackListValue.value);
    currentList.removeWhere((contact) => userIDList.contains(contact.userID));
    _contactState.blackListValue.value = List.unmodifiable(currentList);
  }
}
