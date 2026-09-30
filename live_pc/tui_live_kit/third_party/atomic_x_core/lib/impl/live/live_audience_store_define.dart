// Copyright (c) 2025 Tencent. All rights reserved.
// Module:   LiveAudienceStoreDefine @ AtomicXCore

import 'package:atomic_x_core/api/live/live_audience_store.dart';

extension LiveUserInfoCodec on LiveUserInfo {
  /// Encodes this [LiveUserInfo] into a JSON-compatible map for the native layer.
  Map<String, Object> toMap() {
    return <String, Object>{
      'userID': userID,
      'userName': userName,
      'avatarURL': avatarURL,
      'level': level,
    };
  }

  /// Decodes a [LiveUserInfo] from a native payload [map].
  ///
  /// Returns a default-constructed instance when [map] is null.
  static LiveUserInfo fromMap(Map<String, dynamic>? map) {
    if (map == null) return LiveUserInfo();
    return LiveUserInfo(
      userID: (map['userID'] as String?) ?? '',
      userName: (map['userName'] as String?) ?? '',
      avatarURL: (map['avatarURL'] as String?) ?? '',
      level: (map['level'] as num?)?.toInt() ?? 0,
    );
  }
}
