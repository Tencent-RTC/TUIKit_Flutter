import 'dart:convert';

class UserModel {
  String userId;
  String userName;
  String avatarURL;

  UserModel({required this.userId, this.userName = '', this.avatarURL = ''});

  Map<String, dynamic> toMap() {
    return <String, dynamic>{'userId': userId, 'userName': userName, 'avatarURL': avatarURL};
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      userId: (map['userId'] ?? '') as String,
      userName: (map['userName'] ?? '') as String,
      avatarURL: (map['avatarURL'] ?? '') as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory UserModel.fromJson(String source) => UserModel.fromMap(json.decode(source) as Map<String, dynamic>);
}
