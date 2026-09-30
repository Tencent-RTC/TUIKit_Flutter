import 'dart:async';

import 'package:meta/meta.dart';
import 'package:atomic_x_core/api/define.dart';
import 'package:atomic_x_core/impl/contact/contact_store_impl.dart';
import 'package:flutter/foundation.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_friend_application.dart';

class GetContactInfoCompletionHandler extends CompletionHandler {
  List<ContactInfo> contactInfoList;

  GetContactInfoCompletionHandler({
    this.contactInfoList = const [],
  });
}

abstract class ContactState {
  ValueListenable<List<ContactInfo>> get friendList;

  ValueListenable<List<FriendApplicationInfo>> get friendApplicationList;

  ValueListenable<int> get friendApplicationUnreadCount;

  ValueListenable<List<ContactInfo>> get blackList;
}

abstract class ContactStore {
  static ContactStore get shared => ContactStoreImpl.shared;

  ContactState get state;

  Future<CompletionHandler> loadFriends();

  Future<CompletionHandler> addFriend({required String userID, String? remark, String? addWording});

  Future<CompletionHandler> deleteFriend({required String userID});

  Future<CompletionHandler> setFriendRemark({required String userID, required String remark});

  Future<GetContactInfoCompletionHandler> getContactInfo({required List<String> userIDList});

  Future<CompletionHandler> loadBlackList();

  Future<CompletionHandler> addToBlacklist({required String userID});

  Future<CompletionHandler> removeFromBlacklist({required String userID});

  Future<CompletionHandler> loadFriendApplications();

  Future<CompletionHandler> acceptFriendApplication({required FriendApplicationInfo info});

  Future<CompletionHandler> refuseFriendApplication({required FriendApplicationInfo info});

  Future<CompletionHandler> clearFriendApplicationUnreadCount();
}

class ContactInfo {
  String userID;
  String? avatarURL;
  String? nickname;
  String? aboutMe;
  ContactOnlineStatus onlineStatus;
  bool isInBlacklist;
  bool isFriend;
  String? friendRemark;

  ContactInfo({
    required this.userID,
    this.avatarURL,
    this.nickname,
    this.aboutMe,
    this.onlineStatus = ContactOnlineStatus.unknown,
    this.isInBlacklist = false,
    this.isFriend = false,
    this.friendRemark,
  });
}

enum ContactOnlineStatus {
  unknown,
  online,
  offline,
}

enum FriendApplicationType {
  received,
  sent,
  both,
}

class FriendApplicationInfo {
  final String userID;
  final String? avatarURL;
  final String? title;
  final String? source;
  final FriendApplicationType type;
  final String? addWording;
  @internal
  final V2TimFriendApplication? rawApplication;

  const FriendApplicationInfo({
    required this.userID,
    this.avatarURL,
    this.title,
    this.source,
    required this.type,
    this.addWording,
    this.rawApplication,
  });
}
