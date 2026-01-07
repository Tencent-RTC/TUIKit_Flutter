/// MentionInfo represents a mention (@) in the message input.
class MentionInfo {
  /// Special userID for @All
  static const String atAllUserID = '__kImSDK_MesssageAtALL__';

  final String userID;
  final String displayName;
  int startIndex;

  MentionInfo({
    required this.userID,
    required this.displayName,
    required this.startIndex,
  });

  bool get isAtAll => userID == atAllUserID;
  int get length => mentionText.length;
  int get endIndex => startIndex + length;
  String get mentionText => '@$displayName ';

  MentionInfo copyWith({
    String? userID,
    String? displayName,
    int? startIndex,
  }) {
    return MentionInfo(
      userID: userID ?? this.userID,
      displayName: displayName ?? this.displayName,
      startIndex: startIndex ?? this.startIndex,
    );
  }

  @override
  String toString() {
    return 'MentionInfo(userID: $userID, displayName: $displayName, startIndex: $startIndex, length: $length)';
  }
}
