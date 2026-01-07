import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import 'storage_service.dart';

class UserService {
  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;
  UserService._internal();

  static UserService get instance => _instance;

  final ValueNotifier<UserModel?> userModel = ValueNotifier(null);

  final ValueNotifier<bool> openMicrophone = ValueNotifier(true);
  final ValueNotifier<bool> userSpeaker = ValueNotifier(true);
  final ValueNotifier<bool> openCamera = ValueNotifier(true);

  static const String _storageUserModelKey = 'user_model';

  Future<void> saveUserModel() async {
    if (userModel.value != null) {
      final map = userModel.value!.toMap();
      final jsonStr = json.encode(map);
      await StorageService.instance.setString(_storageUserModelKey, jsonStr);
    }
  }

  Future<void> loadUserModel() async {
    try {
      final jsonStr = StorageService.instance.getString(_storageUserModelKey);
      if (jsonStr.isEmpty) return;

      final decoded = json.decode(jsonStr);

      if (decoded is Map<String, dynamic>) {
        userModel.value = UserModel.fromMap(decoded);
      } else {
        print('ERROR: decoded is not Map, type=${decoded.runtimeType}');
      }
    } catch (e, stack) {
      print('ERROR loading user model: $e');
      print('Stack: $stack');
      await destroyUserModel();
    }
  }

  Future<void> destroyUserModel() async {
    await StorageService.instance.remove(_storageUserModelKey);
    userModel.value = null;
  }

  bool haveLoggedInBefore() {
    return StorageService.instance.containsKey(_storageUserModelKey);
  }

  void dispose() {
    userModel.dispose();
    openMicrophone.dispose();
    userSpeaker.dispose();
    openCamera.dispose();
  }
}
