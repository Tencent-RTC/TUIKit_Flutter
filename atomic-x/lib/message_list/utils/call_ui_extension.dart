import 'dart:convert';

import 'package:tuikit_atomic_x/message_list/widgets/join_in_group_call_widget.dart';
import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/cupertino.dart';

class CallUIExtension {
  static Widget getJoinInGroupCallWidget(String groupId, Map<String, String>? groupAttributes) {
    try {
      if (groupAttributes == null || !groupAttributes.containsKey('inner_attr_kit_info')) {
        return const SizedBox();
      }

      final groupAttAryString = groupAttributes['inner_attr_kit_info'];
      final groupAttAryMap = jsonDecode(groupAttAryString!);

      String? callId = groupAttAryMap['call_id'];
      final businessType = groupAttAryMap['business_type'];
      final roomIDValue = groupAttAryMap['room_id'];
      final roomIDType = groupAttAryMap['room_id_type'];
      final mediaTypeString = groupAttAryMap['call_media_type'];
      final userListFromAttribute = groupAttAryMap['user_list'];
      if (userListFromAttribute is! List) {
        return const SizedBox();
      }

      List<Map<String, dynamic>> userListMap = List<Map<String, dynamic>>.from(userListFromAttribute);

      String roomId = "";
      if (roomIDType != null && roomIDValue != null) {
        roomId = roomIDValue;
      }

      CallMediaType mediaType;
      if (mediaTypeString == 'audio') {
        mediaType = CallMediaType.audio;
      } else {
        mediaType = CallMediaType.video;
      }

      List<String> userIds = [];
      for (var user in userListMap) {
        final userId = user['userid']?.toString();
        if (userId != null && userId.isNotEmpty) {
          userIds.add(userId);
        }
      }

      if (businessType != 'callkit' || userIds.length <= 1 || (mediaTypeString?.isEmpty ?? true)) {
        return const SizedBox();
      }

      return JoinInGroupCallWidget(
        userIDs: userIds,
        roomId: roomId,
        mediaType: mediaType,
        groupId: groupId,
        callId: callId,
      );
    } on FormatException catch (e) {
      print('CallUIExtension - FormatException: $e');
      return const SizedBox();
    } catch (e) {
      print('CallUIExtension - Error: $e');
      return const SizedBox();
    }
  }
}
